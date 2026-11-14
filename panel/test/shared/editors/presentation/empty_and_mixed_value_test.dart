import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  for (final mixed in [false, true]) {
    testWidgets("nullable text distinguishes empty from mixed $mixed", (
      tester,
    ) async {
      final writes = <int>[];
      final panel = await tester.pumpPanel(
        const [],
        at: PanelLocation.component(
          ValidatedTextField<int>(
            value: null,
            mixed: mixed,
            serialize: int.parse,
            onChanged: writes.add,
          ),
        ),
      );
      expect(panel.shows(mixedValueReplacementMessage), mixed);
      expect(writes, isEmpty);
      await panel.field("").type("7");
      expect(writes, [7]);
    });

    testWidgets("color distinguishes empty from mixed $mixed through edits", (
      tester,
    ) async {
      final field = NullableFieldOwner<Color>(mixed);
      final panel = await field.pump(
        tester,
        (value, mixed, changed, cleared) => mixed
            ? ColorPickerField(
                color: null,
                mixed: true,
                includeAlpha: false,
                onChanged: changed,
                onCleared: cleared,
              )
            : ColorPickerField(
                color: value,
                includeAlpha: false,
                onChanged: changed,
                onCleared: cleared,
              ),
      );
      expect(panel.shows(mixedValueReplacementMessage), mixed);
      expect(panel.shows("This value is Unfilled"), !mixed);
      await panel.tapOn(find.tooltip("Open color picker"));
      expect(panel.shows("Choose one replacement color."), mixed);
      await panel.tapOn(find.tooltip("Close color picker"));
      expect(field.writes, isEmpty);
      expect(field.clears, 0);
      await panel.field("").type("#AABBCC");
      expect(field.writes, [const Color(0xFFAABBCC)]);
      await panel.field("").type("");
      expect(field.clears, 1);
      expect(field.writes, [const Color(0xFFAABBCC)]);
      expect(panel.shows("This value is Unfilled"), isTrue);
      expect(panel.shows(mixedValueLabel), isFalse);
      expect(panel.shows(mixedValueReplacementMessage), isFalse);
    });

    for (final parts in [
      (date: true, time: false),
      (date: false, time: true),
      (date: true, time: true),
    ]) {
      testWidgets(
        "timestamp ${parts.date}/${parts.time} distinguishes empty from mixed $mixed",
        (tester) async {
          final field = NullableFieldOwner<DateTime>(mixed);
          final panel = await field.pump(
            tester,
            (value, mixed, changed, cleared) => mixed
                ? DateTimePickerField(
                    value: null,
                    mixed: true,
                    includeDate: parts.date,
                    includeTime: parts.time,
                    onChanged: changed,
                    onCleared: cleared,
                  )
                : DateTimePickerField(
                    value: value,
                    includeDate: parts.date,
                    includeTime: parts.time,
                    onChanged: changed,
                    onCleared: cleared,
                  ),
          );
          expect(panel.shows(mixedValueLabel), mixed);
          expect(panel.shows(mixedValueReplacementMessage), mixed);
          expect(panel.shows("This value is Unfilled"), !mixed);
          await panel.tapOn(find.tooltip("Open picker"));
          expect(panel.shows("Choose one replacement value."), mixed);
          await panel.tapOn(find.tooltip("Close picker"));
          expect(field.writes, isEmpty);
          expect(field.clears, 0);
          // A partial entry takes its missing parts from the start of today.
          final now = DateTime.now();
          final seed = DateTime(now.year, now.month, now.day);
          final expected = DateTime.utc(
            parts.date ? 2028 : seed.year,
            parts.date ? 2 : seed.month,
            parts.date ? 29 : seed.day,
            parts.time ? 7 : seed.hour,
            parts.time ? 6 : seed.minute,
            parts.time ? 5 : seed.second,
          );
          await panel
              .field("")
              .type(
                parts.date && parts.time
                    ? "2028-02-29 07:06:05"
                    : parts.date
                    ? "2028-02-29"
                    : "07:06:05",
              );
          expect(field.writes, [expected]);
          await panel.field("").type("");
          expect(field.clears, 1);
          expect(field.writes, [expected]);
          expect(panel.shows("This value is Unfilled"), isTrue);
          expect(panel.shows(mixedValueLabel), isFalse);
          expect(panel.shows(mixedValueReplacementMessage), isFalse);
        },
      );
    }
  }
}
