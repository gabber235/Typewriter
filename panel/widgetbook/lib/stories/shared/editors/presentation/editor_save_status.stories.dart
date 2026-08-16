import "package:flutter/material.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;

@widgetbook.UseCase(name: "States", type: EditorSaveStatus)
Widget editorSaveStatusUseCase(BuildContext context) {
  final phase = context.knobs.object.dropdown(
    label: "State",
    options: EditorSavePhase.values,
    initialOption: EditorSavePhase.pending,
    labelBuilder: (value) => value.name,
  );
  return FakeApp(
    child: Center(
      child: EditorSaveStatus(
        state: EditorSaveState(phase: phase),
        onRetry: () async {},
        onUseRemote: () async {},
        onKeepLocal: () async {},
      ),
    ),
  );
}
