import "package:typewriter_panel/typewriter_panel.dart";

/// Interaction mode for editing the input field identified by [id].
///
/// Input field registration owns the lifecycle of this ID. Leaving the field,
/// dismissing its input, or disposing its registration returns the shared mode
/// to [NormalMode] when this instance is still current.
class InsertMode extends InteractionMode with ModeDisplay, ModeShortcut {
  const InsertMode([this.id = ""]);

  /// Identifier of the registered input field receiving text input.
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
