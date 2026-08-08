import "package:flutter/material.dart";
import "package:typewriter_panel/typewriter_panel.dart";

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
