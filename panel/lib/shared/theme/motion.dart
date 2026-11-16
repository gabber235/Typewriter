import "package:typewriter_panel/typewriter_panel.dart";

/// Travel within this share of the distance counts as settled.
const _settleBand = 0.01;

/// The share of a move a velocity is measured over.
const _slopeStep = 0.005;

/// How a value travels to a target. Every motion token holds one, and a
/// `MotionController` turns it into a [Simulation] that starts from the
/// value and velocity on screen.
sealed class Motion {
  const Motion();

  /// The travel from [from] to [to], leaving at [velocity] units per second.
  Simulation simulate({
    required double from,
    required double to,
    double velocity = 0,
  });

  /// How long the travel takes. For a spring, the time after which it
  /// stays within 1% of the distance; for a loop, one round; for a step
  /// motion, one step.
  Duration get duration;

  /// The same move taking [duration]. A spring keeps its damping ratio.
  Motion withDuration(Duration duration);

  /// The same timing with no travel past the target, for `paced` tokens
  /// under reduced motion.
  Motion get paced;

  /// Lands at once.
  static const Motion instant = InstantMotion();
}

/// The key strike: `1 - e^(-z*w*t) * (cos(wd*t) + (z*w/wd) * sin(wd*t))`
/// with `w = 5/z`, `wd = w*sqrt(1 - z*z)` and
/// `z = -ln(o) / sqrt(pi^2 + ln(o)^2)`, which peaks at `1 + o`.
final class StrikeCurve extends Curve {
  const StrikeCurve({required this.overshoot})
    : assert(overshoot > 0 && overshoot < 1);

  final double overshoot;

  @override
  double transformInternal(double t) {
    final lnO = log(overshoot);
    final z = -lnO / sqrt(pi * pi + lnO * lnO);
    final w = 5 / z;
    final wd = w * sqrt(1 - z * z);
    return 1 - exp(-z * w * t) * (cos(wd * t) + (z * w / wd) * sin(wd * t));
  }
}

/// The carriage return: `1 - (1 - t/h)^1.6` until it hits at [hit], then
/// `1 - a * sin(pi*p) * (1 - p)^1.2` with `p = (t - h) / (1 - h)`.
/// [hit] defaults to rowIn's, since a service sends only the recoil.
final class CarriageCurve extends Curve {
  const CarriageCurve({required this.recoil, this.hit = 0.42})
    : assert(hit > 0 && hit < 1),
      assert(recoil >= 0 && recoil < 1);

  final double hit;
  final double recoil;

  @override
  double transformInternal(double t) {
    if (t < hit) return 1 - pow(1 - t / hit, 1.6).toDouble();
    final p = (t - hit) / (1 - hit);
    return 1 - recoil * sin(pi * p) * pow(1 - p, 1.2);
  }
}

/// Leaving: fast away, no bounce.
const Curve exitCurve = Cubic(0.4, 0, 0.2, 1);

/// A move along [curve] over [duration].
final class CurveMotion extends Motion {
  const CurveMotion(this.curve, this.duration);

  final Curve curve;

  @override
  final Duration duration;

  @override
  Simulation simulate({
    required double from,
    required double to,
    double velocity = 0,
  }) => CurveSimulation(
    curve: curve,
    duration: duration,
    from: from,
    to: to,
    velocity: velocity,
  );

  @override
  CurveMotion withDuration(Duration duration) => CurveMotion(curve, duration);

  @override
  CurveMotion get paced => switch (curve) {
    StrikeCurve() || CarriageCurve() => CurveMotion(exitCurve, duration),
    _ => this,
  };
}

/// Follows [curve] over [duration] and carries the starting [velocity]
/// into the first part of the travel, so a retarget never kinks.
final class CurveSimulation extends Simulation {
  CurveSimulation({
    required this.curve,
    required Duration duration,
    required this.from,
    required this.to,
    this.velocity = 0,
  }) : _seconds = duration.inMicroseconds / Duration.microsecondsPerSecond;

  final Curve curve;
  final double from;
  final double to;
  final double velocity;
  final double _seconds;

  double _progress(double time) =>
      _seconds == 0 ? 1 : (time / _seconds).clamp(0.0, 1.0);

  @override
  double x(double time) {
    final p = _progress(time);
    // Leaves at the given velocity and is gone when p reaches 1.
    final carry = velocity * _seconds * p * (1 - p) * (1 - p);
    return from + (to - from) * curve.transform(p) + carry;
  }

  @override
  double dx(double time) {
    // Cubic curves solve to 0.001 of their input, so a smaller step reads
    // a flat stretch of the curve.
    final step = max(_seconds * _slopeStep, 1e-6);
    final before = max(0, time - step).toDouble();
    final after = time + step;
    return (x(after) - x(before)) / (after - before);
  }

  @override
  bool isDone(double time) => time >= _seconds;
}

/// A spring of mass 1 given as [stiffness] and [damping].
final class SpringMotion extends Motion {
  const SpringMotion({required this.stiffness, required this.damping});

  /// The spring that settles in [settle] at [dampingRatio]; 1 is critical.
  factory SpringMotion.settling(
    Duration settle, {
    required double dampingRatio,
  }) {
    assert(dampingRatio > 0 && settle > Duration.zero);
    final ratio = dampingRatio;
    final seconds = settle.inMicroseconds / Duration.microsecondsPerSecond;
    final natural = _settleProduct(ratio) / seconds;
    return SpringMotion(
      stiffness: natural * natural,
      damping: 2 * ratio * natural,
    );
  }

  final double stiffness;
  final double damping;

  /// Damping over critical damping: under 1 bounces, 1 lands without one.
  double get dampingRatio => damping / (2 * sqrt(stiffness));

  @override
  Duration get duration {
    final seconds = _settleProduct(dampingRatio) / sqrt(stiffness);
    return Duration(microseconds: (seconds * 1e6).round());
  }

  @override
  Simulation simulate({
    required double from,
    required double to,
    double velocity = 0,
  }) {
    final span = max((to - from).abs(), 1.0);
    return SpringSimulation(
      SpringDescription(mass: 1, stiffness: stiffness, damping: damping),
      from,
      to,
      velocity,
      tolerance: Tolerance(
        distance: span * _settleBand / 10,
        velocity: span * _settleBand,
      ),
    );
  }

  @override
  SpringMotion withDuration(Duration duration) =>
      SpringMotion.settling(duration, dampingRatio: dampingRatio);

  @override
  SpringMotion get paced => SpringMotion.settling(duration, dampingRatio: 1);
}

/// The product of natural frequency and settle time at which a unit step
/// of a spring at [ratio] stays inside the settle band.
double _settleProduct(double ratio) {
  if (ratio < 1) {
    return log(1 / (_settleBand * sqrt(1 - ratio * ratio))) / ratio;
  }
  // Within rounding of critical damping the underdamped bound diverges.
  if ((ratio - 1).abs() < 1e-6) {
    // Solves (1 + x) e^-x = band with Newton's method.
    var x = 6.0;
    for (var i = 0; i < 8; i++) {
      final value = (1 + x) * exp(-x) - _settleBand;
      final slope = -x * exp(-x);
      x -= value / slope;
    }
    return x;
  }
  return log(1 / _settleBand) / (ratio - sqrt(ratio * ratio - 1));
}

/// A hold: the [fill] springs to show it, and the key or pointer must stay
/// down for [duration] in total. The clock in `HoldClock` decides.
final class HoldMotion extends Motion {
  const HoldMotion({required this.fill, required this.duration});

  final SpringMotion fill;

  @override
  final Duration duration;

  @override
  Simulation simulate({
    required double from,
    required double to,
    double velocity = 0,
  }) => fill.simulate(from: from, to: to, velocity: velocity);

  @override
  HoldMotion withDuration(Duration duration) =>
      HoldMotion(fill: fill.withDuration(duration), duration: duration);

  @override
  HoldMotion get paced => HoldMotion(fill: fill.paced, duration: duration);
}

/// Lands at once.
final class InstantMotion extends Motion {
  const InstantMotion();

  @override
  Simulation simulate({
    required double from,
    required double to,
    double velocity = 0,
  }) => _LandedSimulation(to);

  @override
  Duration get duration => Duration.zero;

  @override
  InstantMotion withDuration(Duration duration) => this;

  @override
  InstantMotion get paced => this;
}

final class _LandedSimulation extends Simulation {
  _LandedSimulation(this.to);

  final double to;

  @override
  double x(double time) => to;

  @override
  double dx(double time) => 0;

  @override
  bool isDone(double time) => true;
}

/// Goes from `from` to `to` and back on [curve] every [period], for
/// [cycles] rounds or without end. Only busy words and skeletons loop.
final class LoopMotion extends Motion {
  const LoopMotion({required this.curve, required this.period, this.cycles})
    : assert(cycles == null || cycles >= 0);

  final Curve curve;
  final Duration period;
  final int? cycles;

  /// This loop, playing at most [limit] rounds.
  LoopMotion limitedTo(int limit) => LoopMotion(
    curve: curve,
    period: period,
    cycles: cycles == null ? limit : min(cycles!, limit),
  );

  @override
  Duration get duration => period;

  @override
  Simulation simulate({
    required double from,
    required double to,
    double velocity = 0,
  }) => _LoopSimulation(this, from, to);

  @override
  LoopMotion withDuration(Duration duration) =>
      LoopMotion(curve: curve, period: duration, cycles: cycles);

  @override
  LoopMotion get paced => this;
}

final class _LoopSimulation extends Simulation {
  _LoopSimulation(this.motion, this.from, this.to)
    : _period = motion.period.inMicroseconds / Duration.microsecondsPerSecond;

  final LoopMotion motion;
  final double from;
  final double to;
  final double _period;

  @override
  double x(double time) {
    if (isDone(time)) return from;
    final phase = (time / _period) % 1;
    final there = phase < 0.5 ? phase * 2 : (1 - phase) * 2;
    return from + (to - from) * motion.curve.transform(there);
  }

  @override
  double dx(double time) {
    final step = max(_period * _slopeStep, 1e-6);
    return (x(time + step) - x(time)) / step;
  }

  @override
  bool isDone(double time) {
    final cycles = motion.cycles;
    return cycles != null && time >= cycles * _period;
  }
}

/// Moves a count one whole step every [step]: letters typing in or out.
final class StepMotion extends Motion {
  const StepMotion(this.step);

  final Duration step;

  @override
  Duration get duration => step;

  @override
  Simulation simulate({
    required double from,
    required double to,
    double velocity = 0,
  }) => _StepSimulation(from.roundToDouble(), to.roundToDouble(), step);

  @override
  StepMotion withDuration(Duration duration) => StepMotion(duration);

  @override
  StepMotion get paced => this;
}

final class _StepSimulation extends Simulation {
  _StepSimulation(this.from, this.to, Duration step)
    : _step = step.inMicroseconds / Duration.microsecondsPerSecond;

  final double from;
  final double to;
  final double _step;

  double get _distance => (to - from).abs();

  int _steps(double time) =>
      _step == 0 ? _distance.toInt() : (time / _step).floor();

  @override
  double x(double time) =>
      from + (to - from).sign * min(_steps(time), _distance);

  @override
  double dx(double time) => 0;

  @override
  bool isDone(double time) => _steps(time) >= _distance;
}

/// A jam: [cycles] decaying swings around the target over [duration],
/// then rest on it. The swing is a unit; the landing scales it to pixels.
final class JudderMotion extends Motion {
  const JudderMotion({required this.duration, required this.cycles});

  @override
  final Duration duration;
  final int cycles;

  @override
  Simulation simulate({
    required double from,
    required double to,
    double velocity = 0,
  }) => _JudderSimulation(to, duration, cycles, 1);

  /// The judder as a horizontal offset in pixels that swings [amplitude]
  /// and ends at zero, for a jam to play directly.
  Simulation swing(double amplitude) =>
      _JudderSimulation(0, duration, cycles, amplitude);

  @override
  JudderMotion withDuration(Duration duration) =>
      JudderMotion(duration: duration, cycles: cycles);

  @override
  JudderMotion get paced => this;
}

final class _JudderSimulation extends Simulation {
  _JudderSimulation(this.to, Duration duration, this.cycles, this.amplitude)
    : _seconds = duration.inMicroseconds / Duration.microsecondsPerSecond;

  final double to;
  final int cycles;
  final double amplitude;
  final double _seconds;

  @override
  double x(double time) {
    if (isDone(time)) return to;
    final p = time / _seconds;
    return to + amplitude * sin(2 * pi * cycles * p) * (1 - p);
  }

  @override
  double dx(double time) {
    final step = max(_seconds * _slopeStep, 1e-6);
    return (x(time + step) - x(time)) / step;
  }

  @override
  bool isDone(double time) => time >= _seconds;
}
