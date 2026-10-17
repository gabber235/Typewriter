import "package:typewriter_panel/typewriter_panel.dart";

/// Paints one animated decoration and publishes its displayed surface.
///
/// Supply the raw fill in [decoration], including its authored opacity. The
/// parent surface is composed each frame, so parent changes do not restart a
/// tween of an already composed color. [foregroundFor] receives that effective
/// displayed background and can keep contrast correct during a transition.
/// An explicit [foreground] interpolates instead. These options are exclusive.
/// With neither option, an explicit fill derives contrast and no fill inherits.
class SurfaceContainer extends ImplicitlyAnimatedWidget {
  const SurfaceContainer({
    required this.decoration,
    required super.duration,
    required this.child,
    this.foreground,
    this.foregroundFor,
    this.secondaryForeground,
    this.padding,
    this.width,
    this.height,
    super.curve,
    super.onEnd,
    super.key,
  }) : assert(foreground == null || foregroundFor == null);

  final BoxDecoration decoration;
  final Color? foreground;
  final Color Function(BuildContext, Color)? foregroundFor;
  final Color? secondaryForeground;
  final EdgeInsetsGeometry? padding;
  final double? width;
  final double? height;
  final Widget child;

  @override
  AnimatedWidgetBaseState<SurfaceContainer> createState() =>
      _SurfaceContainerState();
}

class _SurfaceContainerState extends AnimatedWidgetBaseState<SurfaceContainer> {
  DecorationTween? _decoration;
  EdgeInsetsGeometryTween? _padding;
  Tween<double>? _width;
  Tween<double>? _height;
  ColorTween? _foreground;

  @override
  void forEachTween(TweenVisitor<dynamic> visitor) {
    _decoration = visitor(
      _decoration,
      widget.decoration,
      (dynamic value) => DecorationTween(begin: value as BoxDecoration),
    ) as DecorationTween?;
    _padding = visitor(
      _padding,
      widget.padding,
      (dynamic value) =>
          EdgeInsetsGeometryTween(begin: value as EdgeInsetsGeometry),
    ) as EdgeInsetsGeometryTween?;
    _width = visitor(
      _width,
      widget.width,
      (dynamic value) => Tween<double>(begin: value as double),
    ) as Tween<double>?;
    _height = visitor(
      _height,
      widget.height,
      (dynamic value) => Tween<double>(begin: value as double),
    ) as Tween<double>?;
    _foreground = visitor(
      _foreground,
      widget.foreground,
      (dynamic value) => ColorTween(begin: value as Color),
    ) as ColorTween?;
  }

  @override
  Widget build(BuildContext context) {
    final decoration =
        (_decoration?.evaluate(animation) ?? widget.decoration)
            as BoxDecoration;
    final fill = decoration.color ?? Colors.transparent;
    final effective = Color.alphaBlend(fill, Surface.colorOf(context));
    final foreground =
        widget.foregroundFor?.call(context, effective) ??
        _foreground?.evaluate(animation) ??
        (decoration.color == null ? null : effective.on(context));
    return Container(
      decoration: decoration,
      padding: _padding?.evaluate(animation),
      width: _width?.evaluate(animation),
      height: _height?.evaluate(animation),
      child: Surface(
        color: fill,
        foreground: foreground,
        secondaryForeground: widget.secondaryForeground,
        child: widget.child,
      ),
    );
  }
}
