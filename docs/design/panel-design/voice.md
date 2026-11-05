# Voice

**Be clear when it matters. Play when it doesn't.** Typewriter has a sense of humour, but many of its users
do not have English as a first language, so a joke must never stand between someone and what they need to know.

## Two registers

| Register | When | How it reads |
| --- | --- | --- |
| **Clear** | Errors, warnings, permissions, anything permanent, anything that costs work, anything to act on | Plain, literal words. Short sentences. No idioms, no wordplay |
| **Playful** | Sign in, empty states, long waits, small successes, first run, crash screens around the clear part | Jokes welcome, in simple words. Removing the joke must lose no information |

## Rules

### VO-01 MUST: Important text is literal

When a message matters, it says what happened and what to do, in simple literal English.

- Why: an idiom a native speaker enjoys can stop someone else from understanding what went wrong.
- Check: `visual-llm`.
- Broken: severity 3.
- Do: "The realm did not answer. Retry."
- Don't: "The realm is ignoring us."

### VO-02 MUST: Jokes carry no information

A joke goes beside the clear information, and the clear information stands alone.

- Why: people must be able to skip the joke and lose nothing.
- Check: `visual-llm`.
- Broken: severity 2.
- Do: "Hacking into the Matrix" beside the status "Connecting to the realm".
- Don't: "Hacking into the Matrix" as the only text on the screen.

### VO-03 SHOULD: Playful moments exist

Empty states, sign in, long waits, and crash screens have some personality.

- Why: the panel should sound like someone made it. A sterile voice is a defect here too.
- Check: `human`.
- Broken: severity 1.
- Do: "This page is blank. Press N and fix that."
- Don't: "No data available."

### VO-04 MUST: One action, one name

An action keeps its name everywhere, and its result uses the same word: Publish leads to Published.

- Why: a second name reads as a second action, especially in a second language.
- Check: `visual-llm` across pages.
- Broken: severity 2.
- Don't: "Remove member" and "Remove Member".

### VO-05 MUST: Sentence case and real plurals

- Why: consistency, and "item(s)" reads as a template.
- Check: `visual-llm`.
- Broken: severity 1.
- Do: "Delete 3 pages?"
- Don't: "Delete 3 item(s)?", or strings joined so that "Unbind" becomes "unbindd".

## Examples

| Moment | Text |
| --- | --- |
| Sign in | Your journey starts here |
| Empty book | This page is blank. Press N and fix that. |
| Long wait | Connecting to the realm. A rotating joke may sit beside this, with the status always shown |
| Crash | That jammed. Reload the panel, and tell us on Discord if it happens again. |
| Normal error | The realm did not answer. Retry. |
| Permanent action | Remove Ada? They lose access straight away. |
| Saved | Saved |
| Deleted, with undo | Deleted Arrival. Undo |
