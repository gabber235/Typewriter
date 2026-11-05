import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  final catalog = CheckedEditorCatalog(compiledSdkControlCatalog);
  final book = skir.ResourceId(value: "book:compiled");
  final record = skir.AuthoringRecord(
    configuration: compiledSdkBookRecord.configuration,
    fields: [
      for (final field in compiledSdkBookRecord.fields)
        if (field.name == "title")
          skir.FieldValue(
            name: "title",
            value: skir.DataValue.wrapStringValue("Main story"),
          )
        else
          field,
    ],
  );
  final selected = catalog.selectPresentation(
    record.configuration,
    skir.PresentationRole.item,
  ) as SelectedEditorPresentation;

  testWidgets("a book item shows its title on a cover in its accent color", (
    tester,
  ) async {
    final appearance = catalog.appearanceOf(record);
    final scope = PortablePresentationScope(
      operations: testPortableOperations(),
      bindings: {
        configuredValueBindingId: PortableExpressionBinding(
          value: compiledSdkBookValue,
          location: skir.ValueLocation(resource: book, path: editorRootPath),
          schema: CompletePortablePresentationBinding(
            skir.TypeUse.wrapNamed(
              (record.configuration as skir.TypeSelection_completeWrapper)
                  .value,
            ),
          ),
        ),
        presentationSubjectIdentifierBindingId: book.toExpressionBinding(),
        presentationSubjectAppearanceBindingId: appearance
            .toExpressionBinding(),
      },
      budget: skir.EvaluationBudget(maxSteps: 10000, maxCollectionItems: 1000),
      catalog: catalog,
      queries: PortableExpressionQueries(
        catalog: catalog,
        authored: AuthoringDocument(
          catalog: catalog,
          entries: {book: skir.AuthoringResource(id: book, content: record)},
          links: const [],
        ),
      ),
      resource: book,
      role: skir.PresentationRole.item,
    ).withMaterial(selected.material);
    await tester.pumpPanel(
      const [],
      at: PanelLocation.component(
        SizedBox(
          width: 240,
          height: 333,
          child: PortablePresentationNodeRenderer(
            node: selected.material.layout,
            scope: scope,
            fillAvailableSpace: true,
          ),
        ),
      ),
    );
    expect(find.text("Main story"), findsOneWidget);
    final cover = find.ancestor(
      of: find.text("Main story"),
      matching: find.byType(SurfaceContainer),
    );
    expect(
      tester.widget<SurfaceContainer>(cover.first).decoration.color,
      appearance.accentColor,
    );
    expect(tester.takeException(), isNull);
  });
}
