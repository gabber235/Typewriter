import "package:flutter/material.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:typewriter_panel/typewriter_panel.dart";

/// Carries the nesting depth used by descendant [DepthBox] surfaces.
///
/// The nearest container is authoritative for implicit depth. It is an
/// inherited layout context, not a shared mutable state store.
class DepthContainer extends InheritedWidget {
  const DepthContainer({required this.depth, required super.child, super.key});

  final int depth;

  @override
  bool updateShouldNotify(covariant DepthContainer oldWidget) {
    return depth != oldWidget.depth;
  }

  static DepthContainer? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<DepthContainer>();
  }
}

/// Wraps content in the panel's depth aware surface treatment.
///
/// When [depth] is omitted, the value is derived from the nearest
/// [DepthContainer]. Set [enabled] to false to suppress surface treatment and
/// depth propagation while retaining the child.
class DepthBox extends HookWidget {
  const DepthBox({
    required this.child,
    this.enabled = true,
    this.shape,
    this.depth,
    super.key,
  });

  final bool enabled;
  final Widget child;

  final ShapeBorder? shape;
  final int? depth;

  @override
  Widget build(BuildContext context) {
    final parent = DepthContainer.maybeOf(context);
    final depth = this.depth ?? (parent?.depth ?? -1) + 1;
    final surfaceColor = Surface.maybeOf(context)?.color;

    final color = enabled
        ? surfaceColor != null && depth == 0
              ? surfaceColor
              : depth.isEven
              ? Theme.of(context).colorScheme.surfaceContainerLowest
              : Theme.of(context).colorScheme.surface
        : Colors.transparent;

    final widget = Semantics(
      container: true,
      child: Material(
        color: color,
        shape:
            shape ??
            RoundedRectangleBorder(
              borderRadius: context.shapes.mediumBorderRadius,
            ),
        child: Surface(color: color, child: child),
      ),
    );

    if (!enabled) {
      return widget;
    }

    return DepthContainer(depth: depth, child: widget);
  }
}
