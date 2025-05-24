import "dart:async";
import "dart:ui";

import "package:flutter/material.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:typewriter_panel/utils/snackbar.dart";

class LoadingButton extends HookWidget {
  const LoadingButton({
    required this.child,
    required this.onPressed,
    this.style,
    super.key,
  });

  factory LoadingButton.icon({
    required Widget icon,
    required Widget label,
    required FutureOr<void> Function()? onPressed,
    ButtonStyle? style,
    IconAlignment? iconAlignment,
    Key? key,
  }) = _LoadingButtonIcon;

  final Widget child;
  final FutureOr<void> Function()? onPressed;
  final ButtonStyle? style;

  @override
  Widget build(BuildContext context) {
    final isLoading = useState(false);

    return FilledButton(
      style: style,
      onPressed: onPressed == null || isLoading.value
          ? null
          : () async {
              isLoading.value = true;
              try {
                await onPressed?.call();
              } on Exception catch (e) {
                if (!context.mounted) {
                  return;
                }
                showErrorSnackBar(
                  context,
                  e.toString(),
                );
              } finally {
                if (context.mounted) {
                  isLoading.value = false;
                }
              }
            },
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
    IconAlignment? iconAlignment,
    super.style,
    super.key,
  }) : super(
          child: _LoadingButtonWithIconChild(
            label: label,
            icon: icon,
            buttonStyle: style,
            iconAlignment: iconAlignment,
          ),
        );
}

class _LoadingButtonWithIconChild extends StatelessWidget {
  const _LoadingButtonWithIconChild({
    required this.label,
    required this.icon,
    required this.buttonStyle,
    required this.iconAlignment,
  });

  final Widget label;
  final Widget icon;
  final ButtonStyle? buttonStyle;
  final IconAlignment? iconAlignment;

  @override
  Widget build(BuildContext context) {
    final defaultFontSize =
        buttonStyle?.textStyle?.resolve(const <WidgetState>{})?.fontSize ??
            14.0;
    final scale = clampDouble(
          MediaQuery.textScalerOf(context).scale(defaultFontSize) / 14.0,
          1.0,
          2.0,
        ) -
        1.0;
    // Adjust the gap based on the text scale factor. Start at 8, and lerp
    // to 4 based on how large the text is.
    final gap = lerpDouble(8, 4, scale)!;
    final filledButtonTheme = FilledButtonTheme.of(context);
    final effectiveIconAlignment = iconAlignment ??
        filledButtonTheme.style?.iconAlignment ??
        buttonStyle?.iconAlignment ??
        IconAlignment.start;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: effectiveIconAlignment == IconAlignment.start
          ? <Widget>[icon, SizedBox(width: gap), Flexible(child: label)]
          : <Widget>[Flexible(child: label), SizedBox(width: gap), icon],
    );
  }
}
