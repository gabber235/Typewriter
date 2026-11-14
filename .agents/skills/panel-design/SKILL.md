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
| Something happens that the user did not just do | Focus and layout stay still, and scroll stays anchored. A changed value moves with `waveSlow`; an added or removed thing uses its usual move. A chip springs in with who did it and why, as their avatar when one exists | 3 |

## Surfaces

| When | Then | Sev |
|---|---|---|
| A task concerns something on screen | Do it where that thing is: its row, its control, or the inspector. New things appear as a row in place | 2 |
| A choice comes from a short fixed list | Use a popover at the control or focused row | 2 |
| A choice comes from a list that can grow or be searched | Use the search overlay | 2 |
| A task needs more room than its place has | The row or control grows into a surface with `surfaceIn`, and Esc shrinks it back. It stays optional. Never strike in at the centre over a dimmed page | 2 |
| Other work cannot continue until a question is answered | Use a dialog. Nothing else may use one | 2 |
| The window is under 900 px, or a pane would be narrower than 320 px | Show one pane at a time, in the order tree, content, inspector. Floating surfaces become bottom sheets. No action is lost | 3 |

## Feedback

| When | Then | Sev |
|---|---|---|
| Anything needs saying | Say it where it happened: under the field, at the control, at the save status. With no such place, say it at page level | 3 |
| Something succeeds | Say nothing if the result is visible. Otherwise type the result word at the control, or show a clearing toast for background work | 2 |
| Something fails | The control shakes and turns red briefly, then returns to its normal action, so pressing it again repeats the action. Never add a second button or a red border. The message says what happened and the next step, and stays until the next try. Keep the user's work | 3 |
| Several things fail at once | The first takes the move and focus. The rest show still messages | 2 |
| A change appears elsewhere on screen | A `wave` through the letters switches the text in other places showing it, not the place the user edited. Changes that are not text use a fill that fades | 2 |
| Something is empty | Show the mascot, a large playful line, and a serious subtitle saying what belongs here. If the user can add one, put the main action on the right with its key | 2 |
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
| An action loses the user's work or makes someone else act again, and cannot be undone (Discard, Use saved, Decline, Remove member, Revoke, Unbind, a Realm declared confirmation) | Hold to confirm, as long as its weight: `holdLight` when only the user's own unsent work is lost (Discard, Use saved), `holdHeavy` when someone else must act again (Remove member, Decline, Revoke, Unbind), `holdPermanent` when nothing recovers it (deleting a Realm resource). Every hold declares its weight; a Realm operation declares it in Kotlin. The row or button grows a fill from its start edge on a spring, the key cap glows, and one line states the outcome and count in reserved space: its verb types itself and the rest arrives whole on a bounce, all in the first third of the hold. A held button sinks from 1 to 4 px and shrinks to 0.95 over the hold, trembles once between 86 and 96 percent of it, and on completion springs back and types its done word (Removed, Revoked, Discarded) for `holdDoneShow`, 1.3 s, before its label returns; a Realm operation declares no done word and types none. A filled button fills black at 28 percent; a row, a flat or an outlined button fills red at 16 percent. Show the hold only once that text is known. Releasing, leaving the button, or moving focus cancels; pressing again continues from the fill. A screen reader hears the line and "Long press to confirm", and its long press confirms at once. No setting replaces the hold yet; it arrives with account settings | 4 |
| An action can simply be done again and loses nothing (Publish, cancelling one's own request) | One press, no hold and no question. Its key works only where the action is shown | 2 |
| Anything would skip those rules | Remove it | 4 |

## Motion

| When | Then | Sev |
|---|---|---|
| The user causes something to arrive | It comes from where it was caused and lands with its token | 2 |
| Something exists before and after a change | Move it to its new place instead of replacing it. Opening a row turns that row into the page heading; the rest ripple in, and Back reverses | 2 |
| Moving between pages with nothing to carry over | The page swaps at once and its rows ripple in with `loadIn`: from the right going deeper, from the left going back. Between sibling pages they come by sidebar order: from below going down the sidebar, from above going up | 2 |
| Showing any state on something | Change the thing itself: its fill, its letters, its depth. Never add a border, line, spinner, or second control. Add an element only for information not otherwise visible, such as who did it, and it must arrive with motion | 2 |
| Anything changes state | The move performs the change: the value switches as the motion passes, never first. Animate inside the component: label, width, colour. Nothing swaps. Shared letters stay and only the different letters type: Publish, Publishing, Published | 2 |
| Anything grows or responds over time: a hold, a fill, progress, a press | Drive it with a spring so it has weight. Nothing moves linearly | 2 |
| Text appears | Reserve its space so nothing shifts. Short text, about 20 letters or fewer, types itself. Longer text arrives whole, on a bounce, with chunks animating inside. It never delays reading | 2 |
| A key is in use | Its key cap glows | 2 |
| A control is busy or unavailable | It looks pressed in, like a held key. When busy, its label types the busy word and the letters ripple with `ripple` | 2 |
| Anything leaves | It goes towards its origin, faster than it arrived, with no bounce. Something in a list squashes shut with its text, and its neighbours close the gap with it | 2 |
| Something is temporary: an undo, a notice | Its background drains to show the time left | 2 |
| Choosing how strong a move is | Go strong: a deep press, a big bounce, a hard shake. Keep it fast. Flat is the failure to avoid. Be fun when it is not in the way, and shorten or drop any move that makes the user wait | 2 |
| The pointer reaches something you can act on | It rises with `hoverIn`, without a shadow, and leaves with `hoverOut`. If it has a key, its key cap strikes up with `capIn` | 2 |
| A button has a key | Always show the key cap. Pressing either one presses both | 2 |
| Focus moves | The ring travels with `focusMove`, across panes too, so it leads the eye | 2 |
| A pane gains focus | It lifts forward and brightens while the others sink back, with `paneFocus` | 2 |
| A move repeats fast or would go off screen | Make it smaller, down to none. A held key makes the ring jump | 2 |
| Several moves would play together | Only the user's latest action moves. Everything else changes without motion | 2 |
| Something a service or realm presents changes state | The panel picks the move from the change: hovered on `hoverIn`, off `hoverOut`, focused `focusMove`, pressed `press`, selected `ink`, a collection item added `rowIn` and leaving `listOut`. The service may override how each plays, keyed by that state or by the item's arrival or leave: a timed override (duration, curve or both: strike, carriage, exit, ease out, linear) or a spring. A duration alone on a spring move keeps its damping ratio. Reduced motion applies after the override | 2 |
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
| Choosing an action's weight | One filled button per pane at most: its main action, placed with the operations it belongs to, never floating over content. The rest are flat, or outlined for the likely next step, each with its icon. Kotlin declares each operation's emphasis (flat, outline, filled); when two ask to be filled, the panel fills the first and shows the rest flat. Operations are ordered by group, then order, and each group is a section with a divider between, the same list in the inspector and the context menu; danger tone gets its own section and is held. Row actions show on hover and focus, and in the context menu | 2 |
| Placing content | A title and its content share one left edge. Table rows are about 42 px, and at least 44 px on touch | 2 |
| Showing many things that have details | Use a table with an inspector. The table scans, and the selected thing appears large in the inspector with its details, actions, and keys | 2 |
| Designing or simplifying anything a user sees | Keep its character: things look like what they are (a book is a stacked cover that springs when chosen), a thing's title is large and in its colour, the mascot and playful lines appear where nothing depends on them. When a change removes something, name the character that replaces it. Professional and fun; never sterile or corporate | 3 |
| A static page feels boring | Add interest with real information and identity: a stable colour tile or icon for each person or kind of thing, a small visual of real data such as activity. Keep exact values in the inspector | 2 |
| Showing the health of many things | Every item states its status in words, such as Running. Normal states may carry a small, quiet colour; what is wrong gets the strongest colour and size, so the eye finds it first | 3 |
| Adding colour to a page | Colour always carries information: a tile per person or kind, a status, a small visual of real data. Keep it to small marks, balanced across the screen, never large fills. A page with none feels lifeless; colour everywhere overloads | 2 |
| Styling a static page | Familiar and lively: soft filled shapes for controls, spaced muted labels, flat surfaces, identity marks kept. Depth appears only in motion. Never add rules under titles, text markers such as `>`, brackets, physical key rows, or paper panes | 2 |
| Writing text | At least 4.5:1 in both themes | 3 |
| Choosing a font | A full sentence uses IBM Plex Sans. Everything else uses Lilex, at weight 500 or 600 on labels and buttons | 2 |

## Text

| When | Then | Sev |
|---|---|---|
| Misreading would cost the user something | Plain literal English in short sentences: what happened, then what to do. No idioms | 3 |
| Nothing depends on it: sign in, empty, long wait, small success, first run | A joke in simple words is welcome, beside clear text that stands alone | 2 |
| Naming an action | One name everywhere, and its result uses the same word: Publish, Published. Sentence case, whole strings, real plurals | 2 |
| One thing shows in several places | It carries its own name and the same status colour everywhere: card, inspector, list. Never another thing's name | 2 |
| A word names a Typewriter concept (realm, book, page kinds, service) | Where it helps, the word opens a rich tooltip on hover or focus that explains it with a visual and a link to the docs; empty places explain what belongs there. Never a tour or a first visit popup | 2 |

## Building

| When | Then | Sev |
|---|---|---|
| A shared component does the job | Use it. If none does, build it once in `panel/lib/shared` | 2 |
| Rows arrive or leave | Use `AnimatedSliverList`, `AnimatedTable`, `SliverAnimatedContent` or, for editor collections, `CollectionSequence`; pass content only. They play `loadIn`, `rowIn` and `listOut` and keep on screen rows still when rows above the screen change | 2 |
| Writing a Duration, curve or `.ms` for motion | Use a token instead; `design_system_guardrails_test.dart` fails on literal motion in UI code and only shrinks its exemption list | 2 |
| A surface is new or changed | Its story shows every state that applies: default, hover, focus, active, disabled, loading, empty, error, offline, compact | 2 |
| An element is built or redone | A widget test uses it with the keyboard alone, without Tab: every part reached, used, confirmed and left by its keys, and where focus lands | 3 |
| Deciding where inspector content is defined | In Kotlin whenever possible: heading, fields and their labels, operations, concepts. The panel draws what Kotlin declares, so extensions can shape it | 3 |
| No rule or demo settles how something should feel | Build three live options and let a maintainer pick. Add what you learn here as a general rule, not as that element's design | 2 |
| You must break a rule | Ask a maintainer. If approved, add it to the exceptions in the `panel-review` skill | 3 |
| Building a control | Build it on Flutter's widgets layer: `FocusableActionDetector`, `WidgetStatesController`, `Semantics`, gestures, its own painting. Use Material only where Flutter has no primitive: text input, selection, `Scaffold`, tabs | 2 |
| A change touches a line that uses a Material widget | Replace it with the panel's own component, or build that component in `panel/lib/shared/ui` with a story first. The `dart-material-widget` rule fails added lines that use one | 2 |

## Values

| Colour | Value |
|---|---|
| Brand fill | `#009FFF` with black text |
| Brand text | `brandText`: about `#20A3FF` on dark, `#0062CA` on light |
| Status text | `dangerText`, `successText`, `warningText`, `infoText`, derived by `text_tone.dart`: 4.5:1 on every surface, most chroma the gamut allows; dark keeps the hue, light turns it up to 10 degrees. About danger `#FF6F69` and `#CD0006`, success `#00B628` and `#067600`, warning `#E88A00` and `#9F4F00` (dark, light) |
| Info | Violet, OKLCH hue about 288 (`#7C4DFF` fill). Brand is the only blue |
| Any other hue as text | `colors.textOf(hue, over: tint)` |
| Focus ring | 2 px, `#009FFF` on dark, light brand text on light, at least 3:1, at every window size. Never a fill |

| Other | Value |
|---|---|
| Space | 4, 8, 12, 16, 20, 24, 32, 40, 48 |
| Radius | Pane 12, control 8, key cap and small chip 4 |
| Shadow | Menus and toasts, then dialogs. Nothing else |
| Icons | Material Symbols, bundled. 16 px inline, 20 px in controls. Never a Unicode emoji, in the panel or its mocks: always an icon, so it can take colour and weight |

| Token | Curve | Duration | Landing | Reduced |
|---|---|---|---|---|
| `panelIn` | Strike | 420 ms | 10% overshoot from scale 0.92 | jump |
| `surfaceIn` | Spring | Stiffness 280, damping 17 | Position and size go from the opener to the surface | jump |
| `paneFocus` | Spring | Stiffness 300, damping 13 | Active pane scale 1.03, others 0.985, and brightens with a 4% wash | jump |
| `dialogIn` | Strike | 340 ms | 14% overshoot from scale 0.94; the page behind scales to 0.98 | jump |
| `focusMove` | Strike | 170 ms | 5% overshoot | jump |
| `hoverIn` | Strike | 220 ms | Rises 2 px, scale 1.012, one overshoot | still: a control brightens one step |
| `capIn` | Strike | 240 ms | Rises 9 px, one overshoot | still: appears in place |
| `loadIn` | Strike | 190 ms per row | Rises 14 px; the last visible row starts within 150 ms | jump |
| `rowIn` | Carriage | 280 ms | 6% recoil, hit at `h = 0.42` | jump |
| `press` | Spring | Stiffness 300, damping 12 | Sinks 4 px, scale 0.93, big bounce back | still: a control darkens while down |
| `splash` | Ease out | 450 ms | A press splash grows from the press point (a key: the middle) to cover the control; it stays while held and drains with `panelOut` | still: no splash |
| `hoverOut` | Exit | 90 ms | None | still |
| `panelOut` | Exit | 200 ms | None | jump |
| `dialogOut` | Exit | 150 ms | None | jump |
| `listOut` | Spring | Stiffness 380, damping 30 | Height, vertical scale, and opacity go to 0 together | jump |
| `holdLight` | Spring | Settles in 1.2 s | The fill leads and settles; the clock decides. The button sinks 1 to 4 px, scales to 0.95, and trembles 2 px once between 86 and 96 percent | paced: fills in place |
| `holdHeavy` | Spring | Settles in 1.8 s | As `holdLight` | paced: fills in place |
| `holdPermanent` | Spring | Settles in 2.6 s | As `holdLight` | paced: fills in place |
| `ripple` | Ease in and out | 620 ms, 42 ms between letters | Letters rise 3 px, looping | still |
| `skeleton` | Linear | 1000 ms per sweep | A skeleton's shimmer, looping | still: placeholders stay still |
| `wave` | Spring per letter | Settles in 420 ms, 34 ms between letters | Each letter rises 4 px, turns brand blue, and switches as it passes | jump |
| `waveSlow` | Ease in and out | 1000 ms, 60 ms between letters | As `wave`, 2 px | jump |
| `drain` | Linear | 6 s | The one linear move, since it shows real time | paced: empties in place |
| `type` | Stepped | 36 ms per letter | None | paced: still types |
| `ink` | Ease out | 900 ms fade; 2 s for changes by others | None | paced |
| `jam` | Judder | 400 ms | 4 cycles, 9 px and decaying, with a red flash that fades in 1.5 s | still: keeps the red flash without the shake |

- **Arrivals:** reach the final position within 150 ms; the landing plays after that.
- **Strike:** `1 - e^(-z*w*t) * (cos(wd*t) + (z*w/wd) * sin(wd*t))`, `t` from 0 to 1, `w = 5/z`, `wd = w*sqrt(1 - z*z)`, `z = -ln(o) / sqrt(pi^2 + ln(o)^2)`, `o` the overshoot.
- **Carriage:** `1 - (1 - t/h)^1.6` until `h`, then `1 - a * sin(pi*p) * (1 - p)^1.2`, `p = (t - h) / (1 - h)`, `a` the recoil.
- **Exit:** `Cubic(0.4, 0, 0.2, 1)`.
- **Spring:** mass 1, given as stiffness and damping or as a settle time and damping ratio. A spring settles when it stays within 1% of its travel. A sent duration keeps the damping ratio; a sent spring ignores the duration.
- **Reduced:** `jump` lands at once; `still` never starts the travel, and a control (not a row) shows the state as its fill; `paced` keeps its time with no travel. Only `resolveMotion` applies it.
- **Repeats:** a move that repeats in the same direction before it finished shortens in proportion, and jumps when it repeats within a quarter of its time. A move that turns back continues from where it is at full length.
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
| A move | `useMotion` or `MotionController` with a token through `resolveMotion`; `Rise`, `Enter` with `EnterRun`, `Leave`, `HoldFill` with `HoldClock`, `Ring` with `RingTarget`; `motionTimeline` for framework APIs that take a Duration and a Curve | A literal duration or curve, `AnimationController` with its own timing, `flutter_animate` |
| A button, busy or not | `Button` with its face and a busy word; `dense` for authored compact density | `TextButton`, `FilledButton`, `OutlinedButton`, `ElevatedButton`, `IconButton`, `FloatingActionButton`, `InkWell`, a private spinner |
| A row or card activated as a whole | `Button` with the bare face | `InkWell` |
| A wait | `MotionLabel` rippling the status word, `Shimmer` | `CircularProgressIndicator` |
| A failure at a control | `Jam` around it; `Button` does this itself | A shake of your own, a red border |
| Text that changes or appears | `MotionLabel` | Swapping the whole text |
| A box that grows or shrinks with its content | `MotionSize` | `AnimatedSize`, which throws under reduced motion |
| A message that changes or appears and may wrap | `TypedParagraph` | `MotionLabel`, which keeps one line |
| A field problem | `PortableDiagnosticMessages`: waits `problemWait` after the last edit, types in, says Fixed for `doneShow` when cleared | Showing it at every keystroke |
| A menu or popover | `AnchoredPopup`, `ContextMenuRegion` (on `RawMenuAnchor`) | `PopupMenuButton`, `MenuAnchor`, `DropdownMenu` |
| A tooltip | `PanelTooltip` | `Tooltip`, a button's `tooltip:` |
| A select | `Dropdown`, `MultiselectDropdown` | `DropdownButtonFormField` |
| A dialog | `showAdvancedDialog` (on `RawDialogRoute`) | `AlertDialog` alone, `showDialog`, `showGeneralDialog` |
| An animation | A motion token | `flutter_animate` |
| A sheet | `showPanelSheet` | `showModalBottomSheet` |
| A row that grows | `GrowingCard` (on `Expansible`) | `ExpansionTile`, `Expansible` with its own style |
| A wait before something happens | `context.timing` | A literal `Duration` |
| A permanent action | `ActionRun.hold` with a `HoldPlan` of its `HoldWeight` and done word on the command, rows from `useAnimatedRows` (the entry carries the hold), `CommandButton` for its buttons | `showConfirmationDialogue`, `AlertDialog`, a second confirm path, a hold without a weight |
| A failure or a message | `context.reportFailure` with a retry when one helps, `context.reportSuccess`; the shell's `Toaster` shows them and failures land in Activity | `ScaffoldMessenger`, `SnackBar` |
| A heading | `PageHeading`, `SectionTitle` at theme sizes | Local size or weight overrides |
| A status | `StatusIndicator`, one chip | `TypeBadge`, `SmallChip`, `PresetChip` as separate styles |
| A pane | `Pane` | Local pane colours |
| Showing focus | The one `FocusRingLayer`; a `RingTarget` where the ring should wrap more than the focused node | `FocusHighlight`, a focus border, a focus fill |
| Focus in a list, table or graph | `useAnimatedRows`; `RowStop` inside the row's action set; `RowLanding` in editor rows | A `FocusNode` per row, an id passed beside the row, a focus fill |
| Focus on open | `Pane(openFocus: PaneOpenFocus.firstItem)`; `autofocus` only on a field that exists to be typed into | A post frame `requestFocus` |
| Focus after a create | `rows.focus.expect(id)` | Focusing the row in the create callback |

| Moment | Write |
|---|---|
| Empty book | This page is blank. Subtitle: Pages hold the dialogue and quests of this book. |
| Normal error | The realm did not answer. Press Publish to try again. |
| Wait | Connecting to the realm |
| Permanent action | Remove Ada? They lose access straight away. |
| Removed, with undo | ~~Arrival~~ Undo |
| Crash | That jammed. Reload the panel, and tell us on Discord if it happens again. |
