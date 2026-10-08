import "package:typewriter_panel/typewriter_panel.dart";

/// Presents an asynchronous confirmation action inside an [AlertDialog].
///
/// The dialog owns the countdown and transient loading state. [onConfirm] is
/// awaited before the route returns `true`; cancellation returns `false` and
/// invokes [onCancel] after dismissing the route. Supply exactly one of
/// [body] or [content]. Use [showConfirmationDialogue] for the normal route
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
  /// Mutually exclusive with [content].
  final Widget? body;

  /// Plain text explaining the action being confirmed.
  ///
  /// Mutually exclusive with [body].
  final String? content;

  /// Label for the action that commits the confirmation.
  final String confirmText;

  /// Icon identifier displayed beside [confirmText].
  final String confirmIcon;

  /// Background color for the confirm action.
  final Color confirmColor;

  /// Foreground color for the confirm action.
  final Color onConfirmColor;

  /// Prevents confirmation until this duration has elapsed.
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
  /// The route is dismissed only after this future completes successfully.
  final FutureOr<void> Function()? onConfirm;

  /// Optional notification that the user cancelled the dialog.
  final Function? onCancel;

  @override
  Widget build(BuildContext context) {
    final secondsLeft = useState(delayConfirm.inSeconds);
    final canConfirm = secondsLeft.value <= 0;
    final confirmController = useLoadingButtonController();
    useListenable(confirmController);

    useTimer(1.seconds, (timer) {
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
          TextButton.icon(
            autofocus: !canConfirm,
            icon: Icones(
              cancelIcon,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
            label: Text(cancelText),
            onPressed: cancel,
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
          LoadingButton.filledIcon(
            controller: confirmController,
            autofocus: canConfirm,
            style: FilledButton.styleFrom(
              backgroundColor: confirmColor,
              foregroundColor: onConfirmColor,
            ),
            icon: Icones(confirmIcon, size: 16),
            label: Text(
              canConfirm ? confirmText : "$confirmText (${secondsLeft.value})",
            ),
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
/// dialog when [delayConfirm] is zero, which supports deliberate expert
/// workflows without bypassing a configured safety delay. A dismissed dialog
/// returns `false`.
Future<bool> showConfirmationDialogue({
  required BuildContext context,
  String title = "Are you sure?",
  Color? titleColor,
  String? content = "This action cannot be undone.",
  Widget? body,
  String confirmText = "Confirm",
  String confirmIcon = Fa6Solid.trash,
  Color? confirmColor,
  Color? onConfirmColor,
  Duration delayConfirm = Duration.zero,
  String cancelText = "Cancel",
  String cancelIcon = Fa6Solid.xmark,
  FutureOr<void> Function()? onConfirm,
  Function? onCancel,
}) async {
  // Shift is an explicit expert shortcut, but never bypasses a safety delay.
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

/// Shows a dialog with Typewriter's provider, responsive, and keyboard context.
///
/// Unlike calling [showDialog] directly, the builder can access the existing
/// Riverpod container and the panel's global shortcuts. The returned future
/// carries the route result, or null when no result was supplied.
Future<T?> showAdvancedDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
  Color? barrierColor,
  String? barrierLabel,
  bool useSafeArea = true,
  bool useRootNavigator = true,
  RouteSettings? routeSettings,
  Offset? anchorPoint,
  TraversalEdgeBehavior? traversalEdgeBehavior,
  bool fullscreenDialog = false,
  bool? requestFocus,
  AnimationStyle? animationStyle,
}) => showDialog<T>(
  context: context,
  builder: (ctx) => UncontrolledProviderScope(
    container: ProviderScope.containerOf(context),
    child: Consumer(
      builder: (context, ref, child) {
        return Shortcuts(
          shortcuts: typewriterShortcuts,
          child: GlobalModeShortcut(child: Responsive(child: builder(context))),
        );
      },
    ),
  ),
  barrierDismissible: barrierDismissible,
  barrierColor: barrierColor,
  barrierLabel: barrierLabel,
  useSafeArea: useSafeArea,
  useRootNavigator: useRootNavigator,
  routeSettings: routeSettings,
  anchorPoint: anchorPoint,
  traversalEdgeBehavior: traversalEdgeBehavior,
  fullscreenDialog: fullscreenDialog,
  requestFocus: requestFocus,
  animationStyle: animationStyle,
);
