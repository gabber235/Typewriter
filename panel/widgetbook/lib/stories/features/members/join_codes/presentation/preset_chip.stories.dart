import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/support/story.dart";

/// One duration preset of a join code's expiration; pressing it selects it.
@widgetbook.UseCase(name: "Default", type: PresetChip)
Widget presetChipUseCase(BuildContext context) {
  final selected = context.knobs.boolean(label: "Selected");
  final label = context.knobs.string(label: "Label", initialValue: "7d");
  return Story(
    const [],
    at: PanelLocation.component(
      Center(
        child: _Preset(label: label, selected: selected),
      ),
    ),
  );
}

/// Keeps whether the preset is chosen, as the duration input does.
class _Preset extends HookWidget {
  const _Preset({required this.label, required this.selected});

  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final chosen = useState(selected);
    return PresetChip(
      label: label,
      isSelected: chosen.value,
      onTap: () => chosen.value = !chosen.value,
    );
  }
}
