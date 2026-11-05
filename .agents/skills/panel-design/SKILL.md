---
name: panel-design
description: Rules for how the web panel looks, moves, and behaves. Use before building or changing anything a panel user sees or presses in panel/: pages, widgets, overlays, stories, animation, shortcuts, focus, and text.
---

# Panel Design

Apply every rule whose When matches your change. `Sev` is the severity when broken: 1 cosmetic, 2 minor, 3 major, 4 lost work or a blocked task. When no rule decides a case, ask a maintainer.

## Focus

| When | Then | Sev |
|---|---|---|
| A user's action finishes and they have not moved on | Focus goes where they act next: a new thing's first empty required field, the first bad field after validation, the opener when a surface closes | 3 |
| The focused thing disappears | Focus goes to its nearest neighbour, next before previous, otherwise to what contained it | 3 |
| A page or surface opens | Focus goes to its first item to act on, and to a text field only when typing is its purpose | 3 |
| Something happens that the user did not just do | Focus and layout stay still, and scroll stays anchored. The thing gets a slow ink mark | 3 |

## Surfaces

| When | Then | Sev |
|---|---|---|
| A task concerns something on screen | Do it where that thing is: its row, its control, or the inspector. New things appear as a row in place | 2 |
| A choice comes from a short fixed list | Use a popover at the control or focused row | 2 |
| A choice comes from a list that can grow or be searched | Use the search overlay | 2 |
| A task needs more room than its place has | Open a surface from where it was asked for. It stays optional and Esc closes it | 2 |
| Other work cannot continue until a question is answered | Use a dialog. Nothing else may use one | 2 |
| The window is too narrow for side by side | Show one pane at a time, in the order tree, content, inspector. Floating surfaces become bottom sheets. No action is lost | 3 |

## Feedback

| When | Then | Sev |
|---|---|---|
| Anything needs saying | Say it where it happened: under the field, at the control, at the save status. With no such place, say it at page level | 3 |
| Something succeeds | Say nothing if the result is visible. Otherwise type the result word at the control, or show a clearing toast for background work | 2 |
| Something fails | The control shakes and turns red briefly, then returns to its normal action, so pressing it again repeats the action. Never add a second button or a red border. The message says what happened and the next step, and stays until the next try. Keep the user's work | 3 |
| Several things fail at once | The first takes the move and focus. The rest show still messages | 2 |
| A change appears elsewhere on screen | Put an ink mark on the other places, not on the place the user edited | 2 |
| A list is empty | Say what belongs here. If the user can add one, name the key | 2 |
| Access is lost | Hide the content and show a doorway screen | 3 |
| The connection or a service is lost | Show one steady notice. Content stays readable | 3 |

## Loading and waiting

| When | Then | Sev |
|---|---|---|
| A wait is too short to notice, under 300 ms | Show nothing | 2 |
| Nothing about the page is known yet | Show a doorway screen | 2 |
| The layout is known and its content is not | Show a skeleton of the real layout. Panes load apart without moving each other | 2 |
| Content is on screen and refreshing | Keep it, ripple the status word with `ripple`, and change values without motion | 2 |
| Loaded content arrives | Ripple the visible rows upwards from below with `loadIn`, once per pane | 2 |
| The user causes one new row | Slide it in from the left with `rowIn` | 2 |
| A wait continues past 5 s | Make the words more specific. Motion does not grow | 2 |
| Work has measurable progress | Show stepped progress | 2 |

## Weight

| When | Then | Sev |
|---|---|---|
| An action can be undone | One press, no question. The thing stays in place, struck through, with Undo. Its background drains with `drain`, the inverse of a hold. Focus moves on. When time runs out it collapses with `listOut` | 4 |
| An action cannot be undone, or undo is not built yet | Hold to confirm with `hold`. The row grows a fill on a spring, the key cap glows, and one line states the outcome and count, typed in reserved space in the first third of the hold. Show the hold only once that text is known. Releasing cancels. The hold setting swaps this for a dialog with Cancel focused, confirmed by Ctrl or Cmd+Enter | 4 |
| Anything would skip those rules | Remove it | 4 |

## Motion

| When | Then | Sev |
|---|---|---|
| The user causes something to arrive | It comes from where it was caused and lands with its token. Deeper navigation arrives from the right, and back from the left | 2 |
| Showing any state on something | Change the thing itself: its fill, its letters, its depth. Never add a border, line, spinner, or second control | 2 |
| Anything changes state | Animate between the states inside the component: label, width, colour. Nothing swaps. Shared letters stay and only the different letters type: Publish, Publishing, Published | 2 |
| Anything grows or responds over time: a hold, a fill, progress, a press | Drive it with a spring so it has weight. Nothing moves linearly | 2 |
| Text appears | Reserve its space so nothing shifts, and type it. It must finish with time left to read it | 2 |
| A key is in use | Its key cap glows | 2 |
| A control is busy or unavailable | It looks pressed in, like a held key. When busy, its label types the busy word and the letters ripple with `ripple` | 2 |
| Anything leaves | It goes towards its origin, faster than it arrived, with no bounce. Something in a list squashes shut with its text, and its neighbours close the gap with it | 2 |
| Something is temporary: an undo, a notice | Its background drains to show the time left | 2 |
| Choosing how strong a move is | Go strong: a deep press, a big bounce, a hard shake. Keep it fast. Flat is the failure to avoid | 2 |
| The pointer reaches something you can act on | It rises with `hoverIn`, without a shadow, and leaves with `hoverOut`. If it has a key, its key cap strikes up with `capIn` | 2 |
| A button has a key | Always show the key cap. Pressing either one presses both | 2 |
| Focus moves | The ring slides with `focusMove` | 2 |
| A move repeats fast or would go off screen | Make it smaller, down to none. A held key makes the ring jump | 2 |
| Several moves would play together | Only the user's latest action moves. Everything else changes without motion | 2 |
| You cannot name what a move tells the user | Do not add it. Only rippling busy words and skeletons may loop | 2 |
| Any move runs | Input still works, and the move can retarget from where it is | 3 |
| Reduced motion is on | Keep every result and remove the travel, in the tokens, not per widget | 3 |

## Keyboard

| When | Then | Sev |
|---|---|---|
| Adding an action | Make one command through an Intent, used by key, button, menu, and command list (Ctrl or Cmd+K, `?` for the scope) | 3 |
| Something works with one input | Make it work with pointer, keyboard, and touch: hover reveal, drag, pan. Drag also has a single click path | 3 |
| Keys change meaning | Show the mode in the chip: Normal, Insert, Move, Resize. A focused field is Insert, and Esc leaves it | 3 |
| An action means something the key language already covers | Reuse that key, and name the action for its context: D is Remove member on a member and Delete page on a page | 2 |
| Choosing a key for a new meaning | Pick a key no other meaning uses anywhere, and add it to the key language in the same change. Scope changes a key's target, never its meaning | 2 |
| Choosing any key | Use only keys a page can intercept, so never Ctrl or Cmd+N, T, W, or Ctrl+Esc. Single keys follow the off and remap setting | 3 |
| Placing an action | Attach it to the smallest thing it acts on: the focused row, then the selection, then the pane, then the page | 2 |
| One key matches at several levels | The most specific level wins | 2 |
| Both a focused row and a selection exist | Act on the selection if it contains the focused row, otherwise on the focused row | 3 |
| An action cannot work here | Leave it out of key hints and the command list, which list the most specific actions first | 2 |
| Moving around | Tab between controls and groups, arrows and H, J, K, L inside them, Esc out one level | 2 |
| Only touch is available | Hide key caps, key hints, and the mode chip | 2 |

## Look

| When | Then | Sev |
|---|---|---|
| Setting any visual value | Use a token from the tables below or the theme. Add a missing one beside `panel/lib/shared/theme/typewriter_spacing.dart`. Never write a literal | 2 |
| Showing a state | Each signal has one meaning: fill is selected, ring is focus, brighter surface is the active pane, status colour is that status, filled button is the pane's main action. Signals combine and stay distinct | 3 |
| Choosing an action's weight | One filled button per pane at most, in the pane header, right side. The rest are quiet. Row actions show on hover and focus, and in the context menu | 2 |
| Placing content | A title and its content share one left edge. Single line rows are 32 px, 44 px on touch; richer rows grow to fit | 2 |
| Writing text | At least 4.5:1 in both themes | 3 |
| Choosing a font | A full sentence uses IBM Plex Sans. Everything else uses Lilex, at weight 500 or 600 on labels and buttons | 2 |

## Text

| When | Then | Sev |
|---|---|---|
| Misreading would cost the user something | Plain literal English in short sentences: what happened, then what to do. No idioms | 3 |
| Nothing depends on it: sign in, empty, long wait, small success, first run | A joke in simple words is welcome, beside clear text that stands alone | 2 |
| Naming an action | One name everywhere, and its result uses the same word: Publish, Published. Sentence case, whole strings, real plurals | 2 |

## Building

| When | Then | Sev |
|---|---|---|
| A shared component does the job | Use it. If none does, build it once in `panel/lib/shared` | 2 |
| A surface is new or changed | Its story shows every state that applies: default, hover, focus, active, disabled, loading, empty, error, offline, compact | 2 |
| Keyboard behaviour is new or changed | A widget test proves the key path and where focus lands | 3 |
| No rule or demo settles how something should feel | Build three live options and let a maintainer pick. Add what you learn here as a general rule, not as that element's design | 2 |
| You must break a rule | Ask a maintainer. If approved, add it to the exceptions in the `panel-review` skill | 3 |

## Values

| Colour | Value |
|---|---|
| Brand fill | `#009FFF` with black text |
| Brand text | `#33AEFF` on dark, `#006FB8` on light |
| Focus ring | 2 px, `#009FFF` on dark, `#006FB8` on light, at least 3:1, at every window size |

| Other | Value |
|---|---|
| Space | 4, 8, 12, 16, 20, 24, 32, 40, 48 |
| Radius | Pane 12, control 8, key cap and small chip 4 |
| Shadow | Menus and toasts, then dialogs. Nothing else |
| Icons | Material Symbols, bundled. 16 px inline, 20 px in controls |

| Token | Curve | Duration | Landing |
|---|---|---|---|
| `panelIn` | Strike | 420 ms | 10% overshoot |
| `dialogIn` | Strike | 340 ms | 14% overshoot; the page behind scales to 0.98 |
| `focusMove` | Strike | 170 ms | 5% overshoot |
| `hoverIn` | Strike | 220 ms | Rises 2 px, scale 1.012, one overshoot |
| `capIn` | Strike | 240 ms | Rises 9 px, one overshoot |
| `loadIn` | Strike | 190 ms per row | Rises 14 px; the last visible row starts within 150 ms |
| `rowIn` | Carriage | 280 ms | 6% recoil, hit at `h = 0.42` |
| `press` | Spring | Stiffness 300, damping 12 | Sinks 4 px, scale 0.93, big bounce back |
| `hoverOut` | Exit | 90 ms | None |
| `panelOut` | Exit | 200 ms | None |
| `dialogOut` | Exit | 150 ms | None |
| `listOut` | Spring | Stiffness 380, damping 30 | Height, vertical scale, and opacity go to 0 together |
| `hold` | Spring | 800 ms | The fill leads and settles |
| `ripple` | Ease in and out | 620 ms, 42 ms between letters | Letters rise 3 px, looping |
| `drain` | Linear | 6 s | The one linear move, since it shows real time |
| `type` | Stepped | 36 ms per letter | None |
| `ink` | Ease out | 900 ms fade; 2 s for changes by others | None |
| `jam` | Judder | 400 ms | 4 cycles, 9 px and decaying, with a red flash that fades in 1.5 s |

- **Arrivals:** reach the final position within 150 ms; the landing plays after that.
- **Strike:** `1 - e^(-z*w*t) * (cos(wd*t) + (z*w/wd) * sin(wd*t))`, `t` from 0 to 1, `w = 5/z`, `wd = w*sqrt(1 - z*z)`, `z = -ln(o) / sqrt(pi^2 + ln(o)^2)`, `o` the overshoot.
- **Carriage:** `1 - (1 - t/h)^1.6` until `h`, then `1 - a * sin(pi*p) * (1 - p)^1.2`, `p = (t - h) / (1 - h)`, `a` the recoil.
- **Exit:** `Cubic(0.4, 0, 0.2, 1)`.
- **Feel:** when judging a move, open `docs/design/panel-design/demos/experience.html` in a browser.

| Key language | Meaning |
|---|---|
| Enter | Open or activate the focused thing |
| Space | Toggle or expand the focused thing |
| Ctrl or Cmd+Enter | Run the main action of this surface |
| Esc | Step out one level |
| N | Create a new thing here |
| D, Delete, Backspace | Remove the focused or selected thing |
| C | Copy the focused thing's value |
| Arrows, H, J, K, L | Move inside this pane |
| Ctrl+Arrows, Ctrl+H, J, L | Move between panes |
| Home, End | First and last item |
| Ctrl or Cmd+U, D | Scroll a page |
| Ctrl or Cmd+K | Search and commands |
| `?` | All keys for this scope |
| Shift+M, Shift+R | Enter Move or Resize mode |
| Shift+P | Open the realm inbox |
| Ctrl or Cmd+=, -, 0 | Zoom in, out, and reset |

| When you need | Use | Never |
|---|---|---|
| A busy button | `LoadingButton`, `LoadingIconButton` | A private spinner |
| A wait | `ripple` on the status word, `Shimmer` | `CircularProgressIndicator` |
| A menu or popover | `AnchoredPopup`, `ContextMenuRegion` | `PopupMenuButton`, `MenuAnchor` |
| A select | `Dropdown`, `MultiselectDropdown` | `DropdownButtonFormField` |
| A dialog | The one dialog component | `AlertDialog` |
| A permanent action | The hold component | `showConfirmationDialogue` |
| A message | Snackbar helpers | `ScaffoldMessenger` |
| A heading | `PageHeading`, `SectionTitle` at theme sizes | Local size or weight overrides |
| A status | `StatusIndicator`, one chip | `TypeBadge`, `SmallChip`, `PresetChip` as separate styles |
| A pane | `Pane` | Local pane colours |

| Moment | Write |
|---|---|
| Empty book | This page is blank. Press N and fix that. |
| Normal error | The realm did not answer. Press Publish to try again. |
| Wait | Connecting to the realm |
| Permanent action | Remove Ada? They lose access straight away. |
| Removed, with undo | ~~Arrival~~ Undo |
| Crash | That jammed. Reload the panel, and tell us on Discord if it happens again. |
