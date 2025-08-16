import "package:flutter/material.dart";
import "package:typewriter_panel/widgets/generic/components/section.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;

@widgetbook.UseCase(name: "Default", type: Section)
Widget sectionUseCase(BuildContext context) {
  final text = context.knobs.string(
    label: "Text",
    initialValue: "Section content goes here",
  );
  return FakeApp(child: Center(child: Section(child: Text(text))));
}
