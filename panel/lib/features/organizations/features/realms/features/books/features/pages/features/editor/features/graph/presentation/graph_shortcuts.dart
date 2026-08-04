import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:iconify_flutter_plus/icons/ion.dart";
import "package:iconify_flutter_plus/icons/lucide.dart";
import "package:typewriter_panel/typewriter_panel.dart";

List<ActionShortcut> buildGraphShortcuts({
  required bool canMove,
  required bool canResize,
  required Object currentMode,
  required VoidCallback activateMoveMode,
  required VoidCallback activateResizeMode,
  required VoidCallback zoomIn,
  required VoidCallback zoomOut,
  required VoidCallback resetZoom,
}) {
  return [
    if (canMove && currentMode is! GraphMoveMode)
      ActionShortcut(
        id: "graph_move_mode_activate",
        label: "Move Mode",
        description: "Go to Move Mode",
        activators: [
          const SingleActivator(LogicalKeyboardKey.keyM, shift: true),
        ],
        icon: Icones(Ion.md_move),
        onInvoke: (_) => activateMoveMode(),
        priority: 10,
      ),
    if (canResize && currentMode is! GraphResizeMode)
      ActionShortcut(
        id: "graph_resize_mode_activate",
        label: "Resize Mode",
        description: "Go to Resize Mode",
        activators: [
          const SingleActivator(LogicalKeyboardKey.keyR, shift: true),
        ],
        icon: Icones(Lucide.move_diagonal_2),
        onInvoke: (_) => activateResizeMode(),
        priority: 10,
      ),
    ActionShortcut(
      id: "graph_zoom_in",
      label: "Zoom In",
      description: "Zoom the graph in",
      activators: [
        for (final key in [
          LogicalKeyboardKey.equal,
          LogicalKeyboardKey.add,
          LogicalKeyboardKey.numpadEqual,
          LogicalKeyboardKey.numpadAdd,
        ]) ...[
          SingleActivator(key),
          SingleActivator(key, shift: true),
          AdaptiveSingleActivator(key, control: true),
          AdaptiveSingleActivator(key, control: true, shift: true),
        ],
        for (final character in ["=", "+"]) ...[
          CharacterActivator(character),
          CharacterActivator(character, meta: true),
          CharacterActivator(character, control: true),
        ],
      ],
      priority: -2,
      onInvoke: (_) => zoomIn(),
    ),
    ActionShortcut(
      id: "graph_zoom_out",
      label: "Zoom Out",
      description: "Zoom the graph out",
      activators: [
        for (final key in [
          LogicalKeyboardKey.minus,
          LogicalKeyboardKey.underscore,
          LogicalKeyboardKey.numpadSubtract,
        ]) ...[
          SingleActivator(key),
          SingleActivator(key, shift: true),
          AdaptiveSingleActivator(key, control: true),
          AdaptiveSingleActivator(key, control: true, shift: true),
        ],
        for (final character in ["-", "_"]) ...[
          CharacterActivator(character),
          CharacterActivator(character, meta: true),
          CharacterActivator(character, control: true),
        ],
      ],
      priority: -2,
      onInvoke: (_) => zoomOut(),
    ),
    ActionShortcut(
      id: "graph_zoom_reset",
      label: "Reset Zoom",
      description: "Reset zoom to 100% and center",
      activators: [
        for (final key in [
          LogicalKeyboardKey.digit0,
          LogicalKeyboardKey.numpad0,
        ]) ...[
          SingleActivator(key),
          AdaptiveSingleActivator(key, control: true),
        ],
      ],
      priority: -2,
      onInvoke: (_) => resetZoom(),
    ),
  ];
}
