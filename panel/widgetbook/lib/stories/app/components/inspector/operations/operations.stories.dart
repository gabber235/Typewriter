import "package:flutter/material.dart";
import "package:typewriter_panel/logic/selectable/selectable.dart";
import "package:typewriter_panel/logic/selectable/selection.dart";
import "package:typewriter_panel/widgets/app/components/inspector/inspector.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";

Widget operationUseCase(
  BuildContext context,
  List<SelectableIdentifier Function(BuildContext)> builders,
) {
  return FakeApp(
    overrides: [
      selectionProvider.overrideWithBuild(
        (ref, _) => builders.map((b) => b(context)).toList(),
      ),
    ],
    child: Center(child: Operations()),
  );
}

Future<void> delayedSnack(
  BuildContext context, {
  required Duration delay,
  required String text,
  SnackBarAction? action,
}) async {
  await Future.delayed(delay);
  if (!context.mounted) return;
  ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(text), action: action));
}
