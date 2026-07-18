import "package:flutter/material.dart";
import "package:typewriter_panel/shared/ui/components/countdown_badge.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;

@widgetbook.UseCase(name: "Default", type: CountdownBadge)
Widget countdownBadgeDefaultUseCase(BuildContext context) {
  final duration = context.knobs.duration(
    label: "Duration",
    initialValue: Duration(minutes: 2),
  );
  final urgentThresholdSeconds = context.knobs.int.slider(
    label: "Urgent Threshold (seconds)",
    initialValue: 60,
    min: 10,
    max: 120,
  );

  return FakeApp(
    child: Center(
      child: CountdownBadge(
        endDate: DateTime.now().add(duration),
        urgentThreshold: Duration(seconds: urgentThresholdSeconds),
      ),
    ),
  );
}
