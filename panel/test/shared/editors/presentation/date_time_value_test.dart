import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";

void main() {
  final precise = DateTime.utc(2024, 2, 29, 23, 58, 45, 123, 456);

  test("formats every supported editor shape", () {
    expect(
      formatDateTimeEditorValue(precise, includeDate: true, includeTime: true),
      "2024-02-29 23:58:45",
    );
    expect(
      formatDateTimeEditorValue(precise, includeDate: true, includeTime: false),
      "2024-02-29",
    );
    expect(
      formatDateTimeEditorValue(precise, includeDate: false, includeTime: true),
      "23:58:45",
    );
  });

  test("parses leap dates and preserves hidden precision", () {
    final parsed = parseDateTimeEditorValue(
      "2028-02-29 01:02:03",
      current: precise,
      includeDate: true,
      includeTime: true,
    );
    expect(parsed, DateTime.utc(2028, 2, 29, 1, 2, 3, 123, 456));
  });

  test("date only edits preserve the complete stored time", () {
    final parsed = parseDateTimeEditorValue(
      "2025-04-30",
      current: precise,
      includeDate: true,
      includeTime: false,
    );
    expect(parsed, DateTime.utc(2025, 4, 30, 23, 58, 45, 123, 456));
  });

  test("time only edits preserve the complete stored date and precision", () {
    final parsed = parseDateTimeEditorValue(
      "07:06:05",
      current: precise,
      includeDate: false,
      includeTime: true,
    );
    expect(parsed, DateTime.utc(2024, 2, 29, 7, 6, 5, 123, 456));
  });

  test("rejects incomplete drafts and impossible calendar values", () {
    for (final draft in [
      "2024-02",
      "2024-02-30",
      "2023-02-29",
      "2024-13-01",
      "24:00:00",
      "12:60:00",
      "12:30:60",
    ]) {
      expect(
        () => parseDateTimeEditorValue(
          draft,
          current: precise,
          includeDate: draft.contains("-"),
          includeTime: !draft.contains("-") || draft.contains(" "),
        ),
        throwsFormatException,
        reason: draft,
      );
    }
  });

  test("month movement clamps to month length across leap boundaries", () {
    expect(moveMonth(DateTime.utc(2024, 1, 31), 1), DateTime.utc(2024, 2, 29));
    expect(moveMonth(DateTime.utc(2023, 1, 31), 1), DateTime.utc(2023, 2, 28));
    expect(moveMonth(DateTime.utc(2024, 2, 29), 12), DateTime.utc(2025, 2, 28));
    expect(daysInMonth(2024, 2), 29);
    expect(daysInMonth(2023, 2), 28);
  });

  test("both hidden is a deliberate parsing failure", () {
    expect(
      () => parseDateTimeEditorValue(
        "",
        current: precise,
        includeDate: false,
        includeTime: false,
      ),
      throwsFormatException,
    );
  });
}
