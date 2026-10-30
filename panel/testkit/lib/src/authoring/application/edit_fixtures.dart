import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";

/// A draft of one Action whose Style record holds a bold flag, inherited
/// from BaseStyle when [inheritedBold], repetitions and other scalar fields;
/// the Style field is nullable when [nullableStyle] and holds items when
/// [includeItems].
final class ParentFieldFixture {
  factory ParentFieldFixture({
    bool inheritedBold = false,
    bool nullableStyle = false,
    bool includeItems = false,
    String generation = "catalog:parents",
  }) {
    final root = testTypeId("Action");
    final style = testTypeId("Style");
    final baseStyle = testTypeId("BaseStyle");
    final rootUse = skir.NamedTypeUse(definition: root, arguments: const []);
    final styleOwner = skir.FieldOwner(definition: root, name: "style");
    final boldOwner = skir.FieldOwner(
      definition: inheritedBold ? baseStyle : style,
      name: "bold",
    );
    final repetitionsOwner = skir.FieldOwner(
      definition: style,
      name: "repetitions",
    );
    final bytesOwner = skir.FieldOwner(definition: style, name: "bytes");
    final durationOwner = skir.FieldOwner(definition: style, name: "duration");
    final timestampOwner = skir.FieldOwner(
      definition: style,
      name: "timestamp",
    );
    final itemsOwner = skir.FieldOwner(definition: style, name: "items");
    final list = testTypeId("List");
    final styleTemplate = skir.TypeTemplate.wrapNamed(
      skir.NamedTypeTemplate(definition: style, arguments: const []),
    );
    final declaredStyleTemplate = nullableStyle
        ? skir.TypeTemplate.createNullable(value: styleTemplate)
        : styleTemplate;
    final catalogSnapshot = skir.EditorCatalog(
      resourceDisplays: const [],
      resourceOperations: const [],
      generation: skir.CatalogGeneration(value: generation),
      types: [
        skir.PublishedType(
          searchKey: null,
          placementField: null,
          display: defaultTypeDisplay(""),
          definition: skir.TypeDefinition(
            id: root,
            parameters: const [],
            representation: skir.RepresentationTemplate.createRecord(
              fields: [
                skir.FieldDeclaration(
                  owner: styleOwner,
                  type: declaredStyleTemplate,
                  overrides: const [],
                  hasConstructorDefault: false,
                ),
              ],
              abstract_: false,
            ),
            parents: const [],
          ),
          status: skir.DeclarationStatus.ready,
          effectiveFields: [
            skir.EffectiveFieldTemplate(
              key: "style",
              owner: styleOwner,
              type: declaredStyleTemplate,
              rules: const [],
            ),
          ],
          ancestorTemplates: const [],
        ),
        skir.PublishedType(
          searchKey: null,
          placementField: null,
          display: defaultTypeDisplay(""),
          definition: skir.TypeDefinition(
            id: style,
            parameters: const [],
            representation: skir.RepresentationTemplate.createRecord(
              fields: [
                if (!inheritedBold)
                  skir.FieldDeclaration(
                    owner: boldOwner,
                    type: skir.TypeTemplate.wrapScalar(skir.ScalarKind.boolean),
                    overrides: const [],
                    hasConstructorDefault: false,
                  ),
                skir.FieldDeclaration(
                  owner: repetitionsOwner,
                  type: skir.TypeTemplate.wrapScalar(
                    skir.ScalarKind.createInteger(
                      width: skir.IntegerWidth.signedThirtyTwo,
                    ),
                  ),
                  overrides: const [],
                  hasConstructorDefault: true,
                ),
                skir.FieldDeclaration(
                  owner: bytesOwner,
                  type: skir.TypeTemplate.wrapScalar(skir.ScalarKind.bytes),
                  overrides: const [],
                  hasConstructorDefault: false,
                ),
                skir.FieldDeclaration(
                  owner: durationOwner,
                  type: skir.TypeTemplate.wrapScalar(skir.ScalarKind.duration),
                  overrides: const [],
                  hasConstructorDefault: false,
                ),
                skir.FieldDeclaration(
                  owner: timestampOwner,
                  type: skir.TypeTemplate.wrapScalar(skir.ScalarKind.timestamp),
                  overrides: const [],
                  hasConstructorDefault: false,
                ),
                if (includeItems)
                  skir.FieldDeclaration(
                    owner: itemsOwner,
                    type: skir.TypeTemplate.wrapNamed(
                      skir.NamedTypeTemplate(
                        definition: list,
                        arguments: const [],
                      ),
                    ),
                    overrides: const [],
                    hasConstructorDefault: false,
                  ),
              ],
              abstract_: false,
            ),
            parents: inheritedBold
                ? [
                    skir.NamedTypeTemplate(
                      definition: baseStyle,
                      arguments: const [],
                    ),
                  ]
                : const [],
          ),
          status: skir.DeclarationStatus.ready,
          effectiveFields: [
            skir.EffectiveFieldTemplate(
              key: "bold",
              owner: boldOwner,
              type: skir.TypeTemplate.wrapScalar(skir.ScalarKind.boolean),
              rules: const [],
            ),
            skir.EffectiveFieldTemplate(
              key: "repetitions",
              owner: repetitionsOwner,
              type: skir.TypeTemplate.wrapScalar(
                skir.ScalarKind.createInteger(
                  width: skir.IntegerWidth.signedThirtyTwo,
                ),
              ),
              rules: const [],
            ),
            skir.EffectiveFieldTemplate(
              key: "bytes",
              owner: bytesOwner,
              type: skir.TypeTemplate.wrapScalar(skir.ScalarKind.bytes),
              rules: const [],
            ),
            skir.EffectiveFieldTemplate(
              key: "duration",
              owner: durationOwner,
              type: skir.TypeTemplate.wrapScalar(skir.ScalarKind.duration),
              rules: const [],
            ),
            skir.EffectiveFieldTemplate(
              key: "timestamp",
              owner: timestampOwner,
              type: skir.TypeTemplate.wrapScalar(skir.ScalarKind.timestamp),
              rules: const [],
            ),
            if (includeItems)
              skir.EffectiveFieldTemplate(
                key: "items",
                owner: itemsOwner,
                type: skir.TypeTemplate.wrapNamed(
                  skir.NamedTypeTemplate(definition: list, arguments: const []),
                ),
                rules: const [],
              ),
          ],
          ancestorTemplates: inheritedBold
              ? [
                  skir.NamedTypeTemplate(
                    definition: baseStyle,
                    arguments: const [],
                  ),
                ]
              : const [],
        ),
        if (inheritedBold)
          skir.PublishedType(
            searchKey: null,
            placementField: null,
            display: defaultTypeDisplay(""),
            definition: skir.TypeDefinition(
              id: baseStyle,
              parameters: const [],
              representation: skir.RepresentationTemplate.createRecord(
                fields: [
                  skir.FieldDeclaration(
                    owner: boldOwner,
                    type: skir.TypeTemplate.wrapScalar(skir.ScalarKind.boolean),
                    overrides: const [],
                    hasConstructorDefault: true,
                  ),
                ],
                abstract_: false,
              ),
              parents: const [],
            ),
            status: skir.DeclarationStatus.ready,
            effectiveFields: [
              skir.EffectiveFieldTemplate(
                key: "bold",
                owner: boldOwner,
                type: skir.TypeTemplate.wrapScalar(skir.ScalarKind.boolean),
                rules: const [],
              ),
            ],
            ancestorTemplates: const [],
          ),
        if (includeItems)
          skir.PublishedType(
            searchKey: null,
            placementField: null,
            display: defaultTypeDisplay(""),
            definition: skir.TypeDefinition(
              id: list,
              parameters: const [],
              representation: skir.RepresentationTemplate.createSequence(
                item: skir.TypeTemplate.wrapScalar(skir.ScalarKind.text),
                kind: skir.CollectionKind.list,
              ),
              parents: const [],
            ),
            status: skir.DeclarationStatus.ready,
            effectiveFields: const [],
            ancestorTemplates: const [],
          ),
      ],
      relations: const [],
      realmRoot: skir.TypeDefinitionId.defaultInstance,
      presentations: const [],
      presentationMaterials: const [],
      configuration: const [],
      diagnostics: const [],
      endpointBindings: const [],
      capabilities: const [],
      recommendations: const [],
      roleFallbacks: const [],
    );
    final resource = skir.ResourceId(value: "resource:parent");
    final snapshot = skir.AuthoringState(
      confirmedObservation: skir.AuthoringObservationId(value: "fixture:saved"),
      generation: catalogSnapshot.generation,
      resources: [
        skir.AuthoringResource(
          id: resource,
          content: skir.AuthoringRecord(
            configuration: skir.TypeSelection.wrapComplete(rootUse),
            fields: [
              skir.FieldValue(name: "style", value: skir.DataValue.unfilled),
            ],
          ),
        ),
      ],
      links: const [],
      findings: const [],
    );
    skir.ValueLocation location(String field) => skir.ValueLocation(
      resource: resource,
      path: skir.ValuePath(
        segments: [
          skir.PathSegment.createField(name: "style"),
          skir.PathSegment.createField(name: field),
        ],
      ),
    );
    return ParentFieldFixture._(
      draft: AuthoringEdit.fromState(
        snapshot,
        catalog: CheckedEditorCatalog(catalogSnapshot),
      ),
      bold: location("bold"),
      repetitions: location("repetitions"),
      snapshot: snapshot,
    );
  }

  ParentFieldFixture._({
    required this.draft,
    required this.bold,
    required this.repetitions,
    required this.snapshot,
  });

  final AuthoringEdit draft;
  final skir.ValueLocation bold;
  final skir.ValueLocation repetitions;
  final skir.AuthoringState snapshot;

  /// The value the Realm prepares for [request]: a Style holding [bold],
  /// unfilled repetitions and, when [includeItems], an empty item list.
  static skir.PreparedValue preparedStyle(
    skir.ValuePreparationRequest request, {
    required bool bold,
    bool includeItems = false,
  }) {
    final fields = <skir.FieldValue>[
      skir.FieldValue(name: "bold", value: skir.DataValue.wrapBoolean(bold)),
      skir.FieldValue(name: "repetitions", value: skir.DataValue.unfilled),
      if (includeItems)
        skir.FieldValue(
          name: "items",
          value: skir.DataValue.createNamed(
            actualType: skir.NamedTypeUse(
              definition: testTypeId("List"),
              arguments: const [],
            ),
            payload: skir.DataValue.createListValue(items: const []),
          ),
        ),
    ];
    return skir.PreparedValue(
      content: skir.PreparedContent.wrapRecord(
        skir.AuthoringRecord(
          configuration: request.recordSelection,
          fields: [
            skir.FieldValue(
              name: "style",
              value: skir.DataValue.createNamed(
                actualType: skir.NamedTypeUse(
                  definition: testTypeId("Style"),
                  arguments: const [],
                ),
                payload: skir.DataValue.createRecord(fields: fields),
              ),
            ),
          ],
        ),
      ),
      findings: const [],
    );
  }
}

/// A draft of a Book and a page record a creation can link to it; the
/// Book endpoint is ambiguous when [ambiguous].
final class PageCreationFixture {
  factory PageCreationFixture({bool ambiguous = false}) {
    final book = testTypeId("Book");
    final page = testTypeId("Page");
    final sequence = testTypeId("SequencePage");
    final pages = testTypeId("PageList");
    final bookLink = testTypeId("BookPagesBook");
    final pageLink = testTypeId("BookPagesPage");
    final bookEndpoint = skir.EndpointId(value: "book.pages");
    final pageEndpoint = skir.EndpointId(value: "page.book");
    final bookUse = skir.NamedTypeUse(definition: book, arguments: const []);
    final sequenceUse = skir.NamedTypeUse(
      definition: sequence,
      arguments: const [],
    );
    final pagesUse = skir.NamedTypeUse(definition: pages, arguments: const []);
    skir.NamedTypeTemplate template(skir.TypeDefinitionId definition) =>
        skir.NamedTypeTemplate(definition: definition, arguments: const []);
    skir.TypeTemplate named(skir.TypeDefinitionId definition) =>
        skir.TypeTemplate.wrapNamed(template(definition));
    skir.FieldDeclaration field(
      skir.TypeDefinitionId owner,
      String name,
      skir.TypeTemplate type,
    ) => skir.FieldDeclaration(
      owner: skir.FieldOwner(definition: owner, name: name),
      type: type,
      overrides: const [],
      hasConstructorDefault: false,
    );
    skir.EffectiveFieldTemplate effective(
      skir.TypeDefinitionId owner,
      String name,
      skir.TypeTemplate type,
    ) => skir.EffectiveFieldTemplate(
      key: name,
      owner: skir.FieldOwner(definition: owner, name: name),
      type: type,
      rules: const [],
    );
    skir.PublishedType published(
      skir.TypeDefinitionId id,
      skir.RepresentationTemplate representation, {
      List<skir.NamedTypeTemplate> parents = const [],
      List<skir.EffectiveFieldTemplate> fields = const [],
    }) => skir.PublishedType(
      searchKey: null,
      placementField: null,
      display: defaultTypeDisplay(""),
      definition: skir.TypeDefinition(
        id: id,
        parameters: const [],
        representation: representation,
        parents: parents,
      ),
      status: skir.DeclarationStatus.ready,
      effectiveFields: fields,
      ancestorTemplates: parents,
    );
    final bookPagesField = field(book, "pages", named(pages));
    final pageBookField = field(page, "book", named(pageLink));
    final pageNameField = field(
      page,
      "name",
      skir.TypeTemplate.wrapScalar(skir.ScalarKind.text),
    );
    final pageParent = template(page);
    final generation = skir.CatalogGeneration(value: "catalog:page creation");
    final snapshot = skir.EditorCatalog(
      resourceDisplays: const [],
      resourceOperations: const [],
      generation: generation,
      types: [
        published(
          book,
          skir.RepresentationTemplate.createRecord(
            fields: [bookPagesField],
            abstract_: false,
          ),
          fields: [effective(book, "pages", named(pages))],
        ),
        published(
          page,
          skir.RepresentationTemplate.createRecord(
            fields: [pageBookField, pageNameField],
            abstract_: true,
          ),
          fields: [
            effective(page, "book", named(pageLink)),
            effective(
              page,
              "name",
              skir.TypeTemplate.wrapScalar(skir.ScalarKind.text),
            ),
          ],
        ),
        published(
          sequence,
          skir.RepresentationTemplate.createRecord(
            fields: [
              if (ambiguous) field(sequence, "otherBook", named(pageLink)),
            ],
            abstract_: false,
          ),
          parents: [pageParent],
          fields: [
            if (ambiguous) effective(sequence, "otherBook", named(pageLink)),
            effective(page, "book", named(pageLink)),
            effective(
              page,
              "name",
              skir.TypeTemplate.wrapScalar(skir.ScalarKind.text),
            ),
          ],
        ),
        published(
          pages,
          skir.RepresentationTemplate.createSequence(
            item: named(bookLink),
            kind: skir.CollectionKind.list,
          ),
        ),
        published(
          bookLink,
          skir.RepresentationTemplate.createLink(
            endpoint: bookEndpoint,
            target: named(page),
          ),
        ),
        published(
          pageLink,
          skir.RepresentationTemplate.createLink(
            endpoint: pageEndpoint,
            target: named(book),
          ),
        ),
      ],
      relations: [
        skir.RelationContract(
          id: skir.RelationId(value: "book.pages"),
          first: skir.EndpointDefinition(
            id: bookEndpoint,
            slot: skir.EndpointSlot.first,
            resource: template(book),
            cardinality: skir.EndpointCardinality.one,
            onDelete: skir.RelationDeletePolicy.cascade,
          ),
          second: skir.EndpointDefinition(
            id: pageEndpoint,
            slot: skir.EndpointSlot.second,
            resource: template(page),
            cardinality: skir.EndpointCardinality.many,
            onDelete: skir.RelationDeletePolicy.clear,
          ),
          families: const [],
        ),
      ],
      realmRoot: skir.TypeDefinitionId.defaultInstance,
      presentations: const [],
      presentationMaterials: const [],
      configuration: const [],
      diagnostics: const [],
      endpointBindings: [
        skir.EndpointBindingTemplate(
          endpoint: bookEndpoint,
          containingResource: template(book),
          valueOwner: book,
          relativePath: skir.RelativeFieldPattern(
            segments: [
              skir.FieldPatternSegment.createField(name: "pages"),
              skir.FieldPatternSegment.items,
            ],
          ),
          target: named(page),
          containsCollection: true,
        ),
        skir.EndpointBindingTemplate(
          endpoint: pageEndpoint,
          containingResource: template(page),
          valueOwner: page,
          relativePath: skir.RelativeFieldPattern(
            segments: [skir.FieldPatternSegment.createField(name: "book")],
          ),
          target: named(book),
          containsCollection: false,
        ),
        skir.EndpointBindingTemplate(
          endpoint: pageEndpoint,
          containingResource: template(sequence),
          valueOwner: sequence,
          relativePath: skir.RelativeFieldPattern(
            segments: [skir.FieldPatternSegment.createField(name: "book")],
          ),
          target: named(book),
          containsCollection: false,
        ),
        if (ambiguous)
          skir.EndpointBindingTemplate(
            endpoint: pageEndpoint,
            containingResource: template(sequence),
            valueOwner: sequence,
            relativePath: skir.RelativeFieldPattern(
              segments: [
                skir.FieldPatternSegment.createField(name: "otherBook"),
              ],
            ),
            target: named(book),
            containsCollection: false,
          ),
      ],
      capabilities: const [],
      recommendations: const [],
      roleFallbacks: const [],
    );
    final bookId = skir.ResourceId(value: "book:original");
    final pageId = skir.ResourceId(value: "page:created");
    final bookRecord = skir.AuthoringRecord(
      configuration: skir.TypeSelection.wrapComplete(bookUse),
      fields: [
        skir.FieldValue(
          name: "pages",
          value: skir.DataValue.createNamed(
            actualType: pagesUse,
            payload: skir.DataValue.createListValue(items: const []),
          ),
        ),
      ],
    );
    final pageRecord = skir.AuthoringRecord(
      configuration: skir.TypeSelection.wrapComplete(sequenceUse),
      fields: [
        skir.FieldValue(name: "book", value: skir.DataValue.unfilled),
        skir.FieldValue(
          name: "name",
          value: skir.DataValue.wrapStringValue("Verification page"),
        ),
      ],
    );
    final authored = skir.AuthoringState(
      confirmedObservation: skir.AuthoringObservationId(value: "fixture:saved"),
      generation: generation,
      resources: [skir.AuthoringResource(id: bookId, content: bookRecord)],
      links: const [],
      findings: const [],
    );
    return PageCreationFixture._(
      draft: AuthoringEdit.fromState(
        authored,
        catalog: CheckedEditorCatalog(snapshot),
      ),
      book: bookId,
      page: pageId,
      bookEndpoint: bookEndpoint,
      sequenceUse: sequenceUse,
      pageRecord: pageRecord,
    );
  }

  PageCreationFixture._({
    required this.draft,
    required this.book,
    required this.page,
    required this.bookEndpoint,
    required this.sequenceUse,
    required this.pageRecord,
  });

  final AuthoringEdit draft;
  final skir.ResourceId book;
  final skir.ResourceId page;
  final skir.EndpointId bookEndpoint;
  final skir.NamedTypeUse sequenceUse;
  final skir.AuthoringRecord pageRecord;
}

/// A draft of resources linked through a relation with an inverse, and an
/// alternate counterpart, for tests that relink an occurrence.
final class RelationEditFixture {
  factory RelationEditFixture({
    skir.RelationDeletePolicy firstDelete = skir.RelationDeletePolicy.clear,
    skir.RelationDeletePolicy secondDelete = skir.RelationDeletePolicy.clear,
    bool includeOppositeLocation = true,
  }) {
    final fixture = ListRecordFixture();
    final endpoint = skir.EndpointId(value: "test.source");
    final opposite = skir.EndpointId(value: "test.target");
    final relation = skir.RelationId(value: "test.relation");
    final originalTarget = skir.ResourceId(value: "resource:original");
    final newTarget = skir.ResourceId(value: "resource:new");
    final oppositePath = skir.ValuePath(
      segments: [skir.PathSegment.createField(name: "back")],
    );
    final originalOpposite = skir.ValueLocation(
      resource: originalTarget,
      path: oppositePath,
    );
    final newOpposite = skir.ValueLocation(
      resource: newTarget,
      path: oppositePath,
    );
    final alternateOpposite = skir.ValueLocation(
      resource: newTarget,
      path: skir.ValuePath(
        segments: [skir.PathSegment.createField(name: "back2")],
      ),
    );
    final linkType = skir.NamedTypeUse(
      definition: testTypeId("Reference"),
      arguments: const [],
    );
    final originalResource = fixture.snapshot.resources.single;
    final linkedRecord = skir.AuthoringRecord(
      configuration: originalResource.content.configuration,
      fields: [
        for (final field in originalResource.content.fields)
          skir.FieldValue(
            name: field.name,
            value: field.name == "title"
                ? skir.DataValue.createNamed(
                    actualType: linkType,
                    payload: skir.DataValue.createLink(
                      endpoint: endpoint,
                      target: skir.LinkTarget(
                        resource: originalTarget,
                        opposite: includeOppositeLocation ? oppositePath : null,
                      ),
                    ),
                  )
                : field.value,
          ),
      ],
    );
    final snapshot = skir.AuthoringState(
      confirmedObservation: skir.AuthoringObservationId(value: "fixture:saved"),
      generation: fixture.snapshot.generation,
      resources: [
        skir.AuthoringResource(id: originalResource.id, content: linkedRecord),
        for (final target in [originalTarget, newTarget])
          skir.AuthoringResource(
            id: target,
            content: skir.AuthoringRecord(
              configuration: originalResource.content.configuration,
              fields: [
                for (final name in ["back", "back2"])
                  skir.FieldValue(
                    name: name,
                    value: includeOppositeLocation
                        ? skir.DataValue.createNamed(
                            actualType: linkType,
                            payload: skir.DataValue.createLink(
                              endpoint: opposite,
                              target: skir.LinkTarget(
                                resource: fixture.resource,
                                opposite: fixture.title.path,
                              ),
                            ),
                          )
                        : skir.DataValue.unfilled,
                  ),
              ],
            ),
          ),
      ],
      links: [
        skir.LinkProjection(
          contract: relation,
          first: fixture.resource,
          second: originalTarget,
          firstLocation: fixture.title.path,
          secondLocation: includeOppositeLocation ? oppositePath : null,
        ),
      ],
      findings: fixture.snapshot.findings,
    );
    final selection = skir.NamedTypeTemplate(
      definition: fixture.listType.definition,
      arguments: const [],
    );
    final checked = CheckedEditorCatalog(
      skir.EditorCatalog(
        resourceDisplays: const [],
        resourceOperations: const [],
        generation: fixture.snapshot.generation,
        types: const [],
        relations: [
          skir.RelationContract(
            id: relation,
            first: skir.EndpointDefinition(
              id: endpoint,
              slot: skir.EndpointSlot.first,
              resource: selection,
              cardinality: skir.EndpointCardinality.one,
              onDelete: firstDelete,
            ),
            second: skir.EndpointDefinition(
              id: opposite,
              slot: skir.EndpointSlot.second,
              resource: selection,
              cardinality: skir.EndpointCardinality.many,
              onDelete: secondDelete,
            ),
            families: const [],
          ),
        ],
        realmRoot: skir.TypeDefinitionId.defaultInstance,
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
    return RelationEditFixture._(
      draft: AuthoringEdit.fromState(snapshot, catalog: checked),
      occurrence: skir.LinkOccurrence(
        id: skir.LinkOccurrenceId(endpoint: endpoint, location: fixture.title),
        source: fixture.resource,
        target: skir.LinkTarget(
          resource: originalTarget,
          opposite: includeOppositeLocation ? oppositePath : null,
        ),
      ),
      counterpart: skir.LinkOccurrence(
        id: skir.LinkOccurrenceId(endpoint: opposite, location: newOpposite),
        source: newTarget,
        target: skir.LinkTarget(
          resource: fixture.resource,
          opposite: fixture.title.path,
        ),
      ),
      alternateCounterpart: skir.LinkOccurrence(
        id: skir.LinkOccurrenceId(
          endpoint: opposite,
          location: alternateOpposite,
        ),
        source: newTarget,
        target: skir.LinkTarget(
          resource: fixture.resource,
          opposite: fixture.title.path,
        ),
      ),
      newTarget: newTarget,
      originalOpposite: originalOpposite,
      newOpposite: newOpposite,
      alternateOpposite: alternateOpposite,
    );
  }

  RelationEditFixture._({
    required this.draft,
    required this.occurrence,
    required this.counterpart,
    required this.alternateCounterpart,
    required this.newTarget,
    required this.originalOpposite,
    required this.newOpposite,
    required this.alternateOpposite,
  });

  final AuthoringEdit draft;
  final skir.LinkOccurrence occurrence;
  final skir.LinkOccurrence counterpart;
  final skir.LinkOccurrence alternateCounterpart;
  final skir.ResourceId newTarget;
  final skir.ValueLocation originalOpposite;
  final skir.ValueLocation newOpposite;
  final skir.ValueLocation alternateOpposite;
}

/// A draft whose text set and record list need repair after a catalog
/// change.
final class CollectionRepairFixture {
  factory CollectionRepairFixture() {
    final root = testTypeId("CollectionRoot");
    final textSetDefinition = testTypeId("TextSet");
    final recordSetDefinition = testTypeId("RecordSet");
    final itemDefinition = testTypeId("CollectionItem");
    final rootUse = skir.NamedTypeUse(definition: root, arguments: const []);
    final textSet = skir.NamedTypeUse(
      definition: textSetDefinition,
      arguments: const [],
    );
    final itemType = skir.NamedTypeUse(
      definition: itemDefinition,
      arguments: const [],
    );
    final textsOwner = skir.FieldOwner(definition: root, name: "texts");
    final recordsOwner = skir.FieldOwner(definition: root, name: "records");
    final nameOwner = skir.FieldOwner(definition: itemDefinition, name: "name");
    final textSetTemplate = skir.TypeTemplate.createNamed(
      definition: textSetDefinition,
      arguments: const [],
    );
    final recordSetTemplate = skir.TypeTemplate.createNamed(
      definition: recordSetDefinition,
      arguments: const [],
    );
    final itemTemplate = skir.TypeTemplate.createNamed(
      definition: itemDefinition,
      arguments: const [],
    );
    skir.PublishedType published(
      skir.TypeDefinition definition,
      List<skir.EffectiveFieldTemplate> fields,
    ) => skir.PublishedType(
      searchKey: null,
      placementField: null,
      display: defaultTypeDisplay(""),
      definition: definition,
      status: skir.DeclarationStatus.ready,
      effectiveFields: fields,
      ancestorTemplates: const [],
    );
    final catalogSnapshot = skir.EditorCatalog(
      resourceDisplays: const [],
      resourceOperations: const [],
      generation: skir.CatalogGeneration(value: "catalog:collection-repair"),
      types: [
        published(
          skir.TypeDefinition(
            id: root,
            parameters: const [],
            representation: skir.RepresentationTemplate.createRecord(
              fields: [
                skir.FieldDeclaration(
                  owner: textsOwner,
                  type: textSetTemplate,
                  overrides: const [],
                  hasConstructorDefault: false,
                ),
                skir.FieldDeclaration(
                  owner: recordsOwner,
                  type: recordSetTemplate,
                  overrides: const [],
                  hasConstructorDefault: false,
                ),
              ],
              abstract_: false,
            ),
            parents: const [],
          ),
          [
            skir.EffectiveFieldTemplate(
              key: "texts",
              owner: textsOwner,
              type: textSetTemplate,
              rules: const [],
            ),
            skir.EffectiveFieldTemplate(
              key: "records",
              owner: recordsOwner,
              type: recordSetTemplate,
              rules: const [],
            ),
          ],
        ),
        published(
          skir.TypeDefinition(
            id: textSetDefinition,
            parameters: const [],
            representation: skir.RepresentationTemplate.createSequence(
              item: skir.TypeTemplate.wrapScalar(skir.ScalarKind.text),
              kind: skir.CollectionKind.set_,
            ),
            parents: const [],
          ),
          const [],
        ),
        published(
          skir.TypeDefinition(
            id: recordSetDefinition,
            parameters: const [],
            representation: skir.RepresentationTemplate.createSequence(
              item: itemTemplate,
              kind: skir.CollectionKind.set_,
            ),
            parents: const [],
          ),
          const [],
        ),
        published(
          skir.TypeDefinition(
            id: itemDefinition,
            parameters: const [],
            representation: skir.RepresentationTemplate.createRecord(
              fields: [
                skir.FieldDeclaration(
                  owner: nameOwner,
                  type: skir.TypeTemplate.wrapScalar(skir.ScalarKind.text),
                  overrides: const [],
                  hasConstructorDefault: true,
                ),
              ],
              abstract_: false,
            ),
            parents: const [],
          ),
          [
            skir.EffectiveFieldTemplate(
              key: "name",
              owner: nameOwner,
              type: skir.TypeTemplate.wrapScalar(skir.ScalarKind.text),
              rules: const [],
            ),
          ],
        ),
      ],
      relations: const [],
      realmRoot: skir.TypeDefinitionId.defaultInstance,
      presentations: const [],
      presentationMaterials: const [],
      configuration: const [],
      diagnostics: const [],
      endpointBindings: const [],
      capabilities: const [],
      recommendations: const [],
      roleFallbacks: const [],
    );
    final resource = skir.ResourceId(value: "resource:collection-repair");
    final snapshot = skir.AuthoringState(
      confirmedObservation: skir.AuthoringObservationId(value: "fixture:saved"),
      generation: catalogSnapshot.generation,
      resources: [
        skir.AuthoringResource(
          id: resource,
          content: skir.AuthoringRecord(
            configuration: skir.TypeSelection.wrapComplete(rootUse),
            fields: [
              skir.FieldValue(name: "texts", value: skir.DataValue.unfilled),
              skir.FieldValue(name: "records", value: skir.DataValue.unfilled),
            ],
          ),
        ),
      ],
      links: const [],
      findings: const [],
    );
    skir.ValueLocation location(String field) => skir.ValueLocation(
      resource: resource,
      path: skir.ValuePath(
        segments: [skir.PathSegment.createField(name: field)],
      ),
    );
    return CollectionRepairFixture._(
      draft: AuthoringEdit.fromState(
        snapshot,
        catalog: CheckedEditorCatalog(catalogSnapshot),
      ),
      texts: location("texts"),
      records: location("records"),
      textSet: textSet,
      itemType: itemType,
    );
  }

  CollectionRepairFixture._({
    required this.draft,
    required this.texts,
    required this.records,
    required this.textSet,
    required this.itemType,
  });

  final AuthoringEdit draft;
  final skir.ValueLocation texts;
  final skir.ValueLocation records;
  final skir.NamedTypeUse textSet;
  final skir.NamedTypeUse itemType;
}

/// A draft of one untyped record with a title and a list of items, read
/// from a saved state the Realm reported.
final class ListRecordFixture {
  factory ListRecordFixture() {
    final resource = skir.ResourceId(value: "resource:1");
    final title = skir.ValueLocation(
      resource: resource,
      path: skir.ValuePath(
        segments: [skir.PathSegment.createField(name: "title")],
      ),
    );
    final items = skir.ValueLocation(
      resource: resource,
      path: skir.ValuePath(
        segments: [skir.PathSegment.createField(name: "items")],
      ),
    );
    final firstItem = skir.ItemId(value: "first");
    final listType = skir.NamedTypeUse(
      definition: skir.TypeDefinitionId(
        typeId: skir.TypeId.createQualified(
          namespace: "typewriter",
          name: "List",
        ),
        revision: 1,
      ),
      arguments: [skir.TypeUse.wrapScalar(skir.ScalarKind.text)],
    );
    final record = skir.AuthoringRecord(
      configuration: skir.TypeSelection.unknown,
      fields: [
        skir.FieldValue(
          name: "title",
          value: skir.DataValue.wrapStringValue("original"),
        ),
        skir.FieldValue(
          name: "items",
          value: skir.DataValue.createNamed(
            actualType: listType,
            payload: skir.DataValue.createListValue(
              items: [
                skir.ListItem(
                  id: firstItem,
                  value: skir.DataValue.wrapStringValue("first"),
                ),
              ],
            ),
          ),
        ),
      ],
    );
    final absent = skir.InputToken(value: "absent");
    final snapshot = skir.AuthoringState(
      confirmedObservation: skir.AuthoringObservationId(value: "fixture:saved"),
      generation: skir.CatalogGeneration(value: "catalog:1"),
      resources: [skir.AuthoringResource(id: resource, content: record)],
      links: const [],
      findings: const [],
    );
    return ListRecordFixture._(
      draft: AuthoringEdit.fromState(snapshot),
      resource: resource,
      title: title,
      items: items,
      firstItem: firstItem,
      listType: listType,
      absent: absent,
      snapshot: snapshot,
    );
  }

  ListRecordFixture._({
    required this.draft,
    required this.resource,
    required this.title,
    required this.items,
    required this.firstItem,
    required this.listType,
    required this.absent,
    required this.snapshot,
  });

  final AuthoringEdit draft;
  final skir.ResourceId resource;
  final skir.ValueLocation title;
  final skir.ValueLocation items;
  final skir.ItemId firstItem;
  final skir.NamedTypeUse listType;
  final skir.InputToken absent;
  final skir.AuthoringState snapshot;
}
