import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

void main() {
  testWidgets("an owner exposes its declared relation fields", (tester) async {
    final owner = ResolvedTypeRef(
      id: const QualifiedTypeId(namespace: "test", name: "Owner"),
      revision: 1,
    );
    final child = ResolvedTypeRef(
      id: const QualifiedTypeId(namespace: "test", name: "Child"),
      revision: 1,
    );
    final catalog = RealmEditorCatalogSnapshot(
      catalog: TypeCatalog([
        TypeDefinition(
          id: owner,
          kind: NominalTypeKind.concrete,
          representation: RecordType(fields: {
            "cues": TypeField(
              name: "cues",
              type: ListType(element: ReferenceType(target: child)),
            ),
          }),
        ),
        TypeDefinition(id: child, kind: NominalTypeKind.concrete),
      ]),
      generation: const CatalogGeneration("test"),
      relations: {
        "test.cues": RealmRelationDefinition(
          id: "test.cues",
          source: owner,
          target: child,
          onSourceDelete: RealmRelationDeletePolicy.cascade,
          onTargetDelete: RealmRelationDeletePolicy.clear,
          sourceEndpoint: RealmRelationEndpointDefinition(
            owner: owner,
            path: DataPath.root.field("cues"),
            side: RealmRelationEndpointSide.source,
            cardinality: RealmRelationCardinality.many,
          ),
          targetEndpoint: null,
          families: const {"resource.ownership"},
        ),
      },
    );
    await tester.pumpWidget(ProviderScope(
      overrides: [
        realmEditorCatalogProvider.overrideWith(
          (ref) => Stream.value(RealmEditorCatalogState.ready(catalog)),
        ),
      ],
      child: MaterialApp(home: Scaffold(body: RelationAddMenu(
        host: skir.ResourceId(value: "owner"),
        rootType: owner,
      ))),
    ));
    await tester.pumpAndSettle();

    expect(find.byTooltip("Add related resource"), findsOneWidget);
    await tester.tap(find.byTooltip("Add related resource"));
    await tester.pumpAndSettle();
    expect(find.byType(PopupMenuItem<RealmRelationField>), findsOneWidget);
    expect(find.text("Cues"), findsOneWidget);
  });
}
