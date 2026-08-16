import "dart:async";

import "package:flutter/material.dart";
import "package:flutter_animate/flutter_animate.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:typewriter_panel/shared/hooks/forward_animation.dart";
import "package:typewriter_panel/shared/hooks/loading_button_controller.dart";
import "package:typewriter_panel/shared/ui/components/elastic_switcher.dart";
import "package:typewriter_panel/shared/ui/components/loading_button/loading_button_controller.dart";
import "package:typewriter_panel/shared/utilities/snackbar.dart";

enum _LoadingIconButtonVariant { standard, filled, outlined }

/// An icon button that manages async callbacks and reports failures.
class LoadingIconButton extends HookWidget {
  const LoadingIconButton({
    required this.icon,
    required this.onPressed,
    this.iconSize,
    this.visualDensity,
    this.padding,
    this.alignment,
    this.splashRadius,
    this.color,
    this.focusColor,
    this.hoverColor,
    this.highlightColor,
    this.splashColor,
    this.disabledColor,
    this.onHover,
    this.onLongPress,
    this.mouseCursor,
    this.focusNode,
    this.autofocus = false,
    this.tooltip,
    this.enableFeedback,
    this.constraints,
    this.style,
    this.isSelected,
    this.selectedIcon,
    this.statesController,
    this.controller,
    super.key,
  }) : assert(splashRadius == null || splashRadius > 0),
       _variant = _LoadingIconButtonVariant.standard;

  const LoadingIconButton.filled({
    required this.icon,
    required this.onPressed,
    this.iconSize,
    this.visualDensity,
    this.padding,
    this.alignment,
    this.splashRadius,
    this.color,
    this.focusColor,
    this.hoverColor,
    this.highlightColor,
    this.splashColor,
    this.disabledColor,
    this.onHover,
    this.onLongPress,
    this.mouseCursor,
    this.focusNode,
    this.autofocus = false,
    this.tooltip,
    this.enableFeedback,
    this.constraints,
    this.style,
    this.isSelected,
    this.selectedIcon,
    this.statesController,
    this.controller,
    super.key,
  }) : assert(splashRadius == null || splashRadius > 0),
       _variant = _LoadingIconButtonVariant.filled;

  const LoadingIconButton.outlined({
    required this.icon,
    required this.onPressed,
    this.iconSize,
    this.visualDensity,
    this.padding,
    this.alignment,
    this.splashRadius,
    this.color,
    this.focusColor,
    this.hoverColor,
    this.highlightColor,
    this.splashColor,
    this.disabledColor,
    this.onHover,
    this.onLongPress,
    this.mouseCursor,
    this.focusNode,
    this.autofocus = false,
    this.tooltip,
    this.enableFeedback,
    this.constraints,
    this.style,
    this.isSelected,
    this.selectedIcon,
    this.statesController,
    this.controller,
    super.key,
  }) : assert(splashRadius == null || splashRadius > 0),
       _variant = _LoadingIconButtonVariant.outlined;

  final Widget icon;
  final FutureOr<void> Function()? onPressed;
  final double? iconSize;
  final VisualDensity? visualDensity;
  final EdgeInsetsGeometry? padding;
  final AlignmentGeometry? alignment;
  final double? splashRadius;
  final Color? color;
  final Color? focusColor;
  final Color? hoverColor;
  final Color? highlightColor;
  final Color? splashColor;
  final Color? disabledColor;
  final ValueChanged<bool>? onHover;
  final VoidCallback? onLongPress;
  final MouseCursor? mouseCursor;
  final FocusNode? focusNode;
  final bool autofocus;
  final String? tooltip;
  final bool? enableFeedback;
  final BoxConstraints? constraints;
  final ButtonStyle? style;
  final bool? isSelected;
  final Widget? selectedIcon;
  final WidgetStatesController? statesController;
  final LoadingButtonController? controller;
  final _LoadingIconButtonVariant _variant;

  @override
  Widget build(BuildContext context) {
    final defaultController = useLoadingButtonController();
    final effectiveController = controller ?? defaultController;

    useListenable(effectiveController);

    useEffect(() {
      effectiveController.bind(
        onPressed: onPressed,
        onError: (error) {
          if (!context.mounted) return;

          final hasScaffold = ScaffoldMessenger.maybeOf(context) != null;
          if (hasScaffold) showErrorSnackBar(context, error);
        },
      );
      return null;
    }, [effectiveController, onPressed]);

    final animation = useForwardAnimation(
      play: effectiveController.lastError != null,
    );
    final loadingIcon = ElasticSwitcher(
      child: effectiveController.isLoading
          ? const _LoadingIconButtonSpinner()
          : icon,
    );
    final loadingSelectedIcon = selectedIcon == null
        ? null
        : ElasticSwitcher(
            child: effectiveController.isLoading
                ? const _LoadingIconButtonSpinner()
                : selectedIcon,
          );

    final button = switch (_variant) {
      _LoadingIconButtonVariant.standard => IconButton(
        icon: loadingIcon,
        onPressed: effectiveController.canTrigger
            ? effectiveController.handlePress
            : null,
        iconSize: iconSize,
        visualDensity: visualDensity,
        padding: padding,
        alignment: alignment,
        splashRadius: splashRadius,
        color: color,
        focusColor: focusColor,
        hoverColor: hoverColor,
        highlightColor: highlightColor,
        splashColor: splashColor,
        disabledColor: disabledColor,
        onHover: onHover,
        onLongPress: onLongPress,
        mouseCursor: mouseCursor,
        focusNode: focusNode,
        autofocus: autofocus,
        tooltip: tooltip,
        enableFeedback: enableFeedback,
        constraints: constraints,
        style: style,
        isSelected: isSelected,
        selectedIcon: loadingSelectedIcon,
        statesController: statesController,
      ),
      _LoadingIconButtonVariant.filled => IconButton.filled(
        icon: loadingIcon,
        onPressed: effectiveController.canTrigger
            ? effectiveController.handlePress
            : null,
        iconSize: iconSize,
        visualDensity: visualDensity,
        padding: padding,
        alignment: alignment,
        splashRadius: splashRadius,
        color: color,
        focusColor: focusColor,
        hoverColor: hoverColor,
        highlightColor: highlightColor,
        splashColor: splashColor,
        disabledColor: disabledColor,
        onHover: onHover,
        onLongPress: onLongPress,
        mouseCursor: mouseCursor,
        focusNode: focusNode,
        autofocus: autofocus,
        tooltip: tooltip,
        enableFeedback: enableFeedback,
        constraints: constraints,
        style: style,
        isSelected: isSelected,
        selectedIcon: loadingSelectedIcon,
        statesController: statesController,
      ),
      _LoadingIconButtonVariant.outlined => IconButton.outlined(
        icon: loadingIcon,
        onPressed: effectiveController.canTrigger
            ? effectiveController.handlePress
            : null,
        iconSize: iconSize,
        visualDensity: visualDensity,
        padding: padding,
        alignment: alignment,
        splashRadius: splashRadius,
        color: color,
        focusColor: focusColor,
        hoverColor: hoverColor,
        highlightColor: highlightColor,
        splashColor: splashColor,
        disabledColor: disabledColor,
        onHover: onHover,
        onLongPress: onLongPress,
        mouseCursor: mouseCursor,
        focusNode: focusNode,
        autofocus: autofocus,
        tooltip: tooltip,
        enableFeedback: enableFeedback,
        constraints: constraints,
        style: style,
        isSelected: isSelected,
        selectedIcon: loadingSelectedIcon,
        statesController: statesController,
      ),
    };
    final animated = button
        .animate(controller: animation, autoPlay: false)
        .shakeX();

    if (effectiveController.lastError == null) return animated;

    return Tooltip(message: effectiveController.lastError, child: animated);
  }
}

class _LoadingIconButtonSpinner extends StatelessWidget {
  const _LoadingIconButtonSpinner();

  @override
  Widget build(BuildContext context) {
    final iconTheme = IconTheme.of(context);

    return SizedBox.square(
      dimension: iconTheme.size,
      child: CircularProgressIndicator(strokeWidth: 3, color: iconTheme.color),
    );
  }
}
