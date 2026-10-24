import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";

import "../../../support/test_utils.dart";

void main() {
  testWidgets(
    "compiled inherited fields, parts and placement survive edits and reload",
    (tester) async {
      var value = compiledSdkInheritedInspectorValue;
      var catalog = CheckedEditorCatalog(compiledSdkControlCatalog);
      final writes = <skir.ValuePath>[];

      BoundPresentationHost createHost() {
        final actual = value.authoredActualType!;
        final selected = catalog.selectPresentation(
          skir.TypeSelection.wrapComplete(actual),
          skir.PresentationRole.inspector,
        ) as SelectedEditorPresentation;
        expect(
          selected.descriptor.id,
          skir.PresentationId(
            namespace: "fixture",
            name: "inherited child inspector",
          ),
        );
        final host = BoundPresentationHost(
          catalog: catalog,
          root: () => selected.material.layout,
          role: selected.resolvedRole,
          material: selected.material,
          bindings: [
            BoundPresentationBinding(
              id: skir.ExpressionBindingId(value: "configured_value"),
              use: skir.TypeUse.wrapNamed(actual),
              read: (path) => value.editorValueAt(path),
              write: (path, replacement) {
                final result = value.replaceAt(
                  path,
                  replacement,
                ) as PortablePathValue<skir.DataValue>;
                value = result.value;
                writes.add(path);
                return const PortablePresentationWriteResult.applied();
              },
            ),
          ],
          budget: skir.EvaluationBudget(
            maxSteps: 1000,
            maxCollectionItems: 1000,
          ),
        );
        addTearDown(host.dispose);
        return host;
      }

      Future<void> pumpHost(BoundPresentationHost host) => tester.pumpTestApp(
        child: Scaffold(
          body: SingleChildScrollView(
            child: PortablePresentationRenderer(host: host),
          ),
        ),
      );

      List<String> values() => tester
          .widgetList<TextFormField>(find.byType(TextFormField))
          .map((field) => field.controller!.text)
          .toList();

      void expectOrder(List<String> expected) {
        expect(values(), expected);
        expect(find.text("Entry heading"), findsOneWidget);
        expect(find.text("Shared details"), findsOneWidget);
        final fields = find.byType(TextFormField);
        expect(
          tester.getTopLeft(find.text("Entry heading")).dy,
          greaterThan(tester.getTopLeft(fields.at(0)).dy),
        );
        expect(
          tester.getTopLeft(find.text("Entry heading")).dy,
          lessThan(tester.getTopLeft(fields.at(1)).dy),
        );
        expect(
          tester.getTopLeft(find.text("Shared details")).dy,
          greaterThan(tester.getTopLeft(fields.at(1)).dy),
        );
        expect(
          tester.getTopLeft(find.text("Shared details")).dy,
          lessThan(tester.getTopLeft(fields.at(2)).dy),
        );
        expect(tester.takeException(), isNull);
      }

      final placement = compiledSdkPlacementValue;
      final coordinates = [
        for (final field in ["x", "y", "width", "height"])
          placement.authoredField(field)!.authoredInteger!.toString(),
      ];
      await pumpHost(createHost());
      await tester.pumpAndSettle();
      expectOrder([
        "Welcome",
        "Hello player",
        "Shared note",
        "Cooldown",
        ...coordinates,
      ]);

      await tester.enterText(find.byType(TextFormField).first, "  Renamed  ");
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      expect(value.authoredField("name")?.authoredString, "Renamed");
      expect(writes.last, editorRootPath.field("name"));

      await tester.enterText(find.byType(TextFormField).at(2), "Changed note");
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(value.authoredField("notes")?.authoredString, "Changed note");
      expect(writes.last, editorRootPath.field("notes"));

      await tester.enterText(find.byType(TextFormField).at(4), "37");
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      expect(
        value.authoredField("placement")?.authoredField("x")?.authoredInteger,
        BigInt.from(37),
      );
      expect(writes.last, editorRootPath.field("placement").field("x"));

      await tester.pumpWidget(const SizedBox.shrink());
      value = skir.DataValue.serializer.fromBytes(
        skir.DataValue.serializer.toBytes(value),
      );
      catalog = CheckedEditorCatalog(
        skir.EditorCatalog.serializer.fromBytes(
          skir.EditorCatalog.serializer.toBytes(compiledSdkControlCatalog),
        ),
      );
      await pumpHost(createHost());
      await tester.pumpAndSettle();
      expectOrder([
        "Renamed",
        "Hello player",
        "Changed note",
        "Cooldown",
        "37",
        ...coordinates.skip(1),
      ]);
    },
  );
}
