# Experience

**Motion is how the panel points. The typewriter is how it does it with character.** The panel's first
job is to answer the questions a user has while working. Motion, focus, keyboard behaviour, and copy
are the tools that answer them. A move or message that answers none of them does not belong.

## Principles

1. **Every move has a job.** It explains, directs, confirms, or warns. Decoration alone is not a job.
2. **Things come from somewhere.** What opens grows from what opened it, and goes back there.
3. **The focus ring is the guide.** It travels to where the user needs to look next.
4. **One loud thing at a time.** The user's own actions are loud. Everything else stays still, so the
   moving thing is the important thing.
5. **Weight tells consequence.** Routine actions feel light. Serious ones feel heavy before they happen.
6. **Quick to arrive, quiet to leave.** Nobody waits for a landing, and exits never bounce.
7. **One machine, everywhere.** Keys strike, the carriage returns, paper feeds, text types, jams judder.
   The same few actions everywhere, so their meaning can be learned. See [motion.md](motion.md).

## The questions

A reviewer asks each question that applies, for every action on a page.

### XP-01 MUST: Where did this come from?

What opens grows from the control or row that opened it, and closes back there. Focus returns there too.

- Why: a surface that appears from nowhere loses its link to its subject.
- Check: `test` for focus return; `visual-llm` for the origin.
- Broken: severity 2.
- Do: the Unbind dialog grows from the `realm_main` row.
- Don't: the dialog fades in at screen centre with no link to the row.

### XP-02 MUST: What did that just change?

When an action changes something shown elsewhere, every visible place showing it gets a brief ink mark.

- Why: the user sees the consequence without searching for it.
- Check: `visual-llm`.
- Broken: severity 2.
- Do: a rename marks the breadcrumb and the tree row.
- Don't: the breadcrumb changes silently.

### XP-03 MUST: Where should I look next?

After an action, focus lands where the next step is, and the ring travels there visibly.

- Why: the user should never have to hunt for what's next.
- Check: `test` for the focus target; `visual-llm` for the visible ring.
- Broken: severity 3.
- Do: New page moves focus to the new page's title field.
- Don't: the row appears and focus stays on the button.

### XP-04 MUST: What matters most right now?

When several things need attention, the first takes the ring and the move. The rest show a still mark.

- Why: one thing to fix, then the next.
- Check: `visual-llm`.
- Broken: severity 2.
- Do: Publish with two invalid fields: the first jams and takes focus, the second shows its message.
- Don't: both shake, or a summary appears with focus left on the button.

### XP-05 MUST: Where am I going?

Going deeper arrives from the right, going back from the left. The breadcrumb always matches.

- Why: direction builds a map of the product in the user's head.
- Check: `visual-llm`.
- Broken: severity 2.
- Do: Library to book moves in from the right; back moves in from the left.
- Don't: every navigation uses the same fade.

### XP-06 MUST: Did it work?

Success is quiet and leaves by itself. Failure is loud, stays until dealt with, and says how to fix it.

- Why: failure must not be missed, and success must not interrupt.
- Check: `test` for persistence; `visual-llm` for treatment.
- Broken: severity 3.
- Do: `Saved` types itself and clears. `Not saved` jams and offers Retry.
- Don't: a failure toast that disappears on a timer.

### XP-07 MUST: Is it still working?

Waiting shows the blinking caret. Measurable work shows stepped progress. When a wait runs long, the
words say more; the motion does not grow.

- Why: the user needs to know it is alive and what it is waiting on.
- Check: `visual-llm`.
- Broken: severity 2.
- Do: `Connecting`, then `Still connecting, the realm is starting`.
- Don't: a spinner that looks the same at 1 second and at 60.

### XP-08 SHOULD: What can I do, and how can I do it faster?

Using a control by pointer presses its key cap. Using its key presses the control.

- Why: the panel teaches shortcuts just by being used.
- Check: `test` for the shared action path; `visual-llm` for the press.
- Broken: severity 1.
- Do: clicking Copy also presses its `C` cap.
- Don't: a shortcut that only appears in documentation.

### XP-09 MUST: How serious is this?

The weight of the interaction matches the consequence.

- **Routine:** one light press.
- **Recoverable** (books, pages, entries): one press acts at once, with no question, and Undo is offered
  straight away. Undo comes from the realm commit history ([authoring-writes.md](../authoring-writes.md)).
- **Permanent** (removing a member, revoking a join code, unbinding a host): hold the key or button. The row
  fills while it is held, one line says what will happen, and letting go early cancels. A setting replaces
  holding with a dialog that has Cancel focused and confirms on Ctrl or Cmd+Enter.
- No key or modifier skips this protection.
- Until undo exists, recoverable actions use the permanent treatment.

Why: a light action must never have a heavy result, and asking about recoverable work only slows people down.

- Check: `test`; `human` for the feel.
- Broken: severity 4 when data is lost without warning or recovery.
- Do: D on a page removes it and offers Undo. Holding D on a member removes them.
- Don't: Shift+D skips the question, or D then Enter removes a member.

### XP-10 MUST: What happened without me?

Changes from other people and from the system are quiet. They never move layout under the user, never
take focus, and never interrupt.

- Why: the user's work and attention belong to the user.
- Check: `test` for focus and layout stability; `visual-llm` for treatment.
- Broken: severity 3.
- Do: a renamed row gets a slowly appearing mark, and the ring stays where it was.
- Don't: a row jumps while the user is about to act on it.

## Reduced motion

### XP-11 MUST: Every answer survives reduced motion

With reduced motion on, the ring jumps instead of sliding, and marks, messages, and focus changes all
still happen. Only the travel goes away.

- Why: the answer is the requirement, and the motion is one way of giving it.
- Check: `test` with reduced motion on.
- Broken: severity 3.

## Open

- None yet.
