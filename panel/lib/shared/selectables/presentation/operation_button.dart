import "package:typewriter_panel/typewriter_panel.dart";

/// Renders a shortcut aware [Button] for a selection operation.
///
/// The operation supplies shortcut availability. This widget only chooses the
/// face and delegates execution to [onPressed].
class OperationButton extends StatelessWidget {
  const OperationButton.filledIcon({
    required this.operation,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.busyLabel,
    this.color,
    super.key,
  }) : _face = ButtonFace.filled;

  const OperationButton.outlinedIcon({
    required this.operation,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.busyLabel,
    this.color,
    super.key,
  }) : _face = ButtonFace.outlined;

  /// Operation whose shortcut is shown when it can currently invoke.
  final ShortcutableOperation operation;
  final Widget icon;
  final String label;

  /// The word the button types while the operation runs.
  final String? busyLabel;
  final FutureOr<void> Function()? onPressed;

  /// Overrides the face colour, as a destructive operation does.
  final Color? color;
  final ButtonFace _face;

  @override
  Widget build(BuildContext context) {
    final shortcut = operation.shortcut;
    final shortcuts = shortcut.canInvoke
        ? shortcut.shortcuts
        : const <ShortcutActivator>[];
    return Button(
      face: _face,
      icon: _OperationButtonIcon(shortcuts: shortcuts, icon: icon),
      label: label,
      busyLabel: busyLabel,
      color: color,
      onPressed: onPressed,
    );
  }
}

/// The operation's icon and, when it can run by key, the first shortcut,
/// the one the command list also lists first.
class _OperationButtonIcon extends StatelessWidget {
  const _OperationButtonIcon({required this.shortcuts, required this.icon});

  final List<ShortcutActivator> shortcuts;
  final Widget icon;

  @override
  Widget build(BuildContext context) {
    if (shortcuts.isEmpty) return icon;
    final foreground = IconTheme.of(context).color;
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: context.spacing.space2,
      children: [
        icon,
        ShortcutDisplay(
          shortcut: shortcuts.first,
          style: KeyStyle.outline(foregroundColor: foreground),
        ),
      ],
    );
  }
}
