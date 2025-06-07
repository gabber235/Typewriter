import "package:flutter/material.dart";
import "package:typewriter_panel/widgets/generic/components/retry_indicator.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;

@widgetbook.UseCase(name: "Default", type: RetryIndicator)
Widget retryIndicatorUseCase(BuildContext context) {
  return Center(
    child: RetryIndicator(
      message: context.knobs.string(
        label: "Retry Message",
        initialValue: "Retrying...",
      ),
    ),
  );
}
