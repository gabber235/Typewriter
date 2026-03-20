import "package:flutter/material.dart";
import "package:typewriter_panel/widgets/generic/components/surface.dart";

class Section extends StatelessWidget {
  const Section({
    required this.child,
    this.margin = const EdgeInsets.all(8),
    this.backgroundColor,
    super.key,
  });

  final Widget child;

  final Color? backgroundColor;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    final color =
        backgroundColor ?? Theme.of(context).colorScheme.surfaceContainerLowest;
    final radius = BorderRadius.circular(12);

    return Card(
      elevation: 0,
      color: color,
      margin: margin,
      shape: RoundedRectangleBorder(borderRadius: radius),
      child: Surface(
        color: color,
        child: ClipRRect(borderRadius: radius, child: child),
      ),
    );
  }
}
