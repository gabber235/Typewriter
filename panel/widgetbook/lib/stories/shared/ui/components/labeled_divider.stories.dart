import "package:flutter/material.dart";
import "package:typewriter_panel/shared/ui/components/labeled_divider.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;

@widgetbook.UseCase(name: "LabeledDivider", type: LabeledDivider)
Widget labeledDividerUseCase(BuildContext context) {
  final text = context.knobs.string(label: "Text", initialValue: "OR");
  final direction = context.knobs.object.dropdown(
    label: "Direction",
    initialOption: Axis.horizontal,
    options: Axis.values,
    labelBuilder: (option) => option.name,
  );
  final thickness = context.knobs.double.slider(
    label: "Thickness",
    initialValue: 2,
    min: 0,
    max: 10,
  );
  return FakeApp(
    child: Center(
      child: LabeledDivider(
        text: text,
        direction: direction,
        dividerThickness: thickness,
      ),
    ),
  );
}
