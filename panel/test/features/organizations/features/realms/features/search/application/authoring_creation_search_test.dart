import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";

final _refProvider = Provider<Ref>((ref) => ref);

void main() {
  test("creation option identity includes unfinished type arguments", () {
    final definition = skir.ResourceDefinitionId(value: "test.book");
    final type = _definition("Book");
    final first = AuthoringCreationOption(
      definition: definition,
      configuration: skir.TypeSelection.createPending(
        definition: type,
        arguments: [
          skir.ArgumentSelection.wrapChosen(
            skir.TypeUse.wrapScalar(skir.ScalarKind.text),
          ),
        ],
      ),
      label: "Book",
    );
    final second = AuthoringCreationOption(
      definition: definition,
      configuration: skir.TypeSelection.createPending(
        definition: type,
        arguments: [
          skir.ArgumentSelection.wrapChosen(
            skir.TypeUse.wrapScalar(skir.ScalarKind.boolean),
          ),
        ],
      ),
      label: "Book",
    );

    expect(first.id, isNot(second.id));
  });

  test(
    "creation search includes concrete resources with required relationships",
    () async {
      final fixture = _fixture();
      addTearDown(fixture.container.dispose);
      addTearDown(fixture.subscription.close);
      addTearDown(fixture.controller.dispose);
      await pumpEventQueue();

      expect(fixture.controller.snapshot.status, SearchSourceStatus.ready);
      final section =
          fixture.controller.snapshot.nodes.single as SearchSectionNode;
      final option =
          section.children
                  .whereType<SearchResultNode>()
                  .singleWhere(
                    (node) =>
                        (node.result.payload as AuthoringCreationOption)
                            .definition
                            .value ==
                        "test.book",
                  )
                  .result
                  .payload
              as AuthoringCreationOption;
      expect(section.children, hasLength(2));
      final entryOption =
          section.children
                  .whereType<SearchResultNode>()
                  .singleWhere(
                    (node) =>
                        (node.result.payload as AuthoringCreationOption)
                            .definition
                            .value ==
                        "test.entry",
                  )
                  .result
                  .payload
              as AuthoringCreationOption;
      expect(
        entryOption.configuration,
        skir.TypeSelection.createComplete(
          definition: _definition("SimpleMessage"),
          arguments: const [],
        ),
      );
      expect(option.definition, skir.ResourceDefinitionId(value: "test.book"));
      expect(option.label, "Quest Book");
      expect(option.display?.description, "A reusable quest collection");
      expect(option.display?.icon, "material-symbols:book");
      expect(option.display?.color, "#3F51B5");
      expect(
        option.configuration,
        skir.TypeSelection.createComplete(
          definition: _definition("Book"),
          arguments: const [],
        ),
      );
    },
  );

  test("creation search does not depend on ownership endpoint order", () async {
    final fixture = _fixture(reversedOwnership: true);
    addTearDown(fixture.container.dispose);
    addTearDown(fixture.subscription.close);
    addTearDown(fixture.controller.dispose);
    await pumpEventQueue();

    final section =
        fixture.controller.snapshot.nodes.single as SearchSectionNode;
    expect(
      section.children.whereType<SearchResultNode>().map(
        (node) =>
            (node.result.payload as AuthoringCreationOption).definition.value,
      ),
      containsAll(["test.book", "test.entry"]),
    );
  });

  test("creation search filters by the resource label", () async {
    final fixture = _fixture();
    addTearDown(fixture.container.dispose);
    addTearDown(fixture.subscription.close);
    addTearDown(fixture.controller.dispose);
    await pumpEventQueue();

    fixture.controller.updateQuery("missing");
    await pumpEventQueue();

    expect(fixture.controller.snapshot.nodes, isEmpty);
  });

  test(
    "type and text filters apply before the creation result limit",
    () async {
      final fixture = _fixture(manyEntries: true);
      addTearDown(fixture.container.dispose);
      addTearDown(fixture.subscription.close);
      addTearDown(fixture.controller.dispose);
      await pumpEventQueue();
      expect(
        (fixture.controller.snapshot.nodes.single as SearchSectionNode)
            .children,
        hasLength(20),
      );
      fixture.controller.updateQuery("type:Entry ZMessage");
      await pumpEventQueue();
      final section =
          fixture.controller.snapshot.nodes.single as SearchSectionNode;
      final option =
          (section.children.single as SearchResultNode).result.payload
              as AuthoringCreationOption;
      expect(option.label, "ZMessage");
      expect(option.definition.value, "test.entry");
      expect(
        option.configuration,
        skir.TypeSelection.createComplete(
          definition: _definition("ZMessage"),
          arguments: const [],
        ),
      );
    },
  );
}

({
  ProviderContainer container,
  ProviderSubscription<AsyncValue<AuthoringDocument>> subscription,
  SourceController controller,
})
_fixture({bool reversedOwnership = false, bool manyEntries = false}) {
  final organization = skir.RecordId(
    table: "organization",
    key: skir.RecordIdKey.wrapString("test"),
  );
  final realm = skir.RecordId(
    table: "realm",
    key: skir.RecordIdKey.wrapString("test"),
  );
  final container = ProviderContainer.test(
    overrides: [
      organizationIdProvider.overrideWithValue(organization),
      realmIdProvider.overrideWithValue(realm),
      ...authoringFixtureOverrides(
        catalog: _catalog(
          reversedOwnership: reversedOwnership,
          manyEntries: manyEntries,
        ),
      ),
    ],
  );
  final subscription = container.listen(
    selectedWorkingAuthoringDocumentProvider,
    (_, _) {},
  );
  final controller = SourceController(
    source: AuthoringCreationSearchSource(container.read(_refProvider)),
    baseSelectors: const [],
  )..triggerQuery();
  return (
    container: container,
    subscription: subscription,
    controller: controller,
  );
}

CheckedEditorCatalog _catalog({
  bool reversedOwnership = false,
  bool manyEntries = false,
}) {
  final book = _definition("Book");
  final entry = _definition("Entry");
  final owner = skir.EndpointDefinition(
    id: skir.EndpointId(value: "book.entries.book"),
    slot: reversedOwnership
        ? skir.EndpointSlot.second
        : skir.EndpointSlot.first,
    resource: skir.NamedTypeTemplate(definition: book, arguments: const []),
    cardinality: skir.EndpointCardinality.one,
    onDelete: skir.RelationDeletePolicy.clear,
  );
  final child = skir.EndpointDefinition(
    id: skir.EndpointId(value: "book.entries.entry"),
    slot: reversedOwnership
        ? skir.EndpointSlot.first
        : skir.EndpointSlot.second,
    resource: skir.NamedTypeTemplate(definition: entry, arguments: const []),
    cardinality: skir.EndpointCardinality.many,
    onDelete: skir.RelationDeletePolicy.cascade,
  );
  return CheckedEditorCatalog(
    skir.EditorCatalogWireSnapshot(
      resourceOperations: const [],
      resourceOperationContributions: const [],
      generation: skir.CatalogGeneration(value: "catalog:test"),
      types: [
        _published(
          book,
          display: skir.TypeDisplay(
            name: "Quest Book",
            description: "A reusable quest collection",
            icon: "material-symbols:book",
            color: "#3F51B5",
          ),
        ),
        _published(entry, abstract: true),
        _published(_definition("SimpleMessage"), parent: entry),
        if (manyEntries) ...[
          for (var index = 0; index < 25; index++)
            _published(_definition("Entry$index"), parent: entry),
          _published(_definition("ZMessage"), parent: entry),
        ],
      ],
      relations: [
        skir.RelationContract(
          id: skir.RelationId(value: "book.entries"),
          first: reversedOwnership ? child : owner,
          second: reversedOwnership ? owner : child,
          families: [skir.RelationFamilyId(value: "resource.ownership")],
        ),
      ],
      resourceDefinitions: [
        skir.AuthoringResourceDefinition(
          id: skir.ResourceDefinitionId(value: "test.book"),
          root: book,
          navigationHandler: skir.AuthoringNavigationHandler.generic,
        ),
        skir.AuthoringResourceDefinition(
          id: skir.ResourceDefinitionId(value: "test.entry"),
          root: entry,
          navigationHandler: skir.AuthoringNavigationHandler.generic,
        ),
      ],
      presentations: const [],
      presentationMaterials: const [],
      configuration: const [],
      diagnostics: const [],

      endpointBindings: const [],
      capabilities: const [],
      recommendations: const [],
      roleFallbacks: const [],
    ),
  );
}

skir.PublishedType _published(
  skir.TypeDefinitionId id, {
  skir.TypeDisplay? display,
  bool abstract = false,
  skir.TypeDefinitionId? parent,
}) => skir.PublishedType(
  definition: skir.TypeDefinition(
    id: id,
    parameters: const [],
    representation: skir.RepresentationTemplate.createRecord(
      fields: const [],
      abstract_: abstract,
    ),
    parents: [
      if (parent != null)
        skir.NamedTypeTemplate(definition: parent, arguments: const []),
    ],
  ),
  status: skir.DeclarationStatus.ready,
  effectiveFields: const [],
  ancestorTemplates: [
    if (parent != null)
      skir.NamedTypeTemplate(definition: parent, arguments: const []),
  ],
  display: display,
);

skir.TypeDefinitionId _definition(String name) => skir.TypeDefinitionId(
  typeId: skir.TypeId.createQualified(namespace: "test", name: name),
  revision: 1,
);
