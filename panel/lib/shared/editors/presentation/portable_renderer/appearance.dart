part of "../portable_presentation_renderer.dart";

class _PresentationSurface extends StatelessWidget {
  const _PresentationSurface({
    required this.style,
    required this.scope,
    required this.diagnostic,
    required this.child,
  });

  final skir.ContainerLayout style;
  final PortablePresentationScope scope;
  final Widget Function(String) diagnostic;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final inherited = Surface.appearanceOf(context);
    try {
      if (style.transitionMilliseconds < 0) {
        throw const PresentationColorFailure(
          "Presentation duration cannot be negative",
        );
      }
      final resolver = PresentationColorEnvironment.of(
        context,
        appearance: inherited,
      );
      final source = style.backgroundColor;
      final fill = source == null ? null : resolver.resolve(source, scope);
      final background = Color.alphaBlend(
        fill ?? Colors.transparent,
        inherited.color,
      );
      final hasForeground = source != null || style.foregroundColor != null;

      Color foregroundFor(BuildContext context, Color displayed) {
        final foregroundSource = style.foregroundColor;
        return foregroundSource == null
            ? displayed.on(context)
            : PresentationColorEnvironment.of(
                context,
                appearance: inherited.copyWith(color: displayed),
              ).resolve(foregroundSource, scope);
      }

      final foreground = hasForeground
          ? foregroundFor(context, background)
          : inherited.foreground;
      final local = inherited.copyWith(
        color: background,
        foreground: foreground,
        secondaryForeground: hasForeground
            ? Color.alphaBlend(
                foreground.withValues(alpha: foreground.a * 0.7),
                background,
              )
            : inherited.secondaryForeground,
      );
      return SurfaceContainer(
        duration: Duration(milliseconds: style.transitionMilliseconds),
        decoration: BoxDecoration(
          color: fill,
          border: _border(context, style.border, scope, appearance: local),
          borderRadius: _radius(context, style.radius, scope),
        ),
        foregroundFor: hasForeground ? foregroundFor : null,
        child: child,
      );
    } on PresentationColorFailure catch (failure) {
      return diagnostic(failure.message);
    }
  }
}
