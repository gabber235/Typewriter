import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";

import "../../../support/test_utils.dart";

Future<void> _invokePrimaryAction(WidgetTester tester) async {
  final modifier = isApple
      ? LogicalKeyboardKey.metaLeft
      : LogicalKeyboardKey.controlLeft;
  await tester.sendKeyDownEvent(modifier);
  await tester.sendKeyEvent(LogicalKeyboardKey.enter);
  await tester.sendKeyUpEvent(modifier);
}

Widget _dialogLauncher({
  required Future<void> Function() onConfirm,
  VoidCallback? onCancel,
  Duration delayConfirm = Duration.zero,
  Widget? body,
}) {
  return Builder(
    builder: (context) => TextButton(
      onPressed: () => showConfirmationDialogue(
        context: context,
        delayConfirm: delayConfirm,
        body: body,
        onConfirm: onConfirm,
        onCancel: onCancel,
      ),
      child: const Text("Open"),
    ),
  );
}

void main() {
  testWidgets("primary action confirms from anywhere inside the dialog", (
    tester,
  ) async {
    var confirmations = 0;
    await tester.pumpTestApp(
      child: _dialogLauncher(
        body: const TextField(autofocus: true),
        onConfirm: () async => confirmations++,
      ),
    );

    await tester.tap(find.text("Open"));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(EditableText));
    await tester.pump();
    expect(
      tester.widget<EditableText>(find.byType(EditableText)).focusNode.hasFocus,
      isTrue,
    );
    await _invokePrimaryAction(tester);

    await tester.pumpAndSettle();

    expect(confirmations, 1);
    expect(find.byType(ConfirmationDialogue), findsNothing);
  });

  testWidgets("primary action respects the confirmation delay", (tester) async {
    var confirmations = 0;
    await tester.pumpTestApp(
      child: _dialogLauncher(
        delayConfirm: const Duration(seconds: 2),
        onConfirm: () async => confirmations++,
      ),
    );

    await tester.tap(find.text("Open"));
    await tester.pumpAndSettle();
    await _invokePrimaryAction(tester);
    await tester.pump();
    expect(confirmations, 0);

    await tester.pump(const Duration(seconds: 2));
    await _invokePrimaryAction(tester);
    await tester.pumpAndSettle();

    expect(confirmations, 1);
  });

  testWidgets("primary action cannot confirm twice while pending", (
    tester,
  ) async {
    final pending = Completer<void>();
    var confirmations = 0;
    await tester.pumpTestApp(
      child: _dialogLauncher(
        onConfirm: () {
          confirmations++;
          return pending.future;
        },
      ),
    );

    await tester.tap(find.text("Open"));
    await tester.pumpAndSettle();
    await _invokePrimaryAction(tester);
    await tester.pump();
    await _invokePrimaryAction(tester);
    await tester.pump();

    expect(confirmations, 1);
    pending.complete();
    await tester.pumpAndSettle();
  });

  testWidgets("Escape dismisses through the cancellation callback", (
    tester,
  ) async {
    var cancellations = 0;
    await tester.pumpTestApp(
      child: _dialogLauncher(
        onConfirm: () async {},
        onCancel: () => cancellations++,
      ),
    );

    await tester.tap(find.text("Open"));
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();

    expect(cancellations, 1);
    expect(find.byType(ConfirmationDialogue), findsNothing);
  });
}
