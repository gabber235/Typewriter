import "package:flutter/material.dart";
import "package:typewriter_panel/widgets/generic/screens/error_screen.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;

@widgetbook.UseCase(name: "Default", type: ErrorScreen)
Widget errorScreenUseCase(BuildContext context) {
  return ErrorScreen(
    title: context.knobs.string(
      label: "title",
      initialValue: "Oops, something went wrong",
    ),
    message: context.knobs.string(
      label: "message",
      initialValue:
          "Something went wrong, please report this to the Typewriter discord. ",
    ),
  );
}
