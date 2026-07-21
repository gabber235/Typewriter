import "package:flutter/material.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;

@widgetbook.UseCase(name: "Default", type: EmptyScreen)
Widget emptyScreenUseCase(BuildContext context) {
  final shrink = context.knobs.boolean(label: "Shrink", initialValue: false);
  final title = context.knobs.string(
    label: "title",
    initialValue: "Nothing here yet",
  );
  final withButton = context.knobs.boolean(
    label: "With button",
    initialValue: false,
  );
  final buttonText = context.knobs.string(
    label: "buttonText",
    initialValue: "Create new",
  );

  return FakeApp(
    child: EmptyScreen(
      title: title,
      small: shrink,
      buttonText: withButton ? buttonText : null,
      onPressed: withButton ? () {} : null,
    ),
  );
}
