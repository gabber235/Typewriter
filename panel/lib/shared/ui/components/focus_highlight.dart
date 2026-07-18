import "package:flutter/material.dart";
import "package:flutter_animate/flutter_animate.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:typewriter_panel/shared/utilities/context.dart";

enum FocusType { none, focus, primaryFocus }

FocusType _primaryFocus(FocusNode node) {
  return node.hasPrimaryFocus ? FocusType.focus : FocusType.none;
}

FocusType _childFocus(FocusNode node) {
  return node.hasFocus ? FocusType.focus : FocusType.none;
}

FocusType _childPrimaryFocus(FocusNode node) {
  return node.hasPrimaryFocus
      ? FocusType.primaryFocus
      : node.hasFocus
      ? FocusType.focus
      : FocusType.none;
}

enum FocusHighlighting {
  /// Only highlight when it has primary focus, otherwise don't highlight at all.
  onlyPrimary(_primaryFocus),

  /// Only highlight when a child has focus.
  onlyChild(_childFocus),

  // Highlight when it has primary focus or a child has focus.
  primaryAndChild(_childPrimaryFocus);

  const FocusHighlighting(this.fetchFocusType);

  final FocusType Function(FocusNode) fetchFocusType;

  FocusType call(FocusNode node) => fetchFocusType(node);
}

class ManagedFocusHighlight extends HookWidget {
  const ManagedFocusHighlight({
    required this.child,
    this.focusNode,
    this.highlighting = FocusHighlighting.onlyPrimary,
    this.borderRadius,
    this.size = 2,
    this.autofocus = false,
    this.canRequestFocus = true,
    this.skipTraversal = false,
    this.descendantsAreFocusable = true,
    this.descendantsAreTraversable = true,
    this.debugLabel,
    this.onFocusChange,
    this.onKeyEvent,
    super.key,
  });
  final Widget child;
  final FocusNode? focusNode;
  final FocusHighlighting highlighting;

  final BorderRadiusGeometry? borderRadius;
  final double size;

  // Pass-through Focus properties for transparency.
  final bool autofocus;
  final bool canRequestFocus;
  final bool skipTraversal;
  final bool descendantsAreFocusable;
  final bool descendantsAreTraversable;
  final String? debugLabel;
  final ValueChanged<bool>? onFocusChange;
  final FocusOnKeyEventCallback? onKeyEvent;

  @override
  Widget build(BuildContext context) {
    final focusNode = this.focusNode ?? useFocusNode();
    final focusType = useState(FocusType.none);

    return Focus(
      focusNode: focusNode,
      autofocus: autofocus,
      canRequestFocus: canRequestFocus,
      skipTraversal: skipTraversal,
      descendantsAreFocusable: descendantsAreFocusable,
      descendantsAreTraversable: descendantsAreTraversable,
      debugLabel: debugLabel,
      onKeyEvent: onKeyEvent,
      onFocusChange: (hasFocus) {
        focusType.value = highlighting.fetchFocusType(focusNode);
        onFocusChange?.call(hasFocus);
      },
      child: FocusHighlight(
        type: focusType.value,
        borderRadius: borderRadius,
        size: size,
        child: child,
      ),
    );
  }
}

class FocusHighlight extends HookWidget {
  const FocusHighlight({
    required this.child,
    required this.type,
    this.borderRadius,
    this.size = 2,
    super.key,
  });

  final Widget child;
  final FocusType type;
  final BorderRadiusGeometry? borderRadius;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (context.isMobile) {
      return child;
    }
    return AnimatedContainer(
      duration: 200.ms,
      curve: Curves.fastEaseInToSlowEaseOut,
      clipBehavior: Clip.none,
      decoration: BoxDecoration(
        border: Border.fromBorderSide(focusBorder(context, type, width: size)),
        borderRadius: borderRadius,
      ),
      child: child,
    );
  }

  static WidgetStateBorderSide stateBorder(
    BuildContext context, {
    double width = 2.0,
    Color? focusColor,
  }) {
    return WidgetStateBorderSide.resolveWith((states) {
      if (states.contains(WidgetState.focused)) {
        return focusBorder(
          context,
          FocusType.focus,
          width: width,
          focusColor: focusColor,
        );
      }
      return focusBorder(
        context,
        FocusType.none,
        width: width,
        focusColor: focusColor,
      );
    });
  }

  static BorderSide focusBorder(
    BuildContext context,
    FocusType type, {
    double width = 2.0,
    Color? focusColor,
  }) {
    return BorderSide(
      color: switch (type) {
        FocusType.none => Colors.transparent,
        FocusType.focus =>
          focusColor?.withValues(alpha: 0.3) ??
              Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
        FocusType.primaryFocus => Colors.blue.withValues(alpha: 0.3),
      },
      width: width,
    );
  }
}
