import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

/// The panel's text operations. Indexes and lengths count Unicode code
/// points, and every case, normalization and white space rule comes from the
/// pinned Unicode tables in `portable_unicode.dart`, never from the platform.
final class PanelTextKernel implements skir.TextKernel {
  const PanelTextKernel();

  @override
  List<int> codePoints(String value) => value.runes.toList(growable: false);

  @override
  String foldCase(String value) => portableFoldCase(value);

  @override
  String fromCodePoints(List<int> points) {
    for (final point in points) {
      if (point < 0 ||
          point > 0x10ffff ||
          (point >= 0xd800 && point <= 0xdfff)) {
        throw skir.PortableOperationFailure(
          skir.PortableFailures.invalidCodePoint,
          "The value $point is not a Unicode scalar value.",
        );
      }
    }
    return String.fromCharCodes(points);
  }

  @override
  int indexOf(String value, String needle, int from) {
    final source = value.runes.toList(growable: false);
    final pattern = needle.runes.toList(growable: false);
    final start = from < 0 ? 0 : from;
    if (pattern.isEmpty) return start <= source.length ? start : -1;
    for (var index = start; index + pattern.length <= source.length; index++) {
      if (_occursAt(source, pattern, index)) return index;
    }
    return -1;
  }

  @override
  String join(List<String> parts, String separator) => parts.join(separator);

  @override
  int lastIndexOf(String value, String needle, int from) {
    final source = value.runes.toList(growable: false);
    final pattern = needle.runes.toList(growable: false);
    final start = from > source.length ? source.length : from;
    if (pattern.isEmpty) return start >= 0 ? start : -1;
    for (
      var index = start < source.length - pattern.length
          ? start
          : source.length - pattern.length;
      index >= 0;
      index--
    ) {
      if (_occursAt(source, pattern, index)) return index;
    }
    return -1;
  }

  @override
  int length(String value) => value.runes.length;

  @override
  String lower(String value) => portableLower(value);

  @override
  String normalize(String value, skir.UnicodeForm form) => portableNormalize(
    value,
    compatibility:
        form == skir.UnicodeForm.nfkc || form == skir.UnicodeForm.nfkd,
    compose: form == skir.UnicodeForm.nfc || form == skir.UnicodeForm.nfkc,
  );

  /// Digit counts are checked before any big number is built, so long text
  /// costs time linear in its length.
  @override
  skir.PortableDecimal parseDecimal(String value) {
    final match = _numberText.firstMatch(value) ?? _invalidNumber(value);
    final fraction = match.group(3) ?? match.group(4) ?? "";
    final exponentText = match.group(5) ?? "0";
    // An exponent beyond the 32 bit range no host represents is not a number
    // either.
    if (_withoutLeadingZeros(exponentText.replaceFirst(RegExp("^[+-]"), ""))
            .length >
        10) {
      _invalidNumber(value);
    }
    final exponent = int.parse(exponentText);
    if (!_isInt32(exponent)) _invalidNumber(value);
    final coefficient = _withoutLeadingZeros(
      "${match.group(2) ?? ""}$fraction",
    );
    final significant = coefficient.replaceFirst(RegExp(r"0+$"), "");
    if (significant.isEmpty) return skir.PortableDecimal.zero;
    final scale =
        fraction.length - exponent - (coefficient.length - significant.length);
    if (portableDecimalDigits(significant.length, scale) >
        portableMaximumDigits) {
      portableMagnitudeLimit();
    }
    var unscaled = BigInt.parse(significant);
    if (match.group(1) == "-") unscaled = -unscaled;
    return scale < 0
        ? skir.PortableDecimal(unscaled * BigInt.from(10).pow(-scale), 0)
        : skir.PortableDecimal(unscaled, scale);
  }

  /// A component of more significant digits than the portable duration
  /// range has fails `duration_range` before it is parsed.
  @override
  Duration parseDuration(String value) {
    final match = _durationText.firstMatch(value);
    final hasTime = match?.group(3) != null;
    final timeParts = [match?.group(4), match?.group(5), match?.group(6)];
    if (match == null ||
        (match.group(2) == null && !hasTime) ||
        (hasTime && timeParts.every((part) => part == null))) {
      throw skir.PortableOperationFailure(
        skir.PortableFailures.invalidDurationText,
        "The text $value is not an ISO 8601 duration.",
      );
    }
    BigInt part(int group) {
      final digits = _withoutLeadingZeros(match.group(group) ?? "");
      if (digits.length > _durationDigits) {
        throw skir.PortableOperationFailure(
          skir.PortableFailures.durationRange,
          "The duration $value exceeds the portable range.",
        );
      }
      return digits.isEmpty ? BigInt.zero : BigInt.parse(digits);
    }

    final fraction = (match.group(7) ?? "").padRight(3, "0");
    var milliseconds =
        part(2) * BigInt.from(86400000) +
        part(4) * BigInt.from(3600000) +
        part(5) * BigInt.from(60000) +
        part(6) * BigInt.from(1000) +
        BigInt.parse(fraction);
    if (match.group(1) != null) milliseconds = -milliseconds;
    return portableDuration(milliseconds);
  }

  @override
  double parseFloat(String value) {
    final match = _numberText.firstMatch(value) ?? _invalidNumber(value);
    final parsed = double.parse(_plainNumber(match));
    return parsed.isFinite ? parsed : _invalidNumber(value);
  }

  @override
  BigInt parseInteger(String value, int radix) {
    if (radix < 2 || radix > 36) {
      throw skir.PortableOperationFailure(
        skir.PortableFailures.invalidRadix,
        "The radix $radix is outside 2 to 36.",
      );
    }
    final match = _integerText.firstMatch(value) ?? _invalidNumber(value);
    final digits = match.group(2)!;
    for (final unit in digits.toLowerCase().codeUnits) {
      final digit = unit <= 0x39 ? unit - 0x30 : unit - 0x61 + 10;
      if (digit >= radix) _invalidNumber(value);
    }
    // A number of d significant digits is at least radix^(d - 1), so its
    // size is known before it is built.
    final significant = _withoutLeadingZeros(digits).length;
    if (significant > 1 &&
        (significant - 1) * log(radix) / ln2 > portableMaximumBits) {
      portableMagnitudeLimit();
    }
    final magnitude = requireIntegerMagnitude(
      BigInt.parse(digits, radix: radix),
    );
    return match.group(1) == "-" ? -magnitude : magnitude;
  }

  @override
  DateTime parseTimestamp(String value) {
    final match = _timestampText.firstMatch(value);
    if (match == null) _invalidTimestamp(value);
    int field(int group) => int.parse(match.group(group)!);
    final year = field(1);
    final month = field(2);
    final day = field(3);
    final hour = field(4);
    final minute = field(5);
    final second = field(6);
    final millisecond = int.parse(
      (match.group(7) ?? "").padRight(3, "0").substring(0, 3),
    );
    final zone = match.group(8)!;
    var offset = 0;
    if (zone != "Z") {
      final offsetHours = int.parse(zone.substring(1, 3));
      final offsetMinutes = int.parse(zone.substring(4, 6));
      if (offsetHours > 23 || offsetMinutes > 59) _invalidTimestamp(value);
      offset = (offsetHours * 60 + offsetMinutes) * 60000;
      if (zone.startsWith("-")) offset = -offset;
    }
    if (month < 1 ||
        month > 12 ||
        day < 1 ||
        day > portableDaysInMonth(year, month) ||
        hour > 23 ||
        minute > 59 ||
        second > 59) {
      _invalidTimestamp(value);
    }
    final local =
        portableEpochDay(year, month, day) * BigInt.from(86400000) +
        BigInt.from(((hour * 60 + minute) * 60 + second) * 1000 + millisecond);
    return portableTimestamp(local - BigInt.from(offset));
  }

  @override
  List<String> split(String value, String separator) {
    if (separator.isEmpty) {
      throw skir.PortableOperationFailure(skir.PortableFailures.emptySeparator);
    }
    return value.split(separator);
  }

  @override
  String substring(String value, int start, int end) {
    final points = value.runes.toList(growable: false);
    if (start < 0 || end < start || end > points.length) {
      throw skir.PortableOperationFailure(
        skir.PortableFailures.substringRange,
        "The range $start to $end is outside the text of ${points.length} "
        "code points.",
      );
    }
    return String.fromCharCodes(points, start, end);
  }

  @override
  String title(String value) => portableTitle(value);

  @override
  String trimEnd(String value) => portableTrimEnd(value);

  @override
  String trimStart(String value) => portableTrimStart(value);

  @override
  String upper(String value) => portableUpper(value);
}

final _numberText = RegExp(
  r"^([+-]?)(?:([0-9]+)(?:\.([0-9]*))?|\.([0-9]+))(?:[eE]([+-]?[0-9]+))?$",
);

final _integerText = RegExp(r"^([+-]?)([0-9A-Za-z]+)$");

final _durationText = RegExp(
  "^(-)?P(?:([0-9]+)D)?(T(?:([0-9]+)H)?(?:([0-9]+)M)?"
  r"(?:([0-9]+)(?:\.([0-9]{1,3}))?S)?)?$",
);

final _timestampText = RegExp(
  "^([0-9]{4})-([0-9]{2})-([0-9]{2})T([0-9]{2}):([0-9]{2}):([0-9]{2})"
  r"(?:\.([0-9]+))?(Z|[+-][0-9]{2}:[0-9]{2})$",
);

/// The number [match] read in plain digits with an explicit whole part, such
/// as `0.5e3` for `.5e3`.
String _plainNumber(RegExpMatch match) {
  final whole = match.group(2) ?? "0";
  final fraction = match.group(3) ?? match.group(4) ?? "";
  final exponent = match.group(5);
  return "${match.group(1)}$whole${fraction.isEmpty ? "" : ".$fraction"}"
      "${exponent == null ? "" : "e$exponent"}";
}

bool _isInt32(int value) => value >= -2147483648 && value <= 2147483647;

String _withoutLeadingZeros(String digits) =>
    digits.replaceFirst(RegExp("^0+"), "");

/// The digits of the largest portable duration, 9007199254740991 ms; a
/// component with more significant digits exceeds it in any unit.
const _durationDigits = 16;

Never _invalidNumber(String value) => throw skir.PortableOperationFailure(
  skir.PortableFailures.invalidNumberText,
  "The text $value is not a number in the expected syntax.",
);

Never _invalidTimestamp(String value) => throw skir.PortableOperationFailure(
  skir.PortableFailures.invalidTimestampText,
  "The text $value is not an RFC 3339 timestamp.",
);

bool _occursAt(List<int> source, List<int> pattern, int index) {
  for (var offset = 0; offset < pattern.length; offset++) {
    if (source[index + offset] != pattern[offset]) return false;
  }
  return true;
}
