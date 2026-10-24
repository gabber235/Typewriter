import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;

@widgetbook.UseCase(name: "Focus and keyboard interaction", type: Dropdown)
Widget dropdownInteractionUseCase(BuildContext context) =>
    DropdownInteractionStory(
      enabled: context.knobs.boolean(label: "Enabled", initialValue: true),
      width: context.knobs.double.slider(
        label: "Field width",
        initialValue: 360,
        min: 240,
        max: 600,
      ),
    );

class DropdownInteractionStory extends HookWidget {
  const DropdownInteractionStory({
    this.enabled = true,
    this.width = 360,
    super.key,
  });

  final bool enabled;
  final double width;

  @override
  Widget build(BuildContext context) {
    final selected = useState("paper");
    return FakeApp(
      child: SizedBox(
        width: width,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 16,
          children: [
            const Align(child: ModeDisplayWidget()),
            const Text("Realm target"),
            Dropdown<String>(
              enabled: enabled,
              selected: selected.value,
              dropdownMenuEntries: const [
                DropdownMenuEntry(value: "paper", label: "Paper"),
                DropdownMenuEntry(
                  value: "velocity",
                  label: "Velocity (unavailable)",
                  enabled: false,
                ),
                DropdownMenuEntry(value: "fabric", label: "Fabric"),
                DropdownMenuEntry(value: "minestom", label: "Minestom"),
              ],
              onSelected: (value) {
                if (value != null) selected.value = value;
              },
            ),
            Text("Selected: ${selected.value}"),
            const EditorTextField(hintText: "Next field"),
            const Text(
              "Tab focuses the field. Enter opens choices. Type to filter, "
              "use arrows to navigate, and Enter to select. "
              "Escape returns to field navigation.",
            ),
          ],
        ),
      ),
    );
  }
}
