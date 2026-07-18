import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/features/organizations/features/realms/features/books/features/pages/features/editor/domain/data_blueprint.dart";
import "package:typewriter_panel/features/organizations/features/realms/features/books/features/pages/features/editor/features/inspector/presentation/editors.dart";
import "package:typewriter_panel/features/organizations/features/realms/features/books/features/pages/features/editor/features/inspector/presentation/editors/string_editor.dart";

import "../support/editor_utils.dart";

void main() {
  group("StringEditor", () {
    testWidgets("renders existing value and updates on change", (tester) async {
      await tester.pumpEditor(
        dataBlueprint: DataBlueprint.string(),
        initialData: {"test": "Bob"},
      );

      expect(find.text("Bob"), findsOneWidget);
      expect(tester.fieldValue(), "Bob");

      await tester.enterText(find.byType(TextField), "Alice");
      await tester.pumpAndSettle();
      expect(find.text("Alice"), findsOneWidget);
      expect(tester.fieldValue(), "Alice");
    });

    testWidgets("multiline modifier allows multiple lines", (tester) async {
      await tester.pumpEditor(
        dataBlueprint: DataBlueprint.string(modifiers: [Modifier.multiline()]),
      );

      await tester.enterText(find.byType(TextField), "Line 1\nLine 2");
      await tester.pumpAndSettle();

      expect(find.text("Line 1\nLine 2"), findsOneWidget);
      expect(tester.fieldValue(), "Line 1\nLine 2");
    });

    testWidgets("readOnly mode disables editing", (tester) async {
      await tester.pumpEditor(
        dataBlueprint: DataBlueprint.string(),
        initialData: {"test": "Bob"},
        editorMode: EditorMode.readOnlyInspector,
      );

      expect(find.text("Bob"), findsOneWidget);

      await tester.enterText(find.byType(TextField), "Alice");
      await tester.pumpAndSettle();

      expect(find.text("Bob"), findsOneWidget);
      expect(find.text("Alice"), findsNothing);
      expect(tester.fieldValue(), "Bob");

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.readOnly, isTrue);
    });

    testWidgets("readOnly modifier disables editing even in interactive mode", (
      tester,
    ) async {
      await tester.pumpEditor(
        dataBlueprint: DataBlueprint.string(modifiers: [Modifier.readOnly()]),
        initialData: {"test": "Bob"},
        editorMode: EditorMode.interactiveInspector,
      );

      expect(find.text("Bob"), findsOneWidget);

      await tester.enterText(find.byType(TextField), "Alice");
      await tester.pumpAndSettle();

      expect(find.text("Bob"), findsOneWidget);
      expect(find.text("Alice"), findsNothing);
      expect(tester.fieldValue(), "Bob");

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.readOnly, isTrue);
    });

    testWidgets("default hint is shown when no hint is provided", (
      tester,
    ) async {
      await tester.pumpEditor(dataBlueprint: DataBlueprint.string());

      expect(find.text("Enter a string"), findsOneWidget);
    });

    testWidgets("hint parameter overrides default", (tester) async {
      await tester.pumpEditor(
        dataBlueprint: DataBlueprint.string(),
        child: StringEditorWidget(
          path: "test",
          primitiveBlueprint: DataBlueprint.string() as PrimitiveBlueprint,
          editorMode: EditorMode.interactiveInspector,
          hint: "Custom hint",
        ),
      );

      expect(find.text("Custom hint"), findsOneWidget);
    });

    testWidgets("forceValue shows forced text and still updates on change", (
      tester,
    ) async {
      await tester.pumpEditor(
        dataBlueprint: DataBlueprint.string(),
        child: StringEditorWidget(
          path: "test",
          primitiveBlueprint: DataBlueprint.string() as PrimitiveBlueprint,
          editorMode: EditorMode.interactiveInspector,
          forceValue: "Forced",
        ),
      );

      expect(find.text("Forced"), findsOneWidget);

      await tester.enterText(find.byType(TextField), "Alice");
      await tester.pumpAndSettle();

      expect(tester.fieldValue(), "Alice");
      expect(find.text("Alice"), findsOneWidget);
    });

    testWidgets("snake_case modifier formats input to snake_case", (
      tester,
    ) async {
      await tester.pumpEditor(
        dataBlueprint: DataBlueprint.string(modifiers: [Modifier.snakeCase()]),
      );

      await tester.enterText(find.byType(TextField), "Hello World");
      await tester.pumpAndSettle();

      expect(find.text("hello_world"), findsOneWidget);
      expect(tester.fieldValue(), "hello_world");
    });
  });
}
