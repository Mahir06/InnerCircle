#!/usr/bin/env node
// Seeds the sparks and gameContent collections from seed-content.json.
// Usage: GOOGLE_APPLICATION_CREDENTIALS=serviceAccount.json npm run seed

const { initializeApp, applicationDefault } = require("firebase-admin/app");
const { getFirestore } = require("firebase-admin/firestore");
const fs = require("fs");
const path = require("path");

initializeApp({ credential: applicationDefault() });
const db = getFirestore();

const seedPath = path.join(__dirname, "..", "..", "seed-content.json");
const seed = JSON.parse(fs.readFileSync(seedPath, "utf8"));

// every deck key in seed-content.json except meta/sparks becomes a
// gameContent/{deckId} doc: { gameId, items }
const GAME_DECKS = {
  fibber_prompts: "fibber",
  decode_words: "decode",
  snake_game: "theSnake",
  most_likely_to: "mostLikelyTo",
  hot_takes: "hotTakes",
  story_spiral: "storySpiral",
  caption_this: "captionThis",
  emoji_crimes: "emojiCrimes",
  do_you_even_know_me: "doYouEvenKnowMe",
  daily_duel_words: "dailyDuel",
  charades_bollywood: "dumbCharades",
  charades_hollywood: "dumbCharades",
  charades_songs: "dumbCharades",
  charades_impossible: "dumbCharades",
  truth_mild: "truthOrDare",
  truth_spicy: "truthOrDare",
  truth_chaos: "truthOrDare",
  dare_mild: "truthOrDare",
  dare_spicy: "truthOrDare",
  dare_chaos: "truthOrDare",
  kings_cup_rules: "kingsCup",
  kings_cup_zero_proof_forfeits: "kingsCup",
  whisper_down: "whisperDown",
  mafia_nights: "mafiaNights",
  forehead_decks: "foreheadGame",
  two_truths_themes: "twoTruthsAndASnake",
  hot_seat: "hotSeat",
  the_hunt: "theHunt",
  wyr_irl: "wyrIRL",
};

async function main() {
  // sparks pool
  let batch = db.batch();
  for (const spark of seed.sparks_daily) {
    const ref = db.collection("sparks").doc();
    batch.set(ref, { prompt: spark.prompt, kind: spark.kind, activeDate: null });
  }
  await batch.commit();
  console.log(`seeded ${seed.sparks_daily.length} sparks`);

  // game content decks
  batch = db.batch();
  let decks = 0;
  for (const [deckKey, gameId] of Object.entries(GAME_DECKS)) {
    if (!seed[deckKey]) continue;
    const ref = db.collection("gameContent").doc(deckKey);
    batch.set(ref, { gameId, items: seed[deckKey] });
    decks += 1;
  }
  await batch.commit();
  console.log(`seeded ${decks} game content decks`);
}

main().then(() => process.exit(0)).catch((err) => {
  console.error(err);
  process.exit(1);
});
