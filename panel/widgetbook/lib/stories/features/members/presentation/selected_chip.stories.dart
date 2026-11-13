import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/support/story.dart";

/// How many rows are selected, with the button that unselects them all.
/// Unselecting here sets the count to zero.
@widgetbook.UseCase(name: "Default", type: SelectedChip)
Widget selectedChipUseCase(BuildContext context) {
  final count = context.knobs.int.slider(
    label: "Selected",
    initialValue: 3,
    min: 1,
    max: 999,
  );
  return Story(
    const [],
    at: PanelLocation.component(Center(child: _Selection(count: count))),
  );
}

/// Keeps the count, as a membership tab keeps its selection.
class _Selection extends HookWidget {
  const _Selection({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final selected = useState(count);
    return SelectedChip(
      selectedCount: selected.value,
      onClearSelection: () => selected.value = 0,
    );
  }
}
