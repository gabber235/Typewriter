import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

/// The panel's timestamp operations. Calendar fields use the proleptic
/// Gregorian calendar at a fixed offset; names come from intl's CLDR date
/// symbols and zone offsets from the IANA database of package timezone.
final class PanelTimestampKernel implements skir.TimestampKernel {
  const PanelTimestampKernel();

  @override
  skir.DateTimeFields fields(DateTime value, Duration offset) {
    final local =
        BigInt.from(value.millisecondsSinceEpoch) +
        BigInt.from(offset.inMilliseconds);
    if (local < portableTimestampMinimum || local > portableTimestampMaximum) {
      throw skir.PortableOperationFailure(skir.PortableFailures.timestampRange);
    }
    return portableCivilFields(local);
  }

  @override
  DateTime fromEpochMilliseconds(BigInt milliseconds) =>
      portableTimestamp(milliseconds);

  @override
  DateTime fromFields(skir.DateTimeFields fields, Duration offset) {
    if (fields.month < 1 ||
        fields.month > 12 ||
        fields.day < 1 ||
        fields.day > portableDaysInMonth(fields.year, fields.month) ||
        fields.hour < 0 ||
        fields.hour > 23 ||
        fields.minute < 0 ||
        fields.minute > 59 ||
        fields.second < 0 ||
        fields.second > 59 ||
        fields.millisecond < 0 ||
        fields.millisecond > 999) {
      throw skir.PortableOperationFailure(
        skir.PortableFailures.invalidCalendarDate,
      );
    }
    final local =
        portableEpochDay(fields.year, fields.month, fields.day) *
            BigInt.from(86400000) +
        BigInt.from(
          ((fields.hour * 60 + fields.minute) * 60 + fields.second) * 1000 +
              fields.millisecond,
        );
    return portableTimestamp(local - BigInt.from(offset.inMilliseconds));
  }

  @override
  String monthName(int month, String locale, skir.NameStyle style) {
    if (month < 1 || month > 12) {
      throw skir.PortableOperationFailure(
        skir.PortableFailures.invalidMonth,
        "The month $month is outside 1 to 12.",
      );
    }
    final symbols = _symbols(locale);
    if (symbols == null) {
      return style == skir.NameStyle.narrow
          ? "$month"
          : "M${month.toString().padLeft(2, "0")}";
    }
    final names = switch (style) {
      skir.NameStyle.wide => symbols.STANDALONEMONTHS,
      skir.NameStyle.abbreviated => symbols.STANDALONESHORTMONTHS,
      skir.NameStyle.narrow => symbols.STANDALONENARROWMONTHS,
    };
    return names[month - 1];
  }

  @override
  BigInt toEpochMilliseconds(DateTime value) =>
      BigInt.from(value.millisecondsSinceEpoch);

  @override
  String weekdayName(int weekday, String locale, skir.NameStyle style) {
    if (weekday < 1 || weekday > 7) {
      throw skir.PortableOperationFailure(
        skir.PortableFailures.invalidWeekday,
        "The weekday $weekday is outside 1 to 7.",
      );
    }
    final symbols = _symbols(locale);
    if (symbols == null) {
      final name = _rootWeekdays[weekday - 1];
      return style == skir.NameStyle.narrow ? name.substring(0, 1) : name;
    }
    final names = switch (style) {
      skir.NameStyle.wide => symbols.STANDALONEWEEKDAYS,
      skir.NameStyle.abbreviated => symbols.STANDALONESHORTWEEKDAYS,
      skir.NameStyle.narrow => symbols.STANDALONENARROWWEEKDAYS,
    };
    // CLDR lists weekdays from Sunday; weekday 7 is Sunday.
    return names[weekday % 7];
  }

  @override
  Duration zoneOffset(DateTime value, String zone) {
    _loadTimeZones();
    try {
      return getLocation(zone).timeZone(value.millisecondsSinceEpoch).offset;
    } on LocationNotFoundException {
      throw skir.PortableOperationFailure(
        skir.PortableFailures.unknownTimeZone,
        "The zone $zone is not an IANA time zone.",
      );
    }
  }
}

/// The CLDR root weekday names, Monday first, for locales without data.
const _rootWeekdays = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];

/// Every locale's date symbols, built once.
final _dateSymbols = dateTimeSymbolMap();

DateSymbols? _symbols(String locale) =>
    switch (resolvePortableLocale(locale, _dateSymbols.containsKey)) {
      final name? => _dateSymbols[name],
      null => null,
    };

var _timeZonesLoaded = false;

/// Loads the embedded IANA database on first use. The data is compiled into
/// the program, so this works on every platform including the web.
void _loadTimeZones() {
  if (_timeZonesLoaded) return;
  initializeTimeZones();
  _timeZonesLoaded = true;
}
