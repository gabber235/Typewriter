import "package:flutter/material.dart";
import "package:typewriter_panel/widgets/app/components/interaction_mode/mode_display_chip.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;

@widgetbook.UseCase(name: "Default", type: ModeDisplayChip)
Widget modeDisplayChipNormal(BuildContext context) {
  final label = context.knobs.string(label: "Label", initialValue: "Normal");
  final color = context.knobs.color(
    label: "Color",
    initialValue: Colors.blue,
  );

  return FakeApp(
    child: Center(
      child: ModeDisplayChip(
        label: label,
        color: color,
      ),
    ),
  );
}
