import "package:typewriter_panel/typewriter_panel.dart";

/// The clock and fill of one hold.
///
/// [onComplete] runs once the key or pointer has been down for the hold
/// token's duration in total; the token comes with each press, so the
/// weight of the hold sets its length. Time released runs the clock back at the
/// same rate, so a re-press continues from where the fill is. The fill
/// springs with the token and only shows the clock.
final class HoldClock {
  HoldClock({required TickerProvider vsync, required this.onComplete})
    : fill = MotionController(vsync: vsync) {
    _ticker = vsync.createTicker(_tick);
  }

  final VoidCallback onComplete;

  /// 0 to 1 as the hold fills; listen to paint it.
  final MotionController fill;

  /// The share of the hold's time held so far, 0 to 1: the clock itself,
  /// with no spring. A tremble reads it.
  ValueListenable<double> get share => _share;
  final _share = ValueNotifier<double>(0);

  /// The hold token as resolved for the last press, or null before one.
  ResolvedMotion<HoldLanding>? get motion => _pressed ? _motion : null;
  var _pressed = false;
  late final Ticker _ticker;
  late ResolvedMotion<HoldLanding> _motion;
  Duration _held = Duration.zero;
  Duration _lastTick = Duration.zero;
  bool _down = false;
  bool _done = false;

  bool get isDown => _down;
  bool get isDone => _done;

  /// Starts or continues the hold with the hold token as resolved for the
  /// widget that owns it.
  void press(ResolvedMotion<HoldLanding> motion) {
    if (_down || _done) return;
    _motion = motion;
    _pressed = true;
    _down = true;
    fill.to(1, motion);
    if (!_ticker.isActive) {
      _lastTick = Duration.zero;
      _ticker.start();
    }
  }

  /// Releases the hold; the fill and the clock run back.
  void release() {
    if (!_down || _done) return;
    _down = false;
    fill.to(0, _motion);
  }

  /// Completes at once, for the screen reader long press.
  void completeNow(ResolvedMotion<HoldLanding> motion) {
    if (_done) return;
    _motion = motion;
    _pressed = true;
    _finish();
  }

  /// Back to empty after the action ran or failed, ready for the next hold.
  void reset() {
    _ticker.stop();
    _held = Duration.zero;
    _down = false;
    _done = false;
    _share.value = 0;
    fill.jumpTo(0);
  }

  void _tick(Duration elapsed) {
    final step = elapsed - _lastTick;
    _lastTick = elapsed;
    if (_down) {
      _held += step;
      if (_held >= _motion.motion.duration) {
        _finish();
        return;
      }
      _share.value =
          _held.inMicroseconds / _motion.motion.duration.inMicroseconds;
      return;
    }
    _held -= step;
    if (_held > Duration.zero) {
      _share.value =
          _held.inMicroseconds / _motion.motion.duration.inMicroseconds;
      return;
    }
    _held = Duration.zero;
    _share.value = 0;
    _ticker.stop();
  }

  void _finish() {
    _ticker.stop();
    _done = true;
    _down = false;
    _share.value = 1;
    fill.to(1, _motion.instant);
    onComplete();
  }

  void dispose() {
    _ticker.dispose();
    _share.dispose();
    fill.dispose();
  }
}

/// Paints a hold's [fill] behind [child]: it sweeps from the leading edge,
/// and grows in place as a tint under reduced motion. [pressed] shows the
/// busy look, pressed in, while the held action runs. A null [fill]
/// paints nothing.
class HoldFill extends StatelessWidget {
  const HoldFill({
    required this.child,
    this.fill,
    this.pressed = false,
    this.color,
    this.borderRadius,
    super.key,
  });

  final Widget child;
  final Animation<double>? fill;
  final bool pressed;
  final Color? color;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final inPlace = _fillsInPlace(context);
    final press = context.motion.spec(MotionToken.press).landing;
    final color = this.color ?? context.holdFillColor;
    final radius = borderRadius ?? BorderRadius.circular(context.shapes.medium);
    Widget painted(double amount) => CustomPaint(
      painter: _HoldFillPainter(
        amount: amount,
        color: color,
        radius: radius,
        inPlace: inPlace,
        direction: Directionality.of(context),
      ),
      child: child,
    );
    final body = fill == null
        ? (pressed ? painted(1) : child)
        : AnimatedBuilder(
            animation: fill!,
            builder: (context, _) => painted(fill!.value.clamp(0.0, 1.0)),
          );
    if (!pressed) return body;
    // Pressed in, still: the press landing's sink with no travel.
    return Transform.translate(offset: Offset(0, press.sink), child: body);
  }
}

class _HoldFillPainter extends CustomPainter {
  _HoldFillPainter({
    required this.amount,
    required this.color,
    required this.radius,
    required this.inPlace,
    required this.direction,
  });

  final double amount;
  final Color color;
  final BorderRadius radius;
  final bool inPlace;
  final TextDirection direction;

  @override
  void paint(Canvas canvas, Size size) {
    if (amount == 0) return;
    final whole = Offset.zero & size;
    canvas.clipRRect(radius.toRRect(whole));
    if (inPlace) {
      canvas.drawRect(
        whole,
        Paint()..color = color.withValues(alpha: color.a * amount),
      );
      return;
    }
    final width = size.width * amount;
    final left = direction == TextDirection.ltr ? 0.0 : size.width - width;
    canvas.drawRect(
      Rect.fromLTWH(left, 0, width, size.height),
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(_HoldFillPainter old) =>
      old.amount != amount ||
      old.color != color ||
      old.radius != radius ||
      old.inPlace != inPlace ||
      old.direction != direction;
}

/// Whether a hold fills in place, as reduced motion paces every hold
/// weight alike.
bool _fillsInPlace(BuildContext context) =>
    resolveMotion(context, MotionToken.holdLight).reduced == ReducedKind.paced;

/// The colours a hold fills with.
extension HoldFillColors on BuildContext {
  /// The fill of a row, or of a flat or outlined button: red.
  Color get holdFillColor =>
      colors.danger.withValues(alpha: stateTokens.holdOpacity);

  /// The fill over a filled button, whose own colour red would not show on:
  /// black.
  Color get holdFillOnFilledColor =>
      colors.shadow.withValues(alpha: stateTokens.holdOnFilledOpacity);
}

/// [HoldFill] as a decoration, for a TableRow, which is not a widget.
///
/// It paints the same sweep, or the in place tint under reduced motion, with
/// the same painter. Its box painter listens to [amount] and asks the table
/// to repaint, so a hold repaints the table and rebuilds nothing.
class HoldFillDecoration extends Decoration {
  const HoldFillDecoration({
    required this.amount,
    required this.color,
    required this.inPlace,
    this.base,
  });

  /// HoldFill's colour and reduced motion, resolved from [context].
  factory HoldFillDecoration.of(
    BuildContext context, {
    required ValueListenable<double> amount,
    Decoration? base,
  }) {
    return HoldFillDecoration(
      amount: amount,
      color: context.holdFillColor,
      inPlace: _fillsInPlace(context),
      base: base,
    );
  }

  final ValueListenable<double> amount;
  final Color color;
  final bool inPlace;

  /// The row's own decoration, painted under the fill.
  final Decoration? base;

  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) {
    return _HoldFillBoxPainter(this, onChanged);
  }
}

class _HoldFillBoxPainter extends BoxPainter {
  _HoldFillBoxPainter(this.decoration, super.onChanged)
    : _base = onChanged == null
          ? decoration.base?.createBoxPainter()
          : decoration.base?.createBoxPainter(onChanged) {
    if (onChanged case final repaint?) decoration.amount.addListener(repaint);
  }

  final HoldFillDecoration decoration;
  final BoxPainter? _base;

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    _base?.paint(canvas, offset, configuration);
    final size = configuration.size;
    if (size == null) return;
    canvas
      ..save()
      ..translate(offset.dx, offset.dy);
    _HoldFillPainter(
      amount: decoration.amount.value.clamp(0.0, 1.0),
      color: decoration.color,
      radius: BorderRadius.zero,
      inPlace: decoration.inPlace,
      direction: configuration.textDirection ?? TextDirection.ltr,
    ).paint(canvas, size);
    canvas.restore();
  }

  @override
  void dispose() {
    if (onChanged case final repaint?) {
      decoration.amount.removeListener(repaint);
    }
    _base?.dispose();
    super.dispose();
  }
}

/// How a held button gives way under the hold: it sinks from the landing's
/// first depth to its full depth and shrinks to its scale as the [fill]
/// grows, trembles once in the landing's window of the clock's [share], and
/// springs back with `press` once the hold lets go of it.
///
/// A null [fill] is a button nobody holds. [motion] is the hold token as
/// the clock resolved it; under reduced motion the hold has no travel, so
/// nothing sinks or trembles and only the fill shows it.
class HoldPress extends HookWidget {
  const HoldPress({
    required this.child,
    this.fill,
    this.share,
    this.motion,
    super.key,
  });

  final Widget child;
  final Animation<double>? fill;
  final ValueListenable<double>? share;
  final ResolvedMotion<HoldLanding>? motion;

  @override
  Widget build(BuildContext context) {
    final back = useMotionController();
    final press = resolveMotion(context, MotionToken.press);
    final held = fill;
    final landing = motion?.landing;
    final travels = motion?.travels ?? false;
    // Where the button stood when the hold let go, so the spring back starts
    // from there.
    final last = useRef(_Give.none);
    final wasHeld = useRef(false);
    useEffect(() {
      final letGo = wasHeld.value && held == null;
      wasHeld.value = held != null;
      if (letGo && last.value != _Give.none) back.restart(1, 0, press);
      return null;
    }, [held]);

    if (held == null || landing == null || !travels) {
      return AnimatedBuilder(
        animation: back,
        builder: (context, child) =>
            last.value.scaledBy(back.value).apply(child!),
        child: child,
      );
    }
    return AnimatedBuilder(
      animation: Listenable.merge([held, ?share]),
      builder: (context, child) {
        final amount = held.value.clamp(0.0, 1.0);
        final give = amount == 0
            ? _Give.none
            : _Give(
                sink:
                    landing.sinkFrom +
                    (landing.sink - landing.sinkFrom) * amount,
                shrink: (1 - landing.scale) * amount,
                sway: landing.swayAt(share?.value ?? 0),
              );
        last.value = give;
        return give.apply(child!);
      },
      child: child,
    );
  }
}

/// How far a held button has given way.
@immutable
final class _Give {
  const _Give({required this.sink, required this.shrink, required this.sway});

  static const none = _Give(sink: 0, shrink: 0, sway: 0);

  final double sink;
  final double shrink;
  final double sway;

  _Give scaledBy(double t) =>
      _Give(sink: sink * t, shrink: shrink * t, sway: sway * t);

  /// [child] moved and shrunk by this much. The same two transforms wrap it
  /// at rest, so the button keeps its state and focus when a hold starts.
  Widget apply(Widget child) => Transform.translate(
    offset: Offset(sway, sink),
    child: Transform.scale(scale: 1 - shrink, child: child),
  );
}

/// The tremble of a hold.
extension HoldTremble on HoldLanding {
  /// The sideways offset at [share] of the hold's time: one full swing
  /// between [HoldLanding.trembleFrom] and [HoldLanding.trembleTo], still
  /// before and after.
  double swayAt(double share) {
    if (share <= trembleFrom || share >= trembleTo) return 0;
    final t = (share - trembleFrom) / (trembleTo - trembleFrom);
    return tremble * sin(2 * pi * t);
  }
}
