import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

const _picker = "Date and time picker";

void main() {
  testWidgets("direct typing updates only complete valid drafts", (
    tester,
  ) async {
    final (panel, value) = await tester.showDateTimeField();

    await panel.fieldAt(0).type("2028-02");
    expect(panel.shows("Use YYYY-MM-DD HH:mm:ss"), isTrue);
    expect(value().year, 2024);

    await panel.fieldAt(0).type("2028-02-29 07:06:05");
    expect(value(), DateTime.utc(2028, 2, 29, 7, 6, 5, 123, 456));
  });

  testWidgets("closed field uses its format as a placeholder", (tester) async {
    final (panel, _) = await tester.showDateTimeField();

    expect(find.text("YYYY-MM-DD HH:mm:ss"), findsOneWidget);
    expect(panel.shows("This value is Unfilled"), isFalse);
  });

  testWidgets("picker opens, dismisses, and returns focus to its action", (
    tester,
  ) async {
    final (panel, _) = await tester.showDateTimeField();

    await panel.tapOn(find.tooltip("Open picker"));
    expect(panel.shows(_picker), isTrue);

    await panel.press(LogicalKeyboardKey.escape);
    expect(panel.shows(_picker), isFalse);
    expect(panel.hasFocusOn("Open picker"), isTrue);

    await panel.tapOn(find.tooltip("Open picker"));
    await tester.tapAt(const Offset(4, 4));
    await panel.settle();
    expect(panel.shows(_picker), isFalse);
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
    final (panel, _) = await tester.showDateTimeField();

    await panel.press(LogicalKeyboardKey.tab);
    await panel.pressPrimary(LogicalKeyboardKey.keyC);
    expect(clipboardText, "2024-08-12 18:30:45");

    await panel.press(LogicalKeyboardKey.keyP);
    expect(panel.shows(_picker), isTrue);
    await panel.press(LogicalKeyboardKey.keyP);
    expect(panel.shows(_picker), isFalse);
  });

  testWidgets("calendar supports spatial, month, year, and boundary keys", (
    tester,
  ) async {
    final (panel, value) = await tester.showDateTimeField();
    await panel.tapOn(find.tooltip("Open picker"));

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(value().day, 13);

    await tester.sendKeyEvent(LogicalKeyboardKey.end);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(value().day, 31);

    await tester.sendKeyEvent(LogicalKeyboardKey.pageDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(value(), DateTime.utc(2024, 9, 30, 18, 30, 45, 123, 456));

    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.pageUp);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(value().year, 2023);
  });

  testWidgets("pointer date selection preserves time precision", (
    tester,
  ) async {
    final (panel, value) = await tester.showDateTimeField();
    await panel.tapOn(find.tooltip("Open picker"));

    await panel.tapOn(panel.labeled("Thursday, August 22, 2024"));
    expect(value(), DateTime.utc(2024, 8, 22, 18, 30, 45, 123, 456));
  });

  testWidgets("month and year pickers move directly to their selection", (
    tester,
  ) async {
    final (panel, _) = await tester.showDateTimeField();
    await panel.tapOn(find.tooltip("Open picker"));

    await panel.tapOn(panel.labeled("August"));
    expect(panel.shows("Choose month"), isTrue);
    await panel.tapOn(find.bySemanticsLabel(RegExp("February")));
    expect(panel.shows(_picker), isTrue);
    expect(panel.shows("Monday, February 12, 2024"), isTrue);

    await panel.tapOn(panel.labeled("2024"));
    await panel.tapOn(find.bySemanticsLabel(RegExp("2028")));
    expect(panel.shows(_picker), isTrue);
    expect(panel.shows("Saturday, February 12, 2028"), isTrue);
  });

  testWidgets("month and year pickers support keyboard selection", (
    tester,
  ) async {
    final (panel, _) = await tester.showDateTimeField();
    await panel.tapOn(find.tooltip("Open picker"));

    await panel.tapOn(panel.labeled("August"));
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await panel.press(LogicalKeyboardKey.enter);
    expect(panel.shows("Thursday, September 12, 2024"), isTrue);

    await panel.tapOn(panel.labeled("2024"));
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await panel.press(LogicalKeyboardKey.enter);
    expect(panel.shows("Friday, September 12, 2025"), isTrue);

    expect(panel.shows(_picker), isTrue);
  });

  testWidgets("time fields support direct typing and keyboard increments", (
    tester,
  ) async {
    final (panel, value) = await tester.showDateTimeField(includeDate: false);
    await panel.tapOn(find.tooltip("Open picker"));

    await panel.field("Hour").focus();
    await panel.press(LogicalKeyboardKey.end);
    expect(value().hour, 23);

    await panel.press(LogicalKeyboardKey.pageDown);
    expect(value().hour, 17);

    await panel.field("Minute").type("07");
    expect(panel.field("Minute").value, "07");
    expect(value().minute, 7);
    expect(value().second, 45);
    expect(value().microsecond, 456);

    await panel.field("Second").type("09");
    expect(value().second, 9);
    expect(value().microsecond, 456);
  });

  testWidgets("escape leaves time editing before closing the picker", (
    tester,
  ) async {
    final (panel, _) = await tester.showDateTimeField(includeDate: false);
    await panel.tapOn(find.tooltip("Open picker"));
    expect(panel.field("Hour").isFocused, isTrue);
    expect(tester.testTextInput.hasAnyClients, isTrue);

    await panel.press(LogicalKeyboardKey.escape);
    expect(panel.shows(_picker), isTrue);
    // The field keeps focus but no longer takes typed text.
    expect(panel.field("Hour").isFocused, isTrue);
    expect(tester.testTextInput.hasAnyClients, isFalse);

    await panel.press(LogicalKeyboardKey.escape);
    expect(panel.shows(_picker), isFalse);
  });

  testWidgets("two valid digits advance through the time fields", (
    tester,
  ) async {
    final (panel, _) = await tester.showDateTimeField(includeDate: false);
    await panel.tapOn(find.tooltip("Open picker"));

    await panel.field("Hour").type("99");
    expect(panel.field("Hour").isFocused, isTrue);

    await panel.field("Hour").type("09");
    expect(panel.field("Minute").isFocused, isTrue);

    await panel.field("Minute").type("08");
    expect(panel.field("Second").isFocused, isTrue);
  });

  testWidgets("time fields select their whole value on focus", (tester) async {
    final (panel, _) = await tester.showDateTimeField(includeDate: false);
    await panel.tapOn(find.tooltip("Open picker"));

    const whole = TextSelection(baseOffset: 0, extentOffset: 2);
    expect(panel.field("Hour").selection, whole);

    await panel.field("Hour").type("09");
    expect(panel.field("Minute").isFocused, isTrue);
    expect(panel.field("Minute").selection, whole);
  });

  testWidgets("time fields sit in one row under their own labels", (
    tester,
  ) async {
    final (panel, _) = await tester.showDateTimeField(includeDate: false);
    await panel.tapOn(find.tooltip("Open picker"));
    await panel.field("Minute").type("99");

    for (final label in ["Hour", "Minute", "Second"]) {
      expect(find.text(label), findsOneWidget);
      expect(
        tester.getCenter(find.text(label)).dy,
        lessThan(panel.field(label).rect.top),
      );
    }
    final fieldTops = {
      for (final label in ["Hour", "Minute", "Second"])
        panel.field(label).rect.top,
    };
    expect(fieldTops, hasLength(1));

    // The separators carry no semantics; their keys are the only handle.
    final hourCenter = panel.field("Hour").rect.center;
    for (final index in [1, 2]) {
      final separatorCenter = tester.getCenter(
        find.byKey(ValueKey("date_time_separator_$index")),
      );
      expect(separatorCenter.dy, closeTo(hourCenter.dy, 0.1));
    }
  });

  testWidgets("focus remains trapped inside the open picker", (tester) async {
    final (panel, _) = await tester.showDateTimeField();
    await panel.tapOn(find.tooltip("Open picker"));
    final picker = semanticsLabeled(_picker).single;

    for (var index = 0; index < 12; index++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      final focused = find.semantics
          .byPredicate((node) => node.isFocused)
          .evaluate();
      expect(focused, isNotEmpty);
      expect(picker.descendants, contains(focused.last));
    }
  });

  testWidgets("read only permits inspection while disabled cannot open", (
    tester,
  ) async {
    final (panel, readOnlyValue) = await tester.showDateTimeField(
      readOnly: true,
    );
    expect(find.tooltip("Open picker"), findsNothing);

    await panel.press(LogicalKeyboardKey.tab);
    await panel.press(LogicalKeyboardKey.keyP);
    expect(panel.shows(_picker), isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(readOnlyValue().day, 12);

    // A separate field, so nothing the read only one opened carries over.
    await tester.showDateTimeField(enabled: false, key: const Key("disabled"));
    await panel.tapOn(find.tooltip("Open picker"));
    expect(panel.shows(_picker), isFalse);
  });

  testWidgets("semantics expose selected dates and mutation availability", (
    tester,
  ) async {
    final (panel, _) = await tester.showDateTimeField();
    await panel.tapOn(find.tooltip("Open picker"));

    final selected = semanticsLabeled("Monday, August 12, 2024").single;
    expect(
      selected.getSemanticsData().flagsCollection.isSelected,
      Tristate.isTrue,
    );
    expect(selected.isTappable, isTrue);
    expect(panel.shows("Time"), isTrue);
    for (final label in ["Hour", "Minute", "Second"]) {
      expect(panel.field(label).exists, isTrue);
    }
  });
}
