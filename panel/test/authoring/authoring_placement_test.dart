import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  group("a created graph resource", () {
    // Two graph resources of one type: an existing one and one just created
    // with a refined, tinted placement of the same size.
    final root = testTypeId("GraphResource");
    final refined = testTypeId("TintedGraphPlacement");
    final integer = skir.TypeTemplate.wrapScalar(
      skir.ScalarKind.createInteger(width: skir.IntegerWidth.signedThirtyTwo),
    );
    final catalog = testCheckedCatalog(
      types: [
        testPublishedRecord(root, {
          "placement": skir.TypeTemplate.createNamed(
            definition: graphPlacementTypeRef,
            arguments: const [],
          ),
        }, placementField: editorRootPath.field("placement")),
        testPublishedRecord(graphPlacementTypeRef, {
          for (final key in ["x", "y", "width", "height"]) key: integer,
        }),
        testPublishedRecord(
          refined,
          {
            for (final key in ["x", "y", "width", "height"]) key: integer,
            "tint": skir.TypeTemplate.wrapScalar(skir.ScalarKind.text),
          },
          parents: [
            skir.NamedTypeTemplate(
              definition: graphPlacementTypeRef,
              arguments: const [],
            ),
          ],
        ),
      ],
    );
    final configuration = catalog.beginSelection(root);
    final existing = skir.ResourceId(value: "tag:existing");
    final created = skir.ResourceId(value: "tag:created");
    final placement = GraphPlacement(x: 0, y: 0, width: 3, height: 2);
    late AuthoringEdit draft;
    setUp(() {
      draft =
          AuthoringEdit(
            generation: catalog.snapshot.generation,
            catalog: catalog,
            resources: [
              for (final id in [existing, created])
                skir.AuthoringResource(
                  id: id,
                  content: skir.AuthoringRecord(
                    configuration: configuration,
                    fields: [
                      skir.FieldValue(
                        name: "placement",
                        value: id == existing
                            ? placement.toAuthoredValue()
                            : skir.DataValue.createNamed(
                                actualType: skir.NamedTypeUse(
                                  definition: refined,
                                  arguments: const [],
                                ),
                                payload: skir.DataValue.createRecord(
                                  fields: [
                                    ...placement
                                        .toAuthoredValue()
                                        .authoredRecord!
                                        .fields,
                                    skir.FieldValue(
                                      name: "tint",
                                      value: skir.DataValue.wrapStringValue(
                                        "blue",
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
            ],
            links: const [],
          )..placeCreatedResource(
            ResourceCreationRequest(
              id: created,
              type: root,
              configuration: configuration,
            ),
          );
    });

    test("is placed clear of its siblings at its own size", () {
      final before = draft.resource(existing)!.graphRect(catalog)!;
      final after = draft.resource(created)!.graphRect(catalog)!;

      expect(before, placement.gridRect);
      expect(after.overlaps(before, gap: 1), isFalse);
      expect(after.width, placement.width);
      expect(after.height, placement.height);
    });

    test("keeps the refined placement type it was prepared with", () {
      final placement = draft.resource(created)!.authoredField("placement")!;

      expect(placement.authoredActualType!.definition, refined);
      expect(placement.authoredField("tint")!.authoredString, "blue");
    });

    test("refuses a resize to no width and keeps its rectangle", () {
      final placed = draft.resource(created)!.graphRect(catalog);

      expect(() => draft.resizeGraphPlacement(created, 0, 4), throwsStateError);

      expect(draft.resource(created)!.graphRect(catalog), placed);
    });
  });

  test("a placement with an unfilled coordinate reads as unfinished at it", () {
    final unfinished = skir.DataValue.createNamed(
      actualType: skir.NamedTypeUse(
        definition: graphPlacementTypeRef,
        arguments: const [],
      ),
      payload: skir.DataValue.createRecord(
        fields: [
          skir.FieldValue(name: "x", value: skir.DataValue.unfilled),
          for (final key in ["y", "width", "height"])
            skir.FieldValue(name: key, value: skir.DataValue.wrapInteger("1")),
        ],
      ),
    ).readPlacement(CheckedEditorCatalog(skir.EditorCatalog.defaultInstance));

    expect(unfinished, PlacementReading.unfinished(editorRootPath.field("x")));
  });

  final graphValue = skir.DataValue.createRecord(
    fields: [
      skir.FieldValue(name: "x", value: skir.DataValue.wrapInteger("1")),
      skir.FieldValue(name: "y", value: skir.DataValue.wrapInteger("2")),
      skir.FieldValue(name: "width", value: skir.DataValue.wrapInteger("3")),
      skir.FieldValue(name: "height", value: skir.DataValue.wrapInteger("4")),
    ],
  );

  test("placement variants are selected by declared type identity", () {
    final placement = skir.DataValue.createNamed(
      actualType: skir.NamedTypeUse(
        definition: graphPlacementTypeRef,
        arguments: const [],
      ),
      payload: graphValue,
    ).readPlacement(CheckedEditorCatalog(skir.EditorCatalog.defaultInstance));

    expect(placement, isA<ReadyPlacement>());
    expect(
      (placement as ReadyPlacement).placement,
      GraphPlacement(x: 1, y: 2, width: 3, height: 4),
    );
  });

  test("placement decoding rejects an unknown type with a familiar shape", () {
    final unknown = skir.TypeDefinitionId(
      typeId: skir.TypeId.createDeclared(
        value: "b3af85bf5a024f2b8806fb3d5c4f15ec",
      ),
      revision: 1,
    );

    expect(
      skir.DataValue.createNamed(
        actualType: skir.NamedTypeUse(definition: unknown, arguments: const []),
        payload: graphValue,
      ).readPlacement(CheckedEditorCatalog(skir.EditorCatalog.defaultInstance)),
      isA<UnavailablePlacement>(),
    );
  });
}
