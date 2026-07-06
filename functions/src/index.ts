import { initializeApp } from "firebase-admin/app";
import { FieldValue, getFirestore, Timestamp } from "firebase-admin/firestore";
import { onDocumentUpdated } from "firebase-functions/v2/firestore";
import { onSchedule } from "firebase-functions/v2/scheduler";
import { logger } from "firebase-functions";

initializeApp();
const db = getFirestore();

// Deterministic stamp ID keeps awards idempotent across client + functions.
function stampRef(circleId: string, hangoutId: string, kind: string, userId: string) {
  return db
    .collection("circles").doc(circleId)
    .collection("stamps").doc(`${hangoutId}_${kind}_${userId}`);
}

// ---------------------------------------------------------------------------
// sealPostcards: hourly. Closes envelopes whose window expired and awards
// the Scribe stamp to the top contributor of each sealed postcard.
// ---------------------------------------------------------------------------
export const sealPostcards = onSchedule("every 1 hours", async () => {
  const now = Timestamp.now();
  // sealedAt is absent (not null) until sealed, so filter in code
  const pastDeadline = await db
    .collectionGroup("postcards")
    .where("sealsAt", "<=", now)
    .get();
  const expired = pastDeadline.docs.filter((doc) => !doc.data().sealedAt);

  logger.info(`sealing ${expired.length} postcards`);

  for (const doc of expired) {
    const postcard = doc.data();
    const circleRef = doc.ref.parent.parent;
    if (!circleRef) continue;

    await doc.ref.update({ sealedAt: now });

    // Scribe: whoever wrote the most blocks
    const counts = new Map<string, number>();
    for (const block of postcard.blocks ?? []) {
      counts.set(block.authorId, (counts.get(block.authorId) ?? 0) + 1);
    }
    const scribe = [...counts.entries()].sort((a, b) => b[1] - a[1])[0]?.[0];
    if (scribe) {
      await stampRef(circleRef.id, postcard.hangoutId, "scribe", scribe).set({
        userId: scribe,
        kind: "scribe",
        hangoutId: postcard.hangoutId,
        awardedAt: now,
      });
    }

    await circleRef.collection("messages").add({
      senderId: "system",
      sentAt: now,
      type: "system",
      text: `the envelope is sealed ✉️ "${postcard.hangoutTitle ?? "a memory"}" is in the Mailbox forever`,
    });
  }
});

// ---------------------------------------------------------------------------
// dailySpark: every day at noon IST. Promotes one spark to today's prompt
// and drops it into every circle's chat.
// ---------------------------------------------------------------------------
export const dailySpark = onSchedule(
  { schedule: "0 12 * * *", timeZone: "Asia/Kolkata" },
  async () => {
    const today = new Date().toISOString().slice(0, 10);

    const existing = await db.collection("sparks")
      .where("activeDate", "==", today).limit(1).get();
    let sparkDoc = existing.docs[0];

    if (!sparkDoc) {
      // pick an unused spark; recycle the pool when everything's been used
      let pool = await db.collection("sparks")
        .where("activeDate", "==", null).get();
      if (pool.empty) {
        pool = await db.collection("sparks").get();
      }
      if (pool.empty) {
        logger.warn("no sparks seeded, nothing to drop");
        return;
      }
      sparkDoc = pool.docs[Math.floor(Math.random() * pool.size)];
      await sparkDoc.ref.update({ activeDate: today });
    }

    const spark = sparkDoc.data();
    const circles = await db.collection("circles").get();
    logger.info(`dropping today's spark into ${circles.size} circles`);

    for (const circle of circles.docs) {
      await circle.ref.collection("messages").add({
        senderId: "system",
        sentAt: Timestamp.now(),
        type: "spark",
        spark: {
          promptId: sparkDoc.id,
          prompt: spark.prompt,
          kind: spark.kind,
          answers: {},
        },
      });
    }
  }
);

// ---------------------------------------------------------------------------
// awardStamps: fires when a hangout flips to done. Awards Host and
// First One In (server-side safety net for the client-side awards).
// Also keeps circle stats honest if the client bump was missed.
// ---------------------------------------------------------------------------
export const awardStamps = onDocumentUpdated(
  "circles/{circleId}/hangouts/{hangoutId}",
  async (event) => {
    const before = event.data?.before.data();
    const after = event.data?.after.data();
    if (!before || !after) return;
    if (before.status === "done" || after.status !== "done") return;

    const { circleId, hangoutId } = event.params;
    const now = Timestamp.now();

    await stampRef(circleId, hangoutId, "host", after.hostId).set({
      userId: after.hostId,
      kind: "host",
      hangoutId,
      awardedAt: now,
    });

    const arrivals: Record<string, Timestamp> = after.arrivals ?? {};
    const firstIn = Object.entries(arrivals)
      .sort((a, b) => a[1].toMillis() - b[1].toMillis())[0]?.[0];
    if (firstIn) {
      await stampRef(circleId, hangoutId, "firstOneIn", firstIn).set({
        userId: firstIn,
        kind: "firstOneIn",
        hangoutId,
        awardedAt: now,
      });
    }

    if (after.place) {
      await db.collection("circles").doc(circleId).update({
        "stats.placesVisited": FieldValue.increment(1),
      });
    }
  }
);
