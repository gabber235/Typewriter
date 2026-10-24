import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

import "package:typewriter_testkit/typewriter_testkit.dart";

final compiledEntryPageId = skir.ResourceId(value: "page:entry-nodes");
final compiledEntryBookId = skir.ResourceId(value: "book:entry-nodes");
final compiledEntryDestinationId = skir.ResourceId(value: "page:evening");
final compiledEntryFirstId = skir.ResourceId(value: "entry:greeting");
final compiledEntrySecondId = skir.ResourceId(value: "entry:followup");

/// Uses compiler emitted types and layouts with real reciprocal ownership.
AuthoringDocument compiledEntryNodeDocument({
  bool narrow = false,
  bool graphEditor = false,
}) {
  var catalog = CheckedEditorCatalog(compiledSdkControlCatalog);
  final elementType = compiledSdkElementValue.authoredActualType!;
  final pageType = skir.NamedTypeUse(
    definition: skir.TypeDefinitionId(
      typeId: skir.TypeId.createQualified(
        namespace: "kotlin",
        name: "com.typewritermc.library.Page",
      ),
      revision: 1,
    ),
    arguments: const [],
  );
  final pageSelection = skir.TypeSelection.wrapComplete(pageType);
  if (graphEditor) {
    final selected = catalog.selectPresentation(
      pageSelection,
      skir.PresentationRole.inspector,
    ) as SelectedEditorPresentation;
    final snapshot = catalog.snapshot.toMutable();
    snapshot.presentationMaterials = [
      for (final material in snapshot.presentationMaterials)
        if (material.provider == selected.material.provider &&
            material.role == selected.material.role)
          (material.toFrozen().toMutable()..layout = compiledEntryGraphLayout)
              .toFrozen()
        else
          material,
    ];
    catalog = CheckedEditorCatalog(snapshot.toFrozen());
  }
  final defaults = AuthoringDocument(
    catalog: catalog,
    entries: const {},
    links: const [],
  );
  final elementSelection = skir.TypeSelection.wrapComplete(elementType);
  final bookType =
      (compiledSdkBookRecord.configuration
              as skir.TypeSelection_completeWrapper)
          .value;
  final bookSelection = compiledSdkBookRecord.configuration;
  final bookPath = editorRootPath.field("book");
  skir.ValuePath bookMembershipPath(skir.ResourceId id) => skir.ValuePath(
    segments: [
      skir.PathSegment.createField(name: "pages"),
      skir.PathSegment.createItem(id: skir.ItemId(value: id.value)),
    ],
  );
  final bookEndpoint = catalog
      .endpointBindingsAt(
        bookSelection,
        bookMembershipPath(compiledEntryPageId),
      )
      .single
      .template
      .endpoint;
  final pageBookEndpoint = catalog
      .endpointBindingsAt(pageSelection, bookPath)
      .single
      .template
      .endpoint;
  final bookRelation = catalog.snapshot.relations.singleWhere(
    (relation) =>
        relation.first.id == bookEndpoint || relation.second.id == bookEndpoint,
  );
  final elementPagePath = editorRootPath.field("page");
  skir.ValuePath membershipPath(skir.ResourceId id) => skir.ValuePath(
    segments: [
      skir.PathSegment.createField(name: "elements"),
      skir.PathSegment.createItem(id: skir.ItemId(value: id.value)),
    ],
  );
  final pageEndpoint = catalog
      .endpointBindingsAt(pageSelection, membershipPath(compiledEntryFirstId))
      .single
      .template
      .endpoint;
  final elementEndpoint = catalog
      .endpointBindingsAt(elementSelection, elementPagePath)
      .single
      .template
      .endpoint;
  final relation = catalog.snapshot.relations.singleWhere(
    (relation) =>
        relation.first.id == pageEndpoint || relation.second.id == pageEndpoint,
  );
  skir.DataValue typedCollection(
    skir.TypeSelection selection,
    String field,
    List<skir.ListItem> items,
  ) {
    final collectionType = catalog
        .fields(selection)
        .singleWhere((candidate) => candidate.template.key == field)
        .type;
    final payload = skir.DataValue.createListValue(items: items);
    return switch (collectionType) {
      skir.TypeUse_namedWrapper(:final value) => skir.DataValue.createNamed(
        actualType: value,
        payload: payload,
      ),
      _ => payload,
    };
  }

  skir.AuthoringResource resource(
    skir.ResourceId id,
    skir.NamedTypeUse type,
    Map<String, skir.DataValue> fields,
  ) => skir.AuthoringResource(
    id: id,
    definition: catalog.snapshot.resourceDefinitions
        .singleWhere(
          (definition) => catalog
              .knownApplications(skir.TypeSelection.wrapComplete(type))
              .any((application) => application.definition == definition.root),
        )
        .id,
    content: skir.AuthoringRecord(
      configuration: skir.TypeSelection.wrapComplete(type),
      fields: [
        for (final field in catalog.fields(
          skir.TypeSelection.wrapComplete(type),
        ))
          skir.FieldValue(
            name: field.template.key,
            value:
                fields[field.template.key] ?? defaults.defaultValue(field.type),
          ),
      ],
    ),
  );
  final nodes = [compiledEntryFirstId, compiledEntrySecondId];
  return AuthoringDocument(
    confirmedObservation: skir.AuthoringObservationId(
      value: "compiled-entry:saved",
    ),
    catalog: catalog,
    entries: {
      compiledEntryBookId: resource(compiledEntryBookId, bookType, {
        for (final field in compiledSdkBookRecord.fields)
          field.name: field.value,
        "title": skir.DataValue.wrapStringValue("Village quests"),
        "pages": typedCollection(bookSelection, "pages", [
          for (final id in [compiledEntryPageId, compiledEntryDestinationId])
            skir.ListItem(
              id: skir.ItemId(value: id.value),
              value: skir.DataValue.createLink(
                endpoint: bookEndpoint,
                target: skir.LinkTarget(resource: id, opposite: bookPath),
              ),
            ),
        ]),
      }),
      compiledEntryPageId: resource(compiledEntryPageId, pageType, {
        "name": skir.DataValue.wrapStringValue("Village morning"),
        "book": skir.DataValue.createLink(
          endpoint: pageBookEndpoint,
          target: skir.LinkTarget(
            resource: compiledEntryBookId,
            opposite: bookMembershipPath(compiledEntryPageId),
          ),
        ),
        "elements": typedCollection(pageSelection, "elements", [
          for (final id in nodes)
            skir.ListItem(
              id: skir.ItemId(value: id.value),
              value: skir.DataValue.createLink(
                endpoint: pageEndpoint,
                target: skir.LinkTarget(
                  resource: id,
                  opposite: elementPagePath,
                ),
              ),
            ),
        ]),
      }),
      compiledEntryDestinationId: resource(
        compiledEntryDestinationId,
        pageType,
        {
          "name": skir.DataValue.wrapStringValue("Village evening"),
          "book": skir.DataValue.createLink(
            endpoint: pageBookEndpoint,
            target: skir.LinkTarget(
              resource: compiledEntryBookId,
              opposite: bookMembershipPath(compiledEntryDestinationId),
            ),
          ),
          "elements": typedCollection(pageSelection, "elements", []),
        },
      ),
      for (final (index, id) in nodes.indexed)
        id: resource(id, elementType, {
          "name": skir.DataValue.wrapStringValue(
            index == 0 ? "Welcome to the village" : "Meet the village guide",
          ),
          "page": skir.DataValue.createLink(
            endpoint: elementEndpoint,
            target: skir.LinkTarget(
              resource: compiledEntryPageId,
              opposite: membershipPath(id),
            ),
          ),
          "placement": GraphPlacement(
            x: index * 6,
            y: 0,
            width: narrow ? 1 : 4,
            height: 1,
          ).toAuthoredValue(),
        }),
    },
    links: [
      for (final id in [compiledEntryPageId, compiledEntryDestinationId])
        skir.LinkProjection(
          contract: bookRelation.id,
          first: bookRelation.first.id == bookEndpoint
              ? compiledEntryBookId
              : id,
          second: bookRelation.first.id == bookEndpoint
              ? id
              : compiledEntryBookId,
          firstLocation: bookRelation.first.id == bookEndpoint
              ? bookMembershipPath(id)
              : bookPath,
          secondLocation: bookRelation.first.id == bookEndpoint
              ? bookPath
              : bookMembershipPath(id),
        ),
      for (final id in nodes)
        skir.LinkProjection(
          contract: relation.id,
          first: relation.first.id == pageEndpoint ? compiledEntryPageId : id,
          second: relation.first.id == pageEndpoint ? id : compiledEntryPageId,
          firstLocation: relation.first.id == pageEndpoint
              ? membershipPath(id)
              : elementPagePath,
          secondLocation: relation.first.id == pageEndpoint
              ? elementPagePath
              : membershipPath(id),
        ),
    ],
  );
}

/// A fixture page editor using the production graph element and bindings.
final compiledEntryGraphLayout = skir.PresentationNode(
  nodeId: "entry-fixture.graph",
  properties: skir.PresentationProperties.defaultInstance,
  header: null,
  element: skir.PresentationElement.createPageGraph(
    control: skir.BoundControl(
      binding: skir.BindingRef(
        bindingId: skir.ExpressionBindingId(value: "configured_value"),
        path: editorRootPath.field("elements"),
      ),
      label: null,
      description: null,
      prefix: null,
      semanticLabel: null,
    ),
    direction: skir.PageGraphDirection.leftToRight,
    appearance: null,
  ),
);
