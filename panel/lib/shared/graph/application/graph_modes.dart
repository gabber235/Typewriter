import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:typewriter_panel/app/presentation/shortcuts/shortcuts.dart";
import "package:typewriter_panel/shared/graph/presentation/graph_intents.dart";
import "package:typewriter_panel/shared/interaction_mode/application/directional_interaction_mode.dart";
import "package:typewriter_panel/shared/interaction_mode/application/interaction_mode.dart";
import "package:typewriter_panel/shared/interaction_mode/application/mode_display.dart";
import "package:typewriter_panel/shared/interaction_mode/application/mode_shortcut.dart";
import "package:typewriter_panel/shared/interaction_mode/application/modes/normal_mode.dart";
import "package:typewriter_panel/shared/interaction_mode/presentation/mode_display_chip.dart";
import "package:typewriter_panel/shared/utilities/shortcut.dart";
import "package:typewriter_panel/shared/utilities/string.dart";

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
