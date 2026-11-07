import "package:typewriter_panel/typewriter_panel.dart";

/// The clock and fill of one hold.
///
/// [onComplete] runs once the key or pointer has been down for the hold
/// token's duration in total. Time released runs the clock back at the
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
  late final Ticker _ticker;
  late ResolvedMotion<NoLanding> _motion;
  Duration _held = Duration.zero;
  Duration _lastTick = Duration.zero;
  bool _down = false;
  bool _done = false;

  bool get isDown => _down;
  bool get isDone => _done;

  /// Starts or continues the hold with the hold token as resolved for the
  /// widget that owns it.
  void press(ResolvedMotion<NoLanding> motion) {
    if (_down || _done) return;
    _motion = motion;
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
  void completeNow(ResolvedMotion<NoLanding> motion) {
    if (_done) return;
    _motion = motion;
    _finish();
  }

  /// Back to empty after the action ran or failed, ready for the next hold.
  void reset() {
    _ticker.stop();
    _held = Duration.zero;
    _down = false;
    _done = false;
    fill.jumpTo(0);
  }

  void _tick(Duration elapsed) {
    final step = elapsed - _lastTick;
    _lastTick = elapsed;
    if (_down) {
      _held += step;
      if (_held >= _motion.motion.duration) _finish();
      return;
    }
    _held -= step;
    if (_held > Duration.zero) return;
    _held = Duration.zero;
    _ticker.stop();
  }

  void _finish() {
    _ticker.stop();
    _done = true;
    _down = false;
    fill.to(1, _motion.instant);
    onComplete();
  }

  void dispose() {
    _ticker.dispose();
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
    final inPlace =
        resolveMotion(context, MotionToken.hold).reduced == ReducedKind.paced;
    final press = context.motion.spec(MotionToken.press).landing;
    final color =
        this.color ??
        context.colors.danger.withValues(
          alpha: context.stateTokens.pressedOpacity,
        );
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
