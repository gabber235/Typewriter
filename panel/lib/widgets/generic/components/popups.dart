import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_animate/flutter_animate.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:iconify_flutter_plus/icons/fa6_solid.dart";
import "package:iconify_flutter_plus/icons/jam.dart";
import "package:typewriter_panel/hooks/timer.dart";
import "package:typewriter_panel/widgets/generic/components/icones.dart";

class ConfirmationDialogue extends HookWidget {
  const ConfirmationDialogue({
    required this.title,
    required this.content,
    required this.confirmText,
    required this.confirmIcon,
    required this.confirmColor,
    required this.delayConfirm,
    required this.cancelText,
    required this.cancelIcon,
    required this.onConfirm,
    this.onCancel,
    super.key,
  });

  /// The title of the dialogue.
  final String title;

  /// The content of the dialogue. This can be a small piece of text to explain what the user is confirming.
  final String content;

  /// The text of the confirm button
  final String confirmText;

  /// An icon to display on the confirm button
  final String confirmIcon;

  /// The color of the confirm button
  final Color confirmColor;

  /// When [delayConfirm] is larger than 0, the confirm button will be disabled for [delayConfirm] seconds.
  /// This may be useful when the user is about to perform an irreversible action.
  final Duration delayConfirm;

  /// The text of the cancel button
  final String cancelText;

  /// An icon to display on the cancel button
  final String cancelIcon;

  /// The action to perform when the user confirms the action.
  final Function onConfirm;

  /// An optional action to perform when the user cancels the action.
  final Function? onCancel;

  @override
  Widget build(BuildContext context) {
    final secondsLeft = useState(delayConfirm.inSeconds);
    final canConfirm = secondsLeft.value <= 0;

    useTimer(
      1.seconds,
      (timer) {
        secondsLeft.value--;
        if (secondsLeft.value <= 0) {
          timer.cancel();
        }
      },
    );

    return AlertDialog(
      title: Text(title),
      content: Text(content),
      actions: [
        TextButton.icon(
          icon: Icones(
            cancelIcon,
            color: Theme.of(context).textTheme.bodySmall?.color,
          ),
          label: Text(cancelText),
          onPressed: () {
            Navigator.of(context).pop(false);
            onCancel?.call();
          },
          style: TextButton.styleFrom(
            foregroundColor: Theme.of(context).textTheme.bodySmall?.color,
          ),
        ),
        FilledButton.icon(
          icon: Icones(confirmIcon, size: 16),
          label: Text(
            canConfirm ? confirmText : "$confirmText (${secondsLeft.value})",
          ),
          style: FilledButton.styleFrom(
            backgroundColor: confirmColor,
          ),
          onPressed: canConfirm
              ? () {
                  Navigator.of(context).pop(true);
                  onConfirm();
                }
              : null,
        ),
      ],
    );
  }
}

Future<bool> showConfirmationDialogue({
  required BuildContext context,
  required Function onConfirm,
  String title = "Are you sure?",
  String content = "This action cannot be undone.",
  String confirmText = "Confirm",
  String confirmIcon = Fa6Solid.trash,
  Color confirmColor = Colors.redAccent,
  Duration delayConfirm = Duration.zero,
  String cancelText = "Cancel",
  String cancelIcon = Fa6Solid.xmark,
  Function? onCancel,
}) async {
  // If the user has its shift key pressed, we skip the confirmation dialogue.
  // But only if the delay is 0.
  final hasShiftDown = HardwareKeyboard.instance
      .isLogicalKeyPressed(LogicalKeyboardKey.shiftLeft);
  if (hasShiftDown && delayConfirm.inSeconds == 0) {
    onConfirm();
    return true;
  }

  return await showDialog<bool>(
        context: context,
        builder: (context) => ConfirmationDialogue(
          onConfirm: onConfirm,
          title: title,
          content: content,
          confirmText: confirmText,
          confirmIcon: confirmIcon,
          confirmColor: confirmColor,
          delayConfirm: hasShiftDown ? Duration.zero : delayConfirm,
          cancelText: cancelText,
          cancelIcon: cancelIcon,
          onCancel: onCancel,
        ),
      ) ??
      false;
}
