# Panel design record

Choices and findings for the web panel's design. Instructions live in the `panel-design` and `panel-review` skills under `.agents/skills/`.

## Choices by a maintainer

| Topic | Choice |
|---|---|
| Type | Lilex and IBM Plex Sans; JetBrains Mono leaves |
| Colour | Cool as today; warning separate from accent; focus ring blue |
| Motion concept | Motion is how the panel points; the typewriter is how it does it with character |
| Motion feel | Character is required; fast but neutral is rejected; exits never bounce |
| Motion mix | Panel toggle, dialog, and focus move from key strike; new row, button press, and Saved from the machine |
| Keyboard | Visible modes; everything works without a pointer |
| Destructive | Undo for book content, hold for permanent actions, no bypass |
| Layout | The active pane lifts; bottom key hints stay |
| Voice | Between plain and playful: jokes where possible, literal English when it matters |

## Choices by the author, not confirmed

- Material Symbols as the one icon set.
- Which duplicate component survives, in the Components table.
- 32 px rows.

## Draft when rules, not confirmed

The maintainer chose what each behaviour looks like. These rules for when each one applies are the author's draft:

- Choosing a surface, including the option limit of 10 and compact layout.
- Focus targets after each action.
- Feedback by situation, including the 300 ms, 2 s, and 5 s limits.
- Bulk actions, the 800 ms hold, and touch hold.
- Motion under key repeat, off screen focus, bulk rows, loading, hover, and tooltips.
- Ink marks: where they appear, and scroll anchoring.
- Filled action placement, and per row actions.
- Jam values, and the 2 s ink for changes by others.
- Hiding key hints and the mode chip with touch only.
- Where jokes are allowed.

## Open

- Tuning motion tokens in the real panel; the values come from browser demos.
- The active pane lift in light mode.
- A replacement for `Ctrl+Esc` as cancel, and the full key map per scope.
- Undo depends on realm commit history (`docs/design/authoring-writes.md`), which is not built.
- Golden pages: none exist, since no page meets the target yet.

## Findings

Measured at `c5db6eb2f` on 2026-11-05. Counts come from searches. Remove a row when it is fixed.

| Sev | Today | Where |
|---|---|---|
| 4 | Shift+D, Shift+X, and Shift+Backspace delete with no question and no undo; D then Enter deletes, since Delete has focus. Read from code, not run | `shortcuts.dart:81-88`, `popups.dart:151,191` |
| 3 | Emails and join code URLs unblur only on pointer hover | `blur_reveal.dart:4`, `member_table.dart:257`, `join_code_table.dart:230`, `join_code_card.dart:133` |
| 3 | Graph canvas has no keyboard pan; starting a resource drag is pointer only | `graph.dart:328`, `resource_drop_target.dart:593` |
| 3 | Focus ring is grey and hidden at 450 px and below | `color_scheme.dart:92`, `focus_highlight.dart:127` |
| 3 | No shortcut help surface; command list coverage not measured | `search_shortcuts.dart:60` |
| 3 | `Ctrl+N` and `Ctrl+Esc` cannot reach the page | `shortcuts.dart:31,37` |
| 3 | Single key commands cannot be turned off or remapped | `shortcuts.dart`, `normal_mode.dart` |
| 3 | Nothing turns semantics on for web; not run with a screen reader | `web/index.html` |
| 3 | Sidebar takes 1000 ms; 750 ms hover scale and tree insert | `sidebar_shell.dart:34`, `animation.dart:7`, `search_tree_animated_body.dart:25` |
| 3 | `#009FFF` as text on white is 2.84:1 | `color_scheme.dart:6` |
| 3 | Filled New page on every tree row, overlapping labels, one more floating | Story `resourcesurface/routed-resource/Routed-resource=Book` |
| 3 | Selected chip reads weaker than Disabled | Story `controlsshowcase/default` |
| 3 | Unlabelled close button; two more to check | `modal_header.dart:50`, `join_organization.dart:259`, `diagnostic_chrome.dart:333` |
| 2 | 35 durations, elastic at 27 sites, no tokens; 19 of 21 `flutter_animate` files ignore reduced motion | `panel/lib` |
| 2 | Decorative loops: rotating messages, key hints, secret text | `text_scroller.dart:11`, `shortcut_display.dart:118`, `secret_field_displays.dart:35` |
| 2 | One elastic curve in both directions on the sidebar | `sidebar_shell.dart:34` |
| 2 | Active pane is tracked but not shown | `panes.dart:339` |
| 2 | Title and content edges differ: Members 262 and 254, Library 290 and 254, Services 262 and 248 | Stories |
| 2 | Accent and warning are both `Colors.orange`; role colours are raw Material | `color_scheme.dart:7,10`, `service_projection.dart:3-6` |
| 2 | Six icon sets, some fetched at runtime | `icons.dart:6` |
| 2 | Member rows are about 74 px | Story `memberlistpage/default` |
| 2 | Jargon with no next step: "Nothing answered; the service may be away" | `skir_mutation.dart:188` |
| 2 | "Remove member" and "Remove Member"; "Copy join code" and "Copy Join Code" | `member_card.dart:95,232`, `join_code_card.dart:87,206` |
| 2 | 11 raw `AlertDialog`s, 3 menu systems, 2 empty states, 3 private spinners | `panel/lib` |
| 2 | 29 literal `EdgeInsets`, 40 literal radii, `fontSize` on 59 lines outside the theme | `panel/lib` |
| 2 | Guardrail exemptions allow raw role colours and `unbind_operation.dart`, and name unused seed colours | `design_system_guardrails_test.dart` |
| 2 | No guards for motion tokens, icon set, reserved keys, or focus contrast; no golden tests | `panel/` |
| 1 | "item(s)", and "unbindd" from a joined string | `delete_operation.dart:50`, `operations.dart:201` |

Not measured: how anything feels in the real panel, screen reader output, text scale above 1.4, and Rive mascots.

## Research

Mostly preprints and vendor posts.

- LLM reviewers cover single pages well, report many false findings, and are weak across pages (43 to 50%).
- Asked which design looks better, they perform near chance.
- Rule by rule verdicts with region evidence work better.
- Tokens as the source of truth, few rules, and only what an agent cannot infer shape behaviour best.
- Instructions reachable from always loaded context beat skills alone; a default skill went uninvoked in 56% of one vendor's cases.
