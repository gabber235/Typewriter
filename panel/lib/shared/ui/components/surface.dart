import "package:flutter/material.dart";

class Surface extends InheritedWidget {
  const Surface({required this.color, required super.child, super.key});

  final Color color;

  @override
  bool updateShouldNotify(covariant Surface oldWidget) =>
      color != oldWidget.color;

  static Color colorOf(BuildContext context) {
    final surface = maybeOf(context);
    if (surface != null) return surface.color;

    return Theme.of(context).colorScheme.surface;
  }

  static Surface? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<Surface>();
  }
}
