# INNER CIRCLE — The Master Document

**The one-stop context file for this project.** Feed this document to any Claude model (Claude Code, claude.ai, API) and it will have everything: the concept, the research, the architecture, what's built, what's next, and how to take it from here to a Snapchat-scale consumer app. Written for a founder without coding knowledge — every technical section explains what it means and what to say to an AI assistant to act on it.

Last updated: July 2026. Repo: https://github.com/Mahir06/InnerCircle

---

# 1. THE CONCEPT

## 1.1 One-liner
**Inner Circle is the digital headquarters for one close friend group.** Not a social network. One circle, max 10 people, everything a friend group actually does: plan hangouts that don't die in the chat, play games together, and turn memories into collaborative postcards that seal themselves.

## 1.2 Positioning (from the original Figma/AMAIVI board research)
- Not a replacement for big social media. It fills the gap between **static group chats** and **broadcast-style feeds**: a dynamic, playful, private space for one existing close friend group.
- Taglines from ideation: *"Real connections, not random likes"* / *"Curate your crew, connect with those who matter"* / *"Do you have a dead WhatsApp group? Revive it with Inner Circle."*
- **Target audience:** Gen Z friend groups; people avoiding big social media but wanting to stay close with their people; long-distance friend groups; groups where planning always dies in the chat. India-first tone and content (chai, biryani, autos, aunty phrases), globally understandable mechanics.

## 1.3 Problems it solves (verbatim from the board research)
1. Hard to get responses in a group chat
2. One person plans everything
3. Can't decide a place, so the plan dies
4. No cost estimates for plans
5. Don't know friends' schedules
6. People forget to share photos after hangouts
7. Groups go dead

Every core feature maps to one of these: RSVP + polls (1), request-a-planner mode (2), shortlist voting + Discover (3), est. cost field (4), status bar (5), the postcard seal ritual (6), sparks + games + waves (7).

## 1.4 Why this can be big (the Snapchat thesis)
Snapchat won by making one primitive (the disappearing photo) into a daily ritual, then expanding surface area (stories, streaks, map, games). Inner Circle's primitive is **the sealed memory**: a collaborative collage with a 48-hour countdown creates urgency, a reason to open the app daily, and an artifact that compounds (the Mailbox becomes the group's museum). The growth loop: one member books/plans a hangout → Group Ticket invites pull in non-users → the postcard ritual retains them → circle-to-circle friendships expand the graph.

---

# 2. VOCABULARY (use these exact terms in code, UI copy, and prompts)

| Term | Meaning |
|---|---|
| **Inner Circle / IC** | Your one friend group. "IC, i see, icy" wordplay is fair game |
| **Group Ticket** | The 6-character join code. A ticket to the clubhouse |
| **Hangout** | A planned event. Copy synonyms: link up, kicking it, vibing |
| **Circle Up!** | Everyone online at once / meeting IRL; also the wave-everyone CTA |
| **Poster** | The editable invite artifact for a Hangout |
| **Postcard** | Collaborative collage memory artifact created after a Hangout |
| **Mailbox** | Archive of all Postcards (skeuomorphic envelopes) |
| **Time Capsule** | A Postcard locked until a future date |
| **Whisper** | A DM. Deliberately minimal — group activity beats isolation |
| **Peekaboo** | A notification |
| **Wave** | Poke a friend / call the circle online |
| **Sparks** | Daily prompts, would-you-rathers, challenges |
| **Drops** | Dynamic chat message types: text, poll, hangoutInvite, gameInvite, spark, system |
| **Stamps** | Individual badges (First One In, The Host, The Scribe) |
| **Trophies / Awards** | Group awards; yearly voted superlatives ceremony |
| **Bucket List** | The group's long-term shared goals |
| **ID Card** | A member's physical-style, flippable, editable identity card |
| **Circle Page** | The group's editable profile |
| **Game Shelf** | Library of online multiplayer + offline party games |
| **The Scribe** | The AI that summarizes hangout chats into postcard blocks |
| **The Mascot** | Friendly, dramatic, slightly unhinged character for empty states/errors (voice defined; character art not yet designed) |

## 2.1 Copy system (non-negotiable brand voice)
Quirky, warm, Gen Z, playful, lowercase-leaning. **Never corporate. Never use m-dashes.** Examples already shipped: chat = "Spill the Tea" / empty chat = "it's quiet in here. drop a spark?" / forgot password = "damn! really? again?" / profile = "last seen chilling with the Inner Circle". Every system surface (errors, empty states, permissions, notifications) gets this treatment. Easter eggs are a design principle — the app rewards exploration. All copy lives centralized in `InnerCircle/Support/Copy.swift`.

---

# 3. INFORMATION ARCHITECTURE

## 3.1 App structure (5 tabs + overlays)

```
Inner Circle (app)
│
├── ONBOARDING (pre-auth)
│   ├── Story pages (3 swipeable value-prop screens)
│   ├── Auth (email/password; phone OTP planned)
│   ├── ID Card setup (name, emoji, colorway, tagline)
│   └── The Fork: Create circle (name+emoji → Group Ticket reveal+share)
│                 / Join circle (6-char ticket entry)
│
├── TAB 1: HOME — the urgency-ranked feed
│   ├── Status bar (members + "free to hangout" statuses; tap yours to set)
│   ├── Feed cards, ranked: live hangout → open game lobby → game waiting
│   │   on you → expiring postcard → today's spark (playable) → next
│   │   hangout → active poll → spark responses → scribe's 24h recap →
│   │   "out there" event pick → on-this-day memory → game shelf
│   └── → routes to every other tab; games open in sheets
│
├── TAB 2: CHAT ("Spill the Tea")
│   ├── Drops: text, polls (multi-answer), sparks, hangout invites,
│   │   game invites, system announcements
│   ├── Reactions (long-press), quote framing → hall of fame
│   └── + composer: poll builder, drop a spark, open a game table
│
├── TAB 3: HANGOUTS
│   ├── List (posters, status badges LIVE/done, RSVP counts)
│   ├── Plan modes (5): something real (Discover) / custom / how-about-we
│   │   presets / ask-someone-to-plan / shortlist voting
│   ├── Discover: event catalog → detail → pretend booking → ticket stub
│   │   → prefilled hangout with booking code
│   └── Hangout detail: poster (+editor), booking card, request banner,
│       shortlist voting, RSVP, potluck claims, tasks, bucket-list tag,
│       start → arrivals ("i'm here") + hangout chat → end → postcard
│       └── Hangout Chat: full chat surface + "seal the story" (AI digest
│           → postcard block)
│
├── TAB 4: MAILBOX (skeuomorphic)
│   ├── Envelope stack (open flap + seal countdown / wax seal / padlock)
│   ├── Calendar view (dots on memory days) + on-this-day resurfacing
│   └── Postcard Canvas (the collage): paper + stamp + postmark;
│       drag/rotate/resize photos (polaroid), notes, stickers, doodles
│       (finger drawing), badges, scribe summaries; Time Capsule lock;
│       seals at countdown end
│
├── TAB 5: CIRCLE
│   ├── Banner (gradient, name, bio, edit, showcase picker)
│   ├── The Pulse (GitHub-style activity heat map, 20 weeks)
│   ├── Group Ticket share card
│   ├── Stats (hangouts/restaurants/places)
│   ├── Friend requests inbox ("knock knock")
│   ├── Members → ID Cards (flippable physical cards, editable if yours)
│   ├── Friend circles rail → their public profiles
│   ├── Stamps wall, Hall of fame quotes, Bucket List (add/check)
│   └── 🔍 Find Circles (search public circles → profile → add friends)
│
└── GAME SHELF (from Home / live hangouts)
    ├── Live tables (join/watch running sessions)
    ├── Online, playable now: Most Likely To, Hot Takes, Fibber, The Snake
    ├── Offline decks (10): charades, truth-or-dare (3 intensities),
    │   king's cup (+zero-proof), whisper down, mafia nights, forehead
    │   game, two truths & a snake, hot seat, the hunt, WYR IRL
    └── In the workshop (locked teasers): Isle of Settlers, Decode,
        Story Spiral, Caption This, Emoji Crimes, Do You Even Know Me,
        Daily Duel
```

## 3.2 Key user flows (step by step)

**F1. New user, new circle:** open app → 3 story pages → create account (email+password) → make ID Card → "start a circle" → name + emoji → Group Ticket reveal → share sheet → land on Home.

**F2. New user, invited:** receives ticket text → downloads app → story pages → account → ID Card → "i have a Group Ticket" → enters code → lands in the circle with full history visible.

**F3. Plan → hangout → memory (the core loop):**
1. Any member opens Hangouts → + → picks a mode (or books a Discover event).
2. Invite drop lands in chat automatically. Members RSVP, claim potluck, take tasks.
3. Host taps "start the hangout" → status LIVE → announcement in chat, hangout chat opens.
4. People tap "i'm here" (first arrival earns First One In stamp at the end).
5. During: hangout chat, offline game decks from the live section.
6. Host taps "end hangout" → stats bump, bucket-list item checks off, Host + First One In stamps awarded, **postcard opens with 48h countdown**, chat announcement.
7. Everyone collages: photos, notes, doodles, stickers, badges. Anyone in the hangout chat can tap "seal the story" → the Scribe writes the chat's story onto the canvas.
8. Countdown ends → envelope seals (wax seal in the Mailbox). Late = you "forgot," no edits. Optionally locked as a Time Capsule.

**F4. Daily ritual:** noon IST spark drops (Cloud Function when deployed; client fallback live now) → Home card → answer in chat or "make it a game" (spark becomes round one of a Hot Takes table) → lobby invite drops in chat → everyone plays.

**F5. Games:** any member opens a table (shelf, chat composer, or spark) → gameInvite drop in chat → tap to join lobby → host starts → turn-based rounds over live sync → finale scoreboard → winner announced in chat.

**F6. Circle friendship:** Circle Page → 🔍 → search public circles → view profile (bio, stats, showcase postcards) → "add as circle friends" → their Circle Page shows "knock knock" → accept → both see each other in friend rails. (Handshake is eventually-consistent; no cross-circle writes.)

---

# 4. WHAT EXISTS TODAY (fully functional, verified, pushed)

Everything below **works end-to-end against a live Firebase backend** (project `inner-circle-mahir`) and is committed to GitHub (17 commits). Verification method: every block was built, launched in the iOS simulator, screenshot-verified; auth/rules/multiplayer were additionally verified with two real test users against production Firestore.

| Area | Status | Notes |
|---|---|---|
| Onboarding + auth + circle create/join | ✅ live | email/password; rules-enforced join (max 10) |
| Chat with all 6 drop types, reactions, quote saving | ✅ live | polls use transactions (no lost votes) |
| Hangouts: 5 modes, RSVP, potluck, tasks, arrivals, lifecycle | ✅ live | |
| Per-hangout chats + AI "seal the story" | ✅ live | Claude API when key present, quirky local digest otherwise |
| Postcard collage canvas (photos/notes/stickers/doodles/badges) | ✅ live | placements sync live; photos stored in Firestore (free-plan workaround) |
| Envelope Mailbox + calendar + on-this-day + Time Capsules | ✅ live | seal computed client-side until functions deploy |
| Stamps (3 kinds) + stats counters | ✅ live | idempotent (client + future function can both award) |
| Multiplayer games ×4 + offline decks ×10 | ✅ live | shared session engine; 2-player round-trip verified in production |
| Discover events + pretend booking → hangout | ✅ live | 24 dummy events; repository seam ready for a real API |
| Circle social: public profiles, showcase, search, friends | ✅ live | rules deployed |
| Heat map, hall of fame, bucket list, ID cards | ✅ live | |
| Dynamic Home feed | ✅ live | ranked as in §3.1 |
| Design system v2 | ✅ live | purple, Fraunces, chunky cards, skeuomorphism where it delights |
| Security rules | ✅ deployed | member-gated circles, rules-checked join, showcase reads, friend requests |
| Cloud Functions (sealPostcards, dailySpark, awardStamps) | ⚠️ written + typechecked, NOT deployed | needs Blaze plan (see §7) |
| Firebase Storage (full-res photos) | ⚠️ rules written, NOT enabled | needs Blaze; Firestore workaround live |
| Seed content (30 sparks, 29 game decks) | ✅ seeded in production | |

## 4.1 The codebase map (so any Claude can navigate)
```
InnerCircle/                        ← repo root (also has CLAUDE.md, firebase.json,
│                                     firestore.rules, storage.rules, seed-content.json)
├── docs/                           ← this file + master plans v2, v3 + game shelf spec
├── functions/                      ← Cloud Functions (TypeScript) + seed script
└── InnerCircle/                    ← the iOS app (SwiftUI, iOS 27 target)
    ├── App/                        ← entry, session state (AppState), root routing
    ├── Models/                     ← all data types, mirror the Firestore schema
    ├── Repositories/               ← ALL Firebase access lives here (views never
    │                                 touch Firebase — this is why reskinning is safe)
    ├── Features/
    │   ├── Onboarding/  Home/  Chat/  Hangouts/  Mailbox/  Circle/  GameShelf/
    └── Support/                    ← Theme (design system), Copy (all strings),
                                      AISummaryService, seed JSONs, Fraunces fonts
```
**Architecture rule (strict):** views are dumb; view models talk to repositories; repositories talk to Firebase. A design pass never touches logic.

## 4.2 Firestore data model (complete, current)
```
users/{userId}: displayName, avatarUrl?, circleId?, idCard{color,emoji,tagline},
                status{text,emoji,setAt}?, createdAt
circles/{circleId}: name, coverEmoji, code(6-char, indexed), memberIds[],
                bucketList[{id,label,done,doneHangoutId?}],
                stats{hangoutsCompleted,restaurantsVisited,placesVisited},
                quotesArchive[{id,text,authorId,savedBy,at}], createdAt,
                bio?, isPublic?, showcasePostcardIds[]?, friendCircleIds[]?,
                sentFriendRequests[]?
  /messages/{id}: senderId, sentAt, type(text|poll|hangoutInvite|gameInvite|spark|system),
                text?, poll{question,allowsMultipleAnswers,options[{id,label,voterIds[]}]}?,
                hangoutId?, gameSessionId?, spark{promptId,prompt,kind,answers{uid:text}}?,
                reactions{emoji:[uid]}?
  /hangouts/{id}: title, hostId, startsAt?, place?, status(planning|live|done),
                mode(custom|howAboutWe|request|randomizer), poster{templateId,colorway,emoji},
                rsvps{uid:going|maybe|nope}, arrivals{uid:ts}, potluck[], tasks[],
                estCost?, bucketListItemId?, requestedFrom?, requestStatus?,
                shortlist[{id,idea,votes[]}]?, venueBooking{eventId,eventTitle,venue,
                bookingCode,bookedBy,bookedAt}?, createdAt
    /messages/{id}: (same shape as circle messages — the hangout chat)
  /postcards/{id}: hangoutId, hangoutTitle?, templateId, blocks[{id,type(text|photo|
                sticker|badge|aiSummary|doodle), content, authorId, position,
                x?,y?,rotation?,scale?,z?}], contributorIds[], createdAt, sealsAt,
                sealedAt?, unlockAt?, framedBy?
    /media/{id}: data(base64 jpeg), contentType, createdAt   ← free-plan photo storage
  /stamps/{hangoutId_kind_userId}: userId, kind(firstOneIn|host|scribe), hangoutId, awardedAt
  /games/{id}: gameId, hostId, players[], state(lobby|active|done), round, totalRounds,
                phase, prompts[], submissions{uid:v}, votes{uid:v}, scores{uid:int},
                board{string:string}   ← reserved for board games, roles, squads
  /friendRequests/{fromCircleId}: fromCircleId, fromCircleName, fromCircleEmoji,
                sentBy, sentAt, status(pending|accepted)
sparks/{id}: prompt, kind(wouldYouRather|challenge|question), activeDate?
gameContent/{deckId}: gameId, items[]   ← 29 decks seeded
```
**Security model:** everything inside `circles/{id}/**` is members-only. Joining appends exactly your own uid (max 10) — enforced by rules, verified in production. Public circles expose profile fields + up to 3 showcase postcards. Friend requests are the only cross-circle write, restricted to the sender's own request doc.

---

# 5. THE PIPELINE — what to build next (in priority order)

## 5.1 NOW (next 2–4 weeks of sessions) — "make it shippable"
1. **Blaze upgrade + deploy** (30 min, mostly clicks — see §7): unlocks scheduled sealing, the noon spark drop into every chat, server-side stamps, Storage photos, push notifications.
2. **Push notifications (Peekaboos)**: APNs + FCM. The retention engine: "the envelope seals in 3 hours", "spark just dropped", "Prem opened a Fibber table", "you've been voluntold to plan". Requires Apple Developer account + Blaze.
3. **Phone OTP auth** (the board's original spec) + account recovery.
4. **Waves / Circle Up**: one-tap "we should meet" poke → notification to everyone.
5. **Remaining 6 online games** (engine is done; each is ~1 session): Decode (word grid, team play), Story Spiral (auto-saves to a postcard block!), Caption This (uses postcard media), Emoji Crimes, Do You Even Know Me, Daily Duel (daily word + circle leaderboard).
6. **Isle of Settlers** (the Catan-class flagship): dice/resource/build board game on the `board` field. Biggest single build; huge retention payoff.
7. **Whispers (DMs)**: deliberately minimal 1:1 threads (schema already reserved).
8. **Onboarding permissions flow** (notifications, photos, contacts) with mascot copy; contact-based "who else is here".
9. **Media messages in chat** (photos in chat, reuse the postcard media pipeline).
10. **Custom game cards**: circles write their own truth/dare/charades cards saved to a private deck (spec'd in game shelf doc).

## 5.2 NEXT (1–3 months) — "make it sticky"
- **Awards ceremony**: monthly/yearly group-voted superlatives + auto trophies (10 hangouts, 10 restaurants). Big emotional payoff moment.
- **AI layer v2**: context-aware activity suggestions during live hangouts; targeted re-engagement ("it's been 12 days since the last hangout. concerning."); smarter chat digests. Needs a production Anthropic key behind a Cloud Function (never ship keys in the app).
- **Real events API** for Discover (swap the JSON seam): BookMyShow/District/Skiddle-style partner or scraped city guides; booking referral revenue later.
- **Photo gallery extras** (board ideation): shake-to-shuffle memories, photo wall, memory widgets (iOS home screen widget of a random sealed postcard), "framed by" attribution.
- **Streaks**: circle-level streaks (weekly hangout streak, daily spark streak) surfaced on the heat map. Snapchat's most addictive mechanic, adapted to groups.
- **Group mascot pet** (board Tier 3, promoted — feed it together by being active; dies dramatically when the group goes quiet). This is the "tamagotchi retention" play.

## 5.3 LATER (3–12 months) — "make it a network"
- **Group-to-group layer v2**: circle-vs-circle game competitions (the engine's session doc + a `challengerCircleId`), shared events, "circles you may know" discovery via contacts and venue overlap.
- **Money pool** for hangouts (UPI integration in India — needs payments compliance; huge utility unlock).
- **Nearby friend alerts** (opt-in), Minecraft-style map of everywhere the group has been (geo-tagged hangouts).
- **Live audio rooms / walkie-talkie**, AR game rooms (board Tier 3).
- **Multiple circles per user** — the premium unlock (see monetization).
- **Android** (biggest TAM unlock in India; requires a rebuild — Kotlin/Compose or Flutter/React Native rewrite decision; the Firestore backend carries over unchanged).

## 5.4 Monetization (from the board, refined)
Principle: **restrict quantities, never quality.** One circle free forever.
- **IC Plus (subscription)**: multiple circles, >10 members (cap 20), unlimited postcard photo blocks (free tier ~100), premium sticker/poster/ID-card packs, custom game decks beyond a limit, longer time capsules.
- **Partnership revenue**: Discover booking referrals (BookMyShow/District/Zomato-style affiliate), venue promotions ("sponsored: 20% off turf cricket for circles of 6+").
- **Never**: ads in chat, selling data. The privacy promise IS the product.

---

# 6. DESIGN: FROM HERE TO PIXEL-PERFECT

## 6.1 What exists
A coded design system in **one file** (`InnerCircle/Support/Theme.swift`): purple brand (#7B45EB-ish), **Fraunces** display serif (bundled, applied to nav bars app-wide), chunky rounded cards, skeuomorphic moments (envelopes, wax seals, ID cards, paper canvas, postage stamps). Every screen reads colors/fonts/styles from Theme; every string lives in Copy.swift.

## 6.2 The pixel-perfect Figma workflow (step by step, no coding needed)
The project was architected for exactly this: **views contain zero logic**, so replacing their look cannot break features.

1. **Design in Figma.** Build screens on iPhone frames (393×852). Name frames after real screens: `Home`, `Chat`, `PostcardCanvas`, `Mailbox`, `IDCard`, etc. Use Figma styles for colors/type so tokens are extractable.
2. **Connect the Figma MCP server to Claude.** In Figma: enable the Dev Mode MCP server (Figma → Preferences → Enable Dev Mode MCP, or use Figma's remote MCP). In a Claude Code session say: *"connect to my Figma MCP"* — it's already configured in this environment.
3. **Per screen, prompt Claude Code like this** (copy-paste template):
   > "Open my Figma file [paste link with node selected]. Rebuild `HomeView` to match this frame pixel-perfectly. Use `get_design_context` and `get_screenshot` on the selected node. Only change SwiftUI layout/styling — do not touch view models, repositories, or models. Update Theme.swift tokens if the design introduces new colors/type sizes. Build, run in the simulator with `IC_DEMO=1`, screenshot, and compare against the Figma screenshot side by side. Iterate until they match."
4. **Claude verifies itself**: it builds, launches the simulator with demo data (`IC_DEMO=1` + `IC_START_TAB=home|chat|hangouts|mailbox|circle|shelf` shows every screen with realistic content, no login needed), screenshots, and compares to the Figma export. Ask it to overlay/diff if you want extra rigor.
5. **One screen per session**, commit each ("Build discipline" below). Order to reskin: Home → Chat → Mailbox/Canvas → Hangouts → Circle → Games → Onboarding.
6. **Mobbin for reference** (registered, needs one-time authorization — run `/mcp` in an interactive Claude Code session and sign in): pull real Snapchat/BeReal/Partiful flows as reference boards before designing each screen.

## 6.3 Design principles to hold (from the board + what's working)
- Cards are the flagship surface: oversized type, one idea per card, deck-specific color worlds, satisfying deal/flip animations.
- Skeuomorphism where it creates emotion (mail, tickets, ID cards, game tables), flat where it creates speed (feeds, lists).
- The mascot needs character design (illustrations for empty states, errors, onboarding) — commission or generate, then ask Claude to place them (asset catalog + Image views).
- Motion pass: SwiftUI spring animations exist on buttons/cards; a dedicated pass (envelope opening, card dealing, wax-seal stamping, confetti on stamps) is high-ROI. Prompt: *"add a Lottie/Rive-free SwiftUI animation where the envelope flap opens and the postcard slides out when tapping a sealed envelope."*

---

# 7. GOING LIVE — the launch checklist (non-coder edition)

## 7.1 Accounts & money (you do these; ~1 hour total)
1. **Apple Developer Program** — $99/yr — developer.apple.com. Needed for TestFlight, push notifications, App Store.
2. **Firebase Blaze plan** — console.firebase.google.com → inner-circle-mahir → upgrade. Pay-as-you-go; a small app costs single-digit dollars/month. Unlocks: Cloud Functions deploy, Storage, higher limits.
3. **Anthropic API key** — console.anthropic.com — for real AI summaries. Put it behind a Cloud Function (ask Claude: *"move AISummaryService's Claude call into a callable Cloud Function so the key never ships in the app"*).

## 7.2 Then tell Claude Code to (each is one session):
1. "Deploy the Cloud Functions and run the seed script against production; verify sealPostcards seals an expired test postcard."
2. "Set up APNs + FCM push notifications: entitlements, token registration in AppState, notification Cloud Functions for seal-warnings, sparks, game invites, waves."
3. "Switch bundle ID to a real one (e.g. com.kyte.innercircle), set up signing with my Apple team, archive and upload to TestFlight."
4. "Migrate postcard photos from Firestore media docs to Firebase Storage now that Blaze is on; keep backward compatibility with media: pointers."
5. "Add App Store assets: app icon set (need your design), privacy policy page (host on GitHub Pages), App Privacy questionnaire answers, screenshots via simulator."

## 7.3 Launch sequence
1. **TestFlight with 3–5 real friend groups** (your own circle first). Watch: do postcards get sealed with content? Do sparks get answered? Games finished?
2. Iterate the top 3 friction points. 3. **App Store release, India-first.** 4. Campus ambassador loop: the Group Ticket is inherently viral — every circle needs 2–9 more installs. 5. Measure: circles created, % circles with ≥3 members, weekly hangouts per circle, postcard seal rate, D7/D30 retention.

## 7.4 Scale readiness (when it grows)
- Firestore scales horizontally by default; the schema is already per-circle sharded (no global hot documents). At ~100k circles revisit: message pagination (currently last-100), collectionGroup indexes, spark fan-out (move from per-circle writes to a pull model).
- Costs scale with reads: the listener-heavy design is fine to ~tens of thousands of DAU; then add local caching and snapshot debouncing (Claude task, not a rewrite).
- Media: Storage + CDN (automatic via Firebase). AI: batch digests, cache summaries (already cached per message-count).
- Team: this codebase is deliberately legible for AI-assisted development — the architecture rule + this document ARE the onboarding.

---

# 8. WORKING WITH CLAUDE (the founder's playbook)

## 8.1 Environment facts (tell Claude if it doesn't know)
- Repo: `/Users/mahirmalde/Desktop/Desktop/Projects/Inner Circle/InnerCircle`, pushed to `Mahir06/InnerCircle` (gh CLI authenticated).
- **Build with the Xcode 27 beta toolchain**: `DEVELOPER_DIR=/Users/mahirmalde/Downloads/Xcode-beta.app/Contents/Developer xcodebuild -project InnerCircle.xcodeproj -scheme InnerCircle -destination 'generic/platform=iOS Simulator' ARCHS=arm64 build` (release Xcode can't read the project format).
- Run on the iOS 27 simulator via `xcrun simctl install/launch`. **Demo mode**: launch env `IC_DEMO=1` (+ `IC_START_TAB=...`) shows every screen with sample data, no login.
- Firebase project `inner-circle-mahir`; `GoogleService-Info.plist` is in the app folder but **gitignored** (re-download with `firebase apps:sdkconfig IOS 1:806159001044:ios:ccf1855b4010c4a22aa241`). firebase-tools + Node 20 installed under `~/.local`.
- AI summaries read an optional `Secrets.plist` (gitignored) with key `AnthropicAPIKey`.

## 8.2 Build discipline (make Claude follow this every session)
1. One feature block per session. 2. After each block: **build AND launch in the simulator** — compiling is not done; running is done. 3. Commit after every working block with a descriptive message. 4. Push. 5. Views never touch Firebase directly (repositories only). 6. All copy through Copy.swift, all style through Theme.swift, no m-dashes, quirky voice.

## 8.3 Prompt templates that work
- New feature: *"Read docs/INNER-CIRCLE-MASTER-DOC.md first. Build [feature] from pipeline §5.1 item N. Follow the architecture rule. Build, run with IC_DEMO=1, screenshot [screen], commit and push."*
- Bug: *"[Screen] does X when it should do Y. Reproduce in the simulator, fix, verify with a screenshot, commit."*
- Design: use the §6.2 template.
- Never needed: telling it the stack, the schema, or the vocabulary — it's all in this doc.

---

# 9. RESEARCH & IDEATION ARCHIVE (from the original Figma board — kept verbatim so nothing is lost)

**Full feature inventory from ideation**, tiered. Built items marked ✅.

*Tier 1 (functional core):* onboarding & auth ✅ (OTP variant pending), carousel-first home ✅ (evolved into ranked feed), chat with drops ✅, 4 hangout planning modes ✅ (+ 5th, Discover), postcard sealing ritual ✅ (evolved into collage canvas), mailbox + calendar + on-this-day ✅, stamps v1 ✅, circle page ✅, sparks ✅.

*Tier 2 (high impact):* Game Shelf full build (4/10 online ✅, 10/10 offline ✅), whispers, wave/circle-up, AI layer (digests ✅; TL;DR card ✅; re-engagement + live suggestions pending), awards ceremony, ID card customization ✅, photo gallery extras (time capsules ✅; shake-to-shuffle, photo wall, widgets pending), places/planning integrations (dummy Discover ✅; real APIs, restaurant roulette, swipe-to-vote events pending).

*Tier 3 (parked deliberately):* group-to-group follows (basic friends ✅; competitions/discovery pending), group mascot pet, virtual group hug (shake), walkie-talkie, live audio rooms, AR game rooms, money pool, nearby friend alerts, Minecraft-style coverage map, multiple mailbox views (vertical/wall/zoomable canvas), rotary-dial chat input, spy prompts (secret missions), anonymous "guess who posted", habit tracker with group support, doodle battles ✅ (doodles shipped on canvas; battles pending), unboxing virtual gifts, friend fortune, emoji rain, multiple circles (premium).

**System messages ideation (voice examples):** chat "Spill the Tea" / "Warning: may cause group chats until 3 AM" ✅; search "shhh... it stays here" ✅ (find circles); forgot password "damn! really? again?" ✅; status "last seen chilling with the Inner Circle" ✅. Easter egg principle: reward exploration (e.g., a stamp for nailing your username first try — pending).

**Login flow ideation:** splash → 3 story onboarding screens ✅ → phone/email OTP (email/password shipped; OTP pending) → name + avatar ✅ → permissions (pending) → fork: join/create ✅ → creator can pre-make a welcome postcard for joiners (pending — good touch, cheap to build).

**Game Shelf spec** lives in full in `docs/game-shelf-content.md` (all 20 games' mechanics, decks, legal-naming rationale, expansion prompts). Content packs in `seed-content.json` (seeded to production). Deck expansion recipe: *"Here are 40 existing cards for [game] with this tone. Generate 160 more, same tone, no duplicates, no m-dashes, safe and Indian-context-friendly."*

---

# 10. RISKS & HONEST NOTES

- **Two-sided cold start is dodged** (a circle of 4 is a complete product) but **the empty circle is the dropout point**: the creator's first 48 hours decide everything. Invest in the welcome postcard, contact invites, and the mascot cheering them through the first invite.
- **iOS-only caps India reach.** Android is the single biggest growth unlock; plan it once retention is proven (~month 3–6).
- **Snapchat-scale requires a wedge ritual.** Ours is the seal countdown; protect it. Everything that increases "postcards sealed with ≥3 contributors per week per circle" is the metric that matters.
- **Costs**: Firebase free tier carries early usage; Blaze at small scale ≈ $5–20/mo; AI digests behind functions with caching ≈ cents/circle/month.
- **Content safety**: friend-group privacy means low moderation surface, but public circle profiles + showcase postcards need a report flow before App Store review (small build; add to §5.1 when going live).
- **The pbxproj/Xcode-beta quirk** (§8.1) will disappear when Xcode 27 ships stable — until then always use the beta toolchain.

*This document supersedes casual context. Update it when major decisions change — it is the project's memory.*
