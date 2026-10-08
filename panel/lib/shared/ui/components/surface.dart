import "package:typewriter_panel/typewriter_panel.dart";

/// Propagates the effective background color through a widget subtree.
///
/// Consumers should use [colorOf] instead of reaching into an ancestor. A
/// subtree without a [Surface] falls back to the theme surface color.
class Surface extends InheritedWidget {
  const Surface({required this.color, required super.child, super.key});

  /// Background color that descendants should use for contrast decisions.
  final Color color;

  @override
  bool updateShouldNotify(covariant Surface oldWidget) =>
      color != oldWidget.color;

  /// Returns the nearest propagated color, or the theme surface color.
  static Color colorOf(BuildContext context) {
    final surface = maybeOf(context);
    if (surface != null) return surface.color;

    return Theme.of(context).colorScheme.surface;
  }

  /// Returns the nearest [Surface], or null when none encloses [context].
  static Surface? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<Surface>();
  }
}
