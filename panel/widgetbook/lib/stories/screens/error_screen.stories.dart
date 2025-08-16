import "package:flutter/material.dart";
import "package:typewriter_panel/widgets/generic/screens/error_screen.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;

@widgetbook.UseCase(name: "Default", type: ErrorScreen)
Widget errorScreenUseCase(BuildContext context) {
  final shrink = context.knobs.boolean(
    label: "Shrink",
    initialValue: false,
  );
  final title = context.knobs.string(
    label: "title",
    initialValue: "Oops, something went wrong",
  );
  final message = context.knobs.string(
    label: "message",
    initialValue:
        "Something went wrong, please report this to the Typewriter discord. ",
  );

  if (shrink) {
    return FakeApp(
      child: ErrorScreen.small(
        title: title,
        message: message,
      ),
    );
  }

  return FakeApp(
    child: ErrorScreen(
      title: title,
      message: message,
    ),
  );
}
