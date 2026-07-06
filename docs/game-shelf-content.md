# Inner Circle — Game Shelf Spec (10 Online + 10 Offline)

All content packs referenced here live in `seed-content.json`. Naming note: games inspired by commercial titles (Psych, Codenames, Avalon, What Do You Meme) have been given original names and original content so you own the IP and stay clean legally. Mechanics are common-domain; names and content are ours. Deep strategy board games like Catan are out of scope for a chat-first app; the social deduction and word games below deliver the same "game night" energy at a fraction of the build cost.

Shared session model (Firestore, one schema for all online games):
```
games/{sessionId}: gameId, hostId, players[], state, round, phase,
prompts[] (drawn from gameContent), submissions{userId: ...},
votes{userId: targetId}, scores{userId: int}, createdAt
```
Every online game is turn-based over Firestore listeners. No websockets, no servers. A game invite is just a Drop in chat; tapping joins the lobby.

---

## ONLINE GAMES (played in-app)

**1. Fibber** (Psych-style bluffing)
A question about someone in the circle appears ("what is Prem's most irrational fear?"). Everyone except the subject writes a fake answer; the subject writes the real one. All answers shuffle; players vote for the real one. Points: fool a friend +2, find the truth +1. 5 rounds. Content: 40 fill-in prompts in the pack, personalized by inserting member names.

**2. Decode** (Codenames-style word grid)
5x5 grid of words. Two teams, each with a Clue Giver who sees the color map. Clue Givers give a one-word clue + number; teammates tap guesses. Hit the trap word, instant loss. Turn-based, perfect for Firestore. Content: 120 grid words + trap flavor lines.

**3. The Snake** (Avalon/Mafia-style social deduction, hybrid online-offline)
App secretly assigns roles: Snakes (2) vs Loyals. Rounds of mission voting happen in-app; the arguing happens in chat or in person. Snakes sabotage missions anonymously. 3 sabotaged missions = Snakes win. The app is the impartial narrator: role reveals, vote tallies, dramatic round announcements. Content: role cards, narrator lines, mission flavor text.

**4. Most Likely To**
A prompt drops ("most likely to reply 'k' and start a war"), everyone votes for a member, results reveal with a pie of shame. Streak stamps for whoever gets voted 3 rounds straight. Content: 40 prompts.

**5. Hot Takes**
This-or-that with commitment: everyone locks a side, the minority defends themselves in chat (30-second voice note optional). Content: 35 spicy-but-safe debates.

**6. Story Spiral** (from the board's "one sentence at a time, genre twist")
Collaborative story, one sentence per player per turn. Every 3 turns the app forces a genre twist (horror, Bollywood, corporate email, nature documentary). Finished stories auto-save as a Postcard block. Content: 15 genre twists + 25 opening lines.

**7. Caption This** (from the board)
Host uploads a photo (or the app pulls a random one from the group's gallery with permission). Everyone submits a caption anonymously; group votes; winner gets the crown. Winning captions can be saved as cards to the Mailbox. Content: 20 fallback prompt images descriptions + scoring rules.

**8. Emoji Crimes** (emoji pictionary, from the board)
App gives one player a phrase from the deck; they must convey it in emojis only; others guess in chat, fastest correct guess scores. Content: 60 phrases across movies, situations, and inside-joke templates.

**9. Do You Even Know Me**
One member is the subject; they privately answer 5 questions from the deck; everyone else predicts their answers; closest predictor wins. Great for long-distance circles. Content: 40 questions.

**10. Daily Duel** (Wordle-logic word game, original word list)
One shared daily word per circle; everyone gets 6 guesses independently; the circle leaderboard compares guess counts and speed. First solver gets the "Word Nerd" stamp. Content: 90-day curated word list.

---

## OFFLINE GAMES (party content decks, played in person, phone = card dealer)

The app renders these as beautiful swipeable card decks (this is the "very well designed cards" requirement). A "start offline game" flow: pick game → pass-the-phone or everyone opens the deck on their own device via the live hangout.

**1. Dumb Charades**
Classic acting game, app deals the titles. Decks: Bollywood movies (40), Hollywood movies (40), songs (20), impossible mode (10 absurd ones). Timer built in, team scoring.

**2. Truth or Dare**
Spin animation picks a player; they choose truth or dare; app deals a card. Three intensity levels: Mild / Spicy / Chaos (all safe, nothing dangerous or cruel; skip button always visible). Content: 45 truths + 45 dares across levels. Custom cards: circles can write their own and save them to their private deck (board idea: "write your own truths and dares").

**3. King's Cup**
Card-rule drinking game; app deals virtual cards with the rule displayed big. Includes a "zero proof mode" toggle where sips become forfeits (10 jumping jacks, speak in an accent till next turn). Content: all 13 card rules, quirky IC phrasing, + 12 forfeit alternatives. Drink responsibly copy baked in.

**4. Whisper Down** (Paranoia)
App shows a question only to one player ("who here would survive a zombie apocalypse longest?"); they whisper their answer-person's name aloud is NOT allowed, they just say the name; the named person can flip a coin in-app to reveal the question or live in mystery. Content: 30 questions.

**5. Mafia Nights** (Werewolf)
The app is the narrator: assigns roles secretly to each phone, runs night/day cycles with narrator scripts read aloud by the host device, tallies eliminations. Roles: Mafia, Doctor, Detective, Citizens, one wildcard (Drama Queen: must object to every accusation). Content: role descriptions + full narrator script.

**6. Forehead Game** (Heads Up-style, original decks)
Phone on forehead, friends give clues, swipe down for correct. Decks: animals doing jobs, Indian aunty phrases, group inside-joke template deck, celebrities (name only, factual), "things in this room". Content: 60 cards.

**7. Two Truths and a Snake**
Structured rounds with prompt themes so it doesn't stall ("childhood edition", "dating disasters edition"). App tracks who fooled the most people. Content: 15 themed rounds with instructions.

**8. Hot Seat**
One player, 90 seconds, rapid-fire questions dealt by the app, group can veto one skip. Content: 40 questions from soft to unhinged (all safe).

**9. The Hunt** (house-party scavenger hunt)
App deals a list; teams race to photograph items/moments ("something older than the host", "recreate a stock photo", "a stranger's dog if outdoors"). Photos auto-collect into the hangout's Postcard. Content: 3 lists x 12 items (house party, outdoors, restaurant).

**10. Would You Rather: IRL Edition**
Deck of physical-choice would-you-rathers designed for in-person laughing and debating, distinct from the daily Spark pool. Content: 35 cards.

---

## Content & design principles for all decks
- Tone: Gen Z, Indian-context-friendly, playful, PG-13. Nothing cruel, dangerous, discriminatory, or genuinely embarrassing. Skip is always one tap.
- Every deck supports **custom cards** saved per circle (the board's "editable directory of the most played group games customised for your group").
- Funny moments (winning captions, savage votes) can be saved as cards into the Mailbox or the group's quote archive.
- Card visual language: oversized type, one idea per card, deck-specific color worlds, satisfying deal/flip animations. Cards are the flagship design surface of the app.
- Expansion: each deck in `seed-content.json` is a starter pack. To 5x any deck, prompt Claude: "Here are 40 existing cards for [game] with this tone. Generate 160 more, same tone, no duplicates, no m-dashes, keep it safe and Indian-context-friendly."
