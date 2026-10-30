import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  final now = DateTime.utc(2026, 10, 27, 12);

  test("a join code past its expiry is expired with no time left", () {
    withClock(Clock.fixed(now), () {
      final expired = joinCode(
        "ABC123",
        createdAt: now.subtract(const Duration(days: 2)),
        expiresAt: now.subtract(const Duration(days: 1)),
      );

      expect(expired.isExpired, isTrue);
      expect(expired.neverExpires, isFalse);
      expect(expired.remainingDuration, Duration.zero);
    });
  });

  test("a join code before its expiry has the time until it left", () {
    withClock(Clock.fixed(now), () {
      final active = joinCode(
        "ABC123",
        createdAt: now.subtract(const Duration(days: 2)),
        expiresAt: now.add(const Duration(days: 7)),
      );

      expect(active.isExpired, isFalse);
      expect(active.neverExpires, isFalse);
      expect(active.remainingDuration, const Duration(days: 7));
    });
  });

  test("a join code without expiry never expires and has no deadline", () {
    withClock(Clock.fixed(now), () {
      final forever = joinCode(
        "ABC123",
        createdAt: now.subtract(const Duration(days: 2)),
      );

      expect(forever.neverExpires, isTrue);
      expect(forever.isExpired, isFalse);
      expect(forever.remainingDuration, isNull);
    });
  });
}
