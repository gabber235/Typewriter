import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/support/story.dart";

/// The engine [Dropdown] of a Realm, with one engine unavailable; it opens
/// and filters from the keyboard, and hands focus on to the next field.
@widgetbook.UseCase(name: "Default", type: Dropdown)
Widget dropdownUseCase(BuildContext context) {
  final enabled = context.knobs.boolean(label: "Enabled", initialValue: true);
  final long = context.knobs.boolean(label: "Long labels");
  return Story(
    const [],
    at: PanelLocation.component(
      SizedBox(
        width: 360,
        child: _EngineField(enabled: enabled, long: long),
      ),
    ),
  );
}

class _EngineField extends HookWidget {
  const _EngineField({required this.enabled, required this.long});

  final bool enabled;
  final bool long;

  @override
  Widget build(BuildContext context) {
    final selected = useState("paper");
    String label(String name) =>
        long ? "$name (recommended for production servers)" : name;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 16,
      children: [
        Dropdown<String>(
          enabled: enabled,
          selected: selected.value,
          dropdownMenuEntries: [
            MenuChoice(value: "paper", label: label("Paper")),
            MenuChoice(
              value: "velocity",
              label: label("Velocity (unavailable)"),
              enabled: false,
            ),
            MenuChoice(value: "fabric", label: label("Fabric")),
            MenuChoice(value: "minestom", label: label("Minestom")),
          ],
          onSelected: (value) {
            if (value != null) selected.value = value;
          },
        ),
        const EditorTextField(hintText: "Server name"),
      ],
    );
  }
}
