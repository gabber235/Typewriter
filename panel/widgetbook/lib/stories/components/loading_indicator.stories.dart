import "package:flutter/material.dart";
import "package:typewriter_panel/widgets/generic/components/loading_indicator.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;

@widgetbook.UseCase(name: "Default", type: LoadingIndicator)
Widget loadingIndicatorUseCase(BuildContext context) {
  return LoadingIndicator(
    message: context.knobs.string(
      label: "Loading Message",
      initialValue: "Loading...",
    ),
  );
}
