import "dart:ui" show Tristate;

import "package:flutter/material.dart";
import "package:flutter/semantics.dart";
import "package:flutter/services.dart";
import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";

import "../../../support/test_utils.dart";

void main() {
  testWidgets("direct typing updates only complete valid drafts", (
    tester,
  ) async {
    final key = GlobalKey<_DateTimeFieldHarnessState>();
    await tester.pumpTestApp(child: _DateTimeFieldHarness(key: key));

    await tester.enterText(find.byType(TextFormField), "2028-02");
    await tester.pump();
    expect(find.text("Use YYYY-MM-DD HH:mm:ss"), findsOneWidget);
    expect(key.currentState!.value.year, 2024);

    await tester.enterText(find.byType(TextFormField), "2028-02-29 07:06:05");
    await tester.pumpAndSettle();
    expect(
      key.currentState!.value,
      DateTime.utc(2028, 2, 29, 7, 6, 5, 123, 456),
    );
  });

  testWidgets("closed field uses its format as a placeholder", (tester) async {
    await tester.pumpTestApp(child: const _DateTimeFieldHarness());

    final field = tester.widget<InputDecorator>(find.byType(InputDecorator));
    expect(field.decoration.hintText, "YYYY-MM-DD HH:mm:ss");
    expect(field.decoration.helperText, isNull);
    expect(field.decoration.prefixIcon, isA<Center>());
  });

  testWidgets("picker opens, dismisses, and returns focus to its action", (
    tester,
  ) async {
    await tester.pumpTestApp(child: const _DateTimeFieldHarness());

    await tester.tap(find.byTooltip("Open picker"));
    await tester.pumpAndSettle();
    expect(find.byType(DateTimePickerSurface), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byType(DateTimePickerSurface), findsNothing);
    expect(
      FocusManager.instance.primaryFocus?.debugLabel,
      "Open date and time picker",
    );

    await tester.tap(find.byTooltip("Open picker"));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(4, 4));
    await tester.pumpAndSettle();
    expect(find.byType(DateTimePickerSurface), findsNothing);
  });

  testWidgets("closed field exposes copy and picker shortcuts", (tester) async {
    String? clipboardText;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == "Clipboard.setData") {
          clipboardText =
              (call.arguments as Map<Object?, Object?>)["text"] as String?;
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    await tester.pumpTestApp(child: const _DateTimeFieldHarness());

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    final modifier = isApple
        ? LogicalKeyboardKey.metaLeft
        : LogicalKeyboardKey.controlLeft;
    await tester.sendKeyDownEvent(modifier);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyC);
    await tester.sendKeyUpEvent(modifier);
    await tester.pump();
    expect(clipboardText, "2024-08-12 18:30:45");

    await tester.sendKeyEvent(LogicalKeyboardKey.keyP);
    await tester.pumpAndSettle();
    expect(find.byType(DateTimePickerSurface), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyP);
    await tester.pumpAndSettle();
    expect(find.byType(DateTimePickerSurface), findsNothing);
  });

  testWidgets("calendar supports spatial, month, year, and boundary keys", (
    tester,
  ) async {
    final key = GlobalKey<_DateTimeFieldHarnessState>();
    await tester.pumpTestApp(child: _DateTimeFieldHarness(key: key));
    await tester.tap(find.byTooltip("Open picker"));
    await tester.pumpAndSettle();

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(key.currentState!.value.day, 13);

    await tester.sendKeyEvent(LogicalKeyboardKey.end);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(key.currentState!.value.day, 31);

    await tester.sendKeyEvent(LogicalKeyboardKey.pageDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(
      key.currentState!.value,
      DateTime.utc(2024, 9, 30, 18, 30, 45, 123, 456),
    );

    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.pageUp);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(key.currentState!.value.year, 2023);
  });

  testWidgets("pointer date selection preserves time precision", (
    tester,
  ) async {
    final key = GlobalKey<_DateTimeFieldHarnessState>();
    await tester.pumpTestApp(child: _DateTimeFieldHarness(key: key));
    await tester.tap(find.byTooltip("Open picker"));
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel("Thursday, August 22, 2024"));
    await tester.pump();
    expect(
      key.currentState!.value,
      DateTime.utc(2024, 8, 22, 18, 30, 45, 123, 456),
    );
  });

  testWidgets("month and year pickers move directly to their selection", (
    tester,
  ) async {
    await tester.pumpTestApp(child: const _DateTimeFieldHarness());
    await tester.tap(find.byTooltip("Open picker"));
    await tester.pumpAndSettle();

    final monthPicker = tester.widget<Dropdown<int>>(
      find.byKey(const ValueKey("date_time_month_picker")),
    );
    monthPicker.onSelected?.call(2);
    await tester.pump();
    expect(find.bySemanticsLabel("Monday, February 12, 2024"), findsOneWidget);

    final yearPicker = tester.widget<Dropdown<int>>(
      find.byKey(const ValueKey("date_time_year_picker")),
    );
    yearPicker.onSelected?.call(2028);
    await tester.pump();
    expect(
      find.bySemanticsLabel("Saturday, February 12, 2028"),
      findsOneWidget,
    );
  });

  testWidgets("time fields support direct typing and keyboard increments", (
    tester,
  ) async {
    final key = GlobalKey<_DateTimeFieldHarnessState>();
    await tester.pumpTestApp(
      child: _DateTimeFieldHarness(key: key, includeDate: false),
    );
    await tester.tap(find.byTooltip("Open picker"));
    await tester.pumpAndSettle();

    final fields = find.descendant(
      of: find.byType(DateTimePickerSurface),
      matching: find.byType(TextFormField),
    );
    await tester.tap(fields.first);
    await tester.sendKeyEvent(LogicalKeyboardKey.end);
    await tester.pump();
    expect(key.currentState!.value.hour, 23);

    await tester.sendKeyEvent(LogicalKeyboardKey.pageDown);
    await tester.pump();
    expect(key.currentState!.value.hour, 17);

    final minuteEditor = find.byKey(const ValueKey("date_time_minute"));
    final minuteField = find.descendant(
      of: minuteEditor,
      matching: find.byType(TextFormField),
    );
    await tester.tap(minuteField);
    await tester.pump();
    await tester.enterText(minuteField, "07");
    await tester.pump();
    expect(
      tester
          .widget<EditableText>(
            find.descendant(
              of: minuteEditor,
              matching: find.byType(EditableText),
            ),
          )
          .controller
          .text,
      "07",
    );
    expect(key.currentState!.value.minute, 7);
    expect(key.currentState!.value.second, 45);
    expect(key.currentState!.value.microsecond, 456);

    final secondEditor = find.byKey(const ValueKey("date_time_second"));
    final secondField = find.descendant(
      of: secondEditor,
      matching: find.byType(TextFormField),
    );
    await tester.tap(secondField);
    await tester.pump();
    await tester.enterText(secondField, "09");
    await tester.pumpAndSettle();
    expect(key.currentState!.value.second, 9);
    expect(key.currentState!.value.microsecond, 456);
  });

  testWidgets("two valid digits advance through the time fields", (
    tester,
  ) async {
    await tester.pumpTestApp(
      child: const _DateTimeFieldHarness(includeDate: false),
    );
    await tester.tap(find.byTooltip("Open picker"));
    await tester.pumpAndSettle();

    final hourField = find.descendant(
      of: find.byKey(const ValueKey("date_time_hour")),
      matching: find.byType(TextFormField),
    );
    await tester.enterText(hourField, "99");
    await tester.pump();
    expect(FocusManager.instance.primaryFocus?.debugLabel, "Hour");

    await tester.enterText(hourField, "09");
    await tester.pumpAndSettle();
    expect(FocusManager.instance.primaryFocus?.debugLabel, "Minute");

    final minuteField = find.descendant(
      of: find.byKey(const ValueKey("date_time_minute")),
      matching: find.byType(TextFormField),
    );
    await tester.enterText(minuteField, "08");
    await tester.pumpAndSettle();
    expect(FocusManager.instance.primaryFocus?.debugLabel, "Second");
  });

  testWidgets("focus remains trapped inside the open picker", (tester) async {
    await tester.pumpTestApp(child: const _DateTimeFieldHarness());
    await tester.tap(find.byTooltip("Open picker"));
    await tester.pumpAndSettle();

    for (var index = 0; index < 12; index++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      final focusContext = FocusManager.instance.primaryFocus?.context;
      expect(focusContext, isNotNull);
      expect(
        find
            .descendant(
              of: find.byType(DateTimePickerSurface),
              matching: find.byElementPredicate(
                (element) => identical(element, focusContext),
              ),
            )
            .evaluate(),
        isNotEmpty,
      );
    }
  });

  testWidgets("read only permits inspection while disabled cannot open", (
    tester,
  ) async {
    final readOnlyKey = GlobalKey<_DateTimeFieldHarnessState>();
    await tester.pumpTestApp(
      child: _DateTimeFieldHarness(key: readOnlyKey, readOnly: true),
    );
    await tester.tap(find.byTooltip("Open picker"));
    await tester.pumpAndSettle();
    expect(find.byType(DateTimePickerSurface), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(readOnlyKey.currentState!.value.day, 12);

    await tester.pumpTestApp(
      child: const _DateTimeFieldHarness(enabled: false),
    );
    await tester.tap(find.byTooltip("Open picker"));
    await tester.pumpAndSettle();
    expect(find.byType(DateTimePickerSurface), findsNothing);
  });

  testWidgets("semantics expose selected dates and mutation availability", (
    tester,
  ) async {
    await tester.pumpTestApp(child: const _DateTimeFieldHarness());
    await tester.tap(find.byTooltip("Open picker"));
    await tester.pumpAndSettle();

    final selected = tester.getSemantics(
      find.bySemanticsLabel("Monday, August 12, 2024"),
    );
    expect(selected.flagsCollection.isSelected, Tristate.isTrue);
    expect(selected.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
    expect(find.bySemanticsLabel("Time"), findsWidgets);
    expect(find.bySemanticsLabel("Hour"), findsWidgets);
    expect(find.bySemanticsLabel("Minute"), findsWidgets);
    expect(find.bySemanticsLabel("Second"), findsWidgets);
  });
}

class _DateTimeFieldHarness extends StatefulWidget {
  const _DateTimeFieldHarness({
    this.includeDate = true,
    this.enabled = true,
    this.readOnly = false,
    super.key,
  });

  final bool includeDate;
  final bool enabled;
  final bool readOnly;

  @override
  State<_DateTimeFieldHarness> createState() => _DateTimeFieldHarnessState();
}

class _DateTimeFieldHarnessState extends State<_DateTimeFieldHarness> {
  DateTime value = DateTime.utc(2024, 8, 12, 18, 30, 45, 123, 456);

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 420,
    child: DateTimePickerField(
      value: value,
      includeDate: widget.includeDate,
      includeTime: true,
      enabled: widget.enabled,
      readOnly: widget.readOnly,
      onChanged: (next) => setState(() => value = next),
    ),
  );
}
