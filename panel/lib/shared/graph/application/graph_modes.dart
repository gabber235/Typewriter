import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:typewriter_panel/typewriter_panel.dart";

/// Graph manipulation mode for moving nodes.
///
/// This mode provides keyboard shortcuts for moving selected graph nodes
/// using hjkl and arrow keys.
class GraphMoveMode extends InteractionMode
    with ModeDisplay, ModeShortcut, DirectionalInteractionMode {
  const GraphMoveMode();

  @override
  String get name => "Graph Move";

  @override
  Widget buildDisplay(BuildContext context) {
    return const ModeDisplayChip(label: "Move", color: Colors.deepPurple);
  }

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
            onInvoke: (ref) => invokeCurrentModeDirection(ref, direction),
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

/// Graph manipulation mode for resizing nodes.
///
/// This mode provides keyboard shortcuts for resizing selected graph nodes
/// using hjkl and arrow keys.
class GraphResizeMode extends InteractionMode
    with ModeDisplay, ModeShortcut, DirectionalInteractionMode {
  @override
  String get name => "Graph Resize";

  @override
  Widget buildDisplay(BuildContext context) {
    return const ModeDisplayChip(
      label: "Resize",
      color: Colors.deepOrangeAccent,
    );
  }

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
            onInvoke: (ref) => invokeCurrentModeDirection(ref, direction),
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
