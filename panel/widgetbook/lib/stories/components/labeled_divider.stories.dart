import "package:flutter/material.dart";
import "package:typewriter_panel/widgets/generic/components/labeled_divider.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;

@widgetbook.UseCase(name: "LabeledDivider", type: LabeledDivider)
Widget labeledDividerUseCase(BuildContext context) {
  final text = context.knobs.string(label: "Text", initialValue: "OR");
  final direction = context.knobs.list(
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
  return Center(
    child: LabeledDivider(
      text: text,
      direction: direction,
      dividerThickness: thickness,
    ),
  );
}
