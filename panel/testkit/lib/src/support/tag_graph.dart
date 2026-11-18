import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/src/shared/editors/presentation_builders.dart";
import "package:typewriter_testkit/src/support/portable_operations.dart";
import "package:typewriter_testkit/src/shared/editors/catalog_fixture.dart";

/// Authored tags linked by their `next` field: by default `tag:one`
/// (Alpha) leads to `tag:two` (Beta). An inspector material declares them
/// as the collection `tags` with the relation `next`, and [scope] renders
/// it for `tag:one`.
final class TagGraph {
  TagGraph._({
    required this.scope,
    required this.material,
    required this.document,
  });

  /// Builds the graph; [graph] replaces the default links with tags keyed by
  /// id that lead to the listed ids. [cycle] links Beta back to Alpha,
  /// [duplicateKey] names both Alpha, and [projected] keys rows by name
  /// instead of by resource.
  factory TagGraph({
    bool cycle = false,
    bool projected = false,
    bool duplicateKey = false,
    Map<String, List<String>>? graph,
  }) {
    final type = typeDefinition("Tag");
    final list = typeDefinition("List");
    final listParameter = skir.ParameterKey(owner: list, index: 0);
    final listOfResources = skir.NamedTypeUse(
      definition: list,
      arguments: [skir.TypeUse.wrapNamed(skir.resourceIdType)],
    );
    final listOfResourcesTemplate = skir.TypeTemplate.createNamed(
      definition: list,
      arguments: [
        skir.TypeTemplate.createNamed(
          definition: skir.resourceIdType.definition,
          arguments: const [],
        ),
      ],
    );
    final generation = skir.CatalogGeneration(value: "catalog:collections");
    final published = publishedType(
      type,
      representation: skir.RepresentationTemplate.createRecord(
        fields: [
          _field(
            type,
            "name",
            skir.TypeTemplate.wrapScalar(skir.ScalarKind.text),
          ),
          _field(type, "next", listOfResourcesTemplate),
        ],
        form: skir.RecordForm.concrete,
      ),
      fields: [
        _effective(
          type,
          "name",
          skir.TypeTemplate.wrapScalar(skir.ScalarKind.text),
        ),
        _effective(type, "next", listOfResourcesTemplate),
      ],
    );
    final checked = CheckedEditorCatalog(
      testCatalogSnapshot(
        generation: generation,
        types: [
          published,
          publishedType(
            list,
            representation: skir.RepresentationTemplate.createSequence(
              item: skir.TypeTemplate.wrapParameter(listParameter),
              kind: skir.CollectionKind.list,
            ),
            parameters: [
              skir.TypeParameter(
                key: listParameter,
                name: "T",
                bounds: const [],
                derived: false,
              ),
            ],
          ),
        ],
      ),
    );
    final one = skir.ResourceId(value: "tag:one");
    final two = skir.ResourceId(value: "tag:two");
    final snapshot = skir.AuthoringState(
      confirmedObservation: skir.AuthoringObservationId(value: "fixture:saved"),
      generation: generation,
      resources: graph == null
          ? [
              _resource(one, type, listOfResources, "Alpha", [two]),
              _resource(
                two,
                type,
                listOfResources,
                duplicateKey ? "Alpha" : "Beta",
                cycle ? [one] : const [],
              ),
            ]
          : [
              for (final entry in graph.entries)
                _resource(
                  skir.ResourceId(value: entry.key),
                  type,
                  listOfResources,
                  switch (entry.key) {
                    "tag:one" => "Alpha",
                    "tag:two" => "Beta",
                    _ => entry.key,
                  },
                  [for (final key in entry.value) skir.ResourceId(value: key)],
                ),
            ],
      links: const [],
      findings: const [],
    );
    final draft = AuthoringEdit.fromState(snapshot, catalog: checked);
    final definition = skir.PresentationCollectionDefinition(
      sourceId: "tags",
      rowBinding: declareBinding(
        rowBinding,
        skir.TypeTemplate.createNamed(definition: type, arguments: const []),
      ),
      key: projected
          ? inputExpression(rowBinding, field: "name")
          : skir.ExpressionNode.createInput(
              binding: resourceBinding,
              path: skir.ValuePath(segments: const []),
            ),
      selectability: skir.ExpressionNode.wrapLiteral(
        skir.DataValue.wrapBoolean(true),
      ),
      relations: [
        skir.PresentationCollectionRelationDefinition(
          relationId: "next",
          targets: inputExpression(rowBinding, field: "next"),
        ),
      ],
      projection: skir.PresentationCollectionProjection(
        root: skir.NamedTypeTemplate(definition: type, arguments: const []),
        resourceBinding: declareBinding(resourceBinding, _resourceIdTemplate),
        fields: [
          for (final field in ["name", if (!projected) "next"])
            skir.PresentationCollectionProjectionField(
              target: skir.ValuePath(
                segments: [skir.PathSegment.createField(name: field)],
              ),
              source: skir.PresentationCollectionProjectionValue.createContent(
                segments: [skir.PathSegment.createField(name: field)],
              ),
            ),
        ],
      ),
    );
    final provider = skir.PresentationId(
      namespace: "test",
      name: "collections",
    );
    final target = skir.PresentationTarget.createNamed(
      definition: type,
      arguments: const [],
    );
    final material = skir.PresentationMaterial(
      inheritableNodes: const [],

      provider: provider,
      target: target,
      role: skir.PresentationRole.inspector,
      layout: presentationSlot("material", "unused"),
      dependencies: skir.PresentationDependencies(
        contextInputs: const [],

        types: const [],
        presentations: const [],
        conversions: const [],
        capabilities: const [],
        collections: [definition],
      ),
      subject: skir.TypeTemplate.createNamed(
        definition: type,
        arguments: const [],
      ),
    );
    final document = draft.toDocument();
    final budget = skir.EvaluationBudget(
      maxSteps: 1000,
      maxCollectionItems: 1000,
    );
    final host = AuthoredPresentationHost(
      resource: one,
      source: document,
      material: material,
      role: skir.PresentationRole.inspector,
      budget: budget,
      capabilities: const PortablePresentationCapabilities(),
    );
    return TagGraph._(
      material: material,
      document: document,
      scope: PortablePresentationScope(
        operations: testPortableOperations(),
        bindings: {
          lookupBinding: PortableExpressionBinding(
            value: projected
                ? skir.DataValue.wrapStringValue("Alpha")
                : one.toExpressionValue(),
          ),
          rootsBinding: PortableExpressionBinding(
            value: _values([one], listOfResources),
          ),
        },
        budget: budget,
        catalog: checked,
        queries: host.document.queries,
        resourceDiagnostics: host.document.resourceDiagnostics,
        material: material,
        host: host,
      ),
    );
  }

  /// The scope that renders the material for `tag:one`, with the lookup key
  /// and the graph roots supplied.
  final PortablePresentationScope scope;

  /// The inspector material declaring the `tags` collection.
  final skir.PresentationMaterial material;

  /// The authored document holding the tags.
  final AuthoringDocument document;

  /// The binding of one collection row.
  static final rowBinding = skir.ExpressionBindingId(value: "collection.row");

  /// The template of one tag row.
  static final rowTemplate = skir.TypeTemplate.createNamed(
    definition: typeDefinition("Tag"),
    arguments: const [],
  );

  /// The template of a list of tag rows.
  static final rowListTemplate = skir.TypeTemplate.createNamed(
    definition: typeDefinition("List"),
    arguments: [rowTemplate],
  );

  /// The binding of a row's resource id.
  static final resourceBinding = skir.ExpressionBindingId(
    value: "collection.resource",
  );

  /// The binding a lookup reads its key from.
  static final lookupBinding = skir.ExpressionBindingId(value: "lookup.key");

  /// The binding a nested lookup reads its key from.
  static final nestedLookupBinding = skir.ExpressionBindingId(
    value: "lookup.nested.key",
  );

  /// The binding the graph reads its roots from.
  static final rootsBinding = skir.ExpressionBindingId(value: "graph.roots");

  /// The binding of a node's children.
  static final childrenBinding = skir.ExpressionBindingId(
    value: "graph.children",
  );

  /// The binding of one child.
  static final childBinding = skir.ExpressionBindingId(value: "graph.child");

  static final _resourceIdTemplate = skir.TypeUse.wrapNamed(skir.resourceIdType)
      .portableTemplate;

  /// A graph over `tags` from [rootsBinding] following `next` in
  /// [direction] up to [maximumDepth], each node named unless it uses a
  /// [disclosure] header, its children laid out by [childrenLayout].
  static skir.PresentationNode node({
    bool disclosure = false,
    int maximumDepth = 8,
    skir.CollectionGraphDirection direction =
        skir.CollectionGraphDirection.forward,
    skir.SequenceLayout? childrenLayout,
  }) {
    final childSlot = presentationSlot("child.slot", "graph.child");
    return skir.PresentationNode(
      nodeId: "graph",
      properties: skir.PresentationProperties.defaultInstance,
      element: skir.PresentationElement.createCollectionGraph(
        sourceId: "tags",
        roots: skir.ExpressionNode.createInput(
          binding: rootsBinding,
          path: skir.ValuePath(segments: const []),
        ),
        rootSequence: columnSequence(
          presentationSlot("root.slot", "graph.root"),
        ),
        relationId: "next",
        direction: direction,
        maximumDepth: maximumDepth,
        node: skir.PresentationNode(
          nodeId: "graph.node",
          properties: skir.PresentationProperties.defaultInstance,
          element: skir.PresentationElement.wrapChildren(
            skir.ChildrenElement.createColumn(
              children: [
                if (!disclosure)
                  skir.AxisChild.wrapFixed(
                    presentationText(
                      "graph.name",
                      inputExpression(rowBinding, field: "name"),
                    ),
                  ),
                skir.AxisChild.wrapFixed(childSlot),
              ],
              layout: skir.AxisChildrenLayout(
                clipOverflow: false,

                spacing: 0,
                mainAxisAlignment: skir.MainAxisAlignment.start,
                crossAxisAlignment: skir.CrossAxisAlignment.start,
              ),
            ),
          ),
          header: disclosure
              ? skir.PresentationHeader(
                  binding: null,
                  title: skir.PresentationHeaderTitle.wrapText(
                    inputExpression(rowBinding, field: "name"),
                  ),
                  description: null,
                  initiallyExpanded: false,
                  items: const [],
                  headerPadding: null,
                  contentPadding: null,
                )
              : null,
        ),
        childrenBinding: declareBinding(childrenBinding, rowListTemplate),
        childBinding: declareBinding(childBinding, rowTemplate),
        children: skir.SequencePresentation(
          item: childSlot,
          empty: null,
          separator: null,
          layout: childrenLayout ?? columnSequence(childSlot).layout,
        ),
      ),
      header: null,
    );
  }

  /// The list of resource keys [values], as roots or lookups read them.
  static skir.DataValue keys(List<String> values) =>
      skir.DataValue.createListValue(
        items: [
          for (final (index, value) in values.indexed)
            skir.ListItem(
              id: skir.ItemId(value: "root:$index"),
              value: skir.ResourceId(value: value).toExpressionValue(),
            ),
        ],
      );
}

skir.AuthoringResource _resource(
  skir.ResourceId id,
  skir.TypeDefinitionId type,
  skir.NamedTypeUse listType,
  String name,
  List<skir.ResourceId> next,
) => skir.AuthoringResource(
  id: id,
  content: skir.AuthoringRecord(
    types: const [],
    configuration: selectionOfUse(
      skir.NamedTypeUse(definition: type, arguments: const []),
    ),
    fields: [
      skir.FieldValue(
        name: "name",
        value: skir.DataValue.wrapStringValue(name),
      ),
      skir.FieldValue(name: "next", value: _values(next, listType)),
    ],
  ),
);

skir.DataValue _values(
  List<skir.ResourceId> values,
  skir.NamedTypeUse listType,
) => skir.DataValue.createNamed(
  actualType: listType,
  payload: skir.DataValue.createListValue(
    items: [
      for (final indexed in values.indexed)
        skir.ListItem(
          id: skir.ItemId(value: "item:${indexed.$1}"),
          value: indexed.$2.toExpressionValue(),
        ),
    ],
  ),
);

skir.FieldDeclaration _field(
  skir.TypeDefinitionId type,
  String name,
  skir.TypeTemplate fieldType,
) => skir.FieldDeclaration(
  owner: skir.FieldOwner(definition: type, name: name),
  type: fieldType,
  overrides: const [],
  hasConstructorDefault: false,
);

skir.EffectiveFieldTemplate _effective(
  skir.TypeDefinitionId type,
  String name,
  skir.TypeTemplate fieldType,
) => skir.EffectiveFieldTemplate(
  key: name,
  owner: skir.FieldOwner(definition: type, name: name),
  type: fieldType,
  rules: const [],
);
