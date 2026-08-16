import "dart:async";

import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_test/flutter_test.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/typewriter_panel.dart";

import "../../../support/test_utils.dart";

void main() {
  const foregroundColor = Color(0xFF123456);

  testWidgets("filled button shows the operation shortcut", (tester) async {
    await tester.pumpTestApp(
      child: Center(
        child: OperationButton.filledIcon(
          operation: const _TestOperation(),
          icon: const Icon(Icons.bolt),
          label: const Text("Run"),
          onPressed: () {},
          style: const ButtonStyle(
            foregroundColor: WidgetStatePropertyAll(foregroundColor),
          ),
        ),
      ),
    );

    expect(find.byType(FilledButton), findsOneWidget);
    expect(find.byType(OutlinedButton), findsNothing);
    expect(_shortcutForegroundColor(tester), foregroundColor);
  });

  testWidgets("outlined button shows the operation shortcut", (tester) async {
    await tester.pumpTestApp(
      child: Center(
        child: OperationButton.outlinedIcon(
          operation: const _TestOperation(),
          icon: const Icon(Icons.bolt),
          label: const Text("Run"),
          onPressed: () {},
          style: const ButtonStyle(
            foregroundColor: WidgetStatePropertyAll(foregroundColor),
          ),
        ),
      ),
    );

    expect(find.byType(OutlinedButton), findsOneWidget);
    expect(find.byType(FilledButton), findsNothing);
    expect(_shortcutForegroundColor(tester), foregroundColor);
  });

  testWidgets("button omits unavailable shortcuts", (tester) async {
    await tester.pumpTestApp(
      child: Center(
        child: OperationButton.filledIcon(
          operation: const _TestOperation(activators: []),
          icon: const Icon(Icons.bolt),
          label: const Text("Run"),
          onPressed: () {},
        ),
      ),
    );

    expect(find.byType(ShortcutDisplay), findsNothing);
  });
}

Color? _shortcutForegroundColor(WidgetTester tester) {
  final display = tester.widget<ShortcutDisplay>(find.byType(ShortcutDisplay));
  return switch (display.style) {
    OutlineKeyStyle(:final foregroundColor) => foregroundColor,
    SolidKeyStyle() => null,
  };
}

class _TestOperation extends ActivatorShortcutOperation {
  const _TestOperation({
    this.activators = const [SingleActivator(LogicalKeyboardKey.keyR)],
  });

  @override
  final List<ShortcutActivator> activators;

  @override
  String get name => "Run";

  @override
  String get description => "Run the test operation";

  @override
  bool canExecuteOn(List<Selectable> selection) => true;

  @override
  FutureOr<void> executeOn(WidgetRef ref) {}

  @override
  Widget inspectorButton(List<Selectable> selection) =>
      throw UnimplementedError();

  @override
  MenuItem menuItem(WidgetRef ref) => throw UnimplementedError();
}
