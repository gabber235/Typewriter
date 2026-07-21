import "dart:async";

import "package:flutter/material.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;

Future<void> _simulateDelay(BuildContext context) async {
  final ms = context.knobs.int.input(label: "Delay (ms)", initialValue: 2500);
  await Future<void>.delayed(Duration(milliseconds: ms));
}

@widgetbook.UseCase(name: "Disabled", type: FloatingButton)
Widget floatingButtonDisabled(BuildContext context) {
  return FakeApp(
    child: FloatingButton(
      icon: const Icon(Icons.add),
      child: const SizedBox.expand(child: Center(child: Text("Hello"))),
    ),
  );
}

@widgetbook.UseCase(name: "Success", type: FloatingButton)
Widget floatingButtonSuccess(BuildContext context) {
  final body = context.knobs.string(label: "Body", initialValue: "Hello");
  return FakeApp(
    child: FloatingButton(
      icon: const Icon(Icons.add),
      onPressed: () async {
        await _simulateDelay(context);
      },
      child: SizedBox.expand(child: Center(child: Text(body))),
    ),
  );
}

@widgetbook.UseCase(name: "Failure", type: FloatingButton)
Widget floatingButtonFailure(BuildContext context) {
  final body = context.knobs.string(label: "Body", initialValue: "Hello");
  return FakeApp(
    child: FloatingButton(
      icon: const Icon(Icons.add),
      onPressed: () async {
        await _simulateDelay(context);
        throw Exception("Simulated failure: action failed");
      },
      child: SizedBox.expand(child: Center(child: Text(body))),
    ),
  );
}
