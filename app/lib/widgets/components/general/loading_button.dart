import "dart:async";
import "dart:math";
import "dart:ui";

import "package:flutter/material.dart" hide FilledButton;
import "package:flutter_hooks/flutter_hooks.dart";
import "package:typewriter/utils/extensions.dart";
import "package:typewriter/widgets/components/general/filled_button.dart";

class LoadingButton extends HookWidget {
  const LoadingButton({
    required this.child,
    required this.onPressed,
    required this.color,
    super.key,
  });

  factory LoadingButton.icon({
    required Widget icon,
    required Widget label,
    required FutureOr<void> Function()? onPressed,
    Color? color,
    Key? key,
  }) = _LoadingButtonIcon;

  final Widget child;
  final FutureOr<void> Function()? onPressed;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isLoading = useState(false);

    return FilledButton(
      onPressed: isLoading.value
          ? null
          : () async {
              isLoading.value = true;
              final scaffold = ScaffoldMessenger.of(context);
              try {
                await onPressed?.call();
              } on Exception {
                scaffold.showSnackBar(
                  SnackBar(
                    content: Text(l10n.unexpectedError),
                  ),
                );
              } finally {
                isLoading.value = false;
              }
            },
      color: color,
      child: IndexedStack(
        index: isLoading.value ? 1 : 0,
        alignment: Alignment.center,
        children: [
          child,
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingButtonIcon extends LoadingButton {
  _LoadingButtonIcon({
    required Widget icon,
    required Widget label,
    required super.onPressed,
    super.color,
    super.key,
  }) : super(
          child: _LoadingButtonWithIconChild(label: label, icon: icon),
        );
}

class _LoadingButtonWithIconChild extends StatelessWidget {
  const _LoadingButtonWithIconChild({
    required this.label,
    required this.icon,
  });

  final Widget label;
  final Widget icon;

  @override
  Widget build(BuildContext context) {
    // ignore: deprecated_member_use
    final scale = MediaQuery.maybeOf(context)?.textScaleFactor ?? 1;
    final gap = scale <= 1 ? 8.0 : lerpDouble(8, 4, min(scale - 1, 1))!;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        IconTheme(
          data: const IconThemeData(
            size: 18,
            color: Colors.white,
          ),
          child: icon,
        ),
        SizedBox(width: gap),
        Flexible(child: label),
      ],
    );
  }
}
