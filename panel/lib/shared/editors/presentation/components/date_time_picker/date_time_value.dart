String formatDateTimeEditorValue(
  DateTime value, {
  required bool includeDate,
  required bool includeTime,
}) {
  final parts = <String>[];
  if (includeDate) {
    parts.add(
      "${value.year.toString().padLeft(4, "0")}-"
      "${value.month.toString().padLeft(2, "0")}-"
      "${value.day.toString().padLeft(2, "0")}",
    );
  }
  if (includeTime) {
    parts.add(
      "${value.hour.toString().padLeft(2, "0")}:"
      "${value.minute.toString().padLeft(2, "0")}:"
      "${value.second.toString().padLeft(2, "0")}",
    );
  }
  return parts.join(" ");
}

String dateTimeEditorFormat({
  required bool includeDate,
  required bool includeTime,
}) {
  if (includeDate && includeTime) return "YYYY-MM-DD HH:mm:ss";
  if (includeDate) return "YYYY-MM-DD";
  if (includeTime) return "HH:mm:ss";
  return "";
}

DateTime parseDateTimeEditorValue(
  String draft, {
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
    _ => throw const FormatException("Enable the date or time before editing"),
  };
  final match = pattern.firstMatch(draft);
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

DateTime replaceDatePart(DateTime current, DateTime date) => DateTime.utc(
  date.year,
  date.month,
  date.day,
  current.hour,
  current.minute,
  current.second,
  current.millisecond,
  current.microsecond,
);

DateTime replaceTimePart(
  DateTime current, {
  int? hour,
  int? minute,
  int? second,
}) => DateTime.utc(
  current.year,
  current.month,
  current.day,
  hour ?? current.hour,
  minute ?? current.minute,
  second ?? current.second,
  current.millisecond,
  current.microsecond,
);

int daysInMonth(int year, int month) => DateTime.utc(year, month + 1, 0).day;

DateTime moveMonth(DateTime value, int delta) {
  final monthIndex = value.year * 12 + value.month - 1 + delta;
  final year = monthIndex ~/ 12;
  final month = monthIndex % 12 + 1;
  return DateTime.utc(
    year,
    month,
    value.day.clamp(1, daysInMonth(year, month)),
  );
}
