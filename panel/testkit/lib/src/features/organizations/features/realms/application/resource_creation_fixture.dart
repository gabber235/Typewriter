import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

import "package:typewriter_testkit/typewriter_testkit.dart";

/// A small catalog of ordinary value requirements, independent of ownership
/// policy between its resources. A store type owns every resource type
/// through its own field, which makes them creatable without adding owner
/// questions.
final class ResourceCreationFixture {
  /// Books owned by a Library that already exists, and pages owned by Books,
  /// each linking back to its owner, as Realm declares them. Creating a page
  /// with a new Book is the creation flow Realm's panel creation test commits.
  ResourceCreationFixture.library() : generation = _libraryGeneration {
    _store = false;
    _record("Library", {"books": _named("Books")}, resource: false);
    _record("Book", {
      "title": _text,
      "library": _named("BookLibrary"),
      "pages": _named("Pages"),
    });
    _record("Page", {"name": _text, "book": _named("PageBook")});
    _sequence("Books", "LibraryBook");
    _sequence("Pages", "BookPage");
    _relation(
      "libraryBooks",
      "Library",
      "books",
      "Book",
      "library",
      "LibraryBook",
      "BookLibrary",
      collection: true,
      ownership: true,
    );
    _relation(
      "bookPages",
      "Book",
      "pages",
      "Page",
      "book",
      "BookPage",
      "PageBook",
      collection: true,
      ownership: true,
    );
  }

  ResourceCreationFixture({bool abstractReport = false})
    : generation = skir.CatalogGeneration(value: "creation:flow") {
    _record("Book", {"title": _text, "pages": _named("Pages")});
    _record("Page", {
      "name": _text,
      "book": _named("PageBook"),
      "elements": _named("Elements"),
    });
    _record("Entry", {"page": _named("EntryPage"), "message": _text});
    _record("Report", {
      if (abstractReport)
        "payload": _named("Delivery")
      else
        "reviewer": _named("ReportBook"),
    });
    if (abstractReport) {
      _record("Delivery", {}, abstract: true, resource: false);
      _record(
        "EmailDelivery",
        {"recipient": _named("ReportBook")},
        parent: "Delivery",
        resource: false,
      );
      _record(
        "PostalDelivery",
        {"recipient": _named("ReportBook")},
        parent: "Delivery",
        resource: false,
      );
    }
    _record("A", {"b": _named("AToB")});
    _record("B", {"a": _named("BToA")});
    _sequence("Pages", "BookPage");
    _sequence("Elements", "PageEntry");
    _relation(
      "bookPages",
      "Book",
      "pages",
      "Page",
      "book",
      "BookPage",
      "PageBook",
      collection: true,
    );
    _relation(
      "pageEntries",
      "Page",
      "elements",
      "Entry",
      "page",
      "PageEntry",
      "EntryPage",
      collection: true,
    );
    _relation("cycle", "A", "b", "B", "a", "AToB", "BToA");
    _relation(
      "review",
      "Report",
      "reviewer",
      "Book",
      null,
      "ReportBook",
      "BookReport",
      sourceBinding: !abstractReport,
    );
  }
  static final _libraryGeneration = skir.CatalogGeneration(
    value: "creation:library",
  );
  final skir.CatalogGeneration generation;
  var _store = true;
  final library = skir.ResourceId(value: "library:existing");
  final book = skir.ResourceId(value: "book:existing");
  final page = skir.ResourceId(value: "page:existing");
  final _types = <skir.PublishedType>[];
  final _resources = <String>[];
  final _bindings = <skir.EndpointBindingTemplate>[];
  final _relations = <skir.RelationContract>[];
  final _text = skir.TypeTemplate.wrapScalar(skir.ScalarKind.text);

  skir.TypeDefinitionId _id(String name) => skir.TypeDefinitionId(
    typeId: skir.TypeId.createQualified(namespace: "creation", name: name),
    revision: 1,
  );
  skir.NamedTypeTemplate _template(String name) =>
      skir.NamedTypeTemplate(definition: _id(name), arguments: const []);
  skir.TypeTemplate _named(String name) =>
      skir.TypeTemplate.wrapNamed(_template(name));
  skir.TypeSelection _selection(String name) =>
      skir.TypeSelection.createComplete(
        definition: _id(name),
        arguments: const [],
      );
  ResourceCreationRequest request(String name) =>
      ResourceCreationRequest(type: _id(name), configuration: _selection(name));

  void _publish(
    String name,
    skir.RepresentationTemplate representation, {
    List<skir.EffectiveFieldTemplate> fields = const [],
    String? parent,
  }) {
    _types.add(
      skir.PublishedType(
        searchKey: null,
        placementField: fields.any((field) => field.key == "placement")
            ? editorRootPath.field("placement")
            : null,
        definition: skir.TypeDefinition(
          id: _id(name),
          parameters: const [],
          representation: representation,
          parents: [if (parent != null) _template(parent)],
        ),
        status: skir.DeclarationStatus.ready,
        effectiveFields: fields,
        ancestorTemplates: [if (parent != null) _template(parent)],
        display: skir.TypeDisplay(
          name: name,
          description: "",
          icon: skir.Icon.wrapIconify(""),
          color: skir.Color(argb: 0xff607d8b.toSigned(32)),
        ),
      ),
    );
  }

  void _record(
    String name,
    Map<String, skir.TypeTemplate> fields, {
    bool abstract = false,
    bool resource = true,
    String? parent,
  }) {
    _publish(
      name,
      skir.RepresentationTemplate.createRecord(
        abstract_: abstract,
        fields: [
          for (final field in fields.entries)
            skir.FieldDeclaration(
              owner: skir.FieldOwner(definition: _id(name), name: field.key),
              type: field.value,
              overrides: const [],
              hasConstructorDefault: false,
            ),
        ],
      ),
      fields: [
        for (final field in fields.entries)
          skir.EffectiveFieldTemplate(
            key: field.key,
            owner: skir.FieldOwner(definition: _id(name), name: field.key),
            type: field.value,
            rules: const [],
          ),
      ],
      parent: parent,
    );
    if (resource) _resources.add(name);
  }

  void _sequence(String name, String item) => _publish(
    name,
    skir.RepresentationTemplate.createSequence(
      item: _named(item),
      kind: skir.CollectionKind.list,
    ),
  );

  void _relation(
    String name,
    String first,
    String firstField,
    String second,
    String? secondField,
    String firstLink,
    String secondLink, {
    bool collection = false,
    bool sourceBinding = true,
    bool ownership = false,
  }) {
    final firstEndpoint = skir.EndpointId(value: "$name:first");
    final secondEndpoint = skir.EndpointId(value: "$name:second");
    _publish(
      firstLink,
      skir.RepresentationTemplate.createLink(
        endpoint: firstEndpoint,
        target: _named(second),
      ),
    );
    _publish(
      secondLink,
      skir.RepresentationTemplate.createLink(
        endpoint: secondEndpoint,
        target: _named(first),
      ),
    );
    _relations.add(
      skir.RelationContract(
        id: skir.RelationId(value: name),
        families: [
          if (ownership) skir.RelationFamilyId(value: "resource.ownership"),
        ],
        first: skir.EndpointDefinition(
          id: firstEndpoint,
          slot: skir.EndpointSlot.first,
          resource: _template(first),
          cardinality: skir.EndpointCardinality.one,
          onDelete: skir.RelationDeletePolicy.clear,
        ),
        second: skir.EndpointDefinition(
          id: secondEndpoint,
          slot: skir.EndpointSlot.second,
          resource: _template(second),
          cardinality: collection
              ? skir.EndpointCardinality.many
              : skir.EndpointCardinality.one,
          onDelete: skir.RelationDeletePolicy.clear,
        ),
      ),
    );
    if (sourceBinding) {
      _binding(first, firstField, firstEndpoint, second, collection);
    }
    if (secondField != null) {
      _binding(second, secondField, secondEndpoint, first, false);
    }
  }

  void _binding(
    String owner,
    String field,
    skir.EndpointId endpoint,
    String target,
    bool collection,
  ) {
    _bindings.add(
      skir.EndpointBindingTemplate(
        endpoint: endpoint,
        containingResource: _template(owner),
        valueOwner: _id(owner),
        target: _named(target),
        containsCollection: collection,
        relativePath: skir.RelativeFieldPattern(
          segments: [
            skir.FieldPatternSegment.createField(name: field),
            if (collection) skir.FieldPatternSegment.items,
          ],
        ),
      ),
    );
  }

  /// The store type and its ownership of every resource type.
  ({
    List<skir.PublishedType> types,
    List<skir.RelationContract> relations,
    List<skir.EndpointBindingTemplate> bindings,
  })
  _realm() {
    final types = <skir.PublishedType>[];
    if (!_store) return (types: types, relations: const [], bindings: const []);
    final relations = <skir.RelationContract>[];
    final bindings = <skir.EndpointBindingTemplate>[];
    final fields = <String, skir.TypeTemplate>{};
    for (final name in _resources) {
      final owner = skir.EndpointId(value: "owns$name:first");
      types
        ..add(
          skir.PublishedType(
            searchKey: null,
            placementField: null,
            definition: skir.TypeDefinition(
              id: _id("Owned$name"),
              parameters: const [],
              representation: skir.RepresentationTemplate.createLink(
                endpoint: owner,
                target: _named(name),
              ),
              parents: const [],
            ),
            status: skir.DeclarationStatus.ready,
            effectiveFields: const [],
            ancestorTemplates: const [],
            display: defaultTypeDisplay("Owned $name"),
          ),
        )
        ..add(
          skir.PublishedType(
            searchKey: null,
            placementField: null,
            definition: skir.TypeDefinition(
              id: _id("Owned${name}List"),
              parameters: const [],
              representation: skir.RepresentationTemplate.createSequence(
                item: _named("Owned$name"),
                kind: skir.CollectionKind.list,
              ),
              parents: const [],
            ),
            status: skir.DeclarationStatus.ready,
            effectiveFields: const [],
            ancestorTemplates: const [],
            display: defaultTypeDisplay("Owned $name list"),
          ),
        );
      fields["owned$name"] = _named("Owned${name}List");
      relations.add(
        skir.RelationContract(
          id: skir.RelationId(value: "owns$name"),
          families: [skir.RelationFamilyId(value: "resource.ownership")],
          first: skir.EndpointDefinition(
            id: owner,
            slot: skir.EndpointSlot.first,
            resource: _template("Store"),
            cardinality: skir.EndpointCardinality.one,
            onDelete: skir.RelationDeletePolicy.cascade,
          ),
          second: skir.EndpointDefinition(
            id: skir.EndpointId(value: "owns$name:second"),
            slot: skir.EndpointSlot.second,
            resource: _template(name),
            cardinality: skir.EndpointCardinality.many,
            onDelete: skir.RelationDeletePolicy.clear,
          ),
        ),
      );
      bindings.add(
        skir.EndpointBindingTemplate(
          endpoint: owner,
          containingResource: _template("Store"),
          valueOwner: _id("Store"),
          target: _named(name),
          containsCollection: true,
          relativePath: skir.RelativeFieldPattern(
            segments: [
              skir.FieldPatternSegment.createField(name: "owned$name"),
              skir.FieldPatternSegment.items,
            ],
          ),
        ),
      );
    }
    types.add(
      skir.PublishedType(
        searchKey: null,
        placementField: null,
        definition: skir.TypeDefinition(
          id: _id("Store"),
          parameters: const [],
          representation: skir.RepresentationTemplate.createRecord(
            abstract_: false,
            fields: [
              for (final field in fields.entries)
                skir.FieldDeclaration(
                  owner: skir.FieldOwner(
                    definition: _id("Store"),
                    name: field.key,
                  ),
                  type: field.value,
                  overrides: const [],
                  hasConstructorDefault: false,
                ),
            ],
          ),
          parents: const [],
        ),
        status: skir.DeclarationStatus.ready,
        effectiveFields: [
          for (final field in fields.entries)
            skir.EffectiveFieldTemplate(
              key: field.key,
              owner: skir.FieldOwner(definition: _id("Store"), name: field.key),
              type: field.value,
              rules: const [],
            ),
        ],
        ancestorTemplates: const [],
        display: defaultTypeDisplay("Store"),
      ),
    );
    return (types: types, relations: relations, bindings: bindings);
  }

  /// The record [name] starts with, prepared like any creation.
  skir.AuthoringRecord _prepared(AuthoringDocument document, String name) {
    final step = fixturePreparationStep(
      document,
      skir.PreparationOperation.createStart(
        catalog: generation,
        target: skir.PreparationTarget.wrapRecord(_selection(name)),
        suppliedValue: null,
      ),
    );
    final content = switch (step) {
      skir.PreparationStep_readyWrapper(:final value) => value.content,
      skir.PreparationStep_needsInputWrapper(:final value) => value.content,
      _ => throw StateError("Fixture cannot initialize $name"),
    };
    return (content as skir.PreparedContent_recordWrapper).value;
  }

  /// The edit that creates the Library in an empty realm, as Realm provisions
  /// it before any Book is created.
  AuthoringEdit librarySeed() =>
      AuthoringEdit.fromDocument(document())
        ..create(library, _prepared(document(), "Library"));

  /// A realm holding only the Library.
  AuthoringDocument libraryDocument() => librarySeed().toDocument();

  AuthoringDocument document({bool existing = false}) {
    final realm = _realm();
    final catalog = CheckedEditorCatalog(
      skir.EditorCatalogWireSnapshot(
        resourceDisplays: const [],
        resourceOperations: const [],
        resourceOperationContributions: const [],
        generation: generation,
        types: [..._types, ...realm.types],
        relations: [..._relations, ...realm.relations],
        // The realm root stays unpublished: the store is an ordinary owner,
        // so every resource it owns is creatable.
        realmRoot: _id("Realm"),
        endpointBindings: [..._bindings, ...realm.bindings],
        presentations: const [],
        presentationMaterials: const [],
        configuration: const [],
        diagnostics: const [],
        capabilities: const [],
        recommendations: const [],
        roleFallbacks: const [],
      ),
    );
    var document = AuthoringDocument(
      catalog: catalog,
      entries: const {},
      links: const [],
    );
    if (existing) {
      final edit = AuthoringEdit.fromDocument(document);
      for (final (id, name) in [(book, "Book"), (page, "Page")]) {
        final step = fixturePreparationStep(
          document,
          skir.PreparationOperation.createStart(
            catalog: generation,
            target: skir.PreparationTarget.wrapRecord(_selection(name)),
            suppliedValue: null,
          ),
        );
        final content = switch (step) {
          skir.PreparationStep_readyWrapper(:final value) => value.content,
          skir.PreparationStep_needsInputWrapper(:final value) => value.content,
          _ => throw StateError("Fixture cannot initialize $name"),
        };
        edit.create(id, (content as skir.PreparedContent_recordWrapper).value);
      }
      final source = skir.ValueLocation(
        resource: page,
        path: skir.ValuePath(
          segments: [skir.PathSegment.createField(name: "book")],
        ),
      );
      final plan = (edit.linkPlans(
        catalog: catalog,
        source: source,
      ) as PortableLinkPlanReady).plans.single;
      edit.applyResolvedReference(
        edit.resolveReference(
          catalog: catalog,
          plan: plan,
          target: plan.targets.single,
        ),
      );
      document = edit.toDocument();
    }
    return document;
  }
}
