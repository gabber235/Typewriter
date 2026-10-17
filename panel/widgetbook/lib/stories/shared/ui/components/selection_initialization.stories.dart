import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;

@widgetbook.UseCase(
  name: "Controlled default selection",
  type: SelectionInitialization,
)
Widget selectionInitializationUseCase(BuildContext context) {
  final count = context.knobs.int.slider(
    label: "Options",
    initialValue: 1,
    min: 0,
    max: 4,
  );
  final preferred = context.knobs.int.slider(
    label: "Preferred option",
    initialValue: 2,
    min: 1,
    max: 4,
  );
  return SelectionInitializationStory(count: count, preferred: preferred);
}

class SelectionInitializationStory extends HookWidget {
  const SelectionInitializationStory({
    this.count = 1,
    this.preferred = 2,
    super.key,
  });
  final int count;
  final int preferred;

  @override
  Widget build(BuildContext context) {
    final selected = useState<int?>(null);
    return FakeApp(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AdaptiveChoiceControl<int>(
            choices: {for (var i = 1; i <= count; i++) i: "Option $i"},
            selected: selected.value,
            defaultValue: preferred,
            onSelected: (value) => selected.value = value,
          ),
          Text("Draft value: ${selected.value ?? "none"}"),
        ],
      ),
    );
  }
}
