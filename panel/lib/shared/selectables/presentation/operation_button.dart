import "dart:async";

import "package:flutter/material.dart";
import "package:typewriter_panel/typewriter_panel.dart";

enum _OperationButtonVariant { filled, outlined }

class OperationButton extends StatelessWidget {
  const OperationButton.filledIcon({
    required this.operation,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.style,
    super.key,
  }) : _variant = _OperationButtonVariant.filled;

  const OperationButton.outlinedIcon({
    required this.operation,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.style,
    super.key,
  }) : _variant = _OperationButtonVariant.outlined;

  final ShortcutableOperation operation;
  final Widget icon;
  final Widget label;
  final FutureOr<void> Function()? onPressed;
  final ButtonStyle? style;
  final _OperationButtonVariant _variant;

  @override
  Widget build(BuildContext context) {
    final shortcut = operation.shortcut;
    final shortcuts = shortcut.canInvoke
        ? shortcut.shortcuts
        : const <ShortcutActivator>[];
    final operationLabel = _OperationButtonLabel(
      shortcuts: shortcuts,
      child: label,
    );

    return switch (_variant) {
      _OperationButtonVariant.filled => LoadingButton.filledIcon(
        icon: icon,
        label: operationLabel,
        onPressed: onPressed,
        style: style,
      ),
      _OperationButtonVariant.outlined => LoadingButton.outlinedIcon(
        icon: icon,
        label: operationLabel,
        onPressed: onPressed,
        style: style,
      ),
    };
  }
}

class _OperationButtonLabel extends StatelessWidget {
  const _OperationButtonLabel({required this.shortcuts, required this.child});

  final List<ShortcutActivator> shortcuts;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: DefaultTextStyle.merge(
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            softWrap: false,
            child: child,
          ),
        ),
        if (shortcuts.isNotEmpty) ...[
          SizedBox(width: context.spacing.space2),
          Builder(
            builder: (context) {
              final foregroundColor = DefaultTextStyle.of(context).style.color;
              return RotatingShortcuts(
                shortcuts: shortcuts,
                style: KeyStyle.outline(foregroundColor: foregroundColor),
              );
            },
          ),
        ],
      ],
    );
  }
}
