import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";

import "../../../support/test_utils.dart";

void main() {
  for (final mixed in [false, true]) {
    testWidgets("nullable text distinguishes empty from mixed $mixed", (
      tester,
    ) async {
      final writes = <int>[];
      await tester.pumpTestApp(
        child: Scaffold(
          body: ValidatedTextField<int>(
            value: null,
            mixed: mixed,
            serialize: int.parse,
            onChanged: writes.add,
          ),
        ),
      );
      expect(
        find.text(mixedValueReplacementMessage),
        mixed ? findsOneWidget : findsNothing,
      );
      expect(writes, isEmpty);
      await tester.enterText(find.byType(TextFormField), "7");
      await tester.pumpAndSettle();
      expect(writes, [7]);
    });

    testWidgets("color distinguishes empty from mixed $mixed through edits", (
      tester,
    ) async {
      var selectionMixed = mixed;
      Color? value;
      final writes = <Color>[];
      var clears = 0;
      await tester.pumpTestApp(
        child: StatefulBuilder(
          builder: (_, setState) {
            void changed(Color next) => setState(() {
              value = next;
              selectionMixed = false;
              writes.add(next);
            });
            void cleared() => setState(() {
              value = null;
              selectionMixed = false;
              clears++;
            });
            return Scaffold(
              body: selectionMixed
                  ? ColorPickerField.mixed(
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
          },
        ),
      );
      expect(
        find.text("Multiple colors"),
        mixed ? findsOneWidget : findsNothing,
      );
      expect(
        find.text(mixedValueReplacementMessage),
        mixed ? findsOneWidget : findsNothing,
      );
      expect(
        find.text("This value is Unfilled"),
        mixed ? findsNothing : findsOneWidget,
      );
      await tester.tap(find.byTooltip("Open color picker"));
      await tester.pumpAndSettle();
      expect(
        find.text("Choose one replacement color."),
        mixed ? findsOneWidget : findsNothing,
      );
      await tester.tap(find.byTooltip("Close color picker"));
      await tester.pumpAndSettle();
      expect(writes, isEmpty);
      expect(clears, 0);
      await tester.enterText(find.byType(TextFormField), "#AABBCC");
      await tester.pumpAndSettle();
      expect(writes, [const Color(0xFFAABBCC)]);
      await tester.enterText(find.byType(TextFormField), "");
      await tester.pumpAndSettle();
      expect(clears, 1);
      expect(writes, [const Color(0xFFAABBCC)]);
      expect(find.text("This value is Unfilled"), findsOneWidget);
      expect(find.text("Multiple colors"), findsNothing);
      expect(find.text(mixedValueReplacementMessage), findsNothing);
    });

    for (final parts in [
      (date: true, time: false),
      (date: false, time: true),
      (date: true, time: true),
    ]) {
      testWidgets(
        "timestamp ${parts.date}/${parts.time} distinguishes empty from mixed $mixed",
        (tester) async {
          var selectionMixed = mixed;
          DateTime? value;
          final writes = <DateTime>[];
          var clears = 0;
          await tester.pumpTestApp(
            child: StatefulBuilder(
              builder: (_, setState) {
                void changed(DateTime next) => setState(() {
                  value = next;
                  selectionMixed = false;
                  writes.add(next);
                });
                void cleared() => setState(() {
                  value = null;
                  selectionMixed = false;
                  clears++;
                });
                return Scaffold(
                  body: selectionMixed
                      ? DateTimePickerField.mixed(
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
              },
            ),
          );
          expect(
            find.text("Multiple values"),
            mixed ? findsOneWidget : findsNothing,
          );
          expect(
            find.text(mixedValueReplacementMessage),
            mixed ? findsOneWidget : findsNothing,
          );
          expect(
            find.text("This value is Unfilled"),
            mixed ? findsNothing : findsOneWidget,
          );
          await tester.tap(find.byTooltip("Open picker"));
          await tester.pumpAndSettle();
          final seed = tester
              .widget<DateTimePickerSurface>(find.byType(DateTimePickerSurface))
              .value;
          expect(
            find.text("Choose one replacement value."),
            mixed ? findsOneWidget : findsNothing,
          );
          await tester.tap(find.byTooltip("Close picker"));
          await tester.pumpAndSettle();
          expect(writes, isEmpty);
          expect(clears, 0);
          final expected = DateTime.utc(
            parts.date ? 2028 : seed.year,
            parts.date ? 2 : seed.month,
            parts.date ? 29 : seed.day,
            parts.time ? 7 : seed.hour,
            parts.time ? 6 : seed.minute,
            parts.time ? 5 : seed.second,
          );
          await tester.enterText(
            find.byType(TextFormField),
            parts.date && parts.time
                ? "2028-02-29 07:06:05"
                : parts.date
                ? "2028-02-29"
                : "07:06:05",
          );
          await tester.pumpAndSettle();
          expect(writes, [expected]);
          await tester.enterText(find.byType(TextFormField), "");
          await tester.pumpAndSettle();
          expect(clears, 1);
          expect(writes, [expected]);
          expect(find.text("This value is Unfilled"), findsOneWidget);
          expect(find.text("Multiple values"), findsNothing);
          expect(find.text(mixedValueReplacementMessage), findsNothing);
        },
      );
    }
  }
}
