import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:typewriter_panel/widgets/generic/components/section.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;

@widgetbook.UseCase(name: "Default", type: Section)
Widget sectionUseCase(BuildContext context) {
  final text = context.knobs.string(
    label: "Text",
    initialValue: "Section content goes here",
  );
  return ProviderScope(child: Center(child: Section(child: Text(text))));
}
