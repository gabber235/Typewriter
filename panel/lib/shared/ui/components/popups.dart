import "package:typewriter_panel/typewriter_panel.dart";

/// Presents an asynchronous confirmation action inside an [AlertDialog].
///
/// The dialog owns the countdown and transient loading state. [onConfirm] is
/// awaited before the confirm action returns `true`. The cancel action returns
/// `false` and invokes [onCancel]; route dismissal can return no result without
/// invoking that callback. Supply [body] or [content], with [body] taking
/// precedence. Use [showConfirmationDialogue] for the normal route
/// integration, including the panel's keyboard and provider context.
class ConfirmationDialogue extends HookWidget {
  const ConfirmationDialogue({
    required this.title,
    required this.confirmText,
    required this.confirmIcon,
    required this.confirmColor,
    required this.onConfirmColor,
    required this.delayConfirm,
    required this.cancelText,
    required this.cancelIcon,
    required this.onConfirm,
    this.titleColor,
    this.body,
    this.content,
    this.onCancel,
    this.confirmBusyText,
    super.key,
  }) : assert(
         content != null || body != null,
         "Either content or body must be provided",
       );

  /// The title of the dialogue.
  final String title;

  /// The color for the title text.
  final Color? titleColor;

  /// Rich content explaining the action being confirmed.
  ///
  /// Takes precedence over [content] when both are supplied.
  final Widget? body;

  /// Plain text explaining the action being confirmed.
  ///
  /// Used when [body] is absent.
  final String? content;

  /// Label for the action that commits the confirmation.
  final String confirmText;

  /// The word the confirm button types while [onConfirm] runs: Deleting.
  /// Without one the confirm label ripples.
  final String? confirmBusyText;

  /// Icon identifier displayed beside [confirmText].
  final String confirmIcon;

  /// Background color for the confirm action.
  final Color confirmColor;

  /// Foreground color for the confirm action.
  final Color onConfirmColor;

  /// Counts down this duration's whole seconds before enabling confirmation.
  ///
  /// The countdown is displayed in the confirm label. This is useful before
  /// an irreversible action.
  final Duration delayConfirm;

  /// The text of the cancel button
  final String cancelText;

  /// An icon to display on the cancel button
  final String cancelIcon;

  /// The asynchronous operation to run after confirmation.
  ///
  /// The confirm action dismisses the route after successful completion if it
  /// is still mounted. Other dismissal actions remain available while waiting.
  final FutureOr<void> Function()? onConfirm;

  /// Optional notification that the user cancelled the dialog.
  final Function? onCancel;

  @override
  Widget build(BuildContext context) {
    final secondsLeft = useState(delayConfirm.inSeconds);
    final canConfirm = secondsLeft.value <= 0;
    final confirmController = useButtonController();
    useListenable(confirmController);

    useTimer(const Duration(seconds: 1), (timer) {
      secondsLeft.value--;
      if (secondsLeft.value <= 0) {
        timer.cancel();
      }
    });

    void cancel() {
      Navigator.of(context).pop(false);
      onCancel?.call();
    }

    Future<void> confirm() async {
      await onConfirm?.call();
      if (!context.mounted) return;
      Navigator.of(context).pop(true);
    }

    return ManagedActionSet(
      shortcuts: [
        if (canConfirm && !confirmController.isLoading)
          ActionShortcut.intent(
            id: "dialog.confirm",
            label: confirmText,
            description: "$confirmText this action",
            intent: PrimaryActionIntent,
            priority: 100,
            onInvoke: (_) {
              confirmController.trigger();
            },
          ),
        ActionShortcut.intent(
          id: "dialog.dismiss",
          label: cancelText,
          description: "Dismiss this dialog",
          intent: DismissIntent,
          priority: 99,
          onInvoke: (_) => cancel(),
          show: false,
        ),
      ],
      child: AlertDialog(
        title: Text(
          title,
          style: Theme.of(context).textTheme.titleLarge!
              .copyWith(color: titleColor),
        ),
        content: body ?? Text(content!),
        actions: [
          Button(
            autofocus: !canConfirm,
            icon: Icones(cancelIcon),
            label: cancelText,
            onPressed: cancel,
            color: Theme.of(context).textTheme.bodySmall?.color,
          ),
          Button(
            face: ButtonFace.filled,
            controller: confirmController,
            autofocus: canConfirm,
            color: confirmColor,
            icon: Icones(confirmIcon, size: 16),
            label: canConfirm
                ? confirmText
                : "$confirmText (${secondsLeft.value})",
            busyLabel: confirmBusyText,
            onPressed: canConfirm ? confirm : null,
          ),
        ],
      ),
    );
  }
}

/// Shows a confirmation dialog and returns whether confirmation completed.
///
/// The caller's [onConfirm] is awaited. Holding either Shift key bypasses the
/// dialog when [delayConfirm] has zero whole seconds. For a longer delay, Shift
/// still shows the dialog but removes its countdown. A dismissed dialog
/// returns `false`.
Future<bool> showConfirmationDialogue({
  required BuildContext context,
  String title = "Are you sure?",
  Color? titleColor,
  String? content = "This action cannot be undone.",
  Widget? body,
  String confirmText = "Confirm",
  String? confirmBusyText,
  String confirmIcon = Fa6Solid.trash,
  Color? confirmColor,
  Color? onConfirmColor,
  Duration delayConfirm = Duration.zero,
  String cancelText = "Cancel",
  String cancelIcon = Fa6Solid.xmark,
  FutureOr<void> Function()? onConfirm,
  Function? onCancel,
}) async {
  // Shift bypasses a zero second dialog and removes longer countdowns below.
  final hasShiftDown =
      HardwareKeyboard.instance.isLogicalKeyPressed(
        LogicalKeyboardKey.shiftLeft,
      ) ||
      HardwareKeyboard.instance.isLogicalKeyPressed(
        LogicalKeyboardKey.shiftRight,
      );
  if (hasShiftDown && delayConfirm.inSeconds == 0) {
    await onConfirm?.call();
    return true;
  }

  return await showAdvancedDialog<bool>(
        context: context,
        builder: (context) => ConfirmationDialogue(
          title: title,
          titleColor: titleColor,
          content: body != null ? null : content,
          body: body,
          confirmText: confirmText,
          confirmBusyText: confirmBusyText,
          confirmIcon: confirmIcon,
          confirmColor: confirmColor ?? Theme.of(context).colorScheme.error,
          onConfirmColor:
              onConfirmColor ?? Theme.of(context).colorScheme.onError,
          delayConfirm: hasShiftDown ? Duration.zero : delayConfirm,
          cancelText: cancelText,
          cancelIcon: cancelIcon,
          onConfirm: onConfirm,
          onCancel: onCancel,
        ),
      ) ??
      false;
}

/// Shows the panel's one dialog, with Typewriter's provider, responsive and
/// keyboard context: it arrives with dialogIn, leaves with dialogOut, and
/// the page behind sinks back while it is open. The returned future carries
/// the route result, or null when no result was supplied.
Future<T?> showAdvancedDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
}) {
  // Read once: the dialog outlives [context] while it closes, such as when
  // the dialog's action removed the resource it was opened from.
  final container = ProviderScope.containerOf(context);
  final navigator = Navigator.of(context, rootNavigator: true);
  return navigator.push(
    MotionDialogRoute<T>(
      arrive: motionTimeline(context, MotionToken.dialogIn),
      leave: motionTimeline(context, MotionToken.dialogOut),
      originScale: context.motion
          .spec(MotionToken.dialogIn)
          .landing
          .originScale,
      sinksPage: true,
      barrierDismissible: barrierDismissible,
      barrierLabel: "Close dialog",
      barrierColor: context.colors.scrim,
      themes: InheritedTheme.capture(from: context, to: navigator.context),
      builder: (_) => SafeArea(
        child: UncontrolledProviderScope(
          container: container,
          child: Consumer(
            builder: (context, ref, child) => Shortcuts(
              shortcuts: typewriterShortcuts,
              child: GlobalModeShortcut(
                child: ManagedActionSet(
                  shortcuts: ref.watch(dialogShortcutsProvider),
                  child: Responsive(child: builder(context)),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

/// The panel's one bottom sheet: surfaceIn up from the bottom edge,
/// panelOut back down, with the caller's provider scope.
extension PanelSheet on BuildContext {
  Future<T?> showPanelSheet<T>(WidgetBuilder builder) {
    final container = ProviderScope.containerOf(this);
    return showModalBottomSheet<T>(
      context: this,
      isScrollControlled: true,
      backgroundColor: colors.surface.withValues(alpha: 0),
      sheetAnimationStyle: motionTimeline(
        this,
        MotionToken.surfaceIn,
      ).styleWith(motionTimeline(this, MotionToken.panelOut)),
      builder: (sheetContext) => UncontrolledProviderScope(
        container: container,
        child: builder(sheetContext),
      ),
    );
  }
}
