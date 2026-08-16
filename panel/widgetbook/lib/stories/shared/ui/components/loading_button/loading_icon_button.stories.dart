import "package:flutter/material.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;

enum _LoadingIconButtonStyle { standard, filled, outlined }

extension on _LoadingIconButtonStyle {
  String get label => switch (this) {
    _LoadingIconButtonStyle.standard => "Standard",
    _LoadingIconButtonStyle.filled => "Filled",
    _LoadingIconButtonStyle.outlined => "Outlined",
  };
}

enum _LoadingIconButtonOutcome { success, failure }

extension on _LoadingIconButtonOutcome {
  String get label => switch (this) {
    _LoadingIconButtonOutcome.success => "Success",
    _LoadingIconButtonOutcome.failure => "Failure",
  };
}

@widgetbook.UseCase(name: "Playground", type: LoadingIconButton)
Widget loadingIconButtonPlaygroundUseCase(BuildContext context) {
  final variant = context.knobs.object.dropdown(
    label: "Variant",
    options: _LoadingIconButtonStyle.values,
    initialOption: _LoadingIconButtonStyle.standard,
    labelBuilder: (value) => value.label,
  );
  final outcome = context.knobs.object.dropdown(
    label: "Outcome",
    options: _LoadingIconButtonOutcome.values,
    initialOption: _LoadingIconButtonOutcome.success,
    labelBuilder: (value) => value.label,
  );
  final tooltip = context.knobs.string(
    label: "Tooltip",
    initialValue: "Refresh",
  );
  final delay = context.knobs.duration(
    label: "Delay",
    initialValue: const Duration(milliseconds: 2500),
  );

  Future<void> onPressed() async {
    await Future<void>.delayed(delay);
    if (outcome == _LoadingIconButtonOutcome.failure) {
      throw Exception("Simulated failure: could not complete action");
    }
  }

  final button = switch (variant) {
    _LoadingIconButtonStyle.standard => LoadingIconButton(
      icon: const Icon(Icons.refresh),
      tooltip: tooltip,
      onPressed: onPressed,
    ),
    _LoadingIconButtonStyle.filled => LoadingIconButton.filled(
      icon: const Icon(Icons.refresh),
      tooltip: tooltip,
      onPressed: onPressed,
    ),
    _LoadingIconButtonStyle.outlined => LoadingIconButton.outlined(
      icon: const Icon(Icons.refresh),
      tooltip: tooltip,
      onPressed: onPressed,
    ),
  };

  return FakeApp(child: Center(child: button));
}
