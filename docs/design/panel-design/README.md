# Panel design

The target for how the web panel looks, moves, and behaves. Builders work from it, and reviewers
judge every page against it. It describes the target; the gap between today's panel and this target
belongs in `baseline.md`.

## How to read this

Rules have an ID, a level, a reason, and a way to check them:

```
XP-03 MUST  After an action, focus lands where the next step is.
  Why    The user should never have to hunt for what's next.
  Check  test
  Broken severity 3
  Do     New page: focus moves to the new page's title field.
  Don't  New page: the row appears and focus stays on the button.
```

- **Levels.** MUST is a defect when broken. SHOULD needs a stated reason to break. MAY is permission.
- **Checks.** `lint` and `test` are automated. `semantics` reads the semantics tree. `visual-llm` is
  judged from a captured state with the region named. `human` needs a maintainer's eye.
- **Severity** uses Nielsen's scale: 0 not a problem, 1 cosmetic, 2 minor, 3 major, 4 catastrophe.
- **Tokens are normative.** When prose and a token disagree, the token wins and the prose is a defect.

## Stance

Typewriter is a professional tool for people who build game content, used for long sessions, mostly
on a desktop, and often from the keyboard alone. It should feel like a well made machine: it responds
at once, it has weight, and it has a personality of its own.

| We choose | Over |
| --- | --- |
| Character | Neutral politeness |
| Guiding the user | Leaving them to work it out |
| Keyboard speed | Pointer convenience |
| One consistent machine | Local cleverness |
| Consequences that can be felt | Uniform treatment of every action |

Anti-goals: a generic admin dashboard; motion nobody could explain; a playful surface that slows down
someone working fast; anything reachable only with a pointer.

## The non-negotiables

Always in force. A page breaking one of these is not done.

| Rule | In short |
| --- | --- |
| XP-03 | After an action, focus lands where the next step is |
| XP-06 | Success is quiet; failure stays and says how to fix it |
| XP-09 | Weight matches consequence: undo for recoverable work, hold for permanent actions, no bypass |
| XP-10 | Changes from others never move layout or take focus |
| XP-11 | Every answer survives reduced motion |
| MO-01 | Every move has a job |
| MO-02 | Arrivals land |
| MO-03 | In place within 150 ms, and retargetable |
| MO-04 | Exits never bounce |
| MO-06 | Durations and curves come from tokens |
| KB-01 | Everything works without a pointer |
| KB-02 | The current mode is always visible |
| KB-03 | Every command is in the command list with its key |
| KB-04 | No default binding on a key the browser or OS takes |
| KB-07 | Focus is never lost |
| CO-01 | Text reaches 4.5:1 |
| CO-03 | The ring is unmistakable, at every size |
| LA-01 | The active pane lifts |
| LA-03 | One main action per pane |
| VO-01 | Important text is literal |

## Chapters

| File | Covers |
| --- | --- |
| [experience.md](experience.md) | The questions the panel answers for its user, on every action |
| [motion.md](motion.md) | The machine: how each kind of move behaves, with tokens |
| [keyboard.md](keyboard.md) | The mode model, commands, focus, and reserved keys |
| [foundations.md](foundations.md) | Type, colour, spacing, shape, elevation, icons, density, layout |
| [components.md](components.md) | One component per job, and the state matrix |
| [patterns.md](patterns.md) | How common situations behave |
| [voice.md](voice.md) | Clear when it matters, playful when it doesn't |
| [pages.md](pages.md) | Page types and every surface to review, with its story |
| [review.md](review.md) | How an agent reviews a page: evidence, severity, output |
| [baseline.md](baseline.md) | Today's panel against the rules: the starting backlog and approved exceptions |
| [demos/experience.html](demos/experience.html) | The experience questions, playing live |

## Open

Each chapter ends with its own Open list where it has one. The biggest open items need the real panel: tuning motion
tokens, and how the active pane lift works in light mode.
