import "package:flutter/material.dart";
import "package:flutter_hooks/flutter_hooks.dart";
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
