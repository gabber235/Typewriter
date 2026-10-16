import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

import "authoring_workspace_fixture.dart";

/// A small catalog of ordinary value requirements, independent of ownership policy.
final class ResourceCreationFixture {
  ResourceCreationFixture({bool abstractReport = false}) {
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
  final generation = skir.CatalogGeneration(value: "creation:flow");
  final book = skir.ResourceId(value: "book:existing");
  final page = skir.ResourceId(value: "page:existing");
  final _types = <skir.PublishedType>[];
  final _definitions = <skir.AuthoringResourceDefinition>[];
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
  skir.ResourceDefinitionId _family(String name) =>
      skir.ResourceDefinitionId(value: "creation.$name");

  ResourceCreationRequest request(String name) => ResourceCreationRequest(
    definition: _family(name),
    configuration: _selection(name),
  );

  void _publish(
    String name,
    skir.RepresentationTemplate representation, {
    List<skir.EffectiveFieldTemplate> fields = const [],
    String? parent,
  }) {
    _types.add(
      skir.PublishedType(
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
          icon: "",
          color: "",
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
    if (resource)
      _definitions.add(
        skir.AuthoringResourceDefinition(
          id: _family(name),
          root: _id(name),
          navigationHandler: skir.AuthoringNavigationHandler.generic,
        ),
      );
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
        families: const [],
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
    if (sourceBinding)
      _binding(first, firstField, firstEndpoint, second, collection);
    if (secondField != null)
      _binding(second, secondField, secondEndpoint, first, false);
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

  AuthoringDocument document({bool existing = false}) {
    final catalog = CheckedEditorCatalog(
      skir.EditorCatalogWireSnapshot(
        generation: generation,
        types: _types,
        relations: _relations,
        resourceDefinitions: _definitions,
        endpointBindings: _bindings,
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
        edit.create(
          id,
          (content as skir.PreparedContent_recordWrapper).value,
          definition: _family(name),
        );
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
