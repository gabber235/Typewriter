import "package:flutter/material.dart";
import "package:typewriter_panel/app/presentation/shortcuts/action_shortcuts.dart";
import "package:typewriter_panel/features/organizations/features/realms/features/books/features/pages/features/editor/features/interaction_mode/application/interaction_mode.dart";
import "package:typewriter_panel/features/organizations/features/realms/features/books/features/pages/features/editor/features/interaction_mode/application/mode_display.dart";
import "package:typewriter_panel/features/organizations/features/realms/features/books/features/pages/features/editor/features/interaction_mode/application/mode_shortcut.dart";
import "package:typewriter_panel/features/organizations/features/realms/features/books/features/pages/features/editor/features/interaction_mode/application/modes/normal_mode.dart";
import "package:typewriter_panel/features/organizations/features/realms/features/books/features/pages/features/editor/features/interaction_mode/presentation/mode_display_chip.dart";
import "package:typewriter_panel/shared/utilities/context.dart";

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
