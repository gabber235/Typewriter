import "package:typewriter_panel/typewriter_panel.dart";

/// Keyboard mode that emits one grid step of movement for the active nodes.
///
/// The graph handles [GraphMoveIntent] and sends the resulting absolute
/// positions to its move callback. This mode changes interaction interpretation,
/// not the graph snapshot or selection owner.
class GraphMoveMode extends InteractionMode
    with ModeDisplay, ModeShortcut, DirectionalInteractionMode {
  const GraphMoveMode();

  @override
  String get name => "Graph Move";

  @override
  ModeLook look(BuildContext context) => ModeLook.move(context);

  @override
  List<ActionShortcut> getShortcuts() {
    return [
      for (final MapEntry(key: keys, value: direction)
          in movementShortcuts.entries)
        for (final key in keys)
          ActionShortcut(
            id: "graph_move_${key.debugName?.snakeCase}",
            label: "Move Node ${direction.name.titleCase()}",
            description: "Move selected node ${direction.name.toLowerCase()}",
            activators: [SingleActivator(key)],
            priority: 20,
            show: false,
            run: ActionRun.press(
              (ref) => invokeCurrentModeDirection(ref, direction),
            ),
          ),
      ActionShortcut(
        id: "graph_move",
        label: "Move",
        description: "Move the selected nodes",
        activators: [
          SortedLogicalKeyActivator.fromList([
            LogicalKeyboardKey.arrowLeft,
            LogicalKeyboardKey.arrowDown,
            LogicalKeyboardKey.arrowUp,
            LogicalKeyboardKey.arrowRight,
          ]),
          SortedLogicalKeyActivator.fromList([
            LogicalKeyboardKey.keyH,
            LogicalKeyboardKey.keyJ,
            LogicalKeyboardKey.keyK,
            LogicalKeyboardKey.keyL,
          ]),
        ],
        priority: 20,
      ),
      escapeToNormalAction(),
    ];
  }

  @override
  Intent intentForDirection(TraversalDirection direction) =>
      GraphMoveIntent(direction: direction);
}

/// Keyboard mode that emits one grid step of resizing for the active nodes.
///
/// The graph handles [GraphResizeIntent] and clamps dimensions to one cell
/// before sending them to its resize callback. This mode changes interaction
/// interpretation, not the graph snapshot or selection owner.
class GraphResizeMode extends InteractionMode
    with ModeDisplay, ModeShortcut, DirectionalInteractionMode {
  @override
  String get name => "Graph Resize";

  @override
  ModeLook look(BuildContext context) => ModeLook.resize(context);

  @override
  List<ActionShortcut> getShortcuts() {
    return [
      for (final MapEntry(key: keys, value: direction)
          in movementShortcuts.entries)
        for (final key in keys)
          ActionShortcut(
            id: "graph_resize_${key.debugName?.snakeCase}",
            label: "Resize Node ${direction.name.titleCase()}",
            description: "Resize selected node ${direction.name.toLowerCase()}",
            activators: [SingleActivator(key)],
            priority: 0,
            show: false,
            run: ActionRun.press(
              (ref) => invokeCurrentModeDirection(ref, direction),
            ),
          ),
      ActionShortcut(
        id: "graph_resize",
        label: "Resize",
        description: "Resize the selected nodes",
        activators: [
          SortedLogicalKeyActivator.fromList([
            LogicalKeyboardKey.arrowLeft,
            LogicalKeyboardKey.arrowDown,
            LogicalKeyboardKey.arrowUp,
            LogicalKeyboardKey.arrowRight,
          ]),
          SortedLogicalKeyActivator.fromList([
            LogicalKeyboardKey.keyH,
            LogicalKeyboardKey.keyJ,
            LogicalKeyboardKey.keyK,
            LogicalKeyboardKey.keyL,
          ]),
        ],
        priority: -1,
      ),
      escapeToNormalAction(),
    ];
  }

  @override
  Intent intentForDirection(TraversalDirection direction) =>
      GraphResizeIntent(direction: direction);
}
