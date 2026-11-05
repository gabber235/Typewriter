# Motion review: Members, Services, resource editor

Motion only. Static, focus target, wording, and weight findings stay in `members.md`, `services.md`,
and `resource-editor.md`; this report replaces their motion `cannot_verify` rows. Evidence is source
code: for every action and state change, the code that runs and what it animates. Paths are below
`panel/lib/` unless they start with `services/`.

## Summary

No page plays a single move from the token table. The panel has no motion tokens at all: every
animation is a literal duration and curve chosen per widget (mostly `ElasticOutCurve`, Material
defaults, and linear implicit animations), reduced motion is handled in a handful of widgets and
missing in the rest, and portable presentations receive raw milliseconds and curves from the
services over the wire.

Single most valuable change: add the motion tokens once in the theme (Strike, Carriage, and Exit
curves, the springs, and a reduced motion resolution inside the tokens), then move the shared
components (`StaggerEntrance`, `ElasticTransition`, `FocusHighlight`, `LoadingButton`,
`GridSelectableCard`, `ResourceItemChrome`, the dialog route, and the portable transition contract)
onto them. Most page findings below disappear with the shared ones.

## Action walk

### Shared code

| Action or state | Moment and expected move | Code | What runs |
|---|---|---|---|
| Any move | Token from the table, reduced motion in the tokens | `shared/theme/*.dart` | No motion token exists; only `tooltipTheme.waitDuration: 100.ms` (`component_themes.dart:106`). MOTION-1, MOTION-2 |
| Hover | `hoverIn` rise 2 px, scale 1.012; `hoverOut` 90 ms | `animation.dart:6-11`; `grid_selectable_card.dart:155`; `sidebar_links.dart:71-80`; `services/.../SurfaceLayouts.kt:17-25` | Ink overlay colour, or scale 1.05 on `ElasticOutCurve(0.4)` 750 ms with a 300 ms `easeInOutQuad` return. MOTION-3 |
| Press | `press` spring, sinks 4 px, scale 0.93 | Theme ink splash (`component_themes.dart:56-68`, `:236`) | Material ink ripple and overlay colour. MOTION-6 |
| Focus move | `focusMove` ring travels | `focus_highlight.dart:130-132`; `selector.dart:161-170`, `:248-264`; `grid_selectable_card.dart:106-114` | Ring appears in place: border colour over 200 or 250 ms, plus a 0 to 15 to 0 px pulse. MOTION-4 |
| Focus moves inside the graph | `focusMove`; viewport follows | `graph.dart:102`; `graph_viewport_controller.dart:17`, `:32` | Viewport pans 250 ms `easeOutCubic`; the framework shortens it under reduced motion (graph.md). MOTION-1 |
| Pane gains focus | `paneFocus` spring, 1.03 and 0.985 | `panes.dart:346`, `focus_highlight.dart:130` | Border colour only, 200 ms `fastEaseInToSlowEaseOut`. MOTION-5 |
| Key pressed | Key cap glows | No key cap on any page button | Nothing glows. MOTION-7 |
| Busy | Pressed in, busy word types, `ripple` | `loading_button.dart:248-340`, `:357-375`; `floating_button.dart:115`; `mutation_activity_button.dart:67` | Icon swapped for a `CircularProgressIndicator`. MOTION-8 |
| Fail | `jam` 400 ms judder with red flash | `loading_button.dart:192-194`, `:347-349`; `forward_animation.dart:11`; `floating_button.dart:31`, `:95` | `flutter_animate` `shakeX` with library defaults over 500 ms, linear, no red flash. MOTION-9 |
| Dialog in and out | `dialogIn` with page behind at 0.98; `dialogOut` | `popups.dart:248-277` (`animationStyle` passed through as null) | Framework dialog route default; page behind does not scale. MOTION-10 |
| Popover in and out | Arrives from the control with `panelIn`; `panelOut` | `anchored_popup.dart:243-249`; `multiselect_dropdown_view.dart:21` | 60 ms linear opacity, no exit; `MenuAnchor` with nothing configured. MOTION-11 |
| Sheet in and out | Grows from the opener with `surfaceIn`; `panelOut` | `custom_appbar.dart:99`; `inspector.dart:71-83`, `:122-127` | Framework bottom sheet; mobile inspector 750 ms `ElasticOutCurve(0.8)` in, 400 ms out. MOTION-12 |
| Inspector opens or closes | Selected item carried into it with `surfaceIn`; `panelOut` | `inspector.dart:248-255`, `:332-359` | Width grows 1000 ms `ElasticOutCurve(0.9)`, closes in 750 ms. MOTION-13 |
| Sidebar collapse | Leave without bounce | `sidebar_shell.dart:33-35` | Width 1000 ms `ElasticOutCurve(0.9)` both ways. MOTION-14 |
| Page change | Rows ripple in from the right going deeper, from the left going back | `theme.dart:30-36` (no `pageTransitionsTheme`); router sets no route type | Framework default page transition. MOTION-15 |
| Rows load | `loadIn` 190 ms per row, rises 14 px, last row starts within 150 ms | `stagger_entrance.dart:3-7`, `:309-345` | 300 ms `easeOutCubic`, 60 ms apart, launch capped at 700 ms, slide 5% of own height. MOTION-16 |
| Row arrives or leaves | `rowIn` from the left; `listOut` faster than arrival | `elastic_transition.dart:19-42`; `animated_list.dart:50-51`, `:82-83` | Elastic height and scale in 300 ms; exit on a cubic in the same 300 ms. MOTION-17 |
| Wait with no layout | Skeleton or `ripple` busy word; nothing else loops | `loading_indicator.dart:21-38`, used by `riverpod.dart:31` | Looping spinner, 1 s slide, linear fade. MOTION-18 |
| Linear curves | Only `drain` is linear | `animated_table.dart:126`, `:137-139`; `anchored_popup.dart:243`; `resource_item_chrome.dart:81-82`; `collection_editor.dart:481-483`; `realm_suspension.dart:71`; `diagnostic_chrome.dart:127`; `header.dart:197`; `error_screen.dart:74-115`; `loading_indicator.dart:38`; `PresentationPaint.kt:88-91` | Linear by default in each. MOTION-19 |
| Portable presentation state changes | Tokens resolved by the panel | `presentation_value_environment.dart:119-139`; `services/.../SurfaceLayouts.kt:11-14`, `:39`; `CoreLibrarySdkProviders.kt:125`; `ElementGraphLayouts.kt:56`; `SearchResultLayouts.kt:67` | The wire carries milliseconds and a curve chosen by each service. MOTION-20 |
| Someone else's change | `waveSlow`; a chip springs in naming who | No `wave` or `waveSlow` anywhere | Values swap or rows bounce in. MOTION-21 |
| Realm suspended | One steady notice | `realm_suspension.dart:36-45`, `:155`; `elastic_switcher.dart:22-40` | Veil scales up from 0 on `ElasticOutCurve(0.7)` with a looping progress bar. MOTION-22 |
| Notice or toast | Background drains with `drain` | `snackbar.dart:10-19` | Framework snackbar with a close icon; no drain. MOTION-23 |

### Members

| Action or state | Moment and expected move | Code | What runs |
|---|---|---|---|
| Open page | Ripple in from the right | Framework route | MOTION-15 |
| Rows load | Skeleton, then `loadIn` once | `member_list.dart:116-130`; `member_table.dart:64`, `:128`, `:205`, `:232`, `:277`, `:303` | Shimmer (loops, reduced motion handled: `shimmer.dart:90`), then `StaggerEntrance` on every cell, so a row enters cell by cell. MOTION-16, MOTION-24 |
| Hover a row | `hoverIn`, `hoverOut` | `member_table.dart:215`, `:237` | `InkWell` overlay. MOTION-3 |
| Hover an email | Reveal | `blur_reveal.dart:16`, `:37` | Blur to 0 in 200 ms `easeOut` (literal). MOTION-1 |
| Press | `press` | `member_table.dart:215`, `:237` | Ink ripple. MOTION-6 |
| Focus a row | `focusMove` | `member_table.dart:193-200` | Row fill switches instantly; no ring. MOTION-4 |
| Select a row | Fill changes as the move passes | `member_table.dart:193-200`; `selectable_avatar.dart:25-34` | Fill and avatar swap instantly. MOTION-25 |
| Selection bar in and out | User caused arrival with its token; leave without bounce | `member_list.dart:90-95` | 800 ms `ElasticOutCurve(0.9)` both ways, 400 ms linear fade. MOTION-26 |
| Change roles | Chip arrives in place; removed chip squashes shut | `member_table.dart:286`; `role_multiselect_dropdown.dart:40-56`; `multiselect_dropdown_view.dart:21` | Chips appear and vanish instantly; menu has no panel motion. MOTION-27, MOTION-11 |
| Remove (row icon, D, bulk) | `hold` fill, then `listOut` | `member_row_actions.dart:21-23`; `member_table.dart:28-37`, `:98` | Icon vanishes at once, dialog, then the row leaves on `ElasticTransition` in reverse. MOTION-28, MOTION-10, MOTION-17 |
| Busy in the dialog | Pressed in, `ripple` | `popups.dart:150-160` | Spinner in the confirm button. MOTION-8 |
| Fail | `jam` at the control | `member_list.dart:62`; `member_actions.dart:53` | Snackbar only. MOTION-9, MOTION-23 |
| Expand a card (compact) | `surfaceIn`; collapse `panelOut` | `member_card.dart:47-53`, `:168`; `elastic_message_transition.dart:19-33` | 500 ms `ElasticOutCurve(0.9)`, 20 ms `easeInCubic` back. MOTION-29 |
| Someone adds or removes a member | Still layout, `waveSlow` | `member_table.dart:28`, `:98`; `member_tablet_list.dart:25`, `:111` | Row bounces in or out on `ElasticTransition`. MOTION-21 |
| Refresh | Keep content, `ripple` the status word | `riverpod.dart:22` (`skipLoadingOnReload`) | Content kept; no status word to ripple. MOTION-21 |
| Load fails | Text arrives whole | `member_list.dart:131-138`; `error_screen.dart:74-115` | Staggered linear fades. MOTION-19 |

### Services

| Action or state | Moment and expected move | Code | What runs |
|---|---|---|---|
| Open page | Ripple in | Framework route | MOTION-15 |
| Graph loads | Skeleton, then `loadIn` | `route.dart:41-48`; `riverpod.dart:31` | Spinner, then the graph appears whole with no entrance. MOTION-18, MOTION-30 |
| Hover a node | `hoverIn`, `hoverOut` | `grid_selectable_card.dart:155`; `animation.dart:6-11` | Scale 1.05 on `ElasticOutCurve(0.4)` 750 ms. MOTION-3 |
| Focus a node | `focusMove` | `selector.dart:161-170`, `:248-264`; `grid_selectable_card.dart:113` | Border appears in place, pixel pulse. MOTION-4 |
| Select a node | Fill changes as the move passes; inspector carries it | `grid_selectable_card.dart:20-21`, `:106-107`; `inspector.dart:332-359` | Fill 250 ms `fastEaseInToSlowEaseOut`; inspector slides open on its own. MOTION-13 |
| Pan, zoom, reset | Fast, reduced to none | `graph_viewport_controller.dart:17`, `:32` | 250 ms `easeOutCubic`; the framework shortens it under reduced motion (graph.md). MOTION-1 |
| Connect: busy | Pressed in, `ripple` | `registration_token_input.dart:60-64` | Spinner. MOTION-8 |
| Connect: invalid token or failure | `jam` on Connect | `registration_token_input.dart:28-31`; `loading_button.dart:347-349` | Invalid token returns without failing the button, so nothing shakes; a request failure gets `shakeX`. MOTION-9 |
| Connect: success | New node comes from Connect | `services_graph.dart:39-45` | Node appears in the repacked graph without motion. MOTION-31 |
| Open a realm (double tap) | Node becomes the page heading | `services_graph.dart:244-248` | Route navigation. MOTION-32 |
| Heartbeat or topology change | `waveSlow`, still layout | `services_graph.dart:274-276`, `:318-345` | Opacity 0.58 and status text switch instantly; repack moves nodes instantly. MOTION-21 |
| Empty | Text arrives whole | `services_graph.dart:30-37` | No motion. Not a finding |

### Resource editor

| Action or state | Moment and expected move | Code | What runs |
|---|---|---|---|
| Open page | Ripple in | Framework route; `resource_route.dart:251` | Spinner while the document loads. MOTION-15, MOTION-18 |
| Rail and body load | `loadIn` per pane | `resources.dart:513-530`, `:642` | No entrance. MOTION-33 |
| Hover or focus a rail row | `hoverIn`, `focusMove` | `authored_resource_items.dart:343-345`; `resource_item_chrome.dart:34-40`, `:81-82` | Fill over 120 ms, linear. MOTION-3, MOTION-4, MOTION-19 |
| Hover or focus a book card | `hoverIn`, `focusMove` | `services/.../BookSdkProvider.kt:173-174`; `SurfaceLayouts.kt:17-41` | Scale 1.05 and tilt on 750 ms elastic; focus border 120 ms linear. MOTION-20 |
| Open a rail row | Row becomes the heading, rest ripple, Back reverses | `resource_route.dart:82` | Body keyed by resource, so it is replaced. MOTION-34 |
| Expand or collapse a chapter | Grow and squash | `resources.dart:591-620`, `:688-691` | Children and icon swap instantly. MOTION-35 |
| Create (N, floating button, heading button, Add entry) | `rowIn` from the left | `resource_creation_action.dart:26`; `resource_route.dart:346`; `collection_rows.dart:393` | Route swaps; new rail row and new entry appear instantly. MOTION-36 |
| Busy on create | Pressed in, `ripple` | `floating_button.dart:115` | Spinner. MOTION-8 |
| Remove (D on a row, Remove item) | Book content: strike, Undo, `drain`, then `listOut` | `delete_operation.dart:48`; `collection_rows.dart:637` | Dialog, then the row disappears. MOTION-37, MOTION-10 |
| Reorder an entry | Spring, no shadow outside menus | `collection_rows.dart:401-405` | Elevation 6 on `easeInOut`. MOTION-19 |
| Field diagnostic appears | Fill fades; failing control jams | `diagnostic_chrome.dart:127-131`; `header.dart:197-220` | 120 ms linear fill (reduced motion handled), 240 ms `easeOut` expand. MOTION-19 |
| Issue check runs and finishes | `ripple` while checking; count changes in place | `resource_issue_badge.dart:19-45` | Badge appears, swaps icon and count, and vanishes instantly. MOTION-38 |
| Background save | Busy word `ripple` | `mutation_activity_button.dart:67` | Spinner. MOTION-8 |
| Someone else edits | `waveSlow` on changed text, still layout | `authored_resource_inspection.dart:97-101` | Values swap; conflict notice pops in and pushes the editor down. MOTION-21 |
| Realm goes offline | Steady notice | `realm_suspension.dart:36`, `:71` | MOTION-22 |

## Findings

### Shared

- id: MOTION-1
  rule: "Any action or state change"
  severity: 2
  region: "Theme; every animated widget"
  evidence: "shared/theme/*.dart has no motion token (only component_themes.dart:106 waitDuration); rg finds none of panelIn, surfaceIn, paneFocus, focusMove, hoverIn, capIn, loadIn, rowIn, press, listOut, hold, ripple, wave, drain, jam in panel/lib; literal durations in e.g. stagger_entrance.dart:3-6, elastic_transition.dart:21-29, inspector.dart:123-136, sidebar_shell.dart:34-35, graph_viewport_controller.dart:17, blur_reveal.dart:16"
  observed: "Every move is a literal duration and curve chosen per widget. No Strike, Carriage, or Exit curve and no spring token exists to use."
  fix: "Add a motion token extension beside typewriter_spacing.dart with the table's curves, springs, and durations, and move every animation onto it."

- id: MOTION-2
  rule: "Reduced motion is on"
  severity: 3
  region: "Every animated widget"
  evidence: "Handled per widget only in stagger_entrance.dart:155, shimmer.dart:90, elastic_switcher.dart:17, anchored_popup.dart:245, animated_slivers.dart:33, :54, realm_suspension.dart:66, diagnostic_chrome.dart:128, header.dart:97, :198, :217. Missing in elastic_transition.dart:19, animated_list.dart:50-51 (used by member_table.dart:28 and member_tablet_list.dart:25 with defaults), member_list.dart:90-95, member_card.dart:47-53, inspector.dart:76, :122, :332, :351, sidebar_shell.dart:33, loading_button.dart:192, floating_button.dart:31, loading_indicator.dart:31, error_screen.dart:74-115, focus_highlight.dart:130, selector.dart:161, grid_selectable_card.dart:155, resource_item_chrome.dart:81, graph_viewport_controller.dart:17, presentation_value_environment.dart:135"
  observed: "Reduced motion is decided in each widget, and most widgets ignore it: rows still bounce in, the inspector and sidebar still spring, buttons still shake."
  fix: "Resolve reduced motion inside the motion tokens so every result stays and travel drops to none; remove the per widget checks."

- id: MOTION-3
  rule: "The pointer reaches something you can act on"
  severity: 2
  region: "Member rows, sidebar links, service nodes, rail rows, book cards"
  evidence: "member_table.dart:215, :237 and sidebar_links.dart:71-80 (InkWell overlay); grid_selectable_card.dart:155 with animation.dart:6-11 (scale 1.05, ElasticOutCurve(0.4) 750 ms, out 300 ms easeInOutQuad); resource_item_chrome.dart:38-40, :81-82 (fill, 120 ms linear); services/sdk/typewriter-api/.../SurfaceLayouts.kt:17-25 (scale 1.05 and rotate 0.005 on selectMotion)"
  observed: "Nothing rises with hoverIn. Hover is a colour overlay, or a 1.05 scale and tilt on a 750 ms elastic with a 300 ms return; no hoverOut."
  fix: "One hover move in a shared wrapper: rise 2 px and scale 1.012 with hoverIn, return with hoverOut; drop hoverRotate and the overlay colours."

- id: MOTION-4
  rule: "Focus moves"
  severity: 2
  region: "Member rows, service nodes, rail rows, book cards, fields"
  evidence: "member_table.dart:193-200 (fill switches, no ring); selector.dart:161-170, :248-264 (200 ms PixelScaleTransition 0 to 15 to 0 on focus gain); grid_selectable_card.dart:106-114 (border 250 ms fastEaseInToSlowEaseOut); resource_item_chrome.dart:38-40; SurfaceLayouts.kt:28-41 (focusRing, 120 ms linear)"
  observed: "No ring travels. Each item draws or fills its own focus in place, with a different duration and curve per component."
  fix: "One focus ring layer that moves between targets with focusMove, across panes, and jumps when a key is held."

- id: MOTION-5
  rule: "A pane gains focus"
  severity: 2
  region: "Every pane: sidebar, services, inspector, resource, resource rail"
  evidence: "panes.dart:339-346 wraps the pane in FocusHighlight; focus_highlight.dart:130-138 animates only the border colour, 200 ms fastEaseInToSlowEaseOut"
  observed: "The active pane only changes border colour. It does not lift to 1.03 and brighten, and the others do not sink to 0.985."
  fix: "Drive pane scale and surface brightness from the paneFocus spring in Pane."

- id: MOTION-6
  rule: "Anything grows or responds over time: a hold, a fill, progress, a press"
  severity: 2
  region: "Every button and pressable row"
  evidence: "component_themes.dart:56-68 (overlay and splash colours), :236 (InkSplash); member_table.dart:215, :237 (InkWell)"
  observed: "A press shows a Material ink ripple. Nothing sinks 4 px and springs back."
  fix: "Replace ink splash with the press spring in the shared button and row components."

- id: MOTION-7
  rule: "A key is in use"
  severity: 2
  region: "D, Delete, N, Enter on Members rows, the services graph, and the editor"
  evidence: "member_row_actions.dart:27-35, registration_token_input.dart:60-64, resource_route.dart:113-117 and :141-151: no button on these pages shows a key cap (ShortcutDisplay is used only in search, shortcut_display.dart:242)"
  observed: "Pressing a key glows nothing, because no key cap is on screen; capIn cannot play on hover either."
  fix: "Show the key cap on every button with a key and glow it while the key is down."

- id: MOTION-8
  rule: "A control is busy or unavailable"
  severity: 2
  region: "Confirm buttons, Connect, floating create button, mutation activity button"
  evidence: "loading_button.dart:248-340 and :357-375; floating_button.dart:115; mutation_activity_button.dart:67"
  observed: "Busy swaps the icon for a spinning CircularProgressIndicator. The control does not press in, and the label does not type a busy word or ripple."
  fix: "Busy presses the control in, types the busy word (Removing, Connecting), and ripples its letters with ripple."

- id: MOTION-9
  rule: "Something fails"
  severity: 2
  region: "LoadingButton and FloatingButton failures; Connect validation"
  evidence: "loading_button.dart:192-194 and :347-349, floating_button.dart:31 and :95 (flutter_animate shakeX, library defaults, linear); forward_animation.dart:11 (500 ms); registration_token_input.dart:28-31 (invalid token returns without failing, so no shake)"
  observed: "Failure plays a default shakeX over 500 ms with no red flash, and an invalid token does not shake Connect at all. Severity 2: only the motion part; message placement is in the page reports."
  fix: "Play jam (400 ms judder, 4 cycles from 9 px, red flash fading over 1.5 s) on the control for every failure, validation included."

- id: MOTION-10
  rule: "Any action or state change"
  severity: 2
  region: "Confirmation dialogs (remove member, delete resource)"
  evidence: "popups.dart:248-277: showDialog with animationStyle passed through as null from every caller; no transitionBuilder"
  observed: "Dialogs use the framework route transition. No dialogIn overshoot, the page behind does not scale to 0.98, and the exit is not dialogOut."
  fix: "Give the one dialog component a route that plays dialogIn and dialogOut and scales the page behind."

- id: MOTION-11
  rule: "The user causes something to arrive"
  severity: 2
  region: "Popovers and menus: role picker, breadcrumbs, context menus"
  evidence: "anchored_popup.dart:243-249 (60 ms linear opacity, no exit); multiselect_dropdown_view.dart:21 (MenuAnchor, nothing configured)"
  observed: "Popovers fade in place in 60 ms and vanish on close. They do not come from the control or land with a token."
  fix: "Grow popovers from their anchor with panelIn and close towards it with panelOut; move the role picker onto AnchoredPopup."

- id: MOTION-12
  rule: "A task needs more room than its place has"
  severity: 2
  region: "Compact rail sheet, mobile inspector"
  evidence: "custom_appbar.dart:99 (showModalBottomSheet defaults); inspector.dart:71-83 and :122-127 (750 ms ElasticOutCurve(0.8) in, 400 ms fastEaseInToSlowEaseOut out)"
  observed: "Sheets rise with framework defaults or a long elastic, not from the opener with surfaceIn."
  fix: "Grow sheets from their opener with surfaceIn and shrink them back with panelOut."

- id: MOTION-13
  rule: "Something exists before and after a change"
  severity: 2
  region: "Inspector beside the services graph"
  evidence: "inspector.dart:332-359 (padding and width, 1000 ms ElasticOutCurve(0.9) open, 750 ms close); :248-255 (750 ms separator)"
  observed: "Selecting a node slides a separate inspector in from the right over a second. The selected card is not carried into it, and closing takes 750 ms."
  fix: "Carry the selected item into the inspector with surfaceIn; close with panelOut."

- id: MOTION-14
  rule: "Anything leaves"
  severity: 2
  region: "Sidebar collapse"
  evidence: "sidebar_shell.dart:33-35 (1000 ms ElasticOutCurve(0.9) in both directions)"
  observed: "Collapsing the sidebar overshoots and bounces, as slow as expanding."
  fix: "Expand on a spring token, collapse with panelOut and no bounce."

- id: MOTION-15
  rule: "Moving between pages with nothing to carry over"
  severity: 2
  region: "Navigation between Members, Services, realm pages"
  evidence: "theme.dart:30-36 (no pageTransitionsTheme); app_router.dart:294 (routes with no route type or transition builder)"
  observed: "Page changes use the framework default transition, the same in both directions."
  fix: "A shared route transition: rows ripple in from the right going deeper, from the left going back."

- id: MOTION-16
  rule: "Loaded content arrives"
  severity: 2
  region: "StaggerEntrance (Members rows); no entrance on Services or the editor"
  evidence: "stagger_entrance.dart:3-7 (300 ms, 60 ms apart, 700 ms launch cap, easeOutCubic, slide 0.05 of own height), :309-345"
  observed: "Rows fade and slide about 2 px over 300 ms on easeOutCubic, and the last row can start up to 700 ms late. loadIn is a 190 ms Strike rising 14 px with the last row starting within 150 ms."
  fix: "Make StaggerEntrance play loadIn: 14 px rise, Strike curve, interval sized so the last visible row starts within 150 ms."

- id: MOTION-17
  rule: "Anything leaves"
  severity: 2
  region: "ElasticTransition and the animated list hooks (Members table and cards)"
  evidence: "elastic_transition.dart:19-42 (height on ElasticOutCurve(0.9), scale 0.9 to 1, reverse on Cubic(.89, -0.01, .51, 1.11)); animated_list.dart:50-51 and :82-83 (insert and remove both 300 ms)"
  observed: "Rows arrive on an elastic grow instead of sliding in from the left with rowIn, and leave on a cubic in the same 300 ms as they arrived, not faster and not on the listOut spring."
  fix: "Insert with rowIn from the left; remove with listOut (height, vertical scale, and opacity together), shorter than the arrival."

- id: MOTION-18
  rule: "You cannot name what a move tells the user"
  severity: 2
  region: "Default loading state (Services page, every AsyncValue call); editor document load"
  evidence: "riverpod.dart:31 uses LoadingIndicator; loading_indicator.dart:26-38 (looping CircularProgressIndicator, 1 s slideY easeInOutCubic, linear fadeIn); resource_route.dart:251 (bare CircularProgressIndicator)"
  observed: "Waits loop a spinner. Only rippling busy words and skeletons may loop."
  fix: "Replace the default loading state with a skeleton of the real layout, or a rippling status word when no layout is known."

- id: MOTION-19
  rule: "Anything grows or responds over time: a hold, a fill, progress, a press"
  severity: 2
  region: "Implicit animations left on their linear default"
  evidence: "animated_table.dart:126, :137-139; anchored_popup.dart:243-247; resource_item_chrome.dart:81-82; collection_editor.dart:481-483; realm_suspension.dart:71; diagnostic_chrome.dart:127-131; header.dart:197-200; member_list.dart:94-95; error_screen.dart:74-115 and loading_indicator.dart:38 (flutter_animate fadeIn, linear default); collection_rows.dart:401-405 (elevation on easeInOut); services/sdk/typewriter-api/.../PresentationPaint.kt:88-91 (transition defaults to LINEAR)"
  observed: "Many moves run linearly. Only drain may be linear."
  fix: "Pass a token to every implicit animation; make a token required so linear cannot be the default."

- id: MOTION-20
  rule: "Any action or state change"
  severity: 2
  region: "Portable presentations: rail rows, book cards, graph nodes, search results"
  evidence: "presentation_value_environment.dart:119-139 renders the wire's milliseconds and curve as given; services/sdk/typewriter-api/src/main/kotlin/com/typewritermc/presentation/SurfaceLayouts.kt:11-14 (300 ms emphasized, 750 ms ElasticOut(0.9) when selected), :39 (120 ms linear focus ring); library/CoreLibrarySdkProviders.kt:125 (100 ms linear); elements/ElementGraphLayouts.kt:56 (400 ms linear); presentation/SearchResultLayouts.kt:67 (300 ms linear)"
  observed: "Each service picks its own milliseconds and curve and ships them in the presentation contract. The panel cannot apply tokens or reduced motion to them."
  fix: "Cause, not patch: change the transition in skir-src/editor/v1/presentation.skir to a motion token name (hoverIn, focusMove, press, and so on), resolve it in the panel, and update the SDK helpers to name tokens."

- id: MOTION-21
  rule: "Something happens that the user did not just do"
  severity: 2
  region: "Live updates on all three pages"
  evidence: "rg finds no wave or waveSlow in panel/lib; member_table.dart:28, :98 and member_tablet_list.dart:25, :111 (rows added or removed by others bounce through ElasticTransition); services_graph.dart:274-276 (availability opacity switches) and :318-345 (status text switches); services_graph.dart:39-45 (repack places nodes without motion); authored_resource_inspection.dart:97-101 (conflict notice inserted with no move)"
  observed: "Changes by others either swap instantly or play the same bouncy move as the user's own actions, and no chip names who did it. Severity 2 covers the motion only; the layout part is under Cannot verify."
  fix: "Changes by others: changed text runs waveSlow, other values fade with ink at 2 s, rows change without travel, and a chip springs in naming who."

- id: MOTION-22
  rule: "The connection or a service is lost"
  severity: 2
  region: "Realm suspension veil over the editor"
  evidence: "realm_suspension.dart:36-45 with elastic_switcher.dart:22-40 (scale from 0 on ElasticOutCurve(0.7) over 800 ms, size on 1000 ms elastic); realm_suspension.dart:155 (indeterminate LinearProgressIndicator)"
  observed: "A lost connection strikes in at the centre, scaling up from nothing on an elastic, with a looping progress bar."
  fix: "Show the notice with no travel (fade with ink), and a rippling status word instead of the progress bar."

- id: MOTION-23
  rule: "Something is temporary: an undo, a notice"
  severity: 2
  region: "Snackbars"
  evidence: "snackbar.dart:10-19 (SnackBar with showCloseIcon, framework enter and exit)"
  observed: "Notices show no time left; their background does not drain."
  fix: "Drain the snackbar background with drain over its lifetime."

### Members

- id: MOTION-24
  rule: "Loaded content arrives"
  severity: 2
  region: "Member table rows"
  evidence: "member_table.dart:64, :128, :205, :232, :277, :303 (a StaggerEntrance per TableCell)"
  observed: "Each cell registers separately, so a row enters cell by cell from left to right instead of as one row."
  fix: "One entrance per row."

- id: MOTION-25
  rule: "Anything changes state"
  severity: 2
  region: "Row selection"
  evidence: "member_table.dart:193-200 (TableRow decoration, not animated); selectable_avatar.dart:25-34 (image replaced by a check)"
  observed: "Selecting swaps the row fill and the avatar at once; nothing moves to perform the change."
  fix: "Animate the fill and the avatar's switch to the check, with the value switching as the move passes."

- id: MOTION-26
  rule: "Anything leaves"
  severity: 2
  region: "Selection bar above the table"
  evidence: "member_list.dart:90-95 (AnimatedSize 800 ms ElasticOutCurve(0.9) both ways; AnimatedSwitcher 400 ms, linear)"
  observed: "The bar bounces when it closes and fades linearly."
  fix: "Arrive from the selection with a token; leave with panelOut and no bounce."

- id: MOTION-27
  rule: "Anything changes state"
  severity: 2
  region: "Roles cell"
  evidence: "member_table.dart:286; role_multiselect_dropdown.dart:40-56 (SmallChip per role in place, no transition)"
  observed: "Adding or removing a role makes chips appear and vanish instantly."
  fix: "A new chip springs in at the field; a removed chip squashes shut and its neighbours close the gap (listOut)."

- id: MOTION-28
  rule: "Anything leaves"
  severity: 2
  region: "Remove member icon and the removed row"
  evidence: "member_row_actions.dart:21-23 (returns SizedBox.shrink once confirmed); member_table.dart:28-37, :98"
  observed: "The remove control disappears at once when confirmation starts; the row later leaves on ElasticTransition in reverse. No hold fill plays."
  fix: "Keep the control while it works; after the hold, the row leaves with listOut."

- id: MOTION-29
  rule: "A task needs more room than its place has"
  severity: 2
  region: "Compact member card expansion"
  evidence: "member_card.dart:47-53 (500 ms ElasticOutCurve(0.9), reverse 20 ms easeInCubic), :168; elastic_message_transition.dart:19-33"
  observed: "The card grows on a literal elastic and snaps shut in 20 ms."
  fix: "Grow with surfaceIn, shrink back with panelOut."

### Services

- id: MOTION-30
  rule: "Loaded content arrives"
  severity: 2
  region: "Services graph"
  evidence: "route.dart:41-48; services_graph.dart:39-45 (Graph built with no entrance scope)"
  observed: "After the spinner, every node appears at once."
  fix: "Ripple the visible nodes in with loadIn, once."

- id: MOTION-31
  rule: "The user causes something to arrive"
  severity: 2
  region: "Graph after Connect succeeds"
  evidence: "registration_token_input.dart:39-42; services_graph.dart:39-45"
  observed: "The new service appears in the repacked graph without motion, and the other nodes jump to new places."
  fix: "The new node comes from the Connect control and lands with its token; the others keep their places."

- id: MOTION-32
  rule: "Something exists before and after a change"
  severity: 2
  region: "Double tap on a realm node"
  evidence: "services_graph.dart:244-248 (context.router.navigate)"
  observed: "Opening a realm replaces the page; the node does not become the realm page heading."
  fix: "Carry the node into the realm heading; the rest ripples in, and Back reverses."

### Resource editor

- id: MOTION-33
  rule: "Loaded content arrives"
  severity: 2
  region: "Rail and body"
  evidence: "shared/editors/presentation/portable_renderer/resources.dart:513-530, :642 (plain Column of rows)"
  observed: "Rail rows and body content appear at once."
  fix: "Ripple each pane in with loadIn, once per pane."

- id: MOTION-34
  rule: "Something exists before and after a change"
  severity: 2
  region: "Opening a rail row"
  evidence: "resource_route.dart:82 (body keyed by resource), :130-139 (heading rebuilt with the new label)"
  observed: "The heading text and body are replaced at once. Replaces the motion part of RESOURCE-22."
  fix: "The opened row moves into the heading, the body ripples in, and Back reverses."

- id: MOTION-35
  rule: "Anything changes state"
  severity: 2
  region: "Chapter groups in the rail"
  evidence: "resources.dart:591-620 (children built only when open), :688-691 (icon swap)"
  observed: "Expanding or collapsing a chapter swaps the icon and inserts or drops its pages instantly."
  fix: "Grow the group on a spring; collapse with listOut; turn the chevron."

- id: MOTION-36
  rule: "The user causes one new row"
  severity: 2
  region: "Create: N, floating button, heading button, Add entry"
  evidence: "resource_creation_action.dart:26 (createAndReveal); resource_route.dart:141-152, :346; collection_rows.dart:393 (ReorderableListView, no insert animation)"
  observed: "The new rail row and new collection entry appear instantly, and the route swaps to the new resource."
  fix: "Slide the new row in from the left with rowIn, then carry it into the heading."

- id: MOTION-37
  rule: "An action can be undone"
  severity: 2
  region: "Delete resource, Remove item"
  evidence: "delete_operation.dart:48 (dialog); collection_rows.dart:637 (runGeneratedRemove)"
  observed: "Removed rows disappear instantly; no strike, no drain, no listOut. Severity 2 covers the motion; the missing undo itself is in the page report."
  fix: "Strike the row in place with Undo, drain its background, then collapse it with listOut."

- id: MOTION-38
  rule: "Anything changes state"
  severity: 2
  region: "Issue badge in the heading"
  evidence: "resource_issue_badge.dart:19-45"
  observed: "The badge pops in and out and swaps icon and count at once; Checking issues shows a still hourglass."
  fix: "Ripple the Checking word while it runs; type only the changed letters of the count."

## Cannot verify

- "Something happens that the user did not just do", layout part (Sev 3): the services graph repacks on every topology change and appears to move nodes, and the conflict notice pushes the editor down. A probe test that adds a host to the topology fake and compares node offsets before and after would settle it.
- "Any move runs": whether input works and moves retarget mid move. Source shows implicit animations (which retarget) and one shot controllers (`LoadingIndicator`, `ElasticTransition` removals behind `IgnorePointer`, `member_tablet_list.dart:105-110`). A test pumping input mid animation would settle it.
- "Choosing how strong a move is": feel, for a maintainer, once tokens exist.

## Rule results

<details>
<summary>Motion rules and walk rows</summary>

| When | Result |
|---|---|
| The user causes something to arrive | fail (MOTION-11, MOTION-31, MOTION-36) |
| Something exists before and after a change | fail (MOTION-13, MOTION-32, MOTION-34) |
| Moving between pages with nothing to carry over | fail (MOTION-15) |
| Showing any state on something | fail (MOTION-8, spinner added) |
| Anything changes state | fail (MOTION-25, MOTION-27, MOTION-35, MOTION-38) |
| Anything grows or responds over time | fail (MOTION-6, MOTION-19) |
| Text appears | fail (no text types; MOTION-8, MOTION-38) |
| A key is in use | fail (MOTION-7) |
| A control is busy or unavailable | fail (MOTION-8) |
| Anything leaves | fail (MOTION-14, MOTION-17, MOTION-26, MOTION-28) |
| Something is temporary | fail (MOTION-23) |
| Choosing how strong a move is | cannot_verify |
| The pointer reaches something you can act on | fail (MOTION-3) |
| A button has a key | fail (MOTION-7) |
| Focus moves | fail (MOTION-4) |
| A pane gains focus | fail (MOTION-5) |
| A move repeats fast or would go off screen | fail (no held key path; focus pulse replays per focus, selector.dart:166-170) |
| Several moves would play together | fail (MOTION-21) |
| You cannot name what a move tells the user | fail (MOTION-18, MOTION-22) |
| Any move runs | cannot_verify |
| Reduced motion is on | fail (MOTION-2) |
| Loaded content arrives | fail (MOTION-16, MOTION-24, MOTION-30, MOTION-33) |
| The user causes one new row | fail (MOTION-36) |
| Something happens that the user did not just do | fail (MOTION-21) |
| Any action or state change (walk) | fail (MOTION-1, MOTION-10, MOTION-20) |

</details>

## Skill friction

- The Motion evidence row and the walk row both say "the moments table", but `panel-design` has no moments table. The only table named Moment is about wording. I mapped each action to the Motion rule whose When matches, and to the rules elsewhere that name a token (`loadIn`, `rowIn`, `hold`, `drain`, `listOut`, `ripple`, `waveSlow`, `jam`).
- With no tokens in the code, every move fails "a literal duration or curve". The skill does not say whether to report that once or on every move; I reported it once (MOTION-1) and kept the page findings for wrong or missing moves.
- No token is named for popovers, sheets, the inspector, sidebar collapse, a page change, or an expanding group. I chose `panelIn`, `panelOut`, and `surfaceIn` by analogy; a row in the moments table for each would remove the guess.
- Severity: the walk row says 2, but some matching rules carry 3 ("Something happens that the user did not just do", "Reduced motion is on"). I used 3 only where the motion itself breaks the rule.
- Motion for portable presentations is authored in `services/`, outside the panel. The review skill does not say whether a review should follow it there.
- The output format puts a shared fault in `cross-page.md`; this brief asked for one combined file. A motion pass on its own may need its own place in the skill.

## Suggestions

- Moments table: add one to `panel-design` with one row per moment (open page, rows load, hover, press, focus move, pane focus, select, busy, fail, remove, create, open a row, popover, sheet, dialog, page change, change by others, refresh) and its token, so both skills point at something real.
- New rule: When a contract carries a move, Then it names a motion token, never a duration or curve. Sev 2.
