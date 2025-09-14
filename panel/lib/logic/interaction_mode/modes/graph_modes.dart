import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:typewriter_panel/logic/interaction_mode/interaction_mode.dart";
import "package:typewriter_panel/logic/interaction_mode/mode_display.dart";
import "package:typewriter_panel/logic/interaction_mode/mode_shortcut.dart";
import "package:typewriter_panel/logic/interaction_mode/modes/normal_mode.dart";
import "package:typewriter_panel/utils/shortuct.dart";
import "package:typewriter_panel/utils/string.dart";
import "package:typewriter_panel/widgets/app/components/graph/graph.dart";
import "package:typewriter_panel/widgets/app/components/interaction_mode/mode_display_chip.dart";
import "package:typewriter_panel/widgets/app/components/action_shortcuts.dart";

/// Graph manipulation mode for moving nodes.
///
/// This mode provides keyboard shortcuts for moving selected graph nodes
/// using hjkl and arrow keys.
class GraphMoveMode extends InteractionMode with ModeDisplay, ModeShortcut {
  const GraphMoveMode();

  @override
  String get name => "Graph Move";

  @override
  Widget buildDisplay(BuildContext context) {
    return const ModeDisplayChip(
      label: "Move",
      color: Colors.deepPurple,
    );
  }

  @override
  List<ActionShortcut> getShortcuts() {
    final movementShortcuts = {
      [LogicalKeyboardKey.arrowUp, LogicalKeyboardKey.keyK]:
          TraversalDirection.up,
      [LogicalKeyboardKey.arrowDown, LogicalKeyboardKey.keyJ]:
          TraversalDirection.down,
      [LogicalKeyboardKey.arrowLeft, LogicalKeyboardKey.keyH]:
          TraversalDirection.left,
      [LogicalKeyboardKey.arrowRight, LogicalKeyboardKey.keyL]:
          TraversalDirection.right,
    };

    return [
      for (final MapEntry(key: keys, value: direction)
          in movementShortcuts.entries)
        for (final key in keys)
          ActionShortcut(
            id: "graph_move_${key.debugName?.snakeCase}",
            label: "Move Node ${direction.name.titleCase()}",
            description: "Move selected node ${direction.name.toLowerCase()}",
            activators: [
              SingleActivator(key),
            ],
            priority: 0,
            show: false,
            onInvoke: (ref) => _invokeGraphMoveIntent(direction),
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
        priority: -1,
      ),
      escapeToNormalAction(),
    ];
  }

  /// Invokes a GraphMoveIntent to move the currently selected graph node.
  ///
  /// This method uses the Flutter Actions system to dispatch a GraphMoveIntent
  /// that can be handled by the graph widget or its parent components.
  ///
  /// Parameters:
  /// - [deltaX]: The horizontal movement amount in pixels
  /// - [deltaY]: The vertical movement amount in pixels
  void _invokeGraphMoveIntent(TraversalDirection direction) {
    final currentFocus = FocusManager.instance.primaryFocus;
    if (currentFocus?.context != null) {
      Actions.invoke(
        currentFocus!.context!,
        GraphMoveIntent(direction: direction),
      );
    }
  }
}

/// Graph manipulation mode for resizing nodes.
///
/// This mode provides keyboard shortcuts for resizing selected graph nodes
/// using hjkl and arrow keys.
class GraphResizeMode extends InteractionMode with ModeDisplay, ModeShortcut {
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
    final movementShortcuts = {
      [LogicalKeyboardKey.arrowUp, LogicalKeyboardKey.keyK]:
          TraversalDirection.up,
      [LogicalKeyboardKey.arrowDown, LogicalKeyboardKey.keyJ]:
          TraversalDirection.down,
      [LogicalKeyboardKey.arrowLeft, LogicalKeyboardKey.keyH]:
          TraversalDirection.left,
      [LogicalKeyboardKey.arrowRight, LogicalKeyboardKey.keyL]:
          TraversalDirection.right,
    };

    return [
      for (final MapEntry(key: keys, value: direction)
          in movementShortcuts.entries)
        for (final key in keys)
          ActionShortcut(
            id: "graph_resize_${key.debugName?.snakeCase}",
            label: "Resize Node ${direction.name.titleCase()}",
            description: "Resize selected node ${direction.name.toLowerCase()}",
            activators: [
              SingleActivator(key),
            ],
            priority: 0,
            show: false,
            onInvoke: (ref) => _invokeGraphResizeIntent(direction),
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

  /// Invokes a GraphResizeIntent to resize the currently selected graph node.
  ///
  /// This method uses the Flutter Actions system to dispatch a GraphResizeIntent
  /// that can be handled by the graph widget or its parent components.
  ///
  /// Parameters:
  /// - [deltaX]: The horizontal movement amount in pixels
  /// - [deltaY]: The vertical movement amount in pixels
  void _invokeGraphResizeIntent(TraversalDirection direction) {
    final currentFocus = FocusManager.instance.primaryFocus;
    if (currentFocus?.context != null) {
      Actions.invoke(
        currentFocus!.context!,
        GraphResizeIntent(direction: direction),
      );
    }
  }
}
