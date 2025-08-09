import "package:flutter/material.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/logic/selectable/selectable.dart";
import "package:typewriter_panel/logic/selectable/selection.dart";
import "package:typewriter_panel/widgets/app/components/inspector/inspector.dart";

Widget operationUseCase(
  BuildContext context,
  List<SelectableIdentifier Function(BuildContext)> builders,
) {
  return Scaffold(
    body: Builder(
      builder: (ctx) {
        final identifiers = builders.map((b) => b(ctx)).toList();
        return ProviderScope(
          overrides: [selectionProvider.overrideWithValue(identifiers)],
          child: Center(child: Operations()),
        );
      },
    ),
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
