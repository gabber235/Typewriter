import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

final _resource = skir.ResourceId(value: "entry:compiled");

void main() {
  testWidgets("an owned graph shows each entry's local name", (tester) async {
    var document = compiledEntryNodeDocument();
    await tester.showCompiledEntryGraph(document);
    expect(find.text("Welcome to the village"), findsOneWidget);

    document = document.changedRemotely(
      (edit) => edit.set(
        skir.ValueLocation(
          resource: compiledEntryFirstId,
          path: editorRootPath.field("name"),
        ),
        skir.DataValue.wrapStringValue("Local rename"),
      ),
    );
    await tester.showCompiledEntryGraph(document);

    expect(find.text("Local rename"), findsOneWidget);
    expect(find.text("Welcome to the village"), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets("a concrete item presentation fills its graph nodes", (
    tester,
  ) async {
    await tester.showCompiledEntryGraph(
      compiledEntryNodeDocument().withConcreteEntryItems(),
    );

    expect(find.text("Concrete surface"), findsNWidgets(2));
    expect(find.text("Welcome to the village"), findsNothing);
    expect(tester.takeException(), isNull);
  });

  for (final mode in [ThemeMode.light, ThemeMode.dark]) {
    testWidgets("a compiled entry shows its name and frames each interaction "
        "state differently in $mode", (tester) async {
      final document = _document;
      Future<BorderSide> frameIn(PresentationInteraction state) async {
        await tester.pumpPanel(
          [if (mode == ThemeMode.dark) dark],
          at: PanelLocation.component(
            SizedBox(
              width: 200,
              height: 50,
              child: PresentationInteractionScope(
                value: state,
                child: AuthoredResourceEditor(
                  resource: _resource,
                  document: document,
                  role: skir.PresentationRole.item,
                  budget: skir.EvaluationBudget(
                    maxSteps: 10000,
                    maxCollectionItems: 1000,
                  ),
                  fillAvailableSpace: true,
                ),
              ),
            ),
          ),
        );
        return tester
            .widgetList<SurfaceContainer>(find.byType(SurfaceContainer))
            .map((surface) => surface.decoration.border)
            .whereType<Border>()
            .single
            .top;
      }

      final idle = await frameIn(const PresentationInteraction());
      expect(find.text("Compiled entry"), findsOneWidget);
      final selected = await frameIn(
        const PresentationInteraction(selected: true),
      );
      final focused = await frameIn(
        const PresentationInteraction(selected: true, focused: true),
      );
      final readOnly = await frameIn(
        const PresentationInteraction(selected: true, readOnly: true),
      );

      expect(selected, isNot(idle));
      expect(focused, isNot(selected));
      // Read only content keeps the selection visible.
      expect(readOnly, selected);
      expect(tester.takeException(), isNull);
    });

    for (final size in [const Size(50, 50), const Size(200, 100)]) {
      final singleCell = size.width == 50;
      testWidgets("a compiled entry ${singleCell ? "hides" : "shows"} its "
          "name in a ${size.width.round()} by ${size.height.round()} node in "
          "$mode", (tester) async {
        await tester.pumpPanel(
          [if (mode == ThemeMode.dark) dark],
          at: PanelLocation.component(
            SizedBox.fromSize(
              size: size,
              child: AuthoredResourceEditor(
                resource: _resource,
                document: _document,
                role: skir.PresentationRole.item,
                budget: skir.EvaluationBudget(
                  maxSteps: 10000,
                  maxCollectionItems: 1000,
                ),
                fillAvailableSpace: true,
              ),
            ),
          ),
        );

        expect(tester.takeException(), isNull);
        expect(
          find.text("Compiled entry").hitTestable(),
          singleCell ? findsNothing : findsOneWidget,
        );
      });
    }
  }
}

final _entry = selectionOfUse(compiledSdkElementValue.authoredActualType!);
final _catalog = CheckedEditorCatalog(compiledSdkControlCatalog);

/// One compiled entry named "Compiled entry", its other fields at their
/// defaults.
final _document = AuthoringDocument(
  catalog: _catalog,
  entries: {
    _resource: skir.AuthoringResource(
      id: _resource,
      content: skir.AuthoringRecord(
        types: const [],
        configuration: _entry,
        fields: [
          for (final field in _catalog.fields(_entry))
            skir.FieldValue(
              name: field.template.key,
              value: field.template.key == "name"
                  ? skir.DataValue.wrapStringValue("Compiled entry")
                  : AuthoringDocument(
                      catalog: _catalog,
                      entries: const {},
                      links: const [],
                    ).defaultValue(field.type),
            ),
        ],
      ),
    ),
  },
  links: const [],
);
