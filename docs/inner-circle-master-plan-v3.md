# Inner Circle — Master Plan v3 (Depth Pass)

Supersedes v2 for scope. v2 shipped the functional core (all Tier 1 + offline Game Shelf + live Firebase). v3 is the depth pass: the app stops being a set of screens and becomes an experience. Everything below is ordered by build block; each block builds, runs, and commits independently.

## Direction (from the founder)

The home feed must be dynamic, not a row of holes. Daily prompts become playable games. The Game Shelf must actually function, multiplayer, including deeper games (Avalon-style social deduction now, a Catan-class board game accounted for in the engine). Journaling gets images, stickers, and the badges you earned at that hangout. Every started hangout gets its own chat, and an AI summary of that chat can be dropped into the postcard. Hangout planning extends to real-world venues and events (BookMyShow / Zomato District energy, dummy data first). Group profiles become social: showcase postcards, search other circles, add them as friends. Stats get creative (GitHub-style heat map of hangouts). The ID Card feels like a physical card you carry and edit.

## Block A — Hangout Chat + AI Digest

- `circles/{id}/hangouts/{hid}/messages` subcollection; same Message/Drops model. ChatRepository generalizes to any messages path.
- Hangout chat opens from the hangout detail once the hangout is live (and stays readable after it ends). System drop announces it in the main chat.
- `AISummaryService`: summarizes any message list in the app's voice.
  - Backend 1: Claude API (`claude-sonnet-5`), key read from gitignored `Secrets.plist` (`AnthropicAPIKey`).
  - Backend 2 (no key): local extractive digest — participants, message count, top-reacted lines, poll results, quirky template. Never blocks the feature on a key.
- "Seal the story" action in hangout chat: generates digest → adds an `aiSummary` block to that hangout's postcard.

## Block B — Postcards v2 (the journal grows up)

- Photo blocks without Blaze: images stored as compressed JPEG base64 in per-photo docs `circles/{id}/postcards/{pid}/media/{mediaId}` (one photo per doc, ~250KB cap, 1MB doc limit respected). Block content holds a `media:` pointer. Storage upload path stays for when Blaze lands.
- New block types: `badge` (a stamp earned at THIS hangout, picked from the stamp wall), `aiSummary` (from Block A). Sticker packs expanded.
- Editor upgrades: block author avatars, long-press to delete your own block before sealing.

## Block C — Multiplayer Game Engine + first playable online games

- Session doc per the v2 schema: `circles/{id}/games/{sessionId}`: gameId, hostId, players[], state (lobby|active|done), round, phase, prompts[], submissions{uid: value}, votes{uid: target}, scores{uid: int}, board{} (reserved for board games), createdAt.
- GameSessionRepository: create/join/leave, phase transitions (host-driven), submissions and votes via field-path updates, realtime listener. All turn-based over Firestore listeners; no servers.
- Game invites are Drops: new `gameInvite` message type; tapping joins the lobby.
- Playable at ship: **Most Likely To** (prompt → vote a member → pie-of-shame reveal, 5 rounds), **Hot Takes** (lock a side → reveal split → minority defends in chat), **Fibber** (Psych-style: subject writes truth, others write fakes, vote the truth, +2 fool / +1 find).
- **The Snake** (the Avalon of Inner Circle): secret roles (2 Snakes), squad picking, mission votes, sabotage, 3 fails = Snakes win. App is the impartial narrator with the seeded lines.
- **Catan-class board game**: the engine's `board` field and turn loop are designed for it; the game itself ("Isle of Settlers" — resources, dice, builds) ships as the flagship of the next games sprint, listed on the shelf as "in the workshop". Building a full board game UI in this pass would starve everything else.
- Sparks become playable: a daily spark can launch a game session (wouldYouRather → Hot Takes format, question kind → answer-and-vote format).

## Block D — Discover: real-world hangouts

- `events-seed.json`: ~24 dummy venues/events across Mumbai-flavored categories (live gigs, food crawls, escape rooms, bowling, comedy nights, turf cricket) with date, price/head, area, emoji, hype copy. Rendered BookMyShow-card style.
- DiscoverView: browse, filter by vibe, "grab tickets" fake-booking flow → confirmation with a booking code → creates a Hangout prefilled (title, venue, date, est cost, poster) with a `venueBooking` field on the hangout + invite drop in chat.
- Entry points: 5th planning mode ("something real"), Home card.
- Later: swap the JSON for a places/events API without touching the UI (repository seam).

## Block E — Circle social layer + creative stats

- Heat map: GitHub-style grid (last 20 weeks) of circle activity (hangouts done + postcards sealed per day) on the Circle Page.
- Circle profile v2: bio + `isPublic` toggle + showcase (pick up to 3 sealed postcards to feature publicly).
- Find circles: search public circles by name → view their public profile (banner, bio, stats, showcase postcards) → send friend request.
- Data: `circles/{id}.bio, isPublic, showcasePostcardIds, friendCircleIds[]`; requests at `circles/{targetId}/friendRequests/{fromCircleId}`.
- Rules update: any signed-in user may create a friendRequest addressed from their own circle; only members accept/delete; public profile fields readable (circle reads already allowed).

## Block F — ID Card v2 + dynamic Home

- ID Card: physical-card treatment — lanyard hole, holo gradient by colorway, avatar, name, tagline, circle name, "member since", stamp count, fake barcode. Tap to flip for stats. Full editor (color/emoji/tagline). Shown on Circle Page member tap + your own from Home.
- Home v2 becomes a feed, ranked by urgency: live hangout > open game lobby > expiring postcard > today's spark (as a playable card) > active poll > event pick from Discover > heat map streak nudge > on-this-day. Chat highlights card uses AISummaryService digest of the last 24h.

## Explicitly deferred (named so nothing is lost)

Isle of Settlers full build; Whispers (DMs); Wave/Circle Up pushes (needs APNs + Blaze functions); real events API; group-vs-group games; awards ceremony; money pool; Storage-backed full-res photos (Blaze).
