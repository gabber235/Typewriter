# Realm modes

## What it is

A realm runs in one of two modes.

| | Development realm | Production realm |
| --- | --- | --- |
| Purpose | Build and try content | Run released content for protagonists |
| Edit entries | Yes | No; entries are not visible or editable |
| Play content | Yes; a production realm is optional | Yes |
| History | Look back in time through SurrealDB versioning | Numbered **revisions** |
| Branches | No (too complex too quickly) | No |
| Assets | Generated as needed | **Pre generated** per revision |
| Data storage and engines | Handles its engines and protagonist data | Handles its engines and protagonist data |

### From development to production

```
Development realm                     Production realm
  edit, play, look back in time
  select all content or a subset  ->  new revision
  (for example these books,           full compilation
   these tags)                        pre generated assets:
                                        resource packs
                                        road networks
                                        other generated data
                                      stored on the realm
                                      roll back or forward between revisions
```

- A new production revision is always created from a development realm.
- The production realm keeps serving all protagonist data storage and its engines across revisions.
- Rolling back to an earlier revision, or forward again, is easy.
- **Data on rollback: the server owner decides** when rolling back.
  - Moving to a revision makes a **backup** of the data at that point. Rolling back can restore that backup.
  - Or keep the current data. Data that is **detectably invalid** (for example its type changed) resets to its default. Data that is invalid in ways that cannot be detected (Ann's stage 5 in a quest that now has 3 stages may be one) is accepted as is.
- A realm cannot switch modes. A development realm stays a development realm; a production realm stays a production realm.

### Cost

Production mode is **free**, but in practice it needs more than one engine: one for the development realm and one for the production realm. More than one engine needs the multi server add on (see [pricing.md](pricing.md)), so production mode is only useful together with it.

## Who it serves

Server owners (safe releases, quick rollback), content creators (develop freely without touching the live server), protagonists (stable content).

## Why

Live servers need stable, fully compiled content and quick rollback, while development needs free editing. Separating the two keeps both simple.

## Horizon and maturity

| Item | Horizon | Maturity |
| --- | --- | --- |
| Development mode (current behaviour) | closed beta | shaped |
| Development history through SurrealDB versioning | closed beta | shaped |
| No branches | closed beta | settled |
| Production mode with revisions and rollback | closed beta (not at the start) | shaped |
| Transfer of a content subset (books, tags) | closed beta (not at the start) | shaped |
| Pre generated assets per revision | closed beta (not at the start) | shaped |
| Data on rollback: restore backup or keep, chosen by the owner | closed beta (not at the start) | shaped |

## Open questions

- None yet.
