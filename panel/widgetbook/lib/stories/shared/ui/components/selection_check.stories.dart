import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/support/story.dart";

/// Every state of a [SelectionCheck]: off, on, partly, and unavailable.
@widgetbook.UseCase(name: "States", type: SelectionCheck)
Widget selectionCheckStatesUseCase(BuildContext context) {
  return Story(
    const [],
    at: PanelLocation.component(
      Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SelectionCheck(value: false, onChanged: () {}),
          SelectionCheck(value: true, onChanged: () {}),
          SelectionCheck(value: null, onChanged: () {}),
          const SelectionCheck(value: false),
          const SelectionCheck(value: true),
        ],
      ),
    ),
  );
}

/// A [SelectionCheck] to press with a click, Space or Enter.
@widgetbook.UseCase(name: "Pressable", type: SelectionCheck)
Widget selectionCheckPressableUseCase(BuildContext context) {
  return const Story([], at: PanelLocation.component(_PressableCheck()));
}

class _PressableCheck extends HookWidget {
  const _PressableCheck();

  @override
  Widget build(BuildContext context) {
    final value = useState<bool?>(null);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SelectionCheck(
          value: value.value,
          autofocus: true,
          onChanged: () => value.value = !(value.value ?? false),
        ),
        const Text("Select all"),
      ],
    );
  }
}
