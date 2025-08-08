import "package:flutter/material.dart";
import "package:flutter_animate/flutter_animate.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:typewriter_panel/utils/context.dart";

enum FocusType { none, focus, primaryFocus }

class ManagedFocusHighlight extends HookWidget {
  const ManagedFocusHighlight({
    required this.child,
    super.key,
  });
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final focusNode = useFocusNode();
    final focusType = useState(FocusType.none);

    return Focus(
      focusNode: focusNode,
      canRequestFocus: false,
      onFocusChange: (_) {
        focusType.value = focusNode.hasPrimaryFocus
            ? FocusType.primaryFocus
            : focusNode.hasFocus
                ? FocusType.focus
                : FocusType.none;
      },
      child: FocusHighlight(
        type: focusType.value,
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
        border: Border.all(
          color: switch (type) {
            FocusType.none => Colors.transparent,
            FocusType.focus =>
              Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
            FocusType.primaryFocus => Colors.blue.withValues(alpha: 0.3),
          },
          width: size,
        ),
        borderRadius: borderRadius,
      ),
      child: child,
    );
  }

  static FocusType focusType(FocusNode focusNode) {
    return focusNode.hasPrimaryFocus
        ? FocusType.primaryFocus
        : focusNode.hasFocus
            ? FocusType.focus
            : FocusType.none;
  }
}
