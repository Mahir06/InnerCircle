# Inner Circle — Master Plan v2 (Figma Ideation Integrated)

Supersedes v1. Everything from the AMAIVI Figma board (features, IA, flows, terminology, copy, monetisation, target audience) is now merged into one execution document, plus the full Game Shelf spec with 10 online + 10 offline games and generated content (see companion files).

**Companion files:**
- `game-shelf-content.md` — all 20 games: rules, mechanics, data models, design direction
- `seed-content.json` — machine-readable content packs ready to seed into Firestore

---

## 1. Product Definition (from the board)

**Positioning:** Not a replacement for big social media. Inner Circle fills the gap between static group chats and broadcast-style feeds: a dynamic, playful, private space for one existing close friend group. "Your digital headquarters for friendship."

**Target audience:** Gen Z friend groups; people avoiding big social media but wanting to stay updated with their people; long-distance friend groups; groups where planning always dies in the chat.

**Problems it solves (straight from the board):** hard to get responses in a group chat, one person plans everything, can't decide a place and the plan dies, no cost estimates, don't know friends' schedules, people forget to share photos after hangouts, groups go dead.

**Taglines to pick from:** "Real connections, not random likes" / "Curate your crew, connect with those who matter" / "Do you have a dead WhatsApp group? Revive it with Inner Circle."

---

## 2. Vocabulary (final, merged from board + v1)

| Term | Meaning |
|---|---|
| **Inner Circle / IC** | Your one friend group. "IC, i see, icy" wordplay is fair game |
| **Group Ticket** | The join code (was Circle Code). A ticket to the clubhouse |
| **Hangout** | A planned event. Board synonyms for copy flavor: link up, kicking it, vibing |
| **Circle Up!** | Everyone online at once / meeting IRL. Also the wave-everyone CTA |
| **Poster** | Editable invite artifact for a Hangout |
| **Postcard** | Collaborative memory/journal artifact. "Mahir has started a postcard, you have 3 hours before the envelope is sealed" |
| **Mailbox** | The feed/archive. Board also calls it burrow / rabbit hole |
| **Time Capsule** | A locked Postcard revealed on a future date |
| **Whisper** | A DM. Deliberately downplayed so group activity beats isolation |
| **Peekaboo** | A notification |
| **Wave** | Poke a friend / call the circle online |
| **Sparks** | Daily prompts, would-you-rathers, challenges |
| **Drops** | Dynamic chat messages: poll, game invite, hangout, spark, workspace |
| **Stamps** | Individual badges |
| **Trophies / Awards** | Group awards; includes a yearly voting ceremony (superlatives voted by the group, "best of the year" style) |
| **Bucket List** | The group's long-term shared goals (go to Gokarna, night on the beach, college in pyjamas) |
| **ID Card** | Customizable member identity card |
| **Game Shelf** | Library of online + in-person games |
| **The Mascot** | A friendly, slightly dramatic character used for tooltips, empty states, and errors. "Friendly sad mascot who doesn't get to hang out with friends" |

**Copy system (from System Messages section):** quirky everywhere, never corporate, no m-dashes. Examples the board already wrote: chat = "Spill the Tea" / "Warning: may cause group chats until 3 AM"; search = "shhh... it stays here"; forgot password = "damn! really? again?"; profile status = "last seen chilling with the Inner Circle". Every system surface (errors, empty states, permissions, notifications) gets this treatment. Easter eggs are a design principle: the app rewards exploration (e.g., a stamp if you nail your username first try).

---

## 3. Full Feature Map (everything on the board, placed in a tier)

### Tier 1 — Build Day (functional core)
1. **Onboarding & Auth** (per the Login flow section): splash → 3 swipeable story-style onboarding screens → phone/email OTP → name + avatar → permissions (notifications, media, location, mic, contacts) → fork: join with Group Ticket (manual entry or invite link) / create circle (name, picture, generates Ticket + shareable invite graphic). Creator can pre-make a welcome Postcard so joiners get a first impression of the app.
2. **Home (carousel-first)** exactly per the Home Task Flow: status bar with who's online + "free to hangout" statuses, then a carousel of card types: Hangout card (upcoming / joined / no hangout empty state), Expiring Postcard card, Chat Highlights card (AI TL;DR later, most-liked message now), Active Poll / poll stats card, Previous Spark responses card, Hangout join request card. Each card redirects to its feature.
3. **Chat with Drops:** text, media, stickers, polls (with multi-answer toggle per the flow), spark drops, hangout invites, game invites. Reactions on messages. Quote-a-message and save it to the group archive ("hall of fame" quotes).
4. **Hangouts, 4 planning modes** (from Features/First Draft): (a) create custom freeform, (b) "How about we..." presets/curated IC experiences, (c) Request mode: ask someone else to plan, they get a pending request to accept, (d) "Not sure?" randomizer/shortlist mode: swipe cards to shortlist ideas, group votes, winner becomes the plan. Then: poster, RSVP (in/out or vote-first depending on mode), schedule picker (calendar, full day/repeat/start-end time), potluck, tasks, est. cost field, bucket-list tag if it fulfills a Bucket List item, start hangout (arrivals tracked), suggested activities during, end hangout.
5. **Postcards with the sealing ritual:** whoever ends a hangout starts the postcard; contributors have a time window (2 days default, countdown shown) before "the envelope is sealed". Blocks: photos, notes, activity cards, funny chats, stickers; auto date/location/attendees. Late = you "forgot", no edits. This time pressure is the photo-sharing fix from the board.
6. **Mailbox:** archive of postcards, visual calendar view (tap dates), "on this day" random memory resurfacing.
7. **Stamps v1** (3 auto-stamps) + group stats counters (hangouts done, places visited).
8. **Circle Page v1:** editable group banner (group pose), members, Group Ticket share, stats, stamps, Bucket List (create/check items).
9. **Sparks:** daily prompt drop at a set time (BeReal logic: time-boxed, brings everyone online at once).

### Tier 2 — Week 1 (high impact, feasible per the board's own prioritization)
- **Game Shelf** full build: 10 online + 10 offline games (spec + content already generated in companion files). Online games run as Firestore game sessions; challenge friends who are online, leaderboard per game.
- **Whispers (DMs)** top-right, deliberately minimal.
- **Wave / Circle Up:** push notification pokes; "we should meet up" one-tap button.
- **AI layer:** chat TL;DR in quirky tone for the Highlights card, targeted re-engagement prompts ("hey! you haven't posted in a while" done nicely), context-aware activity suggestions during live hangouts.
- **Awards ceremony:** group-voted superlatives (monthly/yearly), plus auto Trophies (10 hangouts, 10 restaurants).
- **ID Card customization** + avatar system (base models per the flow).
- **Photo Gallery extras:** shake-to-shuffle memories, shuffle feature surfacing random old photos, photo wall view, "framed by mahir" attribution on group profile, time capsules (lock a postcard until a date), memory widgets.
- **Places & planning integrations:** location-based activity cards ("exciting places around you"), restaurant roulette, swipe-to-vote on nearby events. (BookMyShow-style ticketing collab and court bookings are Phase 2 partnerships; start with a places API.)

### Tier 3 — Phase 2 (parked deliberately)
- Group-to-group: circles can follow each other, see limited public memories/adventures, group-vs-group game competitions, "add friend groups you know" discovery.
- **Group Mascot pet** (feed it together), virtual group hug (shake to hug), walkie-talkie one-way voice, live audio rooms, AR game rooms.
- **Money pool** for hangouts (payment integration, needs care).
- **Nearby friend alerts** (opt-in location).
- Minecraft-style map of all places the group has covered.
- Multiple views of the mailbox (vertical scroll / wall / zoomable canvas), rotary-dial chat input, spy prompts (secret missions behind the group's back), anonymous "guess who posted", habit tracker with group support, doodle battles, unboxing virtual gifts, friend fortune, emoji rain.
- Multiple circles per user (premium).

### Monetisation (from the board, for later)
One circle free; premium unlocks more circles and quantity limits (e.g., 100 photo blocks per postcard free, more paid; member cap 20 free). Restrict quantities, never quality. Partnership revenue via booking/ticketing integrations.

---

## 4. Updated Data Model Additions (delta from v1)

```
users/{userId}
  + status: { text: "free to hangout", emoji, setAt }      // daily status pop-up
  + avatar: { baseModel, accessories[] }

circles/{circleId}
  + bucketList: [{ id, label, done, doneHangoutId? }]
  + bannerUrl, quotesArchive: [{ text, authorId, savedBy, at }]
  + stats: { hangoutsCompleted, restaurantsVisited, placesVisited, onlineHours }

circles/{circleId}/hangouts/{hangoutId}
  + mode: "custom" | "howAboutWe" | "request" | "randomizer"
  + requestedFrom?: userId, requestStatus?: "pending"|"accepted"
  + shortlist?: [{ id, idea, votes: [userId] }]           // randomizer mode
  + estCost?, bucketListItemId?
  + schedule: { days: [date], fullDay, repeat, startTime, endTime }

circles/{circleId}/postcards/{postcardId}
  + sealsAt: timestamp        // the 2-day window; server function seals it
  + framedBy?: userId         // "mahir framed the memory"

circles/{circleId}/games/{sessionId}                       // Game Shelf online sessions
  gameId, hostId, state: "lobby"|"active"|"done",
  players: [userId], round, turns: {...per-game state}, scores: { userId: int }

circles/{circleId}/whispers/{threadId}/messages/{msgId}    // DMs

gameContent/{deckId}                                       // global, seeded from seed-content.json
  gameId, items: [...]

awards/{circleId}/...                                      // group-voted superlatives, later
```

New Cloud Functions: `sealPostcards` (scheduled, closes expired envelopes + awards Scribe stamps), `dailySpark` (existing), `awardStamps` (existing, extended), later `chatDigest` (Claude API TL;DR).

---

## 5. Revised Build-Day Schedule

Same 12-hour structure as v1 with these swaps: hangout create now ships all 4 modes but randomizer uses a simple vote list (swipe UI is a Week 1 polish); postcards get the seal window + countdown from day one (it's just a timestamp + scheduled function); home is carousel-first since the board's task flow is already the spec; Bucket List is a 30-minute add-on to Circle Page (it's a checklist). Offline Game Shelf can land on build day as a stretch goal because it's pure content rendering from `seed-content.json` (no game logic). Online games are Week 1.

Cut order if behind: randomizer mode → media messages → bucket list → offline shelf. Never cut: chat, hangouts, RSVP, postcard seal ritual.

---

## 6. Claude Workflow (unchanged from v1, plus)

- Add `seed-content.json` to the repo; prompt Claude Code: "Write a Node script to seed gameContent and sparks collections from seed-content.json."
- Add to CLAUDE.md: the full vocabulary table above, the copy system rules, and "the Mascot voice: friendly, dramatic, a little unhinged, never mean."
- For each online game in Week 1, one Claude Code session per game using the mechanics spec in `game-shelf-content.md`; the session schema is shared so games 2 through 10 go fast after game 1.
- Figma MCP reskin flow stays as planned; the board's UI/UX Design section frames become the source once you design them.
