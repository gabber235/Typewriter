class RelativeTimeDescription {
  const RelativeTimeDescription({
    required this.compact,
    required this.natural,
    required this.nextRefreshAt,
  });

  final String compact;
  final String natural;
  final DateTime nextRefreshAt;
}

RelativeTimeDescription describeRelativeTime({
  required DateTime value,
  required DateTime now,
}) {
  final future = value.isAfter(now);
  final elapsed = future ? value.difference(now) : now.difference(value);
  if (elapsed.inSeconds < 60) {
    return RelativeTimeDescription(
      compact: "Just now",
      natural: "Just now",
      nextRefreshAt: value.add(const Duration(minutes: 1)),
    );
  }

  final unit = _relativeUnit(elapsed);
  final amount = elapsed.inSeconds ~/ unit.duration.inSeconds;
  final compactValue = future
      ? "in ${unit.compact(amount)}"
      : "${unit.compact(amount)} ago";
  final naturalValue = future
      ? "in ${unit.natural(amount)}"
      : "${unit.natural(amount)} ago";
  final boundary = future
      ? value.subtract(unit.duration * amount)
      : value.add(unit.duration * (amount + 1));
  final nextThreshold = unit.nextThreshold;
  final threshold = future || nextThreshold == null
      ? null
      : value.add(nextThreshold);
  final nextBoundary = threshold != null && threshold.isBefore(boundary)
      ? threshold
      : boundary;

  return RelativeTimeDescription(
    compact: compactValue,
    natural: naturalValue,
    nextRefreshAt: nextBoundary.isAfter(now)
        ? nextBoundary
        : now.add(const Duration(seconds: 1)),
  );
}

_RelativeUnit _relativeUnit(Duration value) {
  if (value.inMinutes < 60) return _RelativeUnit.minute;
  if (value.inHours < 24) return _RelativeUnit.hour;
  if (value.inDays < 7) return _RelativeUnit.day;
  if (value.inDays < 30) return _RelativeUnit.week;
  if (value.inDays < 365) return _RelativeUnit.month;
  return _RelativeUnit.year;
}

enum _RelativeUnit {
  minute(Duration(minutes: 1), "m", "minute"),
  hour(Duration(hours: 1), "h", "hour"),
  day(Duration(days: 1), "d", "day"),
  week(Duration(days: 7), "w", "week"),
  month(Duration(days: 30), "mo", "month"),
  year(Duration(days: 365), "y", "year");

  const _RelativeUnit(this.duration, this.symbol, this.name);

  final Duration duration;
  final String symbol;
  final String name;

  String compact(int amount) => "$amount$symbol";

  String natural(int amount) => "$amount $name${amount == 1 ? "" : "s"}";

  Duration? get nextThreshold => switch (this) {
    _RelativeUnit.minute => const Duration(hours: 1),
    _RelativeUnit.hour => const Duration(days: 1),
    _RelativeUnit.day => const Duration(days: 7),
    _RelativeUnit.week => const Duration(days: 30),
    _RelativeUnit.month => const Duration(days: 365),
    _RelativeUnit.year => null,
  };
}
