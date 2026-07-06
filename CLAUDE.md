# Inner Circle — Project Context for Claude Code

You're building "Inner Circle," an iOS app for one close friend group (max 10 people, one circle per user). This file is your persistent context — read it fully before making changes.

## Stack
- SwiftUI, MVVM, iOS 17+
- Firebase: Auth, Firestore, Storage (added via SPM in Xcode already)
- Cloud Functions (Node/TypeScript) live in a separate `/functions` folder, not part of the Xcode project

## Architecture rule (strict)
Views never touch Firebase directly. All Firestore/Storage/Auth access goes through Repository classes in `Repositories/`. This matters because the UI will later be rebuilt from Figma designs via MCP — keeping views dumb means reskinning never touches logic.

Folder structure:
```
Features/
  Onboarding/
  Home/
  Chat/
  Hangouts/
  Mailbox/
  Circle/
Repositories/
Models/
```

## Vocabulary (use exactly these terms in code, comments, and UI copy)

| Term | Meaning |
|---|---|
| Inner Circle / Circle | The user's one friend group |
| Group Ticket | The 6-character invite code to join a circle |
| Hangout | A planned event |
| Poster | The editable invite artifact for a Hangout |
| RSVP | going / maybe / nope |
| Potluck | Item sign-up list for a Hangout |
| Postcard | Collaborative memory artifact created after a Hangout |
| Mailbox | Archive of all Postcards |
| Time Capsule | A Postcard locked until a future date (`unlockAt` field) |
| Stamps | Individual badges (e.g. "First One In") |
| Trophies | Group-level awards |
| ID Card | A member's customizable profile card |
| Circle Page | The group's editable profile |
| Sparks | Daily prompts / would-you-rathers / challenges |
| Drops | Dynamic chat message types: text, poll, hangoutInvite, spark, system |
| Whisper | A DM (deliberately minimal, group activity is favored) |
| Game Shelf | Library of online + in-person games |

## Copy tone
Quirky, warm, Gen Z, playful. Never corporate. Never use m-dashes. Example: "it's quiet in here. drop a spark?" not "No messages yet."

## Firestore schema

```
users/{userId}
  displayName, avatarUrl, circleId, 
  idCard: { color, emoji, tagline }, 
  status: { text, emoji, setAt },
  createdAt

circles/{circleId}
  name, coverEmoji, coverUrl, code (6-char uppercase, indexed),
  memberIds: [userId], hangoutsCompleted: int, 
  bucketList: [{ id, label, done, doneHangoutId? }],
  stats: { hangoutsCompleted, restaurantsVisited, placesVisited },
  createdAt

circles/{circleId}/messages/{messageId}
  senderId, sentAt,
  type: "text" | "poll" | "hangoutInvite" | "spark" | "system"
  text?, 
  poll?: { question, options: [{ id, label, voterIds: [] }] },
  hangoutId?,
  spark?: { promptId, prompt, answers: { userId: text } }

circles/{circleId}/hangouts/{hangoutId}
  title, hostId, startsAt, place, status: "planning" | "live" | "done",
  mode: "custom" | "howAboutWe" | "request" | "randomizer",
  poster: { templateId, colorway, emoji },
  rsvps: { userId: "going" | "maybe" | "nope" },
  arrivals: { userId: timestamp },
  potluck: [{ id, label, claimedBy? }],
  tasks: [{ id, label, assignedTo?, done }],
  estCost?, bucketListItemId?,
  createdAt

circles/{circleId}/postcards/{postcardId}
  hangoutId, templateId, 
  blocks: [{ id, type: "text"|"photo"|"sticker", content, authorId, position }],
  contributorIds: [], sealedAt?, sealsAt, unlockAt?

circles/{circleId}/stamps/{stampId}
  userId, kind: "firstOneIn" | "host" | "scribe", hangoutId, awardedAt

sparks/{sparkId}
  prompt, kind: "wouldYouRather" | "challenge" | "question", activeDate
```

## Security model
A user can read/write inside `circles/{circleId}/**` only if their uid is in that circle's `memberIds`. Circle codes are looked up via a single indexed query on `circles` collection.

## Build discipline
- One feature block per Claude Code session. Don't sprawl from chat into hangouts into postcards in the same session.
- After finishing a block: actually build and run in Xcode (⌘R) before committing. Don't mark a task done just because the code compiles in isolation — confirm it runs.
- Commit after every working feature.
