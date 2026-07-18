import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/features/organizations/features/realms/features/books/features/pages/features/editor/domain/data_blueprint.dart";
import "package:typewriter_panel/features/organizations/features/realms/features/books/features/pages/features/editor/domain/dynamic_data.dart";
import "package:typewriter_panel/features/organizations/features/realms/features/books/features/pages/features/editor/domain/selection.dart";
import "package:typewriter_panel/features/organizations/features/realms/features/books/features/pages/features/editor/features/inspector/presentation/editors.dart";
import "package:typewriter_panel/features/organizations/features/realms/features/books/features/pages/features/editor/features/inspector/presentation/editors/field_editor.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";

import "../support/editor_utils.dart";

class TestSelectableDataWithTracking extends TestSelectableData {
  TestSelectableDataWithTracking(this.setCalls);

  final List<String> setCalls;

  @override
  Map<String, DynamicData> build() {
    return {};
  }

  @override
  void set(String id, DynamicData data) {
    setCalls.add("$id:${data.toJson()}");
  }
}

void main() {
  group("FieldValueEditor", () {
    testWidgets("Loading state shows skeleton and no input", (tester) async {
      final setCalls = <String>[];

      await tester.pumpEditor(
        overrides: [
          fieldValueProvider.overrideWith((_, _) => SelectedValue.loading()),
          testSelectableDataProvider.overrideWith(
            () => TestSelectableDataWithTracking(setCalls),
          ),
        ],
        path: "test",
        child: FieldValueEditor(
          path: "test",
          dataBlueprint: DataBlueprint.string(),
          editorMode: EditorMode.interactiveInspector,
          builder: (value) => Text(value.toString()),
        ),
      );

      expect(find.text("Bob"), findsNothing);
      // pumpEditor calls set() during setup, so we expect one call
      expect(setCalls.length, 1);

      await tester.tap(find.byType(FieldValueEditor));

      expect(find.text("Bob"), findsNothing);
      // Tapping should not trigger additional set() calls in loading state
      expect(setCalls.length, 1);
    });

    testWidgets("Value state shows the value", (tester) async {
      await tester.pumpEditor(
        overrides: [],
        path: "test",
        dataBlueprint: DataBlueprint.string(),
        child: FieldValueEditor(
          path: "test",
          dataBlueprint: DataBlueprint.string(),
          editorMode: EditorMode.interactiveInspector,
          builder: (value) => Text(value.toString()),
        ),
        initialData: {"test": "Bob"},
      );

      expect(find.text("Bob"), findsOneWidget);
    });

    testWidgets("None state shows reset UI and clicking resets to default", (
      tester,
    ) async {
      final dataBlueprint = DataBlueprint.string(defaultValue: "Bob");
      await tester.pumpEditor(
        overrides: [],
        path: "test",
        dataBlueprint: dataBlueprint,
        child: FieldValueEditor(
          path: "test",
          dataBlueprint: dataBlueprint,
          editorMode: EditorMode.interactiveInspector,
          builder: (value) => Text(value.toString()),
        ),
      );
      // Clear the auto generated data from the [pumpEditor] so it doesn't exist anymore
      tester.setTestSelectableData(data: {});
      await tester.pumpAndSettle();

      expect(find.text("Bob"), findsNothing);
      await tester.tap(find.byType(InkWell));
      await tester.pumpAndSettle();

      expect(find.text("Bob"), findsOneWidget);
    });

    testWidgets(
      "Conflict state shows reset UI and clicking resets to default",
      (tester) async {
        final path = "test";
        final dataBlueprint = DataBlueprint.string(defaultValue: "Bob");
        final objectBlueprint = ObjectBlueprint(fields: {path: dataBlueprint});
        await tester.pumpEditor(
          path: path,
          child: FieldValueEditor(
            path: path,
            dataBlueprint: dataBlueprint,
            editorMode: EditorMode.interactiveInspector,
            builder: (value) => Text(value.toString()),
          ),
        );

        tester
          ..selectSelectables([
            TestSelectableIdentifier(
              id: "first",
              dataBlueprint: objectBlueprint,
            ),
            TestSelectableIdentifier(
              id: "second",
              dataBlueprint: objectBlueprint,
            ),
          ])
          ..setTestSelectableData(selectedId: "first", data: {"test": "Alice"})
          ..setTestSelectableData(
            selectedId: "second",
            data: {"test": "Clare"},
          );

        await tester.pumpAndSettle();

        expect(find.text("Alic"), findsNothing);
        expect(find.text("Bob"), findsNothing);
        expect(find.text("Clare"), findsNothing);

        await tester.tap(find.byType(InkWell));
        await tester.pumpAndSettle();

        expect(find.text("Alic"), findsNothing);
        expect(find.text("Bob"), findsOneWidget);
        expect(find.text("Clare"), findsNothing);
      },
    );

    Future<void> runReadonlyNoneResetDisabled(
      WidgetTester tester, {
      required DataBlueprint dataBlueprint,
      required EditorMode editorMode,
    }) async {
      await tester.pumpEditor(
        overrides: [],
        path: "test",
        dataBlueprint: dataBlueprint,
        child: FieldValueEditor(
          path: "test",
          dataBlueprint: dataBlueprint,
          editorMode: editorMode,
          builder: (value) => Text(value.toString()),
        ),
      );
      tester.setTestSelectableData(data: {});
      await tester.pumpAndSettle();

      expect(find.text("Bob"), findsNothing);

      await tester.tap(find.byType(InkWell));
      await tester.pumpAndSettle();

      expect(find.text("Bob"), findsNothing);
    }

    Future<void> runReadonlyConflictResetDisabled(
      WidgetTester tester, {
      required DataBlueprint dataBlueprint,
      required EditorMode editorMode,
    }) async {
      final path = "test";
      final objectBlueprint = ObjectBlueprint(fields: {path: dataBlueprint});
      await tester.pumpEditor(
        path: path,
        child: FieldValueEditor(
          path: path,
          dataBlueprint: dataBlueprint,
          editorMode: editorMode,
          builder: (value) => Text(value.toString()),
        ),
      );

      tester
        ..selectSelectables([
          TestSelectableIdentifier(id: "first", dataBlueprint: objectBlueprint),
          TestSelectableIdentifier(
            id: "second",
            dataBlueprint: objectBlueprint,
          ),
        ])
        ..setTestSelectableData(selectedId: "first", data: {"test": "Alice"})
        ..setTestSelectableData(selectedId: "second", data: {"test": "Clare"});

      await tester.pumpAndSettle();

      expect(find.text("Alic"), findsNothing);
      expect(find.text("Bob"), findsNothing);
      expect(find.text("Clare"), findsNothing);

      await tester.tap(find.byType(InkWell));
      await tester.pumpAndSettle();

      expect(find.text("Alic"), findsNothing);
      expect(find.text("Bob"), findsNothing);
      expect(find.text("Clare"), findsNothing);
    }

    testWidgets("None state does not reset when editor is read-only (mode)", (
      tester,
    ) async {
      final dataBlueprint = DataBlueprint.string(defaultValue: "Bob");
      await runReadonlyNoneResetDisabled(
        tester,
        dataBlueprint: dataBlueprint,
        editorMode: EditorMode.readOnlyInspector,
      );
    });

    testWidgets(
      "None state does not reset when editor is read-only (modifier)",
      (tester) async {
        final dataBlueprint = DataBlueprint.string(
          defaultValue: "Bob",
          modifiers: [Modifier.readOnly()],
        );
        await runReadonlyNoneResetDisabled(
          tester,
          dataBlueprint: dataBlueprint,
          editorMode: EditorMode.interactiveInspector,
        );
      },
    );

    testWidgets(
      "Conflict state does not reset when editor is read-only (mode)",
      (tester) async {
        final dataBlueprint = DataBlueprint.string(defaultValue: "Bob");
        await runReadonlyConflictResetDisabled(
          tester,
          dataBlueprint: dataBlueprint,
          editorMode: EditorMode.readOnlyInspector,
        );
      },
    );

    testWidgets(
      "Conflict state does not reset when editor is read-only (modifier)",
      (tester) async {
        final dataBlueprint = DataBlueprint.string(
          defaultValue: "Bob",
          modifiers: [Modifier.readOnly()],
        );
        await runReadonlyConflictResetDisabled(
          tester,
          dataBlueprint: dataBlueprint,
          editorMode: EditorMode.interactiveInspector,
        );
      },
    );
  });
}
