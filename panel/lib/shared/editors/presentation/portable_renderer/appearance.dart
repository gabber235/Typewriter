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
      final resolver = PresentationValueEnvironment.of(
        context,
        appearance: inherited,
      );
      final motion = resolver.motion(style.transition, scope);
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
            : PresentationValueEnvironment.of(
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
        duration: motion.duration,
        curve: motion.curve,
        decoration: BoxDecoration(
          color: fill,
          border: _border(context, style.border, scope, appearance: local),
          borderRadius: _radius(context, style.radius, scope),
          boxShadow: [
            for (final shadow in style.shadows)
              _boxShadow(resolver, shadow, scope),
          ],
        ),
        foregroundFor: hasForeground ? foregroundFor : null,
        child: child,
      );
    } on PresentationValueFailure catch (failure) {
      return diagnostic(failure.message);
    }
  }
}

BoxShadow _boxShadow(
  PresentationValueEnvironment environment,
  skir.PresentationShadow shadow,
  PortablePresentationScope scope,
) {
  if (!shadow.blur.isFinite ||
      shadow.blur < 0 ||
      !shadow.spread.isFinite ||
      !shadow.offsetX.isFinite ||
      !shadow.offsetY.isFinite) {
    throw const PresentationValueFailure(
      "Shadow blur must be finite and nonnegative, with finite spread and offsets",
    );
  }
  return BoxShadow(
    color: environment.resolve(shadow.color, scope),
    blurRadius: shadow.blur,
    spreadRadius: shadow.spread,
    offset: Offset(shadow.offsetX, shadow.offsetY),
  );
}
