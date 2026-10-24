import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";

import "../../support/test_utils.dart";

/// The Book item presentation the Kotlin catalog compiled, rendered from its
/// wire material with the appearance the panel binds.
void main() {
  final catalog = CheckedEditorCatalog(compiledSdkControlCatalog);
  final book = skir.ResourceId(value: "book:compiled");
  final record = _titled(compiledSdkBookRecord, "Main story");
  final selected = catalog.selectPresentation(
    record.configuration,
    skir.PresentationRole.item,
  ) as SelectedEditorPresentation;

  test("the compiled book item is the selected item presentation", () {
    expect(selected.material.provider.name, contains("BookItemPresentation"));
  });

  testWidgets(
    "a book item stands as a volume named and colored by its appearance",
    (tester) async {
      final appearance = catalog.appearanceOf(record);
      var interaction = const PresentationInteraction();
      late StateSetter update;
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
        budget: skir.EvaluationBudget(
          maxSteps: 10000,
          maxCollectionItems: 1000,
        ),
        catalog: catalog,
        queries: PortableExpressionQueries(
          catalog: catalog,
          authored: _Document(catalog, {book: record}),
        ),
        resource: book,
        role: skir.PresentationRole.item,
      ).withMaterial(selected.material);
      await tester.pumpTestApp(
        child: Center(
          child: SizedBox(
            width: 240,
            height: 333,
            child: StatefulBuilder(
              builder: (context, setState) {
                update = setState;
                return PresentationInteractionScope(
                  value: interaction,
                  child: PortablePresentationNodeRenderer(
                    node: selected.material.layout,
                    scope: scope,
                    fillAvailableSpace: true,
                  ),
                );
              },
            ),
          ),
        ),
      );
      expect(find.text("Main story"), findsOneWidget);
      final volume = find.ancestor(
        of: find.text("Main story"),
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is ConstrainedBox &&
              widget.constraints == BoxConstraints.tight(const Size(175, 230)),
        ),
      );
      expect(volume, findsOneWidget);
      expect(tester.getSize(volume), const Size(175, 230));
      final cover = find.ancestor(
        of: find.text("Main story"),
        matching: find.byType(SurfaceContainer),
      );
      expect(
        tester.widget<SurfaceContainer>(cover.first).decoration.color,
        appearance.accentColor,
      );
      List<double?> spineTops() => [
        for (final spine in tester.widgetList<AnimatedPositionedDirectional>(
          find.byType(AnimatedPositionedDirectional),
        ))
          if (spine.width == 30) spine.top,
      ];
      expect(spineTops(), [10, 5, 5, 5]);

      update(() => interaction = const PresentationInteraction(selected: true));
      await tester.pumpAndSettle();
      expect(spineTops(), [15, 12, 10, 5]);
      expect(tester.takeException(), isNull);
    },
  );
}

skir.AuthoringRecord _titled(skir.AuthoringRecord record, String title) =>
    skir.AuthoringRecord(
      configuration: record.configuration,
      fields: [
        for (final field in record.fields)
          if (field.name == "title")
            skir.FieldValue(
              name: "title",
              value: skir.DataValue.wrapStringValue(title),
            )
          else
            field,
      ],
    );

final class _Document implements PortableAuthoringView {
  _Document(this.catalog, this.resources);

  final CheckedEditorCatalog catalog;

  @override
  final Map<skir.ResourceId, skir.AuthoringRecord> resources;

  @override
  skir.CatalogGeneration get generation => catalog.snapshot.generation;

  @override
  List<skir.LinkProjection> get links => const [];

  @override
  skir.AuthoringRecord? resource(skir.ResourceId id) => resources[id];

  @override
  PortablePathResult<skir.DataValue> read(skir.ValueLocation location) =>
      const PortablePathUnavailable("Not read by the book item");

  @override
  skir.DataValue defaultValue(skir.TypeUse? type) => skir.DataValue.unfilled;
}
