import "package:flutter/material.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;

enum _LoadingButtonStyle {
  filled,
  filledIcon,
  text,
  textIcon,
  outlined,
  outlinedIcon,
}

extension on _LoadingButtonStyle {
  String get label => switch (this) {
    _LoadingButtonStyle.filled => "Filled",
    _LoadingButtonStyle.filledIcon => "Filled icon",
    _LoadingButtonStyle.text => "Text",
    _LoadingButtonStyle.textIcon => "Text icon",
    _LoadingButtonStyle.outlined => "Outlined",
    _LoadingButtonStyle.outlinedIcon => "Outlined icon",
  };
}

enum _LoadingButtonOutcome { success, failure }

extension on _LoadingButtonOutcome {
  String get label => switch (this) {
    _LoadingButtonOutcome.success => "Success",
    _LoadingButtonOutcome.failure => "Failure",
  };
}

@widgetbook.UseCase(name: "Playground", type: LoadingButton)
Widget loadingButtonPlaygroundUseCase(BuildContext context) {
  final style = context.knobs.object.dropdown(
    label: "Style",
    options: _LoadingButtonStyle.values,
    initialOption: _LoadingButtonStyle.filled,
    labelBuilder: (value) => value.label,
  );
  final outcome = context.knobs.object.dropdown(
    label: "Outcome",
    options: _LoadingButtonOutcome.values,
    initialOption: _LoadingButtonOutcome.success,
    labelBuilder: (value) => value.label,
  );
  final label = context.knobs.string(label: "Label", initialValue: "Create");
  final delay = context.knobs.duration(
    label: "Delay",
    initialValue: const Duration(milliseconds: 2500),
  );

  Future<void> onPressed() async {
    await Future<void>.delayed(delay);
    if (outcome == _LoadingButtonOutcome.failure) {
      throw Exception("Simulated failure: could not complete action");
    }
  }

  final button = switch (style) {
    _LoadingButtonStyle.filled => LoadingButton.filled(
      onPressed: onPressed,
      child: Text(label),
    ),
    _LoadingButtonStyle.filledIcon => LoadingButton.filledIcon(
      onPressed: onPressed,
      icon: const Icon(Icons.add),
      label: Text(label),
    ),
    _LoadingButtonStyle.text => LoadingButton.text(
      onPressed: onPressed,
      child: Text(label),
    ),
    _LoadingButtonStyle.textIcon => LoadingButton.textIcon(
      onPressed: onPressed,
      icon: const Icon(Icons.upload),
      label: Text(label),
    ),
    _LoadingButtonStyle.outlined => LoadingButton.outlined(
      onPressed: onPressed,
      child: Text(label),
    ),
    _LoadingButtonStyle.outlinedIcon => LoadingButton.outlinedIcon(
      onPressed: onPressed,
      icon: const Icon(Icons.download),
      label: Text(label),
    ),
  };

  return FakeApp(child: Center(child: button));
}
