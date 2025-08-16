import "dart:async";

import "package:flutter/material.dart";
import "package:flutter_animate/flutter_animate.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:typewriter_panel/hooks/forward_animation.dart";
import "package:typewriter_panel/utils/snackbar.dart";
import "package:typewriter_panel/widgets/generic/components/elastic_switcher.dart";

enum LoadingVariant { filled, text, outlined }

/// A button that manages async callbacks, shows a loading spinner, and reports errors.
///
/// Variants:
/// - filled / filledIcon
/// - text / textIcon
/// - outlined / outlinedIcon
class LoadingButton extends HookWidget {
  const LoadingButton({
    required this.child,
    required this.onPressed,
    this.variant = LoadingVariant.filled,
    this.style,
    this.onLongPress,
    this.onHover,
    this.onFocusChange,
    this.focusNode,
    this.autofocus = false,
    this.clipBehavior = Clip.none,
    this.statesController,
    super.key,
  }) : icon = null;

  const LoadingButton.icon({
    required this.icon,
    required Widget label,
    required this.onPressed,
    this.variant = LoadingVariant.filled,
    this.style,
    this.onLongPress,
    this.onHover,
    this.onFocusChange,
    this.focusNode,
    this.autofocus = false,
    this.clipBehavior = Clip.none,
    this.statesController,
    super.key,
  }) : child = label;

  const LoadingButton.filled({
    required this.child,
    required this.onPressed,
    this.style,
    this.onLongPress,
    this.onHover,
    this.onFocusChange,
    this.focusNode,
    this.autofocus = false,
    this.clipBehavior = Clip.none,
    this.statesController,
    super.key,
  })  : variant = LoadingVariant.filled,
        icon = null;

  const LoadingButton.filledIcon({
    required this.icon,
    required Widget label,
    required this.onPressed,
    this.style,
    this.onLongPress,
    this.onHover,
    this.onFocusChange,
    this.focusNode,
    this.autofocus = false,
    this.clipBehavior = Clip.none,
    this.statesController,
    super.key,
  })  : variant = LoadingVariant.filled,
        child = label;

  const LoadingButton.text({
    required this.child,
    required this.onPressed,
    this.style,
    this.onLongPress,
    this.onHover,
    this.onFocusChange,
    this.focusNode,
    this.autofocus = false,
    this.clipBehavior = Clip.none,
    this.statesController,
    super.key,
  })  : variant = LoadingVariant.text,
        icon = null;

  const LoadingButton.textIcon({
    required this.icon,
    required Widget label,
    required this.onPressed,
    this.style,
    this.onLongPress,
    this.onHover,
    this.onFocusChange,
    this.focusNode,
    this.autofocus = false,
    this.clipBehavior = Clip.none,
    this.statesController,
    super.key,
  })  : variant = LoadingVariant.text,
        child = label;

  const LoadingButton.outlined({
    required this.child,
    required this.onPressed,
    this.style,
    this.onLongPress,
    this.onHover,
    this.onFocusChange,
    this.focusNode,
    this.autofocus = false,
    this.clipBehavior = Clip.none,
    this.statesController,
    super.key,
  })  : variant = LoadingVariant.outlined,
        icon = null;

  const LoadingButton.outlinedIcon({
    required this.icon,
    required Widget label,
    required this.onPressed,
    this.style,
    this.onLongPress,
    this.onHover,
    this.onFocusChange,
    this.focusNode,
    this.autofocus = false,
    this.clipBehavior = Clip.none,
    this.statesController,
    super.key,
  })  : variant = LoadingVariant.outlined,
        child = label;

  final LoadingVariant variant;

  final Widget? icon;
  final Widget child;

  final FutureOr<void> Function()? onPressed;
  final VoidCallback? onLongPress;
  final ValueChanged<bool>? onHover;
  final ValueChanged<bool>? onFocusChange;
  final FocusNode? focusNode;
  final bool autofocus;
  final Clip clipBehavior;
  final ButtonStyle? style;
  final WidgetStatesController? statesController;

  @override
  Widget build(BuildContext context) {
    final isLoading = useState(false);
    final lastError = useState<String?>(null);

    final animation = useForwardAnimation(play: lastError.value != null);

    final themeStyle = switch (variant) {
      LoadingVariant.filled => FilledButtonTheme.of(context).style,
      LoadingVariant.text => TextButtonTheme.of(context).style,
      LoadingVariant.outlined => OutlinedButtonTheme.of(context).style,
    };
    final mergedStyle = style?.merge(themeStyle) ?? themeStyle;

    Future<void> handlePress() async {
      if (onPressed == null || isLoading.value) return;
      isLoading.value = true;
      lastError.value = null;
      try {
        await onPressed!.call();
      } on Exception catch (e) {
        if (!context.mounted) return;
        lastError.value = e.toString();
        final hasScaffold = ScaffoldMessenger.maybeOf(context) != null;
        if (hasScaffold) {
          showErrorSnackBar(context, lastError.value!);
        }
      } finally {
        if (context.mounted) {
          isLoading.value = false;
        }
      }
    }

    final button = switch ((variant, icon)) {
      (LoadingVariant.filled, null) => FilledButton(
          style: mergedStyle,
          onPressed: onPressed == null || isLoading.value ? null : handlePress,
          onLongPress: onLongPress,
          onHover: onHover,
          onFocusChange: onFocusChange,
          focusNode: focusNode,
          autofocus: autofocus,
          clipBehavior: clipBehavior,
          statesController: statesController,
          child: ElasticSwitcher(
            child: isLoading.value ? _Spinner(buttonStyle: mergedStyle) : child,
          ),
        ),
      (LoadingVariant.filled, _) => FilledButton.icon(
          style: mergedStyle,
          onPressed: onPressed == null || isLoading.value ? null : handlePress,
          onLongPress: onLongPress,
          onHover: onHover,
          onFocusChange: onFocusChange,
          focusNode: focusNode,
          autofocus: autofocus,
          clipBehavior: clipBehavior,
          statesController: statesController,
          icon: ElasticSwitcher(
            child: isLoading.value ? _Spinner(buttonStyle: mergedStyle) : icon!,
          ),
          label: child,
        ),
      (LoadingVariant.text, null) => TextButton(
          style: mergedStyle,
          onPressed: onPressed == null || isLoading.value ? null : handlePress,
          onLongPress: onLongPress,
          onHover: onHover,
          onFocusChange: onFocusChange,
          focusNode: focusNode,
          autofocus: autofocus,
          clipBehavior: clipBehavior,
          statesController: statesController,
          child: ElasticSwitcher(
            child: isLoading.value ? _Spinner(buttonStyle: mergedStyle) : child,
          ),
        ),
      (LoadingVariant.text, _) => TextButton.icon(
          style: mergedStyle,
          onPressed: onPressed == null || isLoading.value ? null : handlePress,
          onLongPress: onLongPress,
          onHover: onHover,
          onFocusChange: onFocusChange,
          focusNode: focusNode,
          autofocus: autofocus,
          clipBehavior: clipBehavior,
          statesController: statesController,
          icon: ElasticSwitcher(
            child: isLoading.value ? _Spinner(buttonStyle: mergedStyle) : icon!,
          ),
          label: child,
        ),
      (LoadingVariant.outlined, null) => OutlinedButton(
          style: mergedStyle,
          onPressed: onPressed == null || isLoading.value ? null : handlePress,
          onLongPress: onLongPress,
          onHover: onHover,
          onFocusChange: onFocusChange,
          focusNode: focusNode,
          autofocus: autofocus,
          clipBehavior: clipBehavior,
          statesController: statesController,
          child: ElasticSwitcher(
            child: isLoading.value ? _Spinner(buttonStyle: mergedStyle) : child,
          ),
        ),
      (LoadingVariant.outlined, _) => OutlinedButton.icon(
          style: mergedStyle,
          onPressed: onPressed == null || isLoading.value ? null : handlePress,
          onLongPress: onLongPress,
          onHover: onHover,
          onFocusChange: onFocusChange,
          focusNode: focusNode,
          autofocus: autofocus,
          clipBehavior: clipBehavior,
          statesController: statesController,
          icon: ElasticSwitcher(
            child: isLoading.value ? _Spinner(buttonStyle: mergedStyle) : icon!,
          ),
          label: child,
        ),
    };

    final animated =
        button.animate(controller: animation, autoPlay: false).shakeX();

    if (lastError.value == null) return animated;

    return Tooltip(
      message: lastError.value,
      child: animated,
    );
  }
}

class _Spinner extends StatelessWidget {
  const _Spinner({
    required this.buttonStyle,
  });

  final ButtonStyle? buttonStyle;

  @override
  Widget build(BuildContext context) {
    final color =
        buttonStyle?.foregroundColor?.resolve({WidgetState.disabled}) ??
            Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38);

    final size = buttonStyle?.iconSize?.resolve({WidgetState.disabled}) ??
        buttonStyle?.iconSize?.resolve({});

    final indicator = CircularProgressIndicator(
      strokeWidth: 3,
      valueColor: AlwaysStoppedAnimation(color),
    );

    return SizedBox.square(
      dimension: size,
      child: indicator,
    );
  }
}
