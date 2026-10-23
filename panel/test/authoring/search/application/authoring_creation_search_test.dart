import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";

import "../../../support/catalog_fixture.dart";

final _refProvider = Provider<Ref>((ref) => ref);

void main() {
  test("creation option identity includes unfinished type arguments", () {
    final type = _definition("Book");
    final first = AuthoringCreationOption(
      type: type,
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
      type: type,
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
                        (node.result.payload as AuthoringCreationOption).type ==
                        _definition("Book"),
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
                        (node.result.payload as AuthoringCreationOption).type ==
                        _definition("SimpleMessage"),
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
      expect(option.label, "Quest Book");
      expect(option.display?.description, "A reusable quest collection");
      expect(
        option.display?.icon,
        skir.Icon.wrapIconify("material-symbols:book"),
      );
      expect(option.display?.color, skir.Color(argb: 0xff3f51b5.toSigned(32)));
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
        (node) => (node.result.payload as AuthoringCreationOption).type,
      ),
      containsAll([_definition("Book"), _definition("SimpleMessage")]),
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

  test("scope keywords come from owner search keys and keep only types inside that scope", () async {
    final fixture = _fixture();
    addTearDown(fixture.container.dispose);
    addTearDown(fixture.subscription.close);
    addTearDown(fixture.controller.dispose);
    await pumpEventQueue();
    final source = AuthoringCreationSearchSource(
      fixture.container.read(_refProvider),
    );
    final controller = SourceController(source: source, baseSelectors: const [])
      ..triggerQuery();
    addTearDown(controller.dispose);

    expect(
      source.selectors.whereType<KeyValueSelectorDefinition>().map(
        (selector) => selector.key,
      ),
      unorderedEquals(["book:", "shelf:", "type:"]),
    );
    controller.updateQuery('book:"Lost tales"');
    await pumpEventQueue();

    final option =
        ((controller.snapshot.nodes.single as SearchSectionNode).children.single
                    as SearchResultNode)
                .result
                .payload
            as AuthoringCreationOption;
    expect(option.type, _definition("SimpleMessage"));
    expect(option.disabledReason, 'No Quest Book named "Lost tales"');
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
      expect(option.type, _definition("ZMessage"));
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
      ...appOverrides(),
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
  return testCheckedCatalog(
    generation: skir.CatalogGeneration(value: "catalog:test"),
    types: [
      _published(
        book,
        searchKey: "book",
        display: skir.TypeDisplay(
          name: "Quest Book",
          description: "A reusable quest collection",
          icon: skir.Icon.wrapIconify("material-symbols:book"),
          color: skir.Color(argb: 0xff3f51b5.toSigned(32)),
        ),
      ),
      _published(_definition("Shelf"), searchKey: "shelf"),
      _published(entry, abstract: true),
      _published(_definition("SimpleMessage"), parent: entry),
      if (manyEntries) ...[
        for (var index = 0; index < 25; index++)
          _published(_definition("Entry$index"), parent: entry),
        _published(_definition("ZMessage"), parent: entry),
      ],
    ],
    relations: [
      // A shelf owns Books, which makes them creatable resources.
      skir.RelationContract(
        id: skir.RelationId(value: "shelf.books"),
        first: skir.EndpointDefinition(
          id: skir.EndpointId(value: "shelf.books.shelf"),
          slot: skir.EndpointSlot.first,
          resource: skir.NamedTypeTemplate(
            definition: _definition("Shelf"),
            arguments: const [],
          ),
          cardinality: skir.EndpointCardinality.one,
          onDelete: skir.RelationDeletePolicy.cascade,
        ),
        second: skir.EndpointDefinition(
          id: skir.EndpointId(value: "shelf.books.book"),
          slot: skir.EndpointSlot.second,
          resource: skir.NamedTypeTemplate(
            definition: book,
            arguments: const [],
          ),
          cardinality: skir.EndpointCardinality.many,
          onDelete: skir.RelationDeletePolicy.clear,
        ),
        families: [skir.resourceOwnershipFamily],
      ),
      skir.RelationContract(
        id: skir.RelationId(value: "book.entries"),
        first: reversedOwnership ? child : owner,
        second: reversedOwnership ? owner : child,
        families: [skir.resourceOwnershipFamily],
      ),
    ],
    realmRoot: skir.TypeDefinitionId.defaultInstance,
  );
}

skir.PublishedType _published(
  skir.TypeDefinitionId id, {
  skir.TypeDisplay? display,
  bool abstract = false,
  skir.TypeDefinitionId? parent,
  String? searchKey,
}) => skir.PublishedType(
  searchKey: searchKey,
  placementField: null,
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
  display: display ?? defaultTypeDisplay(""),
);

skir.TypeDefinitionId _definition(String name) => skir.TypeDefinitionId(
  typeId: skir.TypeId.createQualified(namespace: "test", name: name),
  revision: 1,
);
