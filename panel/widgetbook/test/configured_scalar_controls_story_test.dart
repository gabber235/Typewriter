import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:widgetbook_workspace/stories/shared/editors/presentation/configured_scalar_controls.stories.dart";

void main() {
  testWidgets(
    "scalar gallery retains native keyboard completion and inherited appearance",
    (tester) async {
      await tester.pumpWidget(configuredScalarControlsStory());
      await tester.pumpAndSettle();
      final input = find.widgetWithText(TextFormField, "12.25");
      await tester.enterText(input, "12.26");
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.widgetWithText(TextFormField, "12.5"), findsOneWidget);
      final decoration = tester
          .widget<TextField>(
            find.descendant(
              of: find.widgetWithText(TextFormField, "12.5"),
              matching: find.byType(TextField),
            ),
          )
          .decoration!;
      expect(decoration.border, isA<OutlineInputBorder>());
      expect(
        (decoration.border! as OutlineInputBorder).borderSide,
        BorderSide.none,
      );
      expect(
        (decoration.border! as OutlineInputBorder).borderRadius,
        isNot(BorderRadius.zero),
      );
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    "scalar gallery can remove intrinsic icons without disabling content",
    (tester) async {
      await tester.pumpWidget(
        configuredScalarControlsStory(
          noIcon: true,
          compact: true,
          readOnly: true,
        ),
      );
      await tester.pumpAndSettle();
      final field = tester.widget<TextField>(
        find.descendant(
          of: find.widgetWithText(TextFormField, "Quest checkpoint"),
          matching: find.byType(TextField),
        ),
      );
      expect(field.decoration!.prefixIcon, isNull);
      expect(
        tester
            .widget<EditableText>(
              find.descendant(
                of: find.widgetWithText(TextFormField, "Quest checkpoint"),
                matching: find.byType(EditableText),
              ),
            )
            .readOnly,
        isTrue,
      );
      expect(tester.takeException(), isNull);
    },
  );
}
