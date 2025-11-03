import "dart:async";

import "package:flutter/material.dart";
import "package:flutter_animate/flutter_animate.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:typewriter_panel/hooks/forward_animation.dart";
import "package:typewriter_panel/hooks/loading_button_controller.dart";
import "package:typewriter_panel/utils/snackbar.dart";
import "package:typewriter_panel/widgets/generic/components/elastic_switcher.dart";

enum LoadingVariant { filled, text, outlined }

/// Controller for managing LoadingButton state and actions.
class LoadingButtonController extends ChangeNotifier {
  bool _isLoading = false;
  String? _lastError;
  FutureOr<void> Function()? _onPressed;
  void Function(String error)? _onError;

  /// Whether the button is currently loading.
  bool get isLoading => _isLoading;

  /// The last error that occurred, if any.
  String? get lastError => _lastError;

  /// Whether the button can be triggered (has onPressed and is not loading).
  bool get canTrigger => _onPressed != null && !_isLoading;

  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }

  void _setError(String? error) {
    if (_lastError != error) {
      _lastError = error;
      notifyListeners();
      if (error != null && _onError != null) {
        _onError!(error);
      }
    }
  }

  /// Programmatically trigger the button's onPressed action.
  /// Returns true if the action was triggered, false if the button is disabled or loading.
  bool trigger() {
    if (!canTrigger) return false;
    _handlePress();
    return true;
  }

  Future<void> _handlePress() async {
    if (_onPressed == null || _isLoading) return;

    _setLoading(true);
    _setError(null);

    try {
      await _onPressed!();
    } on Exception catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }
}

/// A button that manages async callbacks, shows a loading spinner, and reports errors.
///
/// Variants:
/// - filled / filledIcon
/// - text / textIcon
/// - outlined / outlinedIcon
///
/// Example usage with controller:
/// ```dart
/// // In a HookWidget:
/// final controller = useLoadingButtonController();
///
/// LoadingButton(
///   controller: controller,
///   child: Text('Save'),
///   onPressed: () async {
///     await saveData();
///   },
/// )
///
/// // Trigger programmatically
/// final success = controller.trigger(); // Returns true if triggered
///
/// // Access state
/// print('Loading: ${controller.isLoading}');
/// print('Error: ${controller.lastError}');
/// print('Can trigger: ${controller.canTrigger}');
/// ```
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
    this.controller,
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
    this.controller,
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
    this.controller,
    super.key,
  }) : variant = LoadingVariant.filled,
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
    this.controller,
    super.key,
  }) : variant = LoadingVariant.filled,
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
    this.controller,
    super.key,
  }) : variant = LoadingVariant.text,
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
    this.controller,
    super.key,
  }) : variant = LoadingVariant.text,
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
    this.controller,
    super.key,
  }) : variant = LoadingVariant.outlined,
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
    this.controller,
    super.key,
  }) : variant = LoadingVariant.outlined,
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
  final LoadingButtonController? controller;

  @override
  Widget build(BuildContext context) {
    final defaultController = useLoadingButtonController();
    final effectiveController = controller ?? defaultController;

    useListenable(effectiveController);

    useEffect(() {
      effectiveController
        .._onPressed = onPressed
        .._onError = (error) {
          if (context.mounted) {
            final hasScaffold = ScaffoldMessenger.maybeOf(context) != null;
            if (hasScaffold) {
              showErrorSnackBar(context, error);
            }
          }
        };
      return null;
    }, [onPressed]);

    final animation = useForwardAnimation(
      play: effectiveController.lastError != null,
    );

    final themeStyle = switch (variant) {
      LoadingVariant.filled => FilledButtonTheme.of(context).style,
      LoadingVariant.text => TextButtonTheme.of(context).style,
      LoadingVariant.outlined => OutlinedButtonTheme.of(context).style,
    };
    final mergedStyle = style?.merge(themeStyle) ?? themeStyle;

    final button = switch ((variant, icon)) {
      (LoadingVariant.filled, null) => FilledButton(
        style: mergedStyle,
        onPressed: effectiveController.canTrigger
            ? effectiveController._handlePress
            : null,
        onLongPress: onLongPress,
        onHover: onHover,
        onFocusChange: onFocusChange,
        focusNode: focusNode,
        autofocus: autofocus,
        clipBehavior: clipBehavior,
        statesController: statesController,
        child: ElasticSwitcher(
          child: effectiveController.isLoading
              ? _Spinner(buttonStyle: mergedStyle)
              : child,
        ),
      ),
      (LoadingVariant.filled, _) => FilledButton.icon(
        style: mergedStyle,
        onPressed: effectiveController.canTrigger
            ? effectiveController._handlePress
            : null,
        onLongPress: onLongPress,
        onHover: onHover,
        onFocusChange: onFocusChange,
        focusNode: focusNode,
        autofocus: autofocus,
        clipBehavior: clipBehavior,
        statesController: statesController,
        icon: ElasticSwitcher(
          child: effectiveController.isLoading
              ? _Spinner(buttonStyle: mergedStyle)
              : icon!,
        ),
        label: child,
      ),
      (LoadingVariant.text, null) => TextButton(
        style: mergedStyle,
        onPressed: effectiveController.canTrigger
            ? effectiveController._handlePress
            : null,
        onLongPress: onLongPress,
        onHover: onHover,
        onFocusChange: onFocusChange,
        focusNode: focusNode,
        autofocus: autofocus,
        clipBehavior: clipBehavior,
        statesController: statesController,
        child: ElasticSwitcher(
          child: effectiveController.isLoading
              ? _Spinner(buttonStyle: mergedStyle)
              : child,
        ),
      ),
      (LoadingVariant.text, _) => TextButton.icon(
        style: mergedStyle,
        onPressed: effectiveController.canTrigger
            ? effectiveController._handlePress
            : null,
        onLongPress: onLongPress,
        onHover: onHover,
        onFocusChange: onFocusChange,
        focusNode: focusNode,
        autofocus: autofocus,
        clipBehavior: clipBehavior,
        statesController: statesController,
        icon: ElasticSwitcher(
          child: effectiveController.isLoading
              ? _Spinner(buttonStyle: mergedStyle)
              : icon!,
        ),
        label: child,
      ),
      (LoadingVariant.outlined, null) => OutlinedButton(
        style: mergedStyle,
        onPressed: effectiveController.canTrigger
            ? effectiveController._handlePress
            : null,
        onLongPress: onLongPress,
        onHover: onHover,
        onFocusChange: onFocusChange,
        focusNode: focusNode,
        autofocus: autofocus,
        clipBehavior: clipBehavior,
        statesController: statesController,
        child: ElasticSwitcher(
          child: effectiveController.isLoading
              ? _Spinner(buttonStyle: mergedStyle)
              : child,
        ),
      ),
      (LoadingVariant.outlined, _) => OutlinedButton.icon(
        style: mergedStyle,
        onPressed: effectiveController.canTrigger
            ? effectiveController._handlePress
            : null,
        onLongPress: onLongPress,
        onHover: onHover,
        onFocusChange: onFocusChange,
        focusNode: focusNode,
        autofocus: autofocus,
        clipBehavior: clipBehavior,
        statesController: statesController,
        icon: ElasticSwitcher(
          child: effectiveController.isLoading
              ? _Spinner(buttonStyle: mergedStyle)
              : icon!,
        ),
        label: child,
      ),
    };

    final animated = button
        .animate(controller: animation, autoPlay: false)
        .shakeX();

    if (effectiveController.lastError == null) return animated;

    return Tooltip(message: effectiveController.lastError, child: animated);
  }
}

class _Spinner extends StatelessWidget {
  const _Spinner({required this.buttonStyle});

  final ButtonStyle? buttonStyle;

  @override
  Widget build(BuildContext context) {
    final color =
        buttonStyle?.foregroundColor?.resolve({WidgetState.disabled}) ??
        Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38);

    final size =
        buttonStyle?.iconSize?.resolve({WidgetState.disabled}) ??
        buttonStyle?.iconSize?.resolve({});

    final indicator = CircularProgressIndicator(
      strokeWidth: 3,
      valueColor: AlwaysStoppedAnimation(color),
    );

    return SizedBox.square(dimension: size, child: indicator);
  }
}
