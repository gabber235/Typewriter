import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/widgets/app/components/validated_text_field.dart";

import "../../../test_utils.dart";

void main() {
  group("ValidatedTextField", () {
    group("number validation", () {
      testWidgets("shows error when value below minimum", (tester) async {
        const min = 5;
        String? validator(int value) {
          if (value < min) return "Value must be at least $min";
          return null;
        }

        await tester.pumpTestApp(
          child: SizedBox(
            width: 400,
            child: ValidatedTextField<int>(
              value: 10,
              deserialize: (v) => v.toString(),
              serialize: int.parse,
              validator: validator,
              name: "number",
            ),
          ),
        );

        final textField = find.byType(TextField);
        expect(textField, findsOneWidget);

        await tester.tap(textField);
        await tester.pumpAndSettle();

        await tester.enterText(textField, "3");
        await tester.pumpAndSettle();

        expect(find.text("Value must be at least 5"), findsOneWidget);
      });

      testWidgets("shows error when value above maximum", (tester) async {
        const max = 10;
        String? validator(int value) {
          if (value > max) return "Value must be at most $max";
          return null;
        }

        await tester.pumpTestApp(
          child: SizedBox(
            width: 400,
            child: ValidatedTextField<int>(
              value: 5,
              deserialize: (v) => v.toString(),
              serialize: int.parse,
              validator: validator,
              name: "number",
            ),
          ),
        );

        final textField = find.byType(TextField);
        await tester.tap(textField);
        await tester.pumpAndSettle();

        await tester.enterText(textField, "15");
        await tester.pumpAndSettle();

        expect(find.text("Value must be at most 10"), findsOneWidget);
      });

      testWidgets("no error shown when value is within valid range", (
        tester,
      ) async {
        const min = 5;
        const max = 10;
        String? validator(int value) {
          if (value < min) return "Value must be at least $min";
          if (value > max) return "Value must be at most $max";
          return null;
        }

        await tester.pumpTestApp(
          child: SizedBox(
            width: 400,
            child: ValidatedTextField<int>(
              value: 5,
              deserialize: (v) => v.toString(),
              serialize: int.parse,
              validator: validator,
              name: "number",
            ),
          ),
        );

        final textField = find.byType(TextField);
        await tester.tap(textField);
        await tester.pumpAndSettle();

        await tester.enterText(textField, "7");
        await tester.pumpAndSettle();

        expect(find.text("Value must be at least 5"), findsNothing);
        expect(find.text("Value must be at most 10"), findsNothing);
      });

      testWidgets("calls onChanged callback with valid parsed value", (
        tester,
      ) async {
        int? lastValue;

        await tester.pumpTestApp(
          child: SizedBox(
            width: 400,
            child: ValidatedTextField<int>(
              value: 5,
              deserialize: (v) => v.toString(),
              serialize: int.parse,
              validator: (_) => null,
              onChanged: (value) => lastValue = value,
              name: "number",
            ),
          ),
        );

        final textField = find.byType(TextField);
        await tester.tap(textField);
        await tester.pumpAndSettle();

        await tester.enterText(textField, "42");
        await tester.pumpAndSettle();

        expect(lastValue, equals(42));
      });

      testWidgets("does not call onChanged when value fails validation", (
        tester,
      ) async {
        int? lastValue;

        await tester.pumpTestApp(
          child: SizedBox(
            width: 400,
            child: ValidatedTextField<int>(
              value: 5,
              deserialize: (v) => v.toString(),
              serialize: int.parse,
              validator: (v) => v < 10 ? "Too small" : null,
              onChanged: (value) => lastValue = value,
              name: "number",
            ),
          ),
        );

        final textField = find.byType(TextField);
        await tester.tap(textField);
        await tester.pumpAndSettle();

        await tester.enterText(textField, "3");
        await tester.pumpAndSettle();

        expect(lastValue, isNull);
        expect(find.text("Too small"), findsOneWidget);
      });
    });

    group("double parsing", () {
      testWidgets("parses decimal values correctly", (tester) async {
        double? lastValue;

        await tester.pumpTestApp(
          child: SizedBox(
            width: 400,
            child: ValidatedTextField<double>(
              value: 0.0,
              deserialize: (v) => v.toString(),
              serialize: double.parse,
              validator: (_) => null,
              onChanged: (value) => lastValue = value,
              name: "decimal",
            ),
          ),
        );

        final textField = find.byType(TextField);
        await tester.tap(textField);
        await tester.pumpAndSettle();

        await tester.enterText(textField, "3.14");
        await tester.pumpAndSettle();

        expect(lastValue, equals(3.14));
      });

      testWidgets("shows parse error for invalid decimal input", (
        tester,
      ) async {
        await tester.pumpTestApp(
          child: SizedBox(
            width: 400,
            child: ValidatedTextField<double>(
              value: 0.0,
              deserialize: (v) => v.toString(),
              serialize: double.parse,
              validator: (_) => null,
              name: "decimal",
            ),
          ),
        );

        final textField = find.byType(TextField);
        await tester.tap(textField);
        await tester.pumpAndSettle();

        await tester.enterText(textField, "abc");
        await tester.pumpAndSettle();

        // Should show an error message about invalid format
        expect(find.textContaining("Invalid"), findsOneWidget);
      });
    });
  });
}
