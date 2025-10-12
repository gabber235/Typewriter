import "package:flutter/material.dart";
import "package:typewriter_panel/logic/interaction_mode/interaction_mode.dart";
import "package:typewriter_panel/logic/interaction_mode/mode_display.dart";
import "package:typewriter_panel/logic/interaction_mode/mode_shortcut.dart";
import "package:typewriter_panel/logic/interaction_mode/modes/normal_mode.dart";
import "package:typewriter_panel/utils/context.dart";
import "package:typewriter_panel/widgets/app/components/action_shortcuts.dart";
import "package:typewriter_panel/widgets/app/components/interaction_mode/mode_display_chip.dart";

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
