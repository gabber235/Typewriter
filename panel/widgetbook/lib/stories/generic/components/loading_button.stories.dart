import "dart:async";

import "package:flutter/material.dart";
import "package:typewriter_panel/widgets/generic/components/loading_button.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;

Future<void> _simulateDelay(BuildContext context) async {
  final ms = context.knobs.int.input(label: "Delay (ms)", initialValue: 2500);
  await Future<void>.delayed(Duration(milliseconds: ms));
}

@widgetbook.UseCase(name: "Filled - Success", type: LoadingButton)
Widget loadingButtonFilledSuccess(BuildContext context) {
  final label = context.knobs.string(label: "Label", initialValue: "Create");
  return FakeApp(
    child: LoadingButton.filled(
      child: Text(label),
      onPressed: () async {
        await _simulateDelay(context);
      },
    ),
  );
}

@widgetbook.UseCase(name: "Filled - Failure", type: LoadingButton)
Widget loadingButtonFilledFailure(BuildContext context) {
  final label = context.knobs.string(label: "Label", initialValue: "Create");
  return FakeApp(
    child: LoadingButton.filled(
      child: Text(label),
      onPressed: () async {
        await _simulateDelay(context);
        throw Exception("Simulated failure: could not complete action");
      },
    ),
  );
}

@widgetbook.UseCase(name: "FilledIcon - Success", type: LoadingButton)
Widget loadingButtonFilledIconSuccess(BuildContext context) {
  final label = context.knobs.string(label: "Label", initialValue: "Add");
  return FakeApp(
    child: LoadingButton.filledIcon(
      icon: const Icon(Icons.add),
      label: Text(label),
      onPressed: () async {
        await _simulateDelay(context);
      },
    ),
  );
}

@widgetbook.UseCase(name: "FilledIcon - Failure", type: LoadingButton)
Widget loadingButtonFilledIconFailure(BuildContext context) {
  final label = context.knobs.string(label: "Label", initialValue: "Add");
  return FakeApp(
    child: LoadingButton.filledIcon(
      icon: const Icon(Icons.add),
      label: Text(label),
      onPressed: () async {
        await _simulateDelay(context);
        throw Exception("Simulated failure: add failed");
      },
    ),
  );
}

@widgetbook.UseCase(name: "Text - Success", type: LoadingButton)
Widget loadingButtonTextSuccess(BuildContext context) {
  final label = context.knobs.string(label: "Label", initialValue: "Retry");
  return FakeApp(
    child: LoadingButton.text(
      child: Text(label),
      onPressed: () async {
        await _simulateDelay(context);
      },
    ),
  );
}

@widgetbook.UseCase(name: "Text - Failure", type: LoadingButton)
Widget loadingButtonTextFailure(BuildContext context) {
  final label = context.knobs.string(label: "Label", initialValue: "Retry");
  return FakeApp(
    child: LoadingButton.text(
      child: Text(label),
      onPressed: () async {
        await _simulateDelay(context);
        throw Exception("Simulated failure: retry failed");
      },
    ),
  );
}

@widgetbook.UseCase(name: "TextIcon - Success", type: LoadingButton)
Widget loadingButtonTextIconSuccess(BuildContext context) {
  final label = context.knobs.string(label: "Label", initialValue: "Upload");
  return FakeApp(
    child: LoadingButton.textIcon(
      icon: const Icon(Icons.upload),
      label: Text(label),
      onPressed: () async {
        await _simulateDelay(context);
      },
    ),
  );
}

@widgetbook.UseCase(name: "TextIcon - Failure", type: LoadingButton)
Widget loadingButtonTextIconFailure(BuildContext context) {
  final label = context.knobs.string(label: "Label", initialValue: "Upload");
  return FakeApp(
    child: LoadingButton.textIcon(
      icon: const Icon(Icons.upload),
      label: Text(label),
      onPressed: () async {
        await _simulateDelay(context);
        throw Exception("Simulated failure: upload failed");
      },
    ),
  );
}

@widgetbook.UseCase(name: "Outlined - Success", type: LoadingButton)
Widget loadingButtonOutlinedSuccess(BuildContext context) {
  final label = context.knobs.string(label: "Label", initialValue: "Save");
  return FakeApp(
    child: LoadingButton.outlined(
      child: Text(label),
      onPressed: () async {
        await _simulateDelay(context);
      },
    ),
  );
}

@widgetbook.UseCase(name: "Outlined - Failure", type: LoadingButton)
Widget loadingButtonOutlinedFailure(BuildContext context) {
  final label = context.knobs.string(label: "Label", initialValue: "Save");
  return FakeApp(
    child: LoadingButton.outlined(
      child: Text(label),
      onPressed: () async {
        await _simulateDelay(context);
        throw Exception("Simulated failure: save failed");
      },
    ),
  );
}

@widgetbook.UseCase(name: "OutlinedIcon - Success", type: LoadingButton)
Widget loadingButtonOutlinedIconSuccess(BuildContext context) {
  final label = context.knobs.string(label: "Label", initialValue: "Download");
  return FakeApp(
    child: LoadingButton.outlinedIcon(
      icon: const Icon(Icons.download),
      label: Text(label),
      onPressed: () async {
        await _simulateDelay(context);
      },
    ),
  );
}

@widgetbook.UseCase(name: "OutlinedIcon - Failure", type: LoadingButton)
Widget loadingButtonOutlinedIconFailure(BuildContext context) {
  final label = context.knobs.string(label: "Label", initialValue: "Download");
  return FakeApp(
    child: LoadingButton.outlinedIcon(
      icon: const Icon(Icons.download),
      label: Text(label),
      onPressed: () async {
        await _simulateDelay(context);
        throw Exception("Simulated failure: download failed");
      },
    ),
  );
}
