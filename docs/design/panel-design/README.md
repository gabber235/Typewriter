# Panel design record

Choices and findings for the web panel's design. Instructions live in the `panel-design` and `panel-review` skills under `.agents/skills/`.

## Choices by a maintainer

| Topic | Choice |
|---|---|
| Type | Lilex and IBM Plex Sans; JetBrains Mono leaves |
| Colour | Cool as today; warning separate from accent; focus ring blue; small balanced marks that carry information, strongest on what is wrong |
| Motion concept | Motion is how the panel points; the typewriter is how it does it with character |
| Motion feel | Character is required; fast but neutral is rejected; exits never bounce |
| Motion mix | Panel toggle, dialog, and focus move from key strike; new row, button press, and Saved from the machine |
| Keyboard | Visible modes; everything works without a pointer |
| Destructive | Undo for book content, hold for actions that lose work or make someone else act again, no bypass |
| Layout | The active pane lifts; bottom key hints stay |
| Hover | Things rise with one overshoot and no shadow; key caps strike up; buttons with a key always show it |
| Loading | Loaded rows ripple upwards from below |
| Rules | General rules that decide many cases, over many specific rows |
| Keys | One key language across the panel; a key keeps its meaning everywhere |
| Actions | As context specific as possible |
| Alignment | Trials of three options per element, to check the rules against the maintainer's feel |
| Holds | Discard, Use saved, and Decline need a hold; Publish and cancelling one's own request are one press |
| Hold weight | A hold lasts as long as its weight: light 1.2 s (Discard draft), heavy 1.8 s (Remove member, Decline, Revoke, Unbind), permanent 2.6 s (deleting a Realm resource). A held button sinks 1 to 4 px, scales to 0.95, trembles once late in the hold, and springs back typing its done word for 1.3 s (`holdDoneShow`). Filled buttons fill black at 28 percent, flat and outlined ones red at 16 percent |
| Operation sections | Operations are ordered by group, then order; each group is a section with a divider, the same list in the inspector and the context menu. Kotlin declares each operation's emphasis (flat, outline, filled); the panel shows the first filled one filled and the rest flat. Destructive operations get their own section and are held |
| Fix order | Broken motion on everyday actions is fixed first, with focus and keys |
| Motion from services | Named moves as the easy default; developers keep full control over duration and curve; good motion controls in the realm make it easy to add |
| Others' changes | Values wave slowly; adds and removes use their usual moves plus a chip with who and why, later an avatar |
| Voice | Between plain and playful: jokes where possible, literal English when it matters |
| Character | Professional and fun, never sterile; a change that removes something names the character that replaces it |
| Inspector source | Headings, fields, operations and concepts are declared in Kotlin whenever possible, so extensions can shape them |
| Keyboard tests | Every built or redone element has a widget test that uses it by keyboard alone, without Tab |
| Teaching | Concept words explain themselves through a rich tooltip and empty states; no tours |
| Material | Controls, popovers, tooltips, dialogs and grow or shrink are built on Flutter's widgets layer; Material stays only where Flutter has no primitive yet (text input, selection, Scaffold, tabs) and moves as each one ships |

## Choices by the author, not confirmed

- Material Symbols as the one icon set.
- Which duplicate component survives, in the Components table.
- Table rows at about 42 px, chosen in a trial.
- Compact below 900 px, or when a pane would be narrower than 320 px.

## Draft when rules, not confirmed

The maintainer chose what each behaviour looks like. These rules for when each one applies are the author's draft, reviewed only in a sample:

- Which surface a task uses, and compact layout.
- Focus targets after each action.
- Which feedback each situation gets, and where.
- Waits: the 300 ms and 5 s limits, doorway versus skeleton, and refreshing without motion.
- Bulk actions, and showing the hold after preparation.
- Moves that repeat fast, and which move wins when several play together.
- Scroll anchoring.
- Filled action placement, and per row actions.
- Hiding key caps, hints, and the mode chip with touch only.
- Where jokes are allowed.
- The key language table, and the selection versus focus rule.
- Values for `jam`, `hoverIn`, `capIn`, `loadIn`, and slow ink.

## Open

- Tuning motion tokens in the real panel; the values come from browser demos.
- The active pane lift in light mode.
- A replacement for `Ctrl+Esc` as cancel, and the full key map per scope.
- Undo depends on realm commit history (`docs/design/authoring-writes.md`), which is not built.
- Golden pages: none exist, since no page meets the target yet.
- What "keep the user's work" means while a realm is suspended, where changes are paused.
- The demo does not yet show hover or loading.

## Trials

Each trial offers three live options, one being the rule as written, shown blind. The takeaway is a general rule, not that element's design.

| Trial | Result for the rule as written | Takeaways |
|---|---|---|
| Hold to confirm | Too flat; linear fill, text popped in and shifted content | Springs over linear; nothing just appears; reserve space; typing leaves time to read; the key in use glows |
| Failed action | Shake liked; red border and second button rejected; label swaps felt inconsistent | Animate state changes inside a component; one control repeats its action; alarms on a control fade by themselves; busy looks pressed in |
| Juice strength | All used the first takeaways; strongest chosen | Go strong by default; the caret in a busy label feels wrong |
| Delete with undo | In place, as the rule said; needed more | Strike through what is going; temporary things show time left; lists collapse rather than slide |
| Busy button | Caret replaced by rippling letters | State shows in the thing itself |
| Row collapse | Squash with its text; the countdown line clashed with the row below | A countdown is the background draining, the inverse of a hold |
| Change shown elsewhere | Letters ripple, not a background flash | Text changes through its letters |
| Tooltip | Short types itself; long rises with a bounce and chunks inside | Effects scale with length; fun when it is not in the way |
| Moving between pages | The opened row becomes the heading; ripple when nothing carries over | Continuity connects an action with its result |
| Change by someone else | Slow wave plus a chip | The animation performs the change; show who when it was not the user; an added element is fine if it carries new information |
| Pane focus | Ring travels, plus lift, shrink, and brighten | Signals stack when each does its own job; the ring always leads |
| Larger surface | The row grows into it | Continuity beats a strike from elsewhere |
| List density | All three rejected | No model yet for static look |
| Empty state | Mascot, large playful line, serious subtitle, action on the right | Play and clarity sit side by side, each in its own place |
| Members page | Table with inspector, with a bit more character and identity; the cast sheet is too different | Static look stays restrained: structure first, a little character. Motion is where the panel goes strong |
| Static identity | Typed details over physical keys or paper | Static identity is typographic; depth belongs to motion |
| Dense page and controls | Muted labels, no rule, no marker; soft filled controls as today | Choosing an option does not mean liking every part; the rule and marker from the earlier pick were wrong |
| Calm but not boring | Person colours, activity bars, roomier rows; no large tile | Interest comes from real information, never decoration |
| Book tree | Colour tile per page type | Real information holds without people |
| Services graph | Grey with a muted status on each, colour only when wrong; load and moving traffic rejected | Status is always readable; colour is saved for what needs attention |

Author predictions: change mark wrong, tooltip half right, navigation right, change by others half right, pane focus half right, surface right, density wrong, empty state half right, members page mostly right, static identity wrong, dense page wrong, controls wrong, interest wrong, book tree right, services graph wrong.

Options must differ in concept. Three sizes of one idea taught nothing.

Across trials, every added element was rejected: red border, second button, caret, ribbon, countdown line.

The maintainer mixes parts across options, so options test ideas rather than whole designs.

## Calibration

Three fresh agents reviewed Members, Services, and the resource editor with only the skills. Reports are in `reviews/`. A maintainer marked 25 finding themes from 70 findings: 24 right, 1 partly. A motion pass followed, since the first skill sent motion to `cannot_verify`: 38 findings in 15 themes, 13 right, 2 partly (who and why on others' changes; services keep control over motion). The partly: colour on healthy states is allowed in small balanced amounts, since a page with none feels lifeless. The skills were tightened where reviewers had to guess.

## Findings

Measured at `c5db6eb2f` on 2026-11-05. Counts come from searches. Remove a row when it is fixed.

| Sev | Today | Where |
|---|---|---|
| 3 | Emails and join code URLs unblur only on pointer hover | `blur_reveal.dart:4`, `member_table.dart:257`, `join_code_table.dart:230`, `join_code_card.dart:133` |
| 3 | Graph canvas has no keyboard pan; starting a resource drag is pointer only | `graph.dart:328`, `resource_drop_target.dart:593` |
| 3 | No shortcut help surface; command list coverage not measured | `search_shortcuts.dart:60` |
| 3 | `Ctrl+N` and `Ctrl+Esc` cannot reach the page | `shortcuts.dart:31,37` |
| 2 | A means create in the resource editor and Apply roles on members; X is an extra alias for remove | `resource_route.dart:115`, `member_actions.dart:68`, `shortcuts.dart:85` |
| 3 | Single key commands cannot be turned off or remapped | `shortcuts.dart`, `normal_mode.dart` |
| 3 | Nothing turns semantics on for web; not run with a screen reader | `web/index.html` |
| 3 | Filled New page on every tree row, overlapping labels, one more floating | Story `resourcesurface/routed-resource/Routed-resource=Book` |
| 3 | Selected chip reads weaker than Disabled | Story `controlsshowcase/default` |
| 3 | Unlabelled close button; two more to check | `modal_header.dart:50`, `join_organization.dart:259`, `diagnostic_chrome.dart:333` |
| 2 | Title and content edges differ: Members 262 and 254, Library 290 and 254, Services 262 and 248 | Stories |
| 2 | Accent and warning are both `Colors.orange`; role colours are raw Material | `color_scheme.dart:7,10`, `service_projection.dart:3-6` |
| 2 | Six icon sets, some fetched at runtime | `icons.dart:6` |
| 2 | Member rows are about 74 px | Story `memberlistpage/default` |
| 2 | Jargon with no next step: "Nothing answered; the service may be away" | `skir_mutation.dart:188` |
| 2 | "Remove member" and "Remove Member"; "Copy join code" and "Copy Join Code" | `member_card.dart:95,232`, `join_code_card.dart:87,206` |
| 2 | 11 raw `AlertDialog`s, 3 menu systems, 2 empty states, 3 private spinners | `panel/lib` |
| 2 | 29 literal `EdgeInsets`, 40 literal radii, `fontSize` on 59 lines outside the theme | `panel/lib` |
| 2 | Guardrail exemptions allow raw role colours and `unbind_operation.dart`, and name unused seed colours | `design_system_guardrails_test.dart` |
| 2 | No guards for the icon set or reserved keys; no golden tests | `panel/` |
| 1 | "unbindd" from a joined string | `operations.dart:201` |

Not measured: how anything feels in the real panel, screen reader output, text scale above 1.4, and Rive mascots.

## Research

Mostly preprints and vendor posts.

- LLM reviewers cover single pages well, report many false findings, and are weak across pages (43 to 50%).
- Asked which design looks better, they perform near chance.
- Rule by rule verdicts with region evidence work better.
- Tokens as the source of truth, few rules, and only what an agent cannot infer shape behaviour best.
- Instructions reachable from always loaded context beat skills alone; a default skill went uninvoked in 56% of one vendor's cases.
