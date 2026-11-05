# Baseline

Today's panel against this record, measured on 2026-11-05 at `c5db6eb2f`. Numbers are search counts, so read them as
sizes rather than exact values. This is the starting backlog. Remove an item when it is fixed.

## Backlog

| Severity | Rule | Today | Where |
| --- | --- | --- | --- |
| 4 | XP-09 | Shift+D, Shift+X, and Shift+Backspace delete with no question and no undo. Plain D then Enter also deletes, since Delete has focus. Read from code, not run | `shortcuts.dart:81-88`, `popups.dart:151,191` |
| 3 | KB-01 | Emails and join code URLs unblur only on pointer hover | `blur_reveal.dart:4`, `member_table.dart:257`, `join_code_table.dart:230`, `join_code_card.dart:133` |
| 3 | KB-01 | The graph canvas has no keyboard pan; starting a resource drag is pointer only | `graph.dart:328`, `resource_drop_target.dart:593` |
| 3 | CO-03 | Focus ring is neutral grey and hidden at 450 px and below; no contrast test | `color_scheme.dart:92`, `focus_highlight.dart:127` |
| 3 | KB-03 | No shortcut help surface. Search exposes each result's commands; whether it reaches every command is not measured | `search_shortcuts.dart:60` |
| 3 | KB-04 | `Ctrl+N` (browser on Windows and Linux) and `Ctrl+Esc` (Windows) cannot reach the page | `shortcuts.dart:31,37` |
| 3 | KB-05 | Single key commands cannot be turned off or remapped | `shortcuts.dart`, `normal_mode.dart` |
| 3 | KB-09 | Nothing turns semantics on for web, so it relies on Flutter's default placeholder. Not run with a screen reader | `web/index.html`, no `ensureSemantics` |
| 3 | MO-03 | Sidebar takes 1000 ms; 750 ms hover scale and tree insert | `sidebar_shell.dart:34`, `animation.dart:7`, `search_tree_animated_body.dart:25` |
| 3 | CO-01 | `#009FFF` as text on white is 2.84:1 | `color_scheme.dart:6` |
| 3 | LA-03 | Filled New page on every tree row, overlapping labels, and one more floating | Story `resourcesurface/routed-resource/Routed-resource=Book` |
| 3 | CM-01 | Selected chip reads weaker than Disabled | Story `controlsshowcase/default` |
| 3 | CM-02 | Unlabelled close button; two more to check | `modal_header.dart:50`, `join_organization.dart:259`, `diagnostic_chrome.dart:333` |
| 2 | MO-06 | 35 distinct duration values, elastic at 27 sites, no tokens; 19 of 21 `flutter_animate` files ignore reduced motion | Across `panel/lib` |
| 2 | MO-05 | Decorative loops: rotating messages, rotating key hints, regenerating secret text | `text_scroller.dart:11`, `shortcut_display.dart:118`, `secret_field_displays.dart:35` |
| 2 | MO-04 | One elastic curve in both directions on the sidebar | `sidebar_shell.dart:34` |
| 2 | LA-01 | Active pane is tracked but not shown | `panes.dart:339` |
| 2 | LA-02 | Title and content on different edges: Members 262 and 254, Library 290 and 254, Services 262 and 248 | Stories |
| 2 | CO-02 | Accent and warning are both `Colors.orange`; role colours are raw Material | `color_scheme.dart:7,10`, `service_projection.dart:3-6` |
| 2 | IC-01 | Six icon sets, some fetched at runtime | `icons.dart:6` |
| 2 | DE-01 | Member rows are about 74 px | Story `memberlistpage/default` |
| 2 | VO-01 | Jargon with no next step: "Nothing answered; the service may be away" | `skir_mutation.dart:188` |
| 2 | VO-04 | "Remove member" and "Remove Member"; "Copy join code" and "Copy Join Code" | `member_card.dart:95,232`, `join_code_card.dart:87,206` |
| 2 | Components | 11 raw `AlertDialog`s, 3 menu systems, 2 empty states, 3 private spinners | See [components.md](components.md) |
| 2 | Spacing | 29 literal `EdgeInsets`, 40 literal radii, `fontSize` set on 59 lines outside the theme | Across `panel/lib` |
| 1 | VO-05 | "item(s)", and "unbindd" from a joined string | `delete_operation.dart:50`, `operations.dart:201` |

## Guards

Existing: `design_system_guardrails_test.dart` blocks raw colours, text styles, some radii, and layout spacing, with a
list of exemptions. The exemptions include raw Material colours for service roles and for `unbind_operation.dart`, which
CO-02 now rejects, and they name seed colours the theme no longer uses, so that list needs a pass.

Missing: motion tokens, icon set, reserved keys, focus contrast, and accessibility guidelines. No golden tests exist.

## Exceptions

Approved deviations, so that reviewers do not flag them again:

- The colour picker's spectrum and checkerboard use raw colours, because they show colour itself.

## Not measured

- How anything feels in the real panel. The demos are browser mockups.
- Screen reader output, text scale above 1.4, and the Rive mascots, which do not render in story captures.
