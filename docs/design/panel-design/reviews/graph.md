# Graph review

Shared surface `panel/lib/shared/graph/`, shown inside canvas pages (the Tags view of the resource
editor, page canvases, Services). Story `shared/graph/presentation/graph/default` (`initial`, `dark`,
six `Content=` images) and `shared/graph/presentation/resizableelement/default`. Canvas evidence also
comes from `features/realms/presentation/resourcesurface/routed-resource/Routed-resource=Tags.png`
and `authoring/presentation/resourcedroptarget/drag-entries-onto-a-page/initial.png`.

Key paths, focus, and motion values come from throwaway probe tests (a `pumpGraph` probe in
`panel/test` and a `pumpStory` probe over the drop target story), run through `cargo xtask heavy`,
then deleted. Paths below are under `panel/lib/shared/graph/` unless stated.

## Summary

Not yet good. The graph draws clearly and its keyboard model is sound (focus inside a selection moves
the selection, Move and Resize show their mode, Esc returns to Normal), but the canvas's own everyday
actions have no motion: a moved or resized node jumps to its new cell on the first frame, and the
resize handle is the only thing that animates, on a private elastic, and only for a mouse.

The single most valuable change: move nodes to their new place with a token (GRAPH-1). Moving and
resizing is what a canvas is for, and every snap, key step, drop, and cancel shares the one code path
in `RenderGraphSurface.performLayout`.

## Action walk

| Action or state | Expected move | Code | What runs |
|---|---|---|---|
| Graph appears | `loadIn` once | `presentation/graph.dart:117-546` | No entrance; every node at once. MOTION-30 |
| Hover a node | `hoverIn`, `hoverOut` | Node body belongs to the consumer | MOTION-3 |
| Hover the resize corner | `hoverIn`; `hoverOut` 90 ms | `presentation/resizable_element.dart:50-60`, `:83-93` | Arc grows on `ElasticOutCurve(0.4)` 700 ms (probe: 1.23 at 100 ms), leaves on `fastLinearToSlowEaseIn` 250 ms (probe: still 0.997 after 90 ms). GRAPH-2 |
| Focus a node | `focusMove`; viewport follows | `presentation/graph.dart:260-273`; `application/graph_viewport_controller.dart:17`, `:33` | Ring is the consumer's (MOTION-4). Viewport pans 250 ms `easeOutCubic` (MOTION-1) |
| Enter Move or Resize mode | Chip letters type the change | `shared/interaction_mode/presentation/mode_display.dart:13-19` | Chip swapped whole. SHARED-GRAPH-3 |
| Move by key, drag, drop, or cancelled drag | Node travels to its new cell | `presentation/graph_surface.dart:154-173` | Offset set in layout; node jumps (probe: 100 of 100 px on the first frame). GRAPH-1 |
| Resize by key or handle | Size grows on a spring | `presentation/graph_surface.dart:160-167` | Size jumps cell by cell. GRAPH-1 |
| Edges follow a node | With the node | `presentation/graph_surface.dart:223-239` | Repaint at the new place. GRAPH-1 |
| Zoom in, out, reset by key | Token, reduced motion in the tokens | `application/graph_viewport_controller.dart:17`, `:28-56` | 250 ms `easeOutCubic` (MOTION-1). With reduced motion the framework shortens it to about 5% (probe: final scale on the first 16 ms frame), so the motion.md row "no reduced motion" for the viewport does not hold |
| Pinch, wheel, pan | Direct | `InteractiveViewer.builder`, `presentation/graph.dart:328-334` | Direct manipulation. Not a finding |
| Another user moves a node | `waveSlow`, still layout | Same as GRAPH-1 | Node jumps. MOTION-21 |

## Findings

- id: GRAPH-1
  rule: "Something exists before and after a change"
  severity: 3
  region: "Every node on the canvas, when moved or resized by key, drag snap, drop, or a cancelled drag; its edges"
  evidence: "presentation/graph_surface.dart:154-173 sets each child's offset and size straight from the layout; probe pumpGraphData moved a node two cells and it was 100 of 100 px along on the first frame; drop target story probe: Shift+M, Right moved the node in the first frame"
  observed: "Nodes and their edges jump to the new cell. A drag preview snaps cell by cell, and a cancelled drag snaps the node back to its origin, all without motion. Raised from 2 to 3: moving and resizing nodes is the canvas's everyday action, so the walk's rule for everyday moves applies."
  fix: "Animate placement inside RenderGraphSurface from the old to the new bounds with a named token (none fits today; see Suggestions), retargeting mid move, with reduced motion in the token."

- id: GRAPH-2
  rule: "The pointer reaches something you can act on"
  severity: 3
  region: "Resize corner of every resizable node"
  evidence: "presentation/resizable_element.dart:50-60 (700 ms ElasticOutCurve(0.4), 250 ms fastLinearToSlowEaseIn reverse); probe: progress 1.23 at 100 ms after hover, 0.997 at 90 ms after leaving"
  observed: "The corner arc springs in on a private 700 ms elastic and leaves on a slow starting 250 ms curve, so it is still fully drawn when hoverOut would have ended. Severity 3: hover is an everyday move."
  fix: "Drive the arc with hoverIn and hoverOut."

- id: GRAPH-3
  rule: "Something works with one input"
  severity: 3
  region: "Resize corner of every resizable node"
  evidence: "presentation/resizable_element.dart:83-93 (MouseRegion is the only trigger), :141-143 (transparent 25 px box); resizable_element_surface.dart:105-108 (handle centred on the corner); probe: progress 0.0 with the node focused"
  observed: "The handle shows only under a mouse pointer. Keyboard focus never reveals it, and on touch it is an invisible box centred on the node's corner, where only the inner quarter takes a touch because the node's own bounds clip hit testing."
  fix: "Show the corner when the node is focused or selected, and on touch make the whole visible corner the target."

- id: GRAPH-4
  rule: "Something works with one input"
  severity: 3
  region: "Moving and resizing nodes"
  evidence: "presentation/graph.dart:382-537 (move only through the DragTarget or GraphMoveIntent), resizable_element.dart:108-137 (resize only by pan); drop target story probe: a tap selects the node and moves nothing"
  observed: "Move and resize work by drag or by a keyboard mode. There is no single click path, such as pick up with a click and place with a second click."
  fix: "Add a click path: a selected node's Move action (also in its context menu) lets the next click on the canvas place it; the same for the resize corner."

- id: GRAPH-5
  rule: "Any action"
  severity: 2
  region: "Zoom out key (minus)"
  evidence: "application/graph_viewport_controller.dart:61 (getMaxScaleOnAxis), :12 (minScale 0.6); presentation/graph.dart:53 (kGraphMinScale 0.1), :132-136; probe: 40 presses of minus reach scale 0.022, 40 presses of equal stop at 2.5"
  observed: "Zooming out by key has no floor. The scale check reads the unscaled z axis, which is always 1, so the clamp never applies below 1. Pinch stops at 0.1 and the controller declares 0.6, so the two inputs have different limits. Kept at 2: 0 resets the zoom."
  fix: "Read the scale from the x axis, and give the controller the graph's one minimum."

- id: GRAPH-6
  rule: "One thing shows in several places"
  severity: 2
  region: "Mode chip in the top bar while in Move or Resize mode"
  evidence: "application/graph_modes.dart:17 (Colors.deepPurple), :76-79 (Colors.deepOrangeAccent); shared/editors/presentation/timeline/application/timeline_modes.dart:16 (context.colors.accent), :80 (context.colors.warning)"
  observed: "The same Move and Resize modes are purple and orange on a graph and accent and warning colour on a timeline. Both are raw colours on the graph."
  fix: "One Move mode and one Resize mode chip style from theme tokens, shared by graph and timeline, using neither a status colour nor a raw colour."

- id: GRAPH-7
  rule: "Writing text"
  severity: 3
  region: "MOVE and RESIZE chip label"
  evidence: "application/graph_modes.dart:17, :76-79; shared/interaction_mode/presentation/mode_display_chip.dart:36 (20% tint on light, 10% on dark), :42; canvas colour sampled from story images: #F9F9FF light, #111318 dark"
  observed: "RESIZE is #FF6E40 on its own tint: 2.15:1 on light. MOVE is #673AB7 on its tint: 2.39:1 on dark. Both under 4.5:1."
  fix: "Covered by the GRAPH-6 fix, with label colours checked at 4.5:1 in both themes."

- id: GRAPH-8
  rule: "Setting any visual value"
  severity: 2
  region: "Dot grid, edges, arrow heads, resize corner, zoom step"
  evidence: "presentation/graph.dart:318, :323 (zoom factor 1.1), :462-465 (Colors.grey at 0.5 for dots); graph_surface.dart:211, :219, :225, :250-258 (dot count, radius, stroke, arrow sizes); resizable_element.dart:17 (handle 25); resizable_element_surface.dart:136, :140, :146 (stroke 3, padding, radius 10)"
  observed: "Visual values are literals and the dot colour is a raw grey. Durations and curves are under MOTION-1."
  fix: "Take colours, strokes, and sizes from theme tokens; add canvas tokens beside typewriter_spacing.dart where none exist."

- id: GRAPH-9
  rule: "Naming an action"
  severity: 2
  region: "Hint bar and key help while a node is focused"
  evidence: "presentation/graph_shortcuts.dart:22-23, :34-35, :45, :70, :94; application/graph_modes.dart:13, :28, :72, :90"
  observed: "`Move Mode`, `Resize Mode`, `Go to Move Mode`, `Zoom In`, `Zoom Out`, `Reset Zoom`, `Move Node Left`, `Graph Move` are Title Case."
  fix: "Sentence case: Move mode, Zoom in, Reset zoom, Move node left."

- id: GRAPH-10
  rule: "Adding an action"
  severity: 2
  region: "Move mode, Resize mode, Zoom in, Zoom out, Reset zoom"
  evidence: "presentation/graph_shortcuts.dart:8-109 (activator ActionShortcuts with local key lists); shared/editors/presentation/timeline/presentation/timeline_shortcuts.dart:84-150 (the same zoom keys copied); shared/shortcuts/shortcuts.dart (no zoom or mode Intent in typewriterShortcuts)"
  observed: "These keys are in the key language, yet each surface defines them as local activators, and graph and timeline keep two copies of the same key lists. Lowered from 3 to 2: the keys work and the hint bar shows them; the cost is drift between copies. The command list part is SHARED-GRAPH-1."
  fix: "Add ZoomIn, ZoomOut, ResetZoom, MoveMode, and ResizeMode Intents to typewriterShortcuts and use ActionShortcut.intent in both canvases."

- id: GRAPH-11
  rule: "An action means something the key language already covers"
  severity: 2
  region: "Zoom keys"
  evidence: "presentation/graph_shortcuts.dart:47-104"
  observed: "The key language gives Ctrl or Cmd+=, -, 0. The graph also binds bare =, +, -, _, and 0, their Shift and numpad forms, and Cmd or Ctrl character forms, so plain single keys gain a meaning the language does not list."
  fix: "Bind the key language's keys only, or add the bare keys to the key language in the same change."

- id: GRAPH-12
  rule: "Moving around"
  severity: 2
  region: "Canvas pane of a page with a graph"
  evidence: "drop target story probe: 14 Tab presses cycle Village quests, Village evening, a `Presentation error` stop, Village morning, and never reach a node; Ctrl+L lands on the pane scope with nothing spoken"
  observed: "Tab never enters the graph. Its nodes, and with them every graph key (the shortcuts only exist while focus is inside the graph), are reachable only by a pointer or by Ctrl+L and then a further key. RESOURCE-3 covers the create key; this is the graph's own nodes."
  fix: "Make the graph one Tab group whose entry lands on the selected node, else the first node in reading order; arrows move inside it."

- id: GRAPH-13
  rule: "A surface is new or changed"
  severity: 2
  region: "Graph story"
  evidence: "widgetbook/lib/stories/shared/graph/presentation/graph.stories.dart:14-49 (only a Content knob), :94-180 (story nodes have no focus or selection); images Content=Groups.png (no group drawn)"
  observed: "The story's nodes cannot take focus or selection, so no image or interaction shows focus, selection, Move or Resize mode, hover on the corner, dragging, resizing, read only, empty, zoomed, or compact. The Groups option shows plain nodes, no containing group."
  fix: "Build story nodes from the shared Selector, add knobs for mode, selection, read only, empty, and zoom, and make Groups contain nodes."

- id: GRAPH-14
  rule: "Something is empty"
  severity: 2
  region: "A graph with no nodes, such as an empty Tags view"
  evidence: "presentation/graph.dart (no empty branch); shared/editors/presentation/portable_renderer/resources.dart:108-210 (the graph layout renders Graph with no empty check, while :342 and :520 show _EmptyResources for other layouts)"
  observed: "An empty graph is a bare dot grid with nothing saying what belongs there or how to add one."
  fix: "Show the shared empty state (mascot, playful line, subtitle, main action on the right) when a graph has no nodes."

## Shared

- id: SHARED-GRAPH-1
  rule: "Adding an action"
  severity: 3
  region: "Search and commands (Ctrl or Cmd+K) on every page"
  evidence: "shared/search/presentation/search_tree_results.dart:195 (commands come from each search result); drop target story probe: with a node focused, Ctrl+K then `zoom` shows no Zoom in, Reset zoom, or Move mode"
  observed: "The command list holds operations on search results only. Actions registered for the focused scope, such as the graph's zoom and modes, never appear in it."
  fix: "List the focused scope's registered actions in the command list, most specific first."

- id: SHARED-GRAPH-2
  rule: "Choosing any key"
  severity: 3
  region: "Every single key binding, here the graph's bare =, -, 0 and the Move and Resize mode keys"
  evidence: "No off or remap setting anywhere in panel/lib (searched for remap, single key, and shortcut settings; the only switch is selectionShortcutsEnabled in shared/selectables/presentation/global_operation_shortcuts.dart:33, which is not a user setting); zoom probes show bare equal and minus act"
  observed: "Single keys cannot be turned off or remapped, so a user whose assistive tool or habit sends them has no escape."
  fix: "Add the single key setting once in the shortcut layer, applied to every ActionShortcut."

- id: SHARED-GRAPH-3
  rule: "Anything changes state"
  severity: 2
  region: "Mode chip in the top bar"
  evidence: "shared/interaction_mode/presentation/mode_display.dart:13-19"
  observed: "NORMAL, MOVE, RESIZE, and INSERT swap as whole widgets. Shared letters do not stay and the new word does not type."
  fix: "One chip that animates its colour and types only the letters that differ."

## Cannot verify

- "Something fails": the commit callbacks return nothing (`application/graph_commit.dart:28`, `:34`), so the graph cannot know a move failed or jam the node. A story whose move callback fails would settle what the user sees.
- "The window is under 900 px": no compact story of a canvas page with a graph.
- "Only touch is available": no touch story; touch panning and the mode chip on touch are unchecked.
- "A move repeats fast or would go off screen": a held arrow in Move mode restarts the 250 ms viewport pan per step. Whether it should shrink to none needs a live check.
- After Ctrl+L, whether the arrows reach a node: not probed.
- How any move feels once tokens exist: for a maintainer.
- The dark outline on the `Rich nodes` cards and on canvas floating buttons: it appears exactly where a widget has elevation (`graph.stories.dart:634`, Card elevation 2), so it may be the elevation shadow as story images draw it. That may also be the untraced cause of RESOURCE-26. A story without elevation would settle it.

## Rule results

<details>
<summary>Every applicable rule</summary>

| Rule (When) | Result |
|---|---|
| A user's action finishes and they have not moved on | pass: Esc out of Move mode leaves focus on the moved node (probe) |
| The focused thing disappears | pass: the focused node stays mounted when panned out of view (`graph.dart:338-344`) |
| A page or surface opens | fail, as SERVICES-2 and RESOURCE-1 (probe: nothing focused on open) |
| Something happens that the user did not just do | fail, MOTION-21 (node jumps, GRAPH-1 cause) |
| A task concerns something on screen | pass: move and resize happen on the node |
| The window is under 900 px | cannot_verify |
| Anything needs saying | cannot_verify |
| Something succeeds | pass: the moved node is the result |
| Something fails | cannot_verify |
| Something is empty | fail, GRAPH-14 |
| Loaded content arrives | fail, MOTION-30 |
| Something exists before and after a change | fail, GRAPH-1 |
| Showing any state on something | pass: the corner arc adds information not otherwise visible and arrives with motion |
| Anything changes state | fail, SHARED-GRAPH-3 |
| Anything grows or responds over time | fail, GRAPH-1 (resize), GRAPH-2 (elastic, not a spring token) |
| A key is in use | fail, MOTION-7 and SHARED-TYPE-2 |
| Anything leaves | fail, GRAPH-2 (corner arc leaves slowly); GRAPH-1 (cancelled drag snaps back) |
| Choosing how strong a move is | cannot_verify |
| The pointer reaches something you can act on | fail, GRAPH-2 |
| Focus moves | fail, MOTION-4 (ring is the consumer's); viewport follows focus |
| A move repeats fast or would go off screen | cannot_verify |
| You cannot name what a move tells the user | pass: nothing loops |
| Any move runs | pass: viewport moves retarget from the current transform (`graph_viewport_controller.dart:28-33`) |
| Reduced motion is on | pass: viewport and corner arc use AnimationController, which the framework shortens (probe) |
| Adding an action | fail, GRAPH-10, SHARED-GRAPH-1 |
| Something works with one input | fail, GRAPH-3, GRAPH-4 |
| Keys change meaning | pass: Shift+M shows MOVE, Esc shows NORMAL (probe) |
| An action means something the key language already covers | fail, GRAPH-11 |
| Choosing any key | fail, SHARED-GRAPH-2 |
| Placing an action | pass: moves act on the selection or the focused node |
| One key matches at several levels | pass: mode keys take priority 20 over pane keys |
| Both a focused row and a selection exist | pass: `graph.dart:70-84` implements it |
| An action cannot work here | pass: Move and Resize are left out when the callback is null (`graph_shortcuts.dart:19`, `:31`) |
| Moving around | fail, GRAPH-12 |
| Only touch is available | cannot_verify |
| Setting any visual value | fail, GRAPH-8 |
| Showing a state | pass for the graph itself; mode chip colour under GRAPH-6 |
| A static page feels boring | pass: edge colours follow the node kind |
| Adding colour to a page | pass: colour sits on edges and nodes only |
| Styling a static page | pass, with the dot grid under Suggestions |
| Writing text | fail, GRAPH-7 |
| Choosing a font | pass: Lilex on the chip and story nodes |
| Naming an action | fail, GRAPH-9 |
| One thing shows in several places | fail, GRAPH-6 |
| A shared component does the job | fail, GRAPH-10 (zoom and mode keys copied in graph and timeline) |
| A surface is new or changed | fail, GRAPH-13 |
| Keyboard behaviour is new or changed | pass: `test/shared/graph/presentation/graph_modes_test.dart`, `graph_zoom_shortcuts_test.dart`, `graph_move_focus_test.dart` |
| Walk: Any action, keys only | fail, GRAPH-12 (reach); zoom and modes work once a node has focus |
| Walk: A value revealed on hover | fail, GRAPH-3 |
| Walk: A drag | fail, GRAPH-4 |
| Walk: Compact width | cannot_verify |

</details>

## Skill friction

- The inventory names one story for the Graph, but its nodes are story fixtures that cannot take focus, so every key path had to come from a second story (the drop target canvas). The inventory could name a canvas story for key paths.
- The fixture nodes break rules themselves (raw colours, text sized by `FittedBox`, a Card shadow). The skill does not say whether story fixture code is judged; I kept it out of the findings.
- The everyday move rule lists hover, press, focus, opening, loading, rows added or removed. Moving a node on a canvas is everyday there but not listed, so raising GRAPH-1 to 3 was a judgement.
- The token table has no move for repositioning something on a canvas, nor for viewport pan and zoom, so "a different move" cannot be checked for them.
- The panel `focused` driver read null while a node held focus; `FocusManager.primaryFocus` was needed to trace Tab.
- Reduced motion: Flutter's AnimationController already shortens moves when animations are disabled. The skill's "no reduced motion path" check reads as a per widget path, which leads to wrong fails (the motion.md viewport row).

## Suggestions

- **Rule gap.** When something moves to a new place on a canvas (a node, a cue), Then it travels there with a named token, `placeMove`, and edges travel with it. Sev 2, 3 for the canvas's own moves.
- **Rule gap.** When the viewport pans or zooms by key, Then it uses a named token and a held key makes it jump. Sev 2.
- **Tags: which tag points where.** In `Routed-resource=Tags.png` the nodes have no shape, so the grey arrow runs beside the labels through both node areas and reads as loose. Edges anchor to the node bounds while the visible content is a label at the left. Either give nodes a soft filled shape or anchor edges to the visible content.
- **What can be removed.** The dot grid fills the whole Tags pane and is the loudest texture there, though it only matters while moving or resizing. Show it faintly, or only in Move and Resize mode and during a drag.
- **Expert speed.** Moving one node takes Shift+M, arrows, Esc. A direct step (for example Alt with arrows, added to the key language) would make the daily case one chord.
- **First time user.** Nothing says nodes can be moved or resized; the corner appears only under a mouse. Showing the corner on the selected node (GRAPH-3) also teaches it.
- **Keyboard resize repeats.** Unlike move, `resizeSelection` (`application/graph_interaction_controller.dart:169-188`) does not accumulate repeats before the snapshot catches up, so a fast held key can lose steps.
- **Canvas nodes outside the graph.** The page canvas in `drag-entries-onto-a-page/initial.png` paints whole nodes in solid red, a large fill for a status. That belongs to the page presentation's review, not the graph.
