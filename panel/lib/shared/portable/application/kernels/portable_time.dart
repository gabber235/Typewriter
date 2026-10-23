import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;

// Portable time rules shared by the text, duration, timestamp and value
// kernels: the representable ranges and the proleptic Gregorian calendar,
// computed on milliseconds since the Unix epoch so no platform date type
// limits or time zone leaks into the result.

/// The largest magnitude of a portable duration, in milliseconds.
final portableDurationLimit = BigInt.parse("9007199254740991");

/// 0001-01-01T00:00:00.000Z in milliseconds since the epoch.
final portableTimestampMinimum = BigInt.parse("-62135596800000");

/// 9999-12-31T23:59:59.999Z in milliseconds since the epoch.
final portableTimestampMaximum = BigInt.parse("253402300799999");

final _millisecondsPerDay = BigInt.from(86400000);

/// [milliseconds] as a duration; beyond the portable range fails
/// `duration_range`.
Duration portableDuration(BigInt milliseconds) {
  if (milliseconds.abs() > portableDurationLimit) {
    throw skir.PortableOperationFailure(skir.PortableFailures.durationRange);
  }
  return Duration(milliseconds: milliseconds.toInt());
}

/// The instant [milliseconds] after the epoch; outside the portable range
/// fails `timestamp_range`.
DateTime portableTimestamp(BigInt milliseconds) {
  if (milliseconds < portableTimestampMinimum ||
      milliseconds > portableTimestampMaximum) {
    throw skir.PortableOperationFailure(skir.PortableFailures.timestampRange);
  }
  return DateTime.fromMillisecondsSinceEpoch(milliseconds.toInt(), isUtc: true);
}

/// Whether [year] is a leap year of the proleptic Gregorian calendar.
bool portableIsLeapYear(int year) =>
    year % 4 == 0 && (year % 100 != 0 || year % 400 == 0);

/// The number of days of [month] (1 to 12) in [year].
int portableDaysInMonth(int year, int month) => switch (month) {
  2 => portableIsLeapYear(year) ? 29 : 28,
  4 || 6 || 9 || 11 => 30,
  _ => 31,
};

/// Days since 1970-01-01 of a proleptic Gregorian date, for any year.
BigInt portableEpochDay(int year, int month, int day) {
  // Howard Hinnant's days_from_civil, on BigInt so every int32 year fits.
  final shifted = BigInt.from(month <= 2 ? year - 1 : year);
  final era = _floorDivide(shifted, BigInt.from(400));
  final yearOfEra = shifted - era * BigInt.from(400);
  final monthIndex = (month + 9) % 12;
  final dayOfYear = (153 * monthIndex + 2) ~/ 5 + day - 1;
  final dayOfEra =
      yearOfEra * BigInt.from(365) +
      yearOfEra ~/ BigInt.from(4) -
      yearOfEra ~/ BigInt.from(100) +
      BigInt.from(dayOfYear);
  return era * BigInt.from(146097) + dayOfEra - BigInt.from(719468);
}

/// The calendar fields of [milliseconds] since the epoch, read in UTC.
skir.DateTimeFields portableCivilFields(BigInt milliseconds) {
  final days = _floorDivide(milliseconds, _millisecondsPerDay);
  final within = (milliseconds - days * _millisecondsPerDay).toInt();
  final shifted = days + BigInt.from(719468);
  final era = _floorDivide(shifted, BigInt.from(146097));
  final dayOfEra = (shifted - era * BigInt.from(146097)).toInt();
  final yearOfEra =
      (dayOfEra - dayOfEra ~/ 1460 + dayOfEra ~/ 36524 - dayOfEra ~/ 146096) ~/
      365;
  final dayOfYear =
      dayOfEra - (365 * yearOfEra + yearOfEra ~/ 4 - yearOfEra ~/ 100);
  final monthIndex = (5 * dayOfYear + 2) ~/ 153;
  final day = dayOfYear - (153 * monthIndex + 2) ~/ 5 + 1;
  final month = monthIndex < 10 ? monthIndex + 3 : monthIndex - 9;
  final year =
      (era * BigInt.from(400)).toInt() + yearOfEra + (month <= 2 ? 1 : 0);
  final weekday = ((days + BigInt.from(3)) % BigInt.from(7)).toInt() + 1;
  final dayNumber = (days - portableEpochDay(year, 1, 1)).toInt() + 1;
  return skir.DateTimeFields(
    year: year,
    month: month,
    day: day,
    hour: within ~/ 3600000,
    minute: within ~/ 60000 % 60,
    second: within ~/ 1000 % 60,
    millisecond: within % 1000,
    weekday: weekday,
    dayOfYear: dayNumber,
  );
}

BigInt _floorDivide(BigInt dividend, BigInt divisor) {
  final quotient = dividend ~/ divisor;
  return dividend.isNegative && quotient * divisor != dividend
      ? quotient - BigInt.one
      : quotient;
}

/// The ISO 8601 text of [value] in hours, minutes and seconds, such as
/// `PT1M30.5S`, `-PT1.5S` or `PT0S`.
String portableDurationText(Duration value) {
  final total = value.inMilliseconds;
  if (total == 0) return "PT0S";
  final magnitude = total.abs();
  final hours = magnitude ~/ 3600000;
  final minutes = magnitude ~/ 60000 % 60;
  final milliseconds = magnitude % 60000;
  final buffer = StringBuffer(total < 0 ? "-PT" : "PT");
  if (hours > 0) buffer.write("${hours}H");
  if (minutes > 0) buffer.write("${minutes}M");
  if (milliseconds > 0) {
    buffer.write(milliseconds ~/ 1000);
    final fraction = (milliseconds % 1000)
        .toString()
        .padLeft(3, "0")
        .replaceFirst(RegExp(r"0+$"), "");
    if (fraction.isNotEmpty) buffer.write(".$fraction");
    buffer.write("S");
  }
  return buffer.toString();
}

/// The RFC 3339 text of [value] in UTC with milliseconds, such as
/// `2024-01-02T03:04:05.000Z`.
String portableTimestampText(DateTime value) {
  final fields = portableCivilFields(BigInt.from(value.millisecondsSinceEpoch));
  String two(int part) => part.toString().padLeft(2, "0");
  return "${fields.year.toString().padLeft(4, "0")}-${two(fields.month)}-"
      "${two(fields.day)}T${two(fields.hour)}:${two(fields.minute)}:"
      "${two(fields.second)}.${fields.millisecond.toString().padLeft(3, "0")}Z";
}
