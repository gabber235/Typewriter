# Review protocol

How an agent reviews the panel against this record, one page at a time. A reviewer checks rules and also judges
the design. It reports evidence, and a maintainer decides.

## Why it works this way

Research on LLM UI review found good coverage per page, many false findings, weak cross page judgement, and near
chance results when asked "which looks better". So: rule by rule verdicts with evidence, findings without evidence
are dropped, a separate cross page pass runs, and no pairwise comparisons of beauty. These sources are mostly
preprints, and nobody has measured a whole design spec, so the protocol is calibrated on real pages first.

## Set up

Generate sources, then render the page's stories. These are heavy commands, and no server is needed:

```
cargo xtask generate
cargo xtask heavy -- bash -c 'cd panel/widgetbook && flutter test test/every_story_test.dart --reporter=failures-only --name "<lowercase story name>"'
```

Story images land in `.xtask/results/stories/`. Each variant shows one state. Read each image at full size; never
judge from a contact sheet.

Know the limits of each source:

| Evidence | Shows | Cannot show |
| --- | --- | --- |
| Story image | Layout, colour, type, states | Motion. Some images catch a row mid entrance, so faded rows are not a contrast finding |
| Source code | Tokens used, curves, reduced motion, shortcuts, focus targets | How it finally looks |
| Widget test with testkit drivers | Keyboard paths, focus movement, semantics | Appearance |
| A maintainer | How it feels | Coverage |

## Steps for one page

1. **Read** [README.md](README.md), then the chapters that apply, and this page's row in [pages.md](pages.md).
2. **List the actions** a user can take on the page, and the states it has. A state with no story is a finding (PA-01).
3. **Walk each rule** that applies and record `pass`, `fail`, or `cannot_verify`. Do not guess: motion seen only in
   stills is `cannot_verify` until the code is read.
4. **Walk each action** through the experience questions XP-01 to XP-11.
5. **Do the keyboard pass.** For every action: how do you reach it, do it, cancel it, and where does focus land?
6. **Do the critique pass.** See below.
7. **Check your findings.** Drop any without evidence. Check each against the exceptions in [baseline.md](baseline.md).
8. **Run it twice** when a finding is severity 3 or 4, with fresh eyes, and keep what both runs support.

## Critique pass: beyond the rules

Rules catch what we foresaw. This pass asks whether the page is actually good.

| Ask | A bad answer sounds like |
| --- | --- |
| What is this page for, and is that obvious within two seconds? | "It's a list, I think of members?" |
| What does the eye land on first? Should it? | The biggest thing on screen is unimportant |
| What could be removed with nothing lost? | Panels, labels, and borders doing no work |
| Does it feel like the machine, or like generic admin UI? | Could be any product with the logo removed |
| What would an expert be slowed down by? | Six keys for a daily action |
| What would a first time user get stuck on? | Nothing says what to do first |

Each critique item names the region, what is wrong, and a concrete proposal. It is a `suggestion`, not a defect, and
it may also propose a new rule when the record has a gap. A maintainer decides.

## Severity

Use Nielsen's scale, weighing frequency, impact, and persistence. Rules state their severity when broken; raise or
lower it only with a stated reason.

| Level | Meaning | Example |
| --- | --- | --- |
| 4 | Catastrophe: lost work or a blocked task | Shift+D deletes with no question and no undo |
| 3 | Major: a required path fails, or trust is damaged | A value only a pointer can reveal |
| 2 | Minor: friction that adds up | Title and content on different left edges |
| 1 | Cosmetic | "Item(s)" |
| 0 | Not a problem | Drop it |

## Output

One file per page in `docs/design/panel-design/reviews/`, for example `members.md`:

```
## Summary
Two sentences: is this page good, and what is the single most valuable change?

## Findings
- id: MEMBERS-3
  rule: KB-01
  verdict: fail
  severity: 3
  region: "Email under each member name, table row"
  evidence: "blur_reveal.dart:4; story memberlistpage/default/initial.png"
  observed: "Emails unblur only on pointer hover."
  fix: "Reveal on row focus and touch as well."

## Cannot verify
Rule, and what would settle it.

## Suggestions
Critique items, each with region and proposal.
```

## Cross page pass

Run this after every page, comparing only the page reports and images, since per page reviews miss these:

- The same action under different names, keys, or positions.
- Pages that disagree on left edge, heading, density, or main action.
- Patterns solved differently in different places.
- Whether moving between pages keeps the user oriented.

## Calibrating the reviewer

Before the full run, review Members, Services, and the resource editor. A maintainer reads the three reports and
marks each finding right or wrong. Tighten this protocol where it was wrong, then start the full run. Once golden
pages exist, the reviewer must also pass them with no severity 3 or 4 findings.
