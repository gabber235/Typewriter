# Patterns

How common situations behave. Each one applies the questions from [experience.md](experience.md).

| Situation | Behaviour | Rules |
| --- | --- | --- |
| **First load** | Skeleton of the real layout; no spinner over a blank page | XP-07 |
| **Waiting, unknown length** | Caret and a status word, and the words get more specific as time passes | XP-07, MO-05 |
| **Waiting, known length** | Stepped progress | XP-07 |
| **Empty** | Says what belongs here and the key that adds the first one, in the playful register | VO-03 |
| **Error in a field** | The first bad field jams and takes focus; others show a still message | XP-04, VO-01 |
| **Error in an action** | Stays until dealt with, says what happened and what to do, offers Retry | XP-06, VO-01 |
| **Saving** | Saves quietly, then `Saved` types itself and clears | XP-06 |
| **Conflict** | Your work is kept; shows both versions and asks for one choice | XP-06, XP-10 |
| **Change by someone else** | A slow ink mark; nothing moves and focus stays | XP-10 |
| **Connection lost** | One steady notice, edits are kept, and nothing blocks reading | XP-06, XP-10 |
| **Recoverable delete** | One press, focus moves to the next row, Undo offered | XP-09, KB-07 |
| **Permanent action** | Hold to confirm; one line says what will happen | XP-09 |
| **Drag** | Lifts, drops with a Carriage landing; has keyboard and single pointer alternatives | KB-08 |
| **Hidden values** | Revealed by pointer hover, keyboard focus, and touch alike | KB-01 |
| **Tooltip** | After a short wait on hover or focus; quiet fade; shows the key | MO-02, XP-08 |

## Every interactive surface has every state

### PA-01 MUST: States are designed, and shown in Widgetbook

Each surface handles default, hover, focus, active, disabled, loading, empty, error, offline, and compact, as far
as they apply, and its story can show each one.

- Why: states nobody designed are where products feel broken, and a reviewer can only judge what it can capture.
- Check: `test` (the story suite renders every knob).
- Broken: severity 2.
