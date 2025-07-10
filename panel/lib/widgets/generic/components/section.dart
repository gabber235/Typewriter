import "package:flutter/material.dart";

class Section extends StatelessWidget {
  const Section({
    required this.child,
    this.margin = const EdgeInsets.all(8),
    super.key,
  });

  final Widget child;

  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerLowest,
      margin: margin,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: child,
    );
  }
}
