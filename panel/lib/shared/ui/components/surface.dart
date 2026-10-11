import "package:typewriter_panel/typewriter_panel.dart";

part "surface.freezed.dart";

@freezed
abstract class SurfaceAppearance with _$SurfaceAppearance {
  const factory SurfaceAppearance({
    required Color color,
    required Color foreground,
    required Color secondaryForeground,
  }) = _SurfaceAppearance;
}

/// Publishes the effective background and foreground of a painted surface.
///
/// This widget observes a fill painted by its owner. Translucent [color] is
/// composed over the parent observation. Omitted foregrounds inherit; supplied
/// foregrounds also scope ordinary text, theme typography, and icons. Explicit
/// leaf colors and Material component palettes keep their own meaning.
class Surface extends StatelessWidget {
  const Surface({
    required this.color,
    required this.child,
    this.foreground,
    this.secondaryForeground,
    super.key,
  });

  final Color color;
  final Color? foreground;
  final Color? secondaryForeground;
  final Widget child;

  static SurfaceAppearance? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_SurfaceScope>()?.value;

  static SurfaceAppearance appearanceOf(BuildContext context) =>
      maybeOf(context) ??
      SurfaceAppearance(
        color: Theme.of(context).colorScheme.surface,
        foreground:
            DefaultTextStyle.of(context).style.color ??
            Theme.of(context).colorScheme.onSurface,
        secondaryForeground: context.colors.contentSecondary,
      );

  static Color colorOf(BuildContext context) => appearanceOf(context).color;
  static Color foregroundOf(BuildContext context) =>
      appearanceOf(context).foreground;
  static Color secondaryForegroundOf(BuildContext context) =>
      appearanceOf(context).secondaryForeground;

  @override
  Widget build(BuildContext context) {
    final inherited = appearanceOf(context);
    final effective = Color.alphaBlend(color, inherited.color);
    final selectedForeground = foreground ?? inherited.foreground;
    final value = SurfaceAppearance(
      color: effective,
      foreground: selectedForeground,
      secondaryForeground:
          secondaryForeground ??
          (foreground == null
              ? inherited.secondaryForeground
              : Color.alphaBlend(
                  selectedForeground.withValues(
                    alpha: selectedForeground.a * 0.7,
                  ),
                  effective,
                )),
    );
    var content = child;
    if (foreground != null) {
      final theme = Theme.of(context);
      content = Theme(
        data: theme.copyWith(
          textTheme: theme.textTheme.apply(
            bodyColor: selectedForeground,
            displayColor: selectedForeground,
          ),
        ),
        child: DefaultTextStyle.merge(
          style: TextStyle(color: selectedForeground),
          child: IconTheme.merge(
            data: IconThemeData(color: selectedForeground),
            child: child,
          ),
        ),
      );
    }
    return _SurfaceScope(value: value, child: content);
  }
}

class _SurfaceScope extends InheritedTheme {
  const _SurfaceScope({required this.value, required super.child});
  final SurfaceAppearance value;

  @override
  bool updateShouldNotify(_SurfaceScope oldWidget) => value != oldWidget.value;

  @override
  Widget wrap(BuildContext context, Widget child) =>
      _SurfaceScope(value: value, child: child);
}
