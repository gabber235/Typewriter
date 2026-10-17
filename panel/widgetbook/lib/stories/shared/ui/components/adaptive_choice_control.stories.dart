import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;

@widgetbook.UseCase(
  name: "Empty and available choices",
  type: AdaptiveChoiceControl,
)
Widget adaptiveChoiceControlUseCase(BuildContext context) {
  final count = context.knobs.int.slider(
    label: "Available choices",
    initialValue: 0,
    min: 0,
    max: 4,
  );
  return FakeApp(
    child: HookBuilder(
      builder: (context) {
        final selected = useState<int?>(0);
        return AdaptiveChoiceControl<int>(
          choices: {for (var i = 0; i < count; i++) i: "Option ${i + 1}"},
          selected: selected.value,
          onSelected: (value) => selected.value = value,
        );
      },
    ),
  );
}

@widgetbook.UseCase(
  name: "Styled and disabled choices",
  type: SlidingChoiceControl,
)
Widget slidingChoiceControlUseCase(BuildContext context) {
  final disabled = context.knobs.boolean(
    label: "Disable SVG",
    initialValue: false,
  );
  return FakeApp(
    child: Center(
      child: SizedBox(
        width: 360,
        child: HookBuilder(
          builder: (context) {
            final selected = useState("Iconify");
            return SlidingChoiceControl<String>(
              selected: selected.value,
              disabled: disabled ? const {"SVG"} : const {},
              children: const {"Iconify": Text("Iconify"), "SVG": Text("SVG")},
              onSelected: (value) {
                if (value != null) selected.value = value;
              },
            );
          },
        ),
      ),
    ),
  );
}
