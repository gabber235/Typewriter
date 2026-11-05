import "package:typewriter_panel/typewriter_panel.dart";

/// The text a duration control shows for a duration in milliseconds.
extension PortableDurationText on int {
  /// The largest units first, such as `1h 2m 3s`, with `0ms` for zero and a
  /// leading `-` for negative durations.
  String get portableDurationText {
    final milliseconds = this;
    var remainder = BigInt.from(milliseconds).abs();
    final parts = <String>[];
    const units = {
      "w": 604800000,
      "d": 86400000,
      "h": 3600000,
      "m": 60000,
      "s": 1000,
      "ms": 1,
    };
    for (final unit in units.entries) {
      final divisor = BigInt.from(unit.value);
      final count = remainder ~/ divisor;
      remainder %= divisor;
      if (count != BigInt.zero) parts.add("$count${unit.key}");
    }
    return "${milliseconds < 0 ? "-" : ""}${parts.isEmpty ? "0ms" : parts.join(" ")}";
  }
}

/// Reading the text an author types into a duration control.
extension PortableDurationTextParsing on String {
  /// The milliseconds of a duration written as space separated parts such as
  /// `2w 5d 23h 59m 59s 999ms`, with an optional sign. Each unit appears at
  /// most once, `min` reads as minutes, and `us` parts must add up to whole
  /// milliseconds.
  ///
  /// Throws a [FormatException] for any other text and for a duration outside
  /// the portable range.
  int get portableDurationMilliseconds {
    var input = trim();
    final negative = input.startsWith("-");
    if (negative || input.startsWith("+")) input = input.substring(1);
    const units = {
      "w": 604800000000,
      "d": 86400000000,
      "h": 3600000000,
      "m": 60000000,
      "s": 1000000,
      "ms": 1000,
      "us": 1,
    };
    final seen = <String>{};
    var microseconds = BigInt.zero;
    for (final part in input.split(" ")) {
      final match = RegExp(r"^(\d+)(w|d|h|min|m|s|ms|us)$").firstMatch(part);
      if (match == null) throw const FormatException("Invalid duration format");
      final unit = match[2] == "min" ? "m" : match[2]!;
      if (!seen.add(unit)) {
        throw const FormatException("Duration unit specified multiple times");
      }
      microseconds += BigInt.parse(match[1]!) * BigInt.from(units[unit]!);
    }
    if (microseconds.remainder(BigInt.from(1000)) != BigInt.zero) {
      throw const FormatException("Duration must use whole milliseconds");
    }
    var milliseconds = microseconds ~/ BigInt.from(1000);
    if (negative) milliseconds = -milliseconds;
    final maximum = BigInt.from(PortableDurationMilliseconds.maximum);
    if (milliseconds < -maximum || milliseconds > maximum) {
      throw const FormatException("Duration exceeds the supported range");
    }
    return milliseconds.toInt();
  }
}
