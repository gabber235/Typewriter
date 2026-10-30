import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";
import "package:widgetbook_workspace/stories/shared/editors/presentation/components/color_picker/color_picker_field.stories.dart";
import "package:widgetbook_workspace/stories/shared/editors/presentation/components/date_time_picker/date_time_picker_field.stories.dart";

import "support/stories.dart";

void main() {
  testWidgets("color field binds valid text only and its picker opens and "
      "closes by keyboard", (tester) async {
    final panel = (await tester.pumpStory(colorPickerFieldUseCase))!;
    expect(panel.shows("Bound color: #CC7C4DFF"), isTrue);

    await panel.fieldAt(0).type("123");
    expect(panel.shows("Bound color: #CC7C4DFF"), isTrue);
    expect(find.textContaining("six RGB or eight ARGB").evaluate(), isNotEmpty);

    await panel.fieldAt(0).type("#FF3498DB");
    expect(panel.shows("Bound color: #FF3498DB"), isTrue);

    await panel.tapOn(find.tooltip("Open color picker"));
    expect(panel.shows("Hue"), isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await panel.settle();
    expect(panel.shows("Hue"), isFalse);
  });

  testWidgets("a read only color field opens its picker without changing "
      "the color, and a disabled one never opens it", (tester) async {
    final panel = (await tester.pumpStory(
      colorPickerFieldUseCase,
      knobs: {"Read only": "true"},
    ))!;
    await panel.tapOn(find.tooltip("Open color picker"));
    await panel.tapOn(find.bySemanticsLabel(RegExp("^Color #")).first);
    expect(panel.shows("Bound color: #CC7C4DFF"), isTrue);

    await tester.pumpStory(
      colorPickerFieldUseCase,
      knobs: {"Enabled": "false"},
    );
    await tester.tap(find.tooltip("Open color picker"), warnIfMissed: false);
    await tester.runStory();
    expect(find.text("Hue"), findsNothing);
  });

  testWidgets("date field binds complete drafts only and its picker opens and "
      "closes by keyboard", (tester) async {
    final panel = (await tester.pumpStory(dateTimePickerFieldUseCase))!;
    expect(panel.shows("Bound start: 2026-10-31T18:30:00.000Z"), isTrue);

    await panel.fieldAt(0).type("2026-11");
    expect(panel.shows("Bound start: 2026-10-31T18:30:00.000Z"), isTrue);

    await panel.fieldAt(0).type("2026-11-01 09:15:00");
    expect(
      find.textContaining("Bound start: 2026-11-01T09:15:00").evaluate(),
      isNotEmpty,
    );

    await panel.tapOn(find.tooltip("Open picker"));
    expect(panel.shows("Date and time picker"), isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await panel.settle();
    expect(panel.shows("Date and time picker"), isFalse);
  });
}
