import "package:flutter_test/flutter_test.dart";
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
    final style = declaredRecord(
      "Style",
      fields: {
        if (!inheritedBold) "bold": skir.ScalarKind.boolean,
        "repetitions": skir.ScalarKind.createInteger(
          width: skir.IntegerWidth.signedThirtyTwo,
        ),
        "bytes": skir.ScalarKind.bytes,
        "duration": skir.ScalarKind.duration,
        "timestamp": skir.ScalarKind.timestamp,
        if (includeItems) "items": "List",
      },
      defaulted: {"repetitions"},
      parents: [if (inheritedBold) "BaseStyle"],
    );
    final saved = authoredDoc(
      [
        authoredRecord("resource:parent", {
          "style": skir.DataValue.unfilled,
        }, type: typeUse("Action")),
      ],
      catalog: authoredCatalog([
        declaredRecord(
          "Action",
          fields: {
            "style": nullableStyle
                ? skir.TypeTemplate.createNullable(
                    value: typeTemplateOf("Style"),
                  )
                : "Style",
          },
        ),
        style,
        if (inheritedBold)
          declaredRecord(
            "BaseStyle",
            fields: {"bold": skir.ScalarKind.boolean},
            defaulted: {"bold"},
          ),
        if (includeItems) declaredCollection("List", skir.ScalarKind.text),
      ], generation: generation),
    );
    return ParentFieldFixture._(
      draft: saved.edit,
      bold: valueAt("resource:parent", ["style", "bold"]),
      repetitions: valueAt("resource:parent", ["style", "repetitions"]),
      snapshot: saved.state,
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
    final saved = authoredDoc(
      [
        authoredRecord("book:original", {
          "pages": typedValue(
            "PageList",
            skir.DataValue.createListValue(items: const []),
          ),
        }, type: typeUse("Book")),
      ],
      catalog: authoredCatalog(
        [
          declaredRecord("Book", fields: {"pages": "PageList"}),
          declaredRecord(
            "Page",
            fields: {"book": "BookPagesPage", "name": skir.ScalarKind.text},
            open: true,
          ),
          declaredRecord(
            "SequencePage",
            fields: {if (ambiguous) "otherBook": "BookPagesPage"},
            parents: ["Page"],
          ),
          declaredCollection("PageList", "BookPagesBook"),
          declaredLink("BookPagesBook", endpoint: "book.pages", target: "Page"),
          declaredLink("BookPagesPage", endpoint: "page.book", target: "Book"),
        ],
        relations: [
          declaredRelation(
            "book.pages",
            endpointOf(
              "book.pages",
              "Book",
              onDelete: skir.RelationDeletePolicy.cascade,
            ),
            endpointOf(
              "page.book",
              "Page",
              cardinality: skir.EndpointCardinality.many,
            ),
          ),
        ],
        endpoints: [
          endpointBinding(
            "book.pages",
            resource: "Book",
            path: ["pages", skir.FieldPatternSegment.items],
            target: "Page",
          ),
          for (final (resource, field) in [
            ("Page", "book"),
            ("SequencePage", "book"),
            if (ambiguous) ("SequencePage", "otherBook"),
          ])
            endpointBinding(
              "page.book",
              resource: resource,
              path: [field],
              target: "Book",
            ),
        ],
        generation: "catalog:page creation",
      ),
    );
    return PageCreationFixture._(
      draft: saved.edit,
      book: skir.ResourceId(value: "book:original"),
      page: skir.ResourceId(value: "page:created"),
      bookEndpoint: skir.EndpointId(value: "book.pages"),
      sequenceUse: typeUse("SequencePage"),
      pageRecord: authoredRecord("page:created", {
        "book": skir.DataValue.unfilled,
        "name": textValue("Verification page"),
      }, type: typeUse("SequencePage")).content,
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
    // One untyped record with a title and a list of items, as the Realm
    // saved it.
    final saved = authoredDoc([
      authoredRecord("resource:1", {
        "title": textValue("original"),
        "items": typedTextList(["first"]),
      }),
    ], generation: skir.CatalogGeneration(value: "catalog:1")).state;
    final source = saved.resources.single.id;
    final title = valueAt(source, ["title"]);
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
    final originalResource = saved.resources.single;
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
      generation: saved.generation,
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
                                resource: source,
                                opposite: title.path,
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
          first: source,
          second: originalTarget,
          firstLocation: title.path,
          secondLocation: includeOppositeLocation ? oppositePath : null,
        ),
      ],
      findings: saved.findings,
    );
    final selection = skir.NamedTypeTemplate(
      definition: listTypeOf(skir.TypeUse.wrapScalar(skir.ScalarKind.text))
          .definition,
      arguments: const [],
    );
    final checked = CheckedEditorCatalog(
      testCatalogSnapshot(
        generation: saved.generation,
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
      ),
    );
    return RelationEditFixture._(
      draft: AuthoringEdit.fromState(snapshot, catalog: checked),
      occurrence: skir.LinkOccurrence(
        id: skir.LinkOccurrenceId(endpoint: endpoint, location: title),
        source: source,
        target: skir.LinkTarget(
          resource: originalTarget,
          opposite: includeOppositeLocation ? oppositePath : null,
        ),
      ),
      counterpart: skir.LinkOccurrence(
        id: skir.LinkOccurrenceId(endpoint: opposite, location: newOpposite),
        source: newTarget,
        target: skir.LinkTarget(resource: source, opposite: title.path),
      ),
      alternateCounterpart: skir.LinkOccurrence(
        id: skir.LinkOccurrenceId(
          endpoint: opposite,
          location: alternateOpposite,
        ),
        source: newTarget,
        target: skir.LinkTarget(resource: source, opposite: title.path),
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
    final saved = authoredDoc(
      [
        authoredRecord("resource:collection-repair", {
          "texts": skir.DataValue.unfilled,
          "records": skir.DataValue.unfilled,
        }, type: typeUse("CollectionRoot")),
      ],
      catalog: authoredCatalog([
        declaredRecord(
          "CollectionRoot",
          fields: {"texts": "TextSet", "records": "RecordSet"},
        ),
        declaredCollection(
          "TextSet",
          skir.ScalarKind.text,
          kind: skir.CollectionKind.set_,
        ),
        declaredCollection(
          "RecordSet",
          "CollectionItem",
          kind: skir.CollectionKind.set_,
        ),
        declaredRecord(
          "CollectionItem",
          fields: {"name": skir.ScalarKind.text},
          defaulted: {"name"},
        ),
      ], generation: "catalog:collection-repair"),
    );
    return CollectionRepairFixture._(
      draft: saved.edit,
      texts: valueAt("resource:collection-repair", ["texts"]),
      records: valueAt("resource:collection-repair", ["records"]),
      textSet: typeUse("TextSet"),
      itemType: typeUse("CollectionItem"),
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

/// The value the Realm prepares for [request]: a record of the requested
/// selection holding [fields], with no findings.
skir.PreparedValue preparedRecord(
  skir.ValuePreparationRequest request,
  List<skir.FieldValue> fields,
) => skir.PreparedValue(
  content: skir.PreparedContent.wrapRecord(
    skir.AuthoringRecord(
      configuration: request.recordSelection,
      fields: fields,
    ),
  ),
  findings: const [],
);

/// A workspace host of [resource] in [source] with no presentation material
/// and nothing to edit through; it lives until the test ends.
AuthoredPresentationHost bareWorkspaceHost(
  skir.ResourceId resource,
  AuthoringDocument source,
) {
  final host = AuthoredPresentationHost(
    resource: resource,
    source: source,
    material: skir.PresentationMaterial.defaultInstance,
    role: skir.PresentationRole.workspace,
    budget: skir.EvaluationBudget(maxSteps: 100, maxCollectionItems: 100),
    capabilities: const PortablePresentationCapabilities(),
  );
  addTearDown(host.dispose);
  return host;
}
