---
name: panel-design
description: Rules for how the web panel looks, moves, and behaves. Use before building or changing anything a panel user sees or presses in panel/: pages, widgets, overlays, stories, animation, shortcuts, focus, and text.
---

# Panel Design

Apply every row whose When matches your change. `Sev` is the severity when broken, on a scale of 1 cosmetic, 2 minor, 3 major, 4 lost work or a blocked task.

## Choosing a surface

| When | Then | Sev |
|---|---|---|
| Editing details of the selected thing | Use the inspector pane, never a dialog | 2 |
| Creating something that needs only a name | Add a row in place with focus on its name | 2 |
| Creating something that needs more | Add a row in place, then show its required fields in the inspector | 2 |
| Picking from 10 options or fewer | Use a popover at the control | 2 |
| Picking from more than 10, or from a searchable set | Use the search overlay | 2 |
| Acting on the focused or selected thing | Offer it in the context menu, the command list, and by key | 2 |
| Work cannot continue until a question is answered | Use a dialog. Example: resolving a conflict | 2 |
| Anything else wants a dialog | Use one of the rows above instead | 2 |
| The window is compact | Show one pane at a time, in the order tree, content, inspector; Back goes up one. Popovers, dialogs, and the inspector become bottom sheets. Every action stays available | 3 |

## Moving focus

| When | Then | Sev |
|---|---|---|
| An action creates something | Move focus to its first empty required field | 3 |
| An action removes a row | Move focus to the next row, or the previous row if it was last, or the pane's add action if none remain | 3 |
| A surface closes | Return focus to what opened it | 3 |
| What opened a surface no longer exists | Follow the row removal rule at its old position | 3 |
| A surface opens | Move focus to its first control, or to Cancel on a dialog for a permanent action | 3 |
| Validation fails | Move focus to the first bad field. It jams; the other bad fields show a still message | 3 |
| An async action succeeds and the next step is clear | Move focus to the next step. Otherwise leave focus alone | 2 |
| An async action finishes after the user has moved on | Leave focus alone | 3 |
| Navigating to a page | Move focus to the page's main pane, first item | 2 |
| Another person or the system changes anything | Never take focus | 3 |
| Selection and focus fall on one row | Show selection as a fill and focus as the ring, both visible | 3 |

## Giving feedback

| When | Then | Sev |
|---|---|---|
| A page's first load | Show a skeleton of the real layout, never a spinner on a blank page | 2 |
| A wait of unknown length passes 300 ms | Show the caret and a status word | 2 |
| That wait passes 5 s | Change the words to say what it waits on. Keep the same motion | 2 |
| Work has measurable progress | Show stepped progress | 2 |
| A save succeeds | Type `Saved` at the save status, then clear it after 2 s | 2 |
| A short action succeeds and its result is visible | Show no message | 2 |
| A short action succeeds and its result is not visible | Type the result word at the control. Example: `Copied` | 2 |
| A long action or a background task succeeds | Show a toast that clears by itself | 2 |
| A field is invalid | Show the message under the field until it is fixed | 3 |
| An action fails | Jam at the control and keep the failure there until retried or dismissed. Say what happened, what to do, and offer Retry | 3 |
| A failure affects the whole page or connection | Show one steady notice. Keep edits, and keep reading unblocked | 3 |
| Two saves conflict | Keep the user's work, show both versions, and ask for one choice | 3 |
| A value shown elsewhere on screen changes through the user's action | Put an ink mark on each other visible place, not on the place they edited | 2 |
| Another person or the system changes something visible | Put a slow ink mark on it. Do not move layout: rows arriving above the viewport keep the scroll position anchored | 3 |
| A list is empty | Say what belongs here and name the key that adds the first one | 2 |

## Serious actions

| When | Then | Sev |
|---|---|---|
| An action removes books, pages, or entries, one or many | Act on one press with no question, and offer Undo at once. Until realm undo exists, use the permanent row below | 4 |
| An action cannot be undone: remove member, revoke join code, unbind host | Hold the key or button for 800 ms. The row fills while held, one line says what will happen, and releasing early cancels | 4 |
| A permanent action covers many items | Hold, and the line states the count | 4 |
| The hold setting is off | Show a dialog with Cancel focused, confirmed by Ctrl or Cmd+Enter | 4 |
| A key or modifier would skip these rows | Remove it. No bypass exists | 4 |
| Touch is the input | Touch and hold with the same timing | 3 |

## Choosing motion

| When | Then | Sev |
|---|---|---|
| A surface arrives from a user action: panel, dialog, menu | Strike, growing from the control or row that opened it | 2 |
| A dialog arrives | Strike, and the page behind scales to 0.98 | 2 |
| Focus moves one step or to a target on screen | Slide the ring with `focusMove` | 2 |
| A key is held and repeating, or focus moves off screen | Jump the ring with no slide | 2 |
| One to eight rows appear from a user action | Carriage, from the left | 2 |
| More than eight rows appear, or rows appear from loading | Appear at once, with no Carriage | 2 |
| A button or a key cap is pressed, by pointer or by key | Carriage press on both the control and its key cap | 1 |
| Anything leaves | Exit, faster than it arrived, back towards its origin. Never overshoot | 2 |
| Navigating deeper | Content arrives from the right. Going back, from the left. The breadcrumb types in | 2 |
| A pointer hovers | Change state at once, with no animation | 2 |
| A tooltip shows | Wait 500 ms on hover or focus, then fade. Include the key | 2 |
| Something is dragged | Lift it; Carriage on drop. Provide a keyboard path and a single pointer path | 2 |
| A new move starts while one runs | Retarget from the current position. Never block input on motion | 3 |
| Two moves would play together | The user's latest action moves. Everything else changes without motion | 2 |
| You want a move with no row above | Do not animate | 2 |
| You want something to loop | Only the caret and loading placeholders may loop. Never rotate messages, hints, or text | 2 |
| Reduced motion is on | Replace travel with an instant change. Keep marks, messages, and focus changes. Handle this in the tokens, not per widget | 3 |
| Writing a duration or curve | Use a motion token below. Add missing tokens beside `panel/lib/shared/theme/typewriter_spacing.dart`. Never write a literal | 2 |
| Showing a Rive mascot | Only on doorway screens, never during active work. Stop it under reduced motion | 2 |

Tokens. Every arrival reaches its final position within 150 ms; the landing plays after that.

| Token | Curve | Duration | Landing |
|---|---|---|---|
| `panelIn` | Strike | 420 ms | 10% overshoot |
| `dialogIn` | Strike | 340 ms | 14% overshoot |
| `focusMove` | Strike | 170 ms | 5% overshoot |
| `rowIn` | Carriage | 280 ms | 6% recoil, hit at `h = 0.42` |
| `press` | Carriage | 220 ms | 12% recoil, hit at `h = 0.3` |
| `panelOut` | Exit | 200 ms | None |
| `dialogOut` | Exit | 150 ms | None |
| `rowOut` | Exit | 160 ms | None |
| `type` | Stepped | 36 ms per letter | None |
| `ink` | Ease out | 900 ms fade; 2 s for changes by others | None |

- **Strike:** `1 - e^(-z*w*t) * (cos(wd*t) + (z*w/wd) * sin(wd*t))`, `t` from 0 to 1, `w = 5/z`, `wd = w*sqrt(1 - z*z)`, `z = -ln(o) / sqrt(pi^2 + ln(o)^2)`, `o` the overshoot.
- **Carriage:** `1 - (1 - t/h)^1.6` until `h`, then `1 - a * sin(pi*p) * (1 - p)^1.2`, `p = (t - h) / (1 - h)`, `a` the recoil.
- **Exit:** `Cubic(0.4, 0, 0.2, 1)`.
- **Jam:** a sideways judder, 2 cycles, 4 px, 240 ms.
- **Feel:** when judging a move, open `docs/design/panel-design/demos/experience.html` in a browser.

## Keyboard

| When | Then | Sev |
|---|---|---|
| Adding any action | Define one command: key, scope, action, through an Intent. Buttons, menus, keys, and the command list call that Intent | 3 |
| Adding any command | List it in the command list (Ctrl or Cmd+K) with its key, and under `?` for its scope | 3 |
| Adding a pointer path: drag, hover reveal, context menu, canvas pan | Add a keyboard path for the same result | 3 |
| Revealing a hidden value | Reveal on hover, on keyboard focus, and on touch | 3 |
| A field gains focus | Enter Insert mode. Esc returns to Normal | 3 |
| The mode changes | Update the mode chip | 3 |
| A surface needs its own keys: graph, timeline | Add a surface mode (Move, Resize) and show it in the chip | 3 |
| Choosing a default key | Never use one the browser or OS takes: Ctrl or Cmd+N, T, W, or Ctrl+Esc | 3 |
| Binding a single key with no modifier | Honour the setting that turns off or remaps single keys, unless the key works only while its control has focus | 3 |
| Moving between controls and groups | Tab | 2 |
| Moving inside a list, tree, table, or menu | Arrows and H, J, K, L | 2 |
| Backing out | Esc steps out one level | 2 |
| Adding an icon button | Give it a label for its tooltip and semantics | 3 |
| Pane has commands | Show its main keys in the bottom hint row. With touch only, hide the hint row and mode chip | 2 |

## Look

| When | Then | Sev |
|---|---|---|
| Text is a full sentence | IBM Plex Sans | 2 |
| Text is anything else: title, nav, label, button, name, value, identifier, key cap | Lilex. Weight 500 or 600 on labels and buttons | 2 |
| Filling a control with brand | `#009FFF` with black text | 2 |
| Brand as text | `#33AEFF` on dark, `#006FB8` on light | 3 |
| Any text | At least 4.5:1, in both themes | 3 |
| Focus ring | 2 px, `#009FFF` on dark, `#006FB8` on light, at least 3:1, at every window size | 3 |
| Showing warning, error, or success | Its status colour, used for nothing else | 2 |
| Setting a space | `TypewriterSpacing`: 4, 8, 12, 16, 20, 24, 32, 40, 48 | 2 |
| Setting a radius | `TypewriterShapes`: pane 12, control 8, key cap and small chip 4 | 2 |
| Separating panes | Surface brightness, no shadow. Only menus and toasts, then dialogs, cast a shadow | 2 |
| A pane holds focus | That pane, and only that one, uses the brighter surface | 2 |
| Laying out a page | Title and content share one left edge | 2 |
| Laying out rows | 32 px with a pointer, 44 px on touch | 2 |
| Adding the action a pane exists for | One filled button in the pane header, right side. A pane has at most one | 2 |
| Adding any other action | Quiet button or menu entry | 2 |
| Adding an action per row | Quiet, shown on row hover and focus, and in the context menu | 2 |
| Adding an icon | Material Symbols, bundled. 16 px inline, 20 px in controls. Nothing is fetched at runtime | 2 |

## Text

| When | Then | Sev |
|---|---|---|
| Errors, warnings, permissions, permanent actions, anything to act on | Plain literal English in short sentences, no idioms or wordplay: what happened, then what to do | 3 |
| Sign in, empty states, waits over 5 s, small successes, first run | A joke in simple words is welcome. Crash screens may add one beside the clear part | 1 |
| Adding a joke | Place it beside the clear text. The clear text must stand alone | 2 |
| Naming an action | Use the same name everywhere. Its result uses the same word: Publish, Published | 2 |
| Writing any label | Sentence case | 1 |
| Writing a count | Real plurals, whole strings. Never `item(s)` or joined verb stems | 1 |

| Moment | Write |
|---|---|
| Empty book | This page is blank. Press N and fix that. |
| Normal error | The realm did not answer. Retry. |
| Wait | Connecting to the realm |
| Permanent action | Remove Ada? They lose access straight away. |
| Removed, with undo | Deleted Arrival. Undo |
| Crash | That jammed. Reload the panel, and tell us on Discord if it happens again. |

## Components

| When you need | Use | Never |
|---|---|---|
| A busy button | `LoadingButton`, `LoadingIconButton` | A private spinner |
| A wait | The caret, `Shimmer` | `CircularProgressIndicator` |
| A menu or popover | `AnchoredPopup`, `ContextMenuRegion` | `PopupMenuButton`, `MenuAnchor` |
| A select | `Dropdown`, `MultiselectDropdown` | `DropdownButtonFormField` |
| A dialog | The one dialog component | `AlertDialog` |
| A permanent action | The hold component | `showConfirmationDialogue` |
| A message | Snackbar helpers | `ScaffoldMessenger` |
| A heading | `PageHeading`, `SectionTitle` at theme sizes | Local size or weight overrides |
| A status | `StatusIndicator`, one chip | `TypeBadge`, `SmallChip`, `PresetChip` as separate styles |
| A pane | `Pane` | Local pane colours |

When the component you need does not exist yet, build it once in `panel/lib/shared` and use it everywhere.

| Control | Hover | Focus | Press | Disabled | Busy |
|---|---|---|---|---|---|
| Filled button | Lighter fill | Ring | `press` | Muted fill and text, no press | Caret replaces icon, label stays |
| Quiet button | Faint fill | Ring | `press` | Muted text | Caret replaces icon, label stays |
| Row | Faint fill | Ring | Selected fill under the ring | Muted text | Skeleton content |
| Field | Lighter border | Ring, Insert mode | Caret | Muted, no caret | Value stays |

## Finishing

| When | Then | Sev |
|---|---|---|
| A surface is new or changed | Its story shows every state that applies: default, hover, focus, active, disabled, loading, empty, error, offline, compact | 2 |
| Keyboard behaviour is new or changed | A widget test proves the key path and where focus lands | 3 |
| You must break a rule | Stop and ask a maintainer. If approved, add it to the exceptions in the `panel-review` skill | 3 |
