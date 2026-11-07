import "package:typewriter_panel/typewriter_panel.dart";

/// A token sampled into the Duration and Curve that framework APIs take.
/// Reduced motion is already applied by resolveMotion: a jump token
/// samples to [instant].
@immutable
final class MotionTimeline {
  const MotionTimeline(this.duration, this.curve);

  static const instant = MotionTimeline(Duration.zero, Curves.linear);

  final Duration duration;
  final Curve curve;

  /// Arrive with this timeline and leave with [leave].
  AnimationStyle styleWith(MotionTimeline leave) => AnimationStyle(
    duration: duration,
    curve: curve,
    reverseDuration: leave.duration,
    reverseCurve: leave.curve.flipped,
  );
}

/// Samples [token] once into a timeline for framework APIs.
MotionTimeline motionTimeline<L extends Landing>(
  BuildContext context,
  MotionToken<L> token, {
  MotionOverride? override,
}) {
  final simulation = resolveMotion(
    context,
    token,
    override: override,
  ).simulate(from: 0, to: 1);
  if (simulation.isDone(0)) return MotionTimeline.instant;
  final seconds = _settleSeconds(simulation);
  return MotionTimeline(
    Duration(microseconds: (seconds * Duration.microsecondsPerSecond).round()),
    _SimulationCurve(simulation, seconds),
  );
}

// 240 Hz steps; the cap only guards a simulation that never reports done.
double _settleSeconds(Simulation simulation) {
  const step = 1 / 240;
  const cap = 10.0;
  var t = step;
  while (!simulation.isDone(t) && t < cap) {
    t += step;
  }
  return t;
}

final class _SimulationCurve extends Curve {
  const _SimulationCurve(this.simulation, this.seconds);

  final Simulation simulation;
  final double seconds;

  // Values above 1 are the landing overshoot; Curve.transform pins 0 and 1.
  @override
  double transformInternal(double t) => simulation.x(t * seconds);
}
