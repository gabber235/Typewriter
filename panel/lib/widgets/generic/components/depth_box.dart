import "package:flutter/material.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:typewriter_panel/widgets/generic/components/surface.dart";

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

    final color = enabled
        ? depth.isEven
              ? Theme.of(context).colorScheme.surfaceContainerLowest
              : Theme.of(context).colorScheme.surface
        : Colors.transparent;

    final widget = Material(
      color: color,
      shape:
          shape ??
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      child: Surface(color: color, child: child),
    );

    if (!enabled) {
      return widget;
    }

    return DepthContainer(depth: depth, child: widget);
  }
}
