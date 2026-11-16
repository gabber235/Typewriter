import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  group("Strike", () {
    for (final overshoot in [0.05, 0.10, 0.14]) {
      test(
        "peaks ${(overshoot * 100).round()}% past the target and lands on it",
        () {
          final curve = StrikeCurve(overshoot: overshoot);
          expect(
            curveSamples(curve.transform).reduce(max),
            closeTo(1 + overshoot, 0.005),
          );
          expect(curve.transform(0), 0);
          expect(curve.transform(1), 1);
        },
      );
    }
  });

  test("Carriage hits at h, recoils no more than a, and lands", () {
    const curve = CarriageCurve(hit: 0.42, recoil: 0.06);
    expect(curve.transform(0.42), closeTo(1, 1e-9));
    final after = curveSamples(curve.transform, from: 0.42);
    expect(after.reduce(min), allOf(lessThan(1), greaterThanOrEqualTo(0.94)));
    expect(curve.transform(1), 1);
  });

  test("Exit never passes the target or goes back", () {
    final values = curveSamples(exitCurve.transform);
    for (var i = 1; i < values.length; i++) {
      expect(
        values[i],
        allOf(lessThanOrEqualTo(1), greaterThanOrEqualTo(values[i - 1])),
      );
    }
  });

  for (final ratio in [0.5, 0.8, 1.0]) {
    test("a spring at ratio $ratio settles in its 800 ms", () {
      final spring = SpringMotion.settling(
        const Duration(milliseconds: 800),
        dampingRatio: ratio,
      );
      final travel = spring.simulate(from: 0, to: 1);
      final late = curveSamples(travel.x, from: 0.8, to: 3);
      // The settle time is where the spring last leaves the band, so allow
      // for rounding at its first sample.
      expect(late.every((x) => (x - 1).abs() <= 0.01 + 1e-9), isTrue);
      final early = curveSamples(travel.x, to: 0.4);
      expect(early.any((x) => (x - 1).abs() > 0.01), isTrue);
      expect(spring.duration.inMilliseconds, closeTo(800, 1));
    });
  }

  test("a spring given a new duration keeps its damping ratio", () {
    const press = SpringMotion(stiffness: 300, damping: 12);
    final shorter = press.withDuration(const Duration(milliseconds: 400));
    expect(shorter.dampingRatio, closeTo(press.dampingRatio, 1e-9));
    expect(shorter.duration.inMilliseconds, closeTo(400, 1));
  });

  test("a curve move leaves at the velocity it was given and still lands", () {
    final travel = const CurveMotion(
      exitCurve,
      Duration(milliseconds: 200),
    ).simulate(from: 0, to: 0, velocity: 5);
    expect(travel.dx(0), closeTo(5, 0.1));
    expect(travel.x(0.2), 0);
  });

  test("a loop of one round ends at rest", () {
    final loop = const LoopMotion(
      curve: Curves.easeInOut,
      period: Duration(milliseconds: 620),
      cycles: 1,
    ).simulate(from: 0, to: 1);
    expect(loop.x(0.31), closeTo(1, 1e-9));
    expect(loop.isDone(0.62), isTrue);
    expect(loop.x(0.7), 0);
  });

  test("a judder swings past half its unit and rests on the target", () {
    final jam = const JudderMotion(
      duration: Duration(milliseconds: 400),
      cycles: 4,
    ).simulate(from: 0, to: 0);
    expect(
      curveSamples(jam.x, to: 0.4).map((x) => x.abs()).reduce(max),
      greaterThan(0.5),
    );
    expect(jam.x(0.4), 0);
  });

  test("typing shows one more letter every 36 ms and stops at the word", () {
    final typing = const StepMotion(Duration(milliseconds: 36))
        .simulate(from: 0, to: 5);
    expect(typing.x(0.035), 0);
    expect(typing.x(0.036), 1);
    expect(typing.x(1), 5);
    expect(typing.isDone(0.18), isTrue);
  });
}
