import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  final now = DateTime.utc(2026, 10, 27, 12);

  test("a join request past its expiry is expired with no time left", () {
    withClock(Clock.fixed(now), () {
      final expired = joinRequest(
        "req-1",
        requestedAt: now.subtract(const Duration(hours: 2)),
        expiresAt: now.subtract(const Duration(hours: 1)),
      );

      expect(expired.isExpired, isTrue);
      expect(expired.remainingDuration, Duration.zero);
    });
  });

  test("a join request before its expiry has the time until it left", () {
    withClock(Clock.fixed(now), () {
      final active = joinRequest(
        "req-1",
        requestedAt: now.subtract(const Duration(hours: 2)),
        expiresAt: now.add(const Duration(hours: 1)),
      );

      expect(active.isExpired, isFalse);
      expect(active.remainingDuration, const Duration(hours: 1));
    });
  });

  test("a join request expiring this instant is expired", () {
    withClock(Clock.fixed(now), () {
      expect(
        joinRequest(
          "req-1",
          requestedAt: now.subtract(const Duration(hours: 2)),
          expiresAt: now,
        ).isExpired,
        isTrue,
      );
    });
  });
}
