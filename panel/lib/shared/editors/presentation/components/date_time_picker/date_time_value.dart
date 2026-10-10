/// English month names indexed by the Dart [DateTime] month minus one.
const calendarMonthNames = [
  "January",
  "February",
  "March",
  "April",
  "May",
  "June",
  "July",
  "August",
  "September",
  "October",
  "November",
  "December",
];

/// English weekday names indexed by the Dart [DateTime] weekday minus one.
const calendarWeekdayNames = [
  "Monday",
  "Tuesday",
  "Wednesday",
  "Thursday",
  "Friday",
  "Saturday",
  "Sunday",
];

/// Formats the enabled timestamp parts as the editor's canonical text form.
///
/// The formatter reads the value's calendar and clock components and omits
/// disabled parts. Subsecond precision is intentionally not displayed because
/// the editor format has second precision. Callers should provide the UTC
/// timestamp used by the editor contract.
extension DateTimeEditorText on DateTime {
  String toEditorText({required bool includeDate, required bool includeTime}) {
    final parts = <String>[];
    if (includeDate) {
      parts.add(
        "${year.toString().padLeft(4, "0")}-"
        "${month.toString().padLeft(2, "0")}-"
        "${day.toString().padLeft(2, "0")}",
      );
    }
    if (includeTime) {
      parts.add(
        "${hour.toString().padLeft(2, "0")}:"
        "${minute.toString().padLeft(2, "0")}:"
        "${second.toString().padLeft(2, "0")}",
      );
    }
    return parts.join(" ");
  }
}

/// Returns the input hint and validation format for the enabled timestamp parts.
String dateTimeEditorFormat({
  required bool includeDate,
  required bool includeTime,
}) {
  if (includeDate && includeTime) return "YYYY-MM-DD HH:mm:ss";
  if (includeDate) return "YYYY-MM-DD";
  if (includeTime) return "HH:mm:ss";
  return "";
}

/// Parses canonical editor text while preserving disabled and subsecond parts.
///
/// Date values must be real calendar dates and time values must fit their
/// component ranges. The returned timestamp is UTC. Invalid drafts throw
/// [FormatException], allowing [ValidatedTextField] to retain the last valid
/// value and show recovery guidance.
extension DateTimeEditorDraft on String {
  DateTime parseEditorDateTime({
    required DateTime current,
    required bool includeDate,
    required bool includeTime,
  }) {
    if (!includeDate && !includeTime) {
      throw const FormatException("Enable the date or time before editing");
    }
    final pattern = switch ((includeDate, includeTime)) {
      (true, true) => RegExp(
        r"^(\d{4})-(\d{2})-(\d{2}) (\d{2}):(\d{2}):(\d{2})$",
      ),
      (true, false) => RegExp(r"^(\d{4})-(\d{2})-(\d{2})$"),
      (false, true) => RegExp(r"^(\d{2}):(\d{2}):(\d{2})$"),
      _ => throw const FormatException(
        "Enable the date or time before editing",
      ),
    };
    final match = pattern.firstMatch(this);
    if (match == null) {
      throw FormatException(
        "Use ${dateTimeEditorFormat(includeDate: includeDate, includeTime: includeTime)}",
      );
    }

    var year = current.year;
    var month = current.month;
    var day = current.day;
    var hour = current.hour;

    var minute = current.minute;

    var second = current.second;
    if (includeDate) {
      year = int.parse(match.group(1)!);
      month = int.parse(match.group(2)!);
      day = int.parse(match.group(3)!);
    }
    if (includeTime) {
      final offset = includeDate ? 3 : 0;
      hour = int.parse(match.group(offset + 1)!);
      minute = int.parse(match.group(offset + 2)!);
      second = int.parse(match.group(offset + 3)!);
    }
    if (year < 1 ||
        month < 1 ||
        month > 12 ||
        hour > 23 ||
        minute > 59 ||
        second > 59) {
      throw const FormatException("Enter a valid date and time");
    }

    final parsed = DateTime.utc(
      year,
      month,
      day,
      hour,
      minute,
      second,
      current.millisecond,
      current.microsecond,
    );
    if (parsed.year != year || parsed.month != month || parsed.day != day) {
      throw const FormatException("Enter a valid calendar date");
    }
    return parsed;
  }
}

extension DateTimeCalendarOperations on DateTime {
  /// Returns this value at midnight UTC using its existing calendar fields.
  DateTime get calendarDate => DateTime.utc(year, month, day);

  /// Compares calendar fields without converting either timestamp.
  bool hasSameCalendarDate(DateTime other) =>
      year == other.year && month == other.month && day == other.day;

  /// Produces the spoken label shared by calendar focus and date cells.
  String get semanticCalendarLabel =>
      "${calendarWeekdayNames[weekday - 1]}, "
      "${calendarMonthNames[month - 1]} $day, $year";

  /// Replaces the calendar date while preserving time and subsecond precision.
  DateTime withDate(DateTime date) => DateTime.utc(
    date.year,
    date.month,
    date.day,
    hour,
    minute,
    second,
    millisecond,
    microsecond,
  );

  /// Replaces selected time components while preserving date and precision.
  DateTime withTime({int? hour, int? minute, int? second}) => DateTime.utc(
    year,
    month,
    day,
    hour ?? this.hour,
    minute ?? this.minute,
    second ?? this.second,
    millisecond,
    microsecond,
  );

  /// Moves this UTC calendar date by [delta] months and clamps its day.
  DateTime moveMonth(int delta) {
    final monthIndex = year * 12 + month - 1 + delta;
    final nextYear = monthIndex ~/ 12;
    final nextMonth = monthIndex % 12 + 1;
    return DateTime.utc(
      nextYear,
      nextMonth,
      day.clamp(1, daysInMonth(nextYear, nextMonth)),
    );
  }
}

int daysInMonth(int year, int month) => DateTime.utc(year, month + 1, 0).day;
