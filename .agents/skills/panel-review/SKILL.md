---
name: panel-review
description: Review a web panel page or surface against the design rules. Use when asked to review, audit, or judge how a panel page looks, moves, or behaves, including page by page review runs.
---

# Panel Review

Load the `panel-design` skill first. Read each of its rules as: when you see When, expect Then, otherwise report at `Sev`.

## Reviewing one page

1. Find the page in the inventory below. Read its stories' source and its presentation code.
2. Render its stories:
   ```
   cargo xtask generate
   cargo xtask heavy -- bash -c 'cd panel/widgetbook && flutter test test/every_story_test.dart --reporter=failures-only --name "<lowercase story name>"'
   ```
3. Open each image in `.xtask/results/stories/` at full size, one at a time.
4. List every action and state on the page. A state with no story is a finding.
5. Check every `panel-design` rule that applies. Record `pass`, `fail`, or `cannot_verify` for each.
6. Run the action walk and the critique below.
7. Drop findings with no evidence, findings under Exceptions, and severity 0.
8. When a finding is severity 3 or 4, check it a second way: a probe test for what the source says, the source for what an image shows. Keep it only if both agree. A missing move, a timing, or a state no story reaches is read from source alone: keep it and write `source only` in evidence.
9. Write `docs/design/panel-design/reviews/<page>.md`.

## Getting evidence

| When checking | Use | When you cannot |
|---|---|---|
| Layout, colour, type, static states | Story image, naming the region | `cannot_verify` |
| A row that looks faded in an image | Source code. It may be caught mid entrance; never report it as contrast | `cannot_verify` |
| Motion | For every action and state change on the page, find the `panel-design` Motion rule whose When fits and the token it names, then the code that runs when it happens. Fail when that code has no move, a different move, a literal duration or curve, an exit that bounces, a linear curve outside `drain`, or no reduced motion path | Never `cannot_verify` for a missing or wrong move; only for feel |
| Focus target, key path, or semantics | Write a throwaway widget test: `pumpStory` for a story, `pumpPanel` for a route. Run it through `cargo xtask heavy --`, cite what it showed, delete it | Read the source and say so |
| A value that differs from the Values tables | Quote "Setting any visual value" | |
| A state the story offers but no image shows | A finding under "A surface is new or changed" | |
| A state only an action reaches: open panel, selection, failure | A probe that runs the action | Source, marked `source only` |
| Which node holds focus | Node rectangles from the probe; an invisible wrapper is a Tab stop with no visible control | |
| How a move feels, once the right token runs | Nothing you can check | `cannot_verify`, for a maintainer |
| Contrast | Compute it from the token values | `cannot_verify` |

## Action walk

For every action on the page:

| When the page has | Do | Expect | Otherwise |
|---|---|---|---|
| Any action | Reach it and run it with keys only | It works, and the command list shows it | 3 |
| Any action that opens something | Cancel it | Esc steps out, focus returns to the opener | 3 |
| Any action | Note where focus lands afterwards | The target in `panel-design` Focus | 3 |
| Any action or state change | Name the move that should play, and find it in source | The move its Motion rule names, on tokens | 2 |
| A create action | Run it | Focus on the new thing's first empty required field | 3 |
| A remove action | Run it | Book content: no question, Undo offered. Anything else: a hold. Focus on the next row | 4 |
| An action that cannot be undone | Press its key once, then press with every modifier | Nothing happens without the full hold | 4 |
| A failing action | Fail it through a fake | The message stays and says what to do; the same control repeats the action | 3 |
| A value revealed on hover | Reach it with keys, then touch | It reveals both ways | 3 |
| A drag | Do it with keys, then with single clicks | Both give the same result | 2 |
| Compact width | Render the compact story | Every action still reachable | 3 |

## Critique

Rules do not cover everything. After the walk, answer each question. Report a poor answer under Suggestions with its region and a concrete proposal.

| Ask | A poor answer |
|---|---|
| What is this page for, and is that clear in two seconds? | It takes reading to work out |
| Where does the eye land first? | On something unimportant |
| What can be removed with nothing lost? | Panels, labels, or borders doing no work |
| Does it feel like this machine? | It could be any admin product with the logo removed |
| What slows an expert down? | Many keys for a daily action |
| Where does a first time user get stuck? | Nothing says what to do first |

Never ask which of two designs looks better. Report what fails and why it fails.

When the rules have a gap, propose a new When and Then row under Suggestions.

## Severity

| Level | When | Example |
|---|---|---|
| 4 | Work is lost or a task is blocked | Shift+D deletes with no question and no undo |
| 3 | A required path fails, or trust is damaged | A value only a pointer can reveal |
| 2 | Friction that adds up | Title and content on different left edges |
| 1 | Cosmetic | A gap of 13 where the scale gives 12 |

Use the rule's `Sev`. Change it only when frequency or impact on this page clearly differs, and say why.

A missing or wrong move on an everyday action (hover, press, focus, opening something, loading, rows added or removed, moving a thing on a canvas) is 3, whatever its rule says; quote `Everyday motion` as its rule. Other motion keeps its rule's `Sev`. Motion the framework already reduces counts as handled.

## Output

```
## Summary
Is this page good? The single most valuable change.

## Findings
- id: MEMBERS-3
  rule: "Something works with one input"
  severity: 3
  region: "Email under each member name, table row"
  evidence: "blur_reveal.dart:4; story memberlistpage/default/initial.png"
  observed: "Emails unblur only on pointer hover."
  fix: "Reveal on row focus and touch as well."

## Cannot verify
The rule, and what would settle it.

## Rule results
<details> with one row per checked rule: When cell, pass, fail, or cannot_verify.

## Skill friction
Where this skill was unclear or made you guess.

## Suggestions
Region and proposal.
```

- `rule` quotes the When cell exactly: the `panel-design` row, or the action walk row when no design row fits.
- A fault in a shared component or the theme goes once in `cross-page.md`. A page report names its id and does not repeat it.
- `evidence` names a file and line, a story image, or a test.
- A maintainer decides what gets fixed. Do not change panel code during a review.

## After every page

Compare the reports and images across pages. Report in `docs/design/panel-design/reviews/cross-page.md`:

- One action with different names, keys, or positions.
- Pages that differ on left edge, heading, density, or main action.
- One situation solved in different ways.
- Moves between pages that lose the user's place.

## Before a full run

When a rule in this skill or `panel-design` changes meaning, review one of Members, Services, or the resource editor again and compare with its report in `docs/design/panel-design/reviews/`. A finding that appears or disappears must follow from the change.

## Inventory

Review in this order. Story paths are below `.xtask/results/stories/`.

| Surface | Route | Story |
|---|---|---|
| Sign in | `/auth` | `features/auth/presentation/authpage/default` |
| Organizations | `/` | `features/organizations/presentation/indexpage/default` |
| Services | `services` | `features/services/presentation/servicespage/default`, `.../inspector` |
| Members | `members/` | `features/members/presentation/memberlistpage/default` |
| Join requests | `members/join-requests` | `features/members/join_requests/presentation/joinrequestspage/default` |
| Join codes | `members/join-codes` | `features/members/join_codes/presentation/joincodespage/default` |
| Realm home | `realm/:realmId/` | `features/realms/presentation/realmhomepage/default` |
| Resource editor | `realm/:realmId/resource/:resourceId` | `features/realms/presentation/resourcesurface/routed-resource` |
| Search | Overlay on any page | `shared/search/presentation/searchmodal/default` |
| Conflict review | Overlay in the editor | `authoring/presentation/authoringconflictnotice/retained-conflict`, `.../authoringconflictcomparison/complete-group-comparison` |
| Type picker | Overlay in the editor | `authoring/presentation/authoredresourceeditor/creation-type-picker` |
| Graph | Inside canvas pages | `shared/graph/presentation/graph/default` |
| Start up, connection lost, crash | Any route | `shared/ui/screens/` stories |
| Realm inbox, activity, selector | Sheets from any page | Their stories under `features/realms` and `shared/` |

## Exceptions

Do not report these:

- The colour picker's spectrum and checkerboard use raw colours.
- A key cap does not glow during a hold; the glow arrives with the shared key cap work.
