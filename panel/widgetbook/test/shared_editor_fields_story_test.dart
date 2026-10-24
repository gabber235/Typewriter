import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:widgetbook_workspace/stories/shared/editors/presentation/components/color_picker/color_picker_field.stories.dart";
import "package:widgetbook_workspace/stories/shared/editors/presentation/components/date_time_picker/date_time_picker_field.stories.dart";
import "package:widgetbook_workspace/stories/shared/ui/input/input_field_container.stories.dart";
import "package:widgetbook_workspace/stories/shared/ui/input/validated_text_field.stories.dart";

void main() {
  testWidgets("input container enters and leaves editing by keyboard", (
    tester,
  ) async {
    await tester.pumpWidget(const InputFieldContainerStory());
    await tester.pumpAndSettle();

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.text("INSERT"), findsOneWidget);

    await tester.enterText(find.byType(TextField), "The found lantern");
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.text("NORMAL"), findsOneWidget);
    expect(find.text("Left editing 1 times"), findsOneWidget);
    expect(find.text("The found lantern"), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets("validated field retains the bound value for invalid drafts", (
    tester,
  ) async {
    await tester.pumpWidget(const ValidatedTextFieldStory());
    await tester.pumpAndSettle();
    expect(find.text("Bound value: 30"), findsOneWidget);

    await tester.enterText(find.byType(TextFormField), "soon");
    await tester.pump();
    expect(find.text("Enter whole seconds"), findsOneWidget);
    expect(find.text("Bound value: 30"), findsOneWidget);

    await tester.enterText(find.byType(TextFormField), "7200");
    await tester.pump();
    expect(find.text("Use at most 3600 seconds"), findsOneWidget);
    expect(find.text("Bound value: 30"), findsOneWidget);

    await tester.enterText(find.byType(TextFormField), "45");
    await tester.pumpAndSettle();
    expect(find.text("Bound value: 45"), findsOneWidget);

    await tester.enterText(find.byType(TextFormField), "");
    await tester.pumpAndSettle();
    expect(find.text("Bound value: empty"), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets("mixed validated field reports the first valid edit", (
    tester,
  ) async {
    await tester.pumpWidget(const ValidatedTextFieldStory(mixed: true));
    await tester.pumpAndSettle();
    expect(find.text("Bound value: mixed"), findsOneWidget);

    await tester.enterText(find.byType(TextFormField), "12");
    await tester.pumpAndSettle();
    expect(find.text("Bound value: 12"), findsOneWidget);
  });

  testWidgets("color field edits through text and opens its picker", (
    tester,
  ) async {
    await tester.pumpWidget(const ColorPickerFieldStory());
    await tester.pumpAndSettle();
    expect(find.text("Bound color: #CC7C4DFF"), findsOneWidget);

    await tester.enterText(find.byType(TextFormField), "123");
    await tester.pump();
    expect(find.textContaining("six RGB or eight ARGB"), findsOneWidget);
    expect(find.text("Bound color: #CC7C4DFF"), findsOneWidget);

    await tester.enterText(find.byType(TextFormField), "#FF3498DB");
    await tester.pumpAndSettle();
    expect(find.text("Bound color: #FF3498DB"), findsOneWidget);

    await tester.tap(find.byTooltip("Open color picker"));
    await tester.pumpAndSettle();
    expect(find.byType(ColorArea), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byType(ColorArea), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets("read only color field inspects without editing", (tester) async {
    await tester.pumpWidget(const ColorPickerFieldStory(readOnly: true));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip("Open color picker"));
    await tester.pumpAndSettle();
    expect(tester.widget<ColorArea>(find.byType(ColorArea)).enabled, isFalse);

    await tester.pumpWidget(const ColorPickerFieldStory(enabled: false));
    await tester.pumpAndSettle();
    expect(find.byTooltip("Open color picker"), findsNothing);
  });

  testWidgets("date field updates only complete drafts and opens its picker", (
    tester,
  ) async {
    await tester.pumpWidget(const DateTimePickerFieldStory());
    await tester.pumpAndSettle();
    expect(find.text("Bound start: 2026-10-31T18:30:00.000Z"), findsOneWidget);

    await tester.enterText(find.byType(TextFormField), "2026-11");
    await tester.pump();
    expect(find.text("Bound start: 2026-10-31T18:30:00.000Z"), findsOneWidget);

    await tester.enterText(find.byType(TextFormField), "2026-11-01 09:15:00");
    await tester.pumpAndSettle();
    expect(find.textContaining("Bound start: 2026-11-01T09:15:00"), findsOne);

    await tester.tap(find.byTooltip("Open picker"));
    await tester.pumpAndSettle();
    expect(find.byType(DateTimePickerSurface), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byType(DateTimePickerSurface), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
