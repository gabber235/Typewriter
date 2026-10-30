import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";

/// Presses the primary action shortcut (Control or Command with Enter), as
/// a user does while a confirmation dialog is open.
extension PrimaryActionShortcut on WidgetTester {
  Future<void> pressPrimaryActionShortcut() async {
    final modifier = isApple
        ? LogicalKeyboardKey.metaLeft
        : LogicalKeyboardKey.controlLeft;
    await sendKeyDownEvent(modifier);
    await sendKeyEvent(LogicalKeyboardKey.enter);
    await sendKeyUpEvent(modifier);
  }
}

/// A button that opens the panel's confirmation dialogue when pressed, with
/// the given confirm, cancel, delay and body.
Widget confirmationDialogLauncher({
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
