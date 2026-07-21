import "package:flutter/material.dart";
import "package:typewriter_panel/typewriter_panel.dart";

/// Insert mode for text editing interactions.
///
/// InsertMode is activated when users are actively editing text in input fields.
/// In this mode, navigation shortcuts are disabled to allow normal text input,
/// and the app bar displays a green indicator to show the current mode.
class InsertMode extends InteractionMode with ModeDisplay, ModeShortcut {
  const InsertMode([this.id = ""]);
  final String id;

  @override
  String get name => "Insert";

  @override
  Widget buildDisplay(BuildContext context) {
    return ModeDisplayChip(
      label: "Insert",
      color: context.isDarkMode ? Colors.greenAccent : Colors.green,
    );
  }

  @override
  List<ActionShortcut> getShortcuts() => [escapeToNormalAction()];
}
