import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";

void main() {
  final now = DateTime.utc(2026, 8, 22, 12);

  test("describes past values across every product threshold", () {
    final cases = <(Duration, String, String)>[
      (const Duration(seconds: 59), "Just now", "Just now"),
      (const Duration(minutes: 1), "1m ago", "1 minute ago"),
      (const Duration(minutes: 5), "5m ago", "5 minutes ago"),
      (const Duration(hours: 1), "1h ago", "1 hour ago"),
      (const Duration(days: 1), "1d ago", "1 day ago"),
      (const Duration(days: 7), "1w ago", "1 week ago"),
      (const Duration(days: 30), "1mo ago", "1 month ago"),
      (const Duration(days: 365), "1y ago", "1 year ago"),
    ];

    for (final (elapsed, compact, natural) in cases) {
      final result = describeRelativeTime(
        value: now.subtract(elapsed),
        now: now,
      );
      expect(result.compact, compact);
      expect(result.natural, natural);
    }
  });

  test("describes future values symmetrically", () {
    final result = describeRelativeTime(
      value: now.add(const Duration(hours: 2)),
      now: now,
    );

    expect(result.compact, "in 2h");
    expect(result.natural, "in 2 hours");
  });

  test("refreshes past values on the next visible unit boundary", () {
    final value = now.subtract(const Duration(minutes: 5, seconds: 20));
    final result = describeRelativeTime(value: value, now: now);

    expect(result.nextRefreshAt, now.add(const Duration(seconds: 40)));
  });

  test("refreshes future values when their visible amount decreases", () {
    final value = now.add(const Duration(minutes: 5, seconds: 20));
    final result = describeRelativeTime(value: value, now: now);

    expect(result.nextRefreshAt, now.add(const Duration(seconds: 20)));
  });

  test("refreshes at a product threshold before a larger unit boundary", () {
    final value = now.subtract(const Duration(days: 29));
    final result = describeRelativeTime(value: value, now: now);

    expect(result.compact, "4w ago");
    expect(result.nextRefreshAt, now.add(const Duration(days: 1)));
  });
}
