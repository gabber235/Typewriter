import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

import "../../../../../support/test_utils.dart";

void main() {
  testWidgets("resource collection lookup binds the selected authored row", (
    tester,
  ) async {
    final fixture = _fixture();
    final node = skir.PresentationNode(
      nodeId: "lookup",
      properties: skir.PresentationProperties.defaultInstance,
      element: skir.PresentationElement.createCollectionLookup(
        sourceId: "tags",
        key: skir.BindingRef(
          bindingId: _lookupBinding,
          path: skir.ValuePath(segments: const []),
        ),
        found: _textNode("found", _read(_rowBinding, "name")),
        missing: _textNode(
          "missing",
          skir.ExpressionNode.wrapLiteral(
            skir.DataValue.wrapStringValue("Missing"),
          ),
        ),
        loading: null,
      ),
      header: null,
    );

    await _pump(tester, node, fixture.scope);

    expect(find.text("Alpha"), findsOneWidget);
    expect(find.text("Missing"), findsNothing);
  });

  testWidgets(
    "collection graph projects relationship targets and follows a cycle once",
    (tester) async {
      final fixture = _fixture(cycle: true);
      final rootSlot = _slotNode("root.slot", "graph.root");
      final childSlot = _slotNode("child.slot", "graph.child");
      final node = skir.PresentationNode(
        nodeId: "graph",
        properties: skir.PresentationProperties.defaultInstance,
        element: skir.PresentationElement.createCollectionGraph(
          sourceId: "tags",
          roots: skir.ExpressionNode.createCollection(
            operation: skir.OperationId(value: "typewriter.collection.map"),
            input: skir.ExpressionNode.createRead(
              binding: _rootsBinding,
              path: skir.ValuePath(segments: const []),
            ),
            bindings: [skir.ExpressionBindingId(value: "root.link")],
            arguments: const [],
            body: skir.ExpressionNode.createCall(
              operation: skir.OperationId(value: "typewriter.link.target"),
              arguments: [
                skir.ExpressionNode.createRead(
                  binding: skir.ExpressionBindingId(value: "root.link"),
                  path: skir.ValuePath(segments: const []),
                ),
              ],
            ),
          ),
          rootSequence: _sequence(rootSlot),
          relationId: "next",
          direction: skir.CollectionGraphDirection.forward,
          maximumDepth: 8,
          node: skir.PresentationNode(
            nodeId: "graph.node",
            properties: skir.PresentationProperties.defaultInstance,
            element: skir.PresentationElement.wrapChildren(
              skir.ChildrenElement.createColumn(
                children: [
                  skir.AxisChild.wrapFixed(
                    _textNode("graph.name", _read(_rowBinding, "name")),
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
            header: null,
          ),
          childrenBindingId: _childrenBinding,
          childBindingId: _childBinding,
          children: _sequence(childSlot),
        ),
        header: null,
      );

      await _pump(
        tester,
        node,
        fixture.scope.withValues({
          _rootsBinding: skir.DataValue.createSetValue(
            items: [
              skir.ListItem(
                id: skir.ItemId(value: "selected.tag"),
                value: skir.DataValue.createLink(
                  endpoint: skir.EndpointId(value: "book.tags"),
                  target: skir.LinkTarget(
                    resource: skir.ResourceId(value: "tag:one"),
                    opposite: null,
                  ),
                ),
              ),
            ],
          ),
        }),
      );

      expect(find.text("Alpha"), findsOneWidget);
      expect(find.text("Beta"), findsOneWidget);
    },
  );

  testWidgets(
    "shared inheritance paths keep independent disclosure after reorder",
    (tester) async {
      final fixture = _fixture(
        graph: {
          "tag:one": ["Shared"],
          "tag:two": ["Shared"],
          "Shared": ["Leaf1", "Leaf2"],
          "Leaf1": [],
          "Leaf2": [],
        },
      );
      final node = _graphNode(disclosure: true);
      final ownerBinding = skir.ExpressionBindingId(value: "invocation.owner");
      PortablePresentationScope scope(
        List<String> roots, {
        String ownerPath = "first",
        String content = "initial",
      }) {
        final base = fixture.scope.withValues({_rootsBinding: _keys(roots)});
        return base.copyWith(
          bindings: {
            ...base.bindings,
            ownerBinding: PortableExpressionBinding(
              value: skir.DataValue.wrapStringValue(content),
              location: skir.ValueLocation(
                resource: skir.ResourceId(value: "tag:one"),
                path: skir.ValuePath(
                  segments: [skir.PathSegment.createField(name: ownerPath)],
                ),
              ),
            ),
          },
        );
      }

      await _pump(tester, node, scope(["tag:one", "tag:two"]));
      await tester.tap(find.text("Alpha"));
      await tester.pumpAndSettle();
      await tester.tap(find.text("Beta"));
      await tester.pumpAndSettle();
      expect(find.text("Shared"), findsNWidgets(2));
      await tester.tap(find.text("Shared").first);
      await tester.pumpAndSettle();
      expect(find.text("Leaf1"), findsOneWidget);
      expect(find.text("Leaf2"), findsOneWidget);

      await _pump(tester, node, scope(["tag:two", "tag:one"]));
      await tester.pumpAndSettle();
      expect(find.text("Shared"), findsNWidgets(2));
      expect(find.text("Leaf1"), findsOneWidget);
      expect(
        tester.getTopLeft(find.text("Leaf1")).dy,
        greaterThan(tester.getTopLeft(find.text("Alpha")).dy),
      );
      await tester.tap(find.text("Shared").first);
      await tester.pumpAndSettle();
      expect(find.text("Leaf1"), findsNWidgets(2));
      await _pump(
        tester,
        node,
        scope(["tag:two", "tag:one"], content: "edited"),
      );
      await tester.pumpAndSettle();
      expect(find.text("Leaf1"), findsNWidgets(2));
      await _pump(
        tester,
        node,
        scope(["tag:two", "tag:one"], ownerPath: "second"),
      );
      await tester.pumpAndSettle();
      expect(find.text("Shared"), findsNothing);
    },
  );

  testWidgets(
    "graph deduplicates siblings and roots but preserves shared paths",
    (tester) async {
      final fixture = _fixture(
        graph: {
          "tag:one": ["Shared", "Shared"],
          "tag:two": ["Shared"],
          "Shared": ["tag:one"],
        },
      );
      await _pump(
        tester,
        _graphNode(),
        fixture.scope.withValues({
          _rootsBinding: _keys(["tag:one", "tag:two", "tag:one"]),
        }),
      );
      expect(find.text("Alpha"), findsNWidgets(2));
      expect(find.text("Beta"), findsOneWidget);
      expect(find.text("Shared"), findsNWidgets(2));
      await tester.pump();
      expect(find.text("Shared"), findsNWidgets(2));
    },
  );

  testWidgets(
    "graph bounds occurrences visibly and keeps depth and reverse traversal",
    (tester) async {
      final fixture = _fixture(
        graph: {
          "tag:one": ["tag:two"],
          "tag:two": ["Shared"],
          "Shared": [],
        },
      );
      await _pump(tester, _graphNode(maximumDepth: 1), fixture.scope);
      expect(find.text("Alpha"), findsOneWidget);
      expect(find.text("Beta"), findsOneWidget);
      expect(find.text("Shared"), findsNothing);

      await _pump(
        tester,
        _graphNode(direction: skir.CollectionGraphDirection.reverse),
        fixture.scope.withValues({
          _rootsBinding: _keys(["Shared"]),
        }),
      );
      expect(find.text("Alpha"), findsOneWidget);
      expect(find.text("Beta"), findsOneWidget);
      expect(find.text("Shared"), findsOneWidget);

      await _pump(
        tester,
        _graphNode(),
        fixture.scope.copyWith(
          budget: skir.EvaluationBudget(maxSteps: 1000, maxCollectionItems: 2),
        ),
      );
      expect(find.text("Alpha"), findsOneWidget);
      expect(find.text("Beta"), findsOneWidget);
      expect(find.text("Shared"), findsNothing);
      expect(
        find.text("The collection graph occurrence limit was reached"),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    "hierarchy resolves trunk in owner scope and branches in item scopes",
    (tester) async {
      final fixture = _fixture(
        graph: {
          "tag:one": ["tag:two", "Shared"],
          "tag:two": [],
          "Shared": [],
        },
      );
      final color = skir.PresentationColor.wrapValue(
        skir.ExpressionNode.createConditional(
          test: skir.ExpressionNode.createCall(
            operation: skir.OperationId(value: "typewriter.value.eq"),
            arguments: [
              _read(_rowBinding, "name"),
              skir.ExpressionNode.wrapLiteral(
                skir.DataValue.wrapStringValue("Alpha"),
              ),
            ],
          ),
          yes: skir.ExpressionNode.wrapLiteral(
            skir.DataValue.wrapInteger("4294901760"),
          ),
          no: skir.ExpressionNode.wrapLiteral(
            skir.DataValue.wrapInteger("4278190335"),
          ),
        ),
      );
      final connector = skir.ConnectorStyle(
        stroke: skir.ConnectorStroke(color: color, width: _number(2)),
        cornerRadius: _number(8),
        startMarker: null,
        endMarker: null,
      );
      await _pump(
        tester,
        _graphNode(
          childrenLayout: skir.SequenceLayout.createHierarchy(
            unaryConnector: connector,
            trunkConnector: connector,
            branchConnector: connector,
            itemSpacing: _number(24),
            indentation: _number(16),
            leadingSpacing: _number(16),
            itemAnchor: skir.ConnectorAnchor.center,
            flattenSingleItem: skir.ExpressionNode.wrapLiteral(
              skir.DataValue.wrapBoolean(true),
            ),
            crossAxisAlignment: skir.CrossAxisAlignment.stretch,
          ),
        ),
        fixture.scope,
      );
      await tester.pumpAndSettle();
      final surface = find.byWidgetPredicate(
        (widget) => widget.runtimeType.toString() == "_HierarchyRenderSurface",
      );
      expect(surface, findsOneWidget);
      final strokes =
          (tester.renderObject(surface) as dynamic).debugStrokes as List;
      expect(strokes, hasLength(3));
      expect((strokes.first as dynamic).color, const Color(0xffff0000));
      expect((strokes[1] as dynamic).color, const Color(0xff0000ff));
      expect((strokes[2] as dynamic).color, const Color(0xff0000ff));
    },
  );

  testWidgets("graph rejects wrongly typed roots and ambiguous keys", (
    tester,
  ) async {
    final fixture = _fixture();
    await _pump(
      tester,
      _graphNode(),
      fixture.scope.withValues({
        _rootsBinding: skir.DataValue.wrapInteger("1"),
      }),
    );
    expect(
      find.text("A collection graph root has the wrong key type"),
      findsOneWidget,
    );
    final duplicate = _fixture(projected: true, duplicateKey: true);
    await _pump(tester, _graphNode(), duplicate.scope);
    expect(
      find.text("The collection graph contains an ambiguous key"),
      findsOneWidget,
    );
  });

  testWidgets("projected collection uses its authored custom key", (
    tester,
  ) async {
    final fixture = _fixture(projected: true);
    final node = skir.PresentationNode(
      nodeId: "lookup.projected",
      properties: skir.PresentationProperties.defaultInstance,
      element: skir.PresentationElement.createCollectionLookup(
        sourceId: "tags",
        key: skir.BindingRef(
          bindingId: _lookupBinding,
          path: skir.ValuePath(segments: const []),
        ),
        found: _textNode("projected.name", _read(_rowBinding, "name")),
        missing: _textNode(
          "projected.missing",
          skir.ExpressionNode.wrapLiteral(
            skir.DataValue.wrapStringValue("Missing"),
          ),
        ),
        loading: null,
      ),
      header: null,
    );

    await _pump(tester, node, fixture.scope);

    expect(find.text("Alpha"), findsOneWidget);
    expect(find.text("Missing"), findsNothing);
  });

  testWidgets("unfinished lookup key renders the missing presentation", (
    tester,
  ) async {
    final fixture = _fixture();
    final node = skir.PresentationNode(
      nodeId: "lookup.unfinished",
      properties: skir.PresentationProperties.defaultInstance,
      element: skir.PresentationElement.createCollectionLookup(
        sourceId: "tags",
        key: skir.BindingRef(
          bindingId: _lookupBinding,
          path: skir.ValuePath(segments: const []),
        ),
        found: _textNode("unfinished.found", _read(_rowBinding, "name")),
        missing: _textNode(
          "unfinished.missing",
          skir.ExpressionNode.wrapLiteral(
            skir.DataValue.wrapStringValue("Choose a tag"),
          ),
        ),
        loading: null,
      ),
      header: null,
    );

    await _pump(
      tester,
      node,
      fixture.scope.withValues({_lookupBinding: skir.DataValue.unfilled}),
    );

    expect(find.text("Choose a tag"), findsOneWidget);
    expect(find.textContaining("wrong type"), findsNothing);
  });

  testWidgets("unfinished graph roots report unavailable input", (
    tester,
  ) async {
    final fixture = _fixture();
    final node = skir.PresentationNode(
      nodeId: "graph.unfinished",
      properties: skir.PresentationProperties.defaultInstance,
      element: skir.PresentationElement.createCollectionGraph(
        sourceId: "tags",
        roots: skir.ExpressionNode.createRead(
          binding: _rootsBinding,
          path: skir.ValuePath(segments: const []),
        ),
        rootSequence: _sequence(_slotNode("unfinished.root", "graph.root")),
        relationId: "next",
        direction: skir.CollectionGraphDirection.forward,
        maximumDepth: 8,
        node: _textNode("unfinished.node", _read(_rowBinding, "name")),
        childrenBindingId: _childrenBinding,
        childBindingId: _childBinding,
        children: _sequence(_slotNode("unfinished.child", "graph.child")),
      ),
      header: null,
    );

    await _pump(
      tester,
      node,
      fixture.scope.withValues({_rootsBinding: skir.DataValue.unfilled}),
    );

    expect(
      find.text("The collection graph roots are unavailable"),
      findsOneWidget,
    );
  });

  testWidgets("duplicate projected keys report ambiguity", (tester) async {
    final fixture = _fixture(projected: true, duplicateKey: true);
    final node = skir.PresentationNode(
      nodeId: "lookup.duplicate",
      properties: skir.PresentationProperties.defaultInstance,
      element: skir.PresentationElement.createCollectionLookup(
        sourceId: "tags",
        key: skir.BindingRef(
          bindingId: _lookupBinding,
          path: skir.ValuePath(segments: const []),
        ),
        found: _textNode("duplicate.found", _read(_rowBinding, "name")),
        missing: _textNode(
          "duplicate.missing",
          skir.ExpressionNode.wrapLiteral(
            skir.DataValue.wrapStringValue("Missing"),
          ),
        ),
        loading: null,
      ),
      header: null,
    );

    await _pump(tester, node, fixture.scope);

    expect(find.text("The collection lookup key is ambiguous"), findsOneWidget);
  });

  testWidgets("nested material keeps a same named source provider scoped", (
    tester,
  ) async {
    final fixture = _nestedMaterialFixture();

    await _pump(tester, fixture.node, fixture.scope);

    expect(find.text("Alpha"), findsOneWidget);
    expect(find.textContaining("wrong type"), findsNothing);
  });
}

({PortablePresentationScope scope, skir.PresentationNode node})
_nestedMaterialFixture() {
  final base = _fixture();
  final original = base.scope.catalog!.snapshot;
  final record = base.document.resources.values.first;
  final type = switch (record.configuration) {
    skir.TypeSelection_completeWrapper(:final value) => value.definition,
    _ => throw StateError("The nested collection fixture must be complete"),
  };
  final nestedProvider = skir.PresentationId(
    namespace: "test",
    name: "nested.collections",
  );
  final nestedDefinition = skir.PresentationCollectionDefinition(
    sourceId: "tags",
    rowType: skir.TypeTemplate.createNamed(
      definition: type,
      arguments: const [],
    ),
    rowBindingId: _rowBinding,
    key: _read(_rowBinding, "name"),
    selectability: skir.ExpressionNode.wrapLiteral(
      skir.DataValue.wrapBoolean(true),
    ),
    relations: const [],
    projection: skir.PresentationCollectionProjection(
      root: skir.NamedTypeTemplate(definition: type, arguments: const []),
      resourceBindingId: _resourceBinding,
      fields: [
        skir.PresentationCollectionProjectionField(
          target: skir.ValuePath(
            segments: [skir.PathSegment.createField(name: "name")],
          ),
          source: skir.PresentationCollectionProjectionValue.createContent(
            segments: [skir.PathSegment.createField(name: "name")],
          ),
        ),
      ],
    ),
    resources: null,
  );
  final nestedLayout = skir.PresentationNode(
    nodeId: "nested.lookup",
    properties: skir.PresentationProperties.defaultInstance,
    element: skir.PresentationElement.createCollectionLookup(
      sourceId: "tags",
      key: skir.BindingRef(
        bindingId: _nestedLookupBinding,
        path: skir.ValuePath(segments: const []),
      ),
      found: _textNode("nested.found", _read(_rowBinding, "name")),
      missing: _textNode(
        "nested.missing",
        skir.ExpressionNode.wrapLiteral(
          skir.DataValue.wrapStringValue("Missing"),
        ),
      ),
      loading: null,
    ),
    header: null,
  );
  final nestedMaterial = skir.PresentationMaterial(
    inheritableNodes: const [],
    resultAppearance: null,

    provider: nestedProvider,
    target: skir.PresentationTarget.createNamed(
      definition: type,
      arguments: const [],
    ),
    role: skir.PresentationRole.inspector,
    layout: nestedLayout,
    dependencies: skir.PresentationDependencies(
      contextInputs: const [],

      types: const [],
      presentations: const [],
      conversions: const [],
      capabilities: const [],
      collections: [nestedDefinition],
    ),
    subject: skir.TypeTemplate.createNamed(
      definition: type,
      arguments: const [],
    ),
  );
  final checked = CheckedEditorCatalog(
    skir.EditorCatalogWireSnapshot(
      generation: original.generation,
      types: original.types,
      relations: original.relations,
      resourceDefinitions: original.resourceDefinitions,
      presentations: original.presentations,
      presentationMaterials: [
        ...original.presentationMaterials,
        nestedMaterial,
      ],
      configuration: original.configuration,
      diagnostics: original.diagnostics,

      endpointBindings: original.endpointBindings,
      capabilities: original.capabilities,
      recommendations: original.recommendations,
      roleFallbacks: original.roleFallbacks,
    ),
  );
  final resource = base.document.resources.keys.first;
  return (
    scope: PortablePresentationScope(
      operations: testPortableOperations(),
      bindings: {
        ...base.scope.bindings,
        _nestedLookupBinding: PortableExpressionBinding(
          value: skir.DataValue.wrapStringValue("Alpha"),
        ),
      },
      budget: base.scope.budget,
      catalog: checked,
      queries: PortableExpressionQueries(
        catalog: checked,
        authored: AuthoringDocument(
          catalog: checked,
          entries: base.document.entries,
          links: base.document.links,
        ),
      ),
      resource: resource,
      material: base.material,
      host: base.scope.host,
    ),
    node: skir.PresentationNode(
      nodeId: "outer.invocation",
      properties: skir.PresentationProperties.defaultInstance,
      element: skir.PresentationElement.createInvocation(
        presentationId: nestedProvider,
        arguments: const [],
      ),
      header: null,
    ),
  );
}

({
  PortablePresentationScope scope,
  skir.PresentationMaterial material,
  AuthoringDocument document,
})
_fixture({
  bool cycle = false,
  bool projected = false,
  bool duplicateKey = false,
  Map<String, List<String>>? graph,
}) {
  final type = _definition("Tag");
  final list = _definition("List");
  final listParameter = skir.ParameterKey(owner: list, index: 0);
  final listOfResources = skir.NamedTypeUse(
    definition: list,
    arguments: [skir.TypeUse.wrapNamed(frameworkResourceIdUse)],
  );
  final listOfResourcesTemplate = skir.TypeTemplate.createNamed(
    definition: list,
    arguments: [
      skir.TypeTemplate.createNamed(
        definition: frameworkResourceIdUse.definition,
        arguments: const [],
      ),
    ],
  );
  final generation = skir.CatalogGeneration(value: "catalog:collections");
  final published = skir.PublishedType(
    display: null,
    definition: skir.TypeDefinition(
      id: type,
      parameters: const [],
      representation: skir.RepresentationTemplate.createRecord(
        fields: [
          _field(
            type,
            "name",
            skir.TypeTemplate.wrapScalar(skir.ScalarKind.text),
          ),
          _field(type, "next", listOfResourcesTemplate),
        ],
        abstract_: false,
      ),
      parents: const [],
    ),
    status: skir.DeclarationStatus.ready,
    effectiveFields: [
      _effective(
        type,
        "name",
        skir.TypeTemplate.wrapScalar(skir.ScalarKind.text),
      ),
      _effective(type, "next", listOfResourcesTemplate),
    ],
    ancestorTemplates: const [],
  );
  final checked = CheckedEditorCatalog(
    skir.EditorCatalogWireSnapshot(
      generation: generation,
      types: [
        published,
        skir.PublishedType(
          display: null,
          definition: skir.TypeDefinition(
            id: list,
            parameters: [
              skir.TypeParameter(
                key: listParameter,
                name: "T",
                bounds: const [],
              ),
            ],
            representation: skir.RepresentationTemplate.createSequence(
              item: skir.TypeTemplate.wrapParameter(listParameter),
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
      resourceDefinitions: [
        skir.AuthoringResourceDefinition(
          id: skir.ResourceDefinitionId(value: "test.tag"),
          root: type,
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
  final one = skir.ResourceId(value: "tag:one");
  final two = skir.ResourceId(value: "tag:two");
  final snapshot = skir.AuthoringState(
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
    rowType: skir.TypeTemplate.createNamed(
      definition: type,
      arguments: const [],
    ),
    rowBindingId: _rowBinding,
    key: projected
        ? _read(_rowBinding, "name")
        : skir.ExpressionNode.createRead(
            binding: _resourceBinding,
            path: skir.ValuePath(segments: const []),
          ),
    selectability: skir.ExpressionNode.wrapLiteral(
      skir.DataValue.wrapBoolean(true),
    ),
    relations: [
      skir.PresentationCollectionRelationDefinition(
        relationId: "next",
        targets: _read(_rowBinding, "next"),
      ),
    ],
    projection: projected
        ? skir.PresentationCollectionProjection(
            root: skir.NamedTypeTemplate(definition: type, arguments: const []),
            resourceBindingId: _resourceBinding,
            fields: [
              skir.PresentationCollectionProjectionField(
                target: skir.ValuePath(
                  segments: [skir.PathSegment.createField(name: "name")],
                ),
                source:
                    skir.PresentationCollectionProjectionValue.createContent(
                      segments: [skir.PathSegment.createField(name: "name")],
                    ),
              ),
            ],
          )
        : null,
    resources: projected
        ? null
        : skir.PresentationResourceCollection(
            root: type,
            resourceBindingId: _resourceBinding,
            appearance: null,
          ),
  );
  final provider = skir.PresentationId(namespace: "test", name: "collections");
  final target = skir.PresentationTarget.createNamed(
    definition: type,
    arguments: const [],
  );
  final material = skir.PresentationMaterial(
    inheritableNodes: const [],
    resultAppearance: null,

    provider: provider,
    target: target,
    role: skir.PresentationRole.inspector,
    layout: _slotNode("material", "unused"),
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
  return (
    material: material,
    document: document,
    scope: PortablePresentationScope(
      operations: testPortableOperations(),
      bindings: {
        _lookupBinding: PortableExpressionBinding(
          value: projected
              ? skir.DataValue.wrapStringValue("Alpha")
              : one.toExpressionValue(),
        ),
        _rootsBinding: PortableExpressionBinding(
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

skir.PresentationNode _graphNode({
  bool disclosure = false,
  int maximumDepth = 8,
  skir.CollectionGraphDirection direction =
      skir.CollectionGraphDirection.forward,
  skir.SequenceLayout? childrenLayout,
}) {
  final childSlot = _slotNode("child.slot", "graph.child");
  return skir.PresentationNode(
    nodeId: "graph",
    properties: skir.PresentationProperties.defaultInstance,
    element: skir.PresentationElement.createCollectionGraph(
      sourceId: "tags",
      roots: skir.ExpressionNode.createRead(
        binding: _rootsBinding,
        path: skir.ValuePath(segments: const []),
      ),
      rootSequence: _sequence(_slotNode("root.slot", "graph.root")),
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
                  _textNode("graph.name", _read(_rowBinding, "name")),
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
                  _read(_rowBinding, "name"),
                ),
                description: null,
                initiallyExpanded: false,
                items: const [],
                headerPadding: null,
                contentPadding: null,
              )
            : null,
      ),
      childrenBindingId: _childrenBinding,
      childBindingId: _childBinding,
      children: skir.SequencePresentation(
        item: childSlot,
        empty: null,
        separator: null,
        layout: childrenLayout ?? _sequence(childSlot).layout,
      ),
    ),
    header: null,
  );
}

skir.DataValue _keys(List<String> values) => skir.DataValue.createListValue(
  items: [
    for (final (index, value) in values.indexed)
      skir.ListItem(
        id: skir.ItemId(value: "root:$index"),
        value: skir.ResourceId(value: value).toExpressionValue(),
      ),
  ],
);

skir.AuthoringResource _resource(
  skir.ResourceId id,
  skir.TypeDefinitionId type,
  skir.NamedTypeUse listType,
  String name,
  List<skir.ResourceId> next,
) => skir.AuthoringResource(
  id: id,
  definition: skir.ResourceDefinitionId(value: "test.tag"),
  content: skir.AuthoringRecord(
    configuration: skir.TypeSelection.createComplete(
      definition: type,
      arguments: const [],
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

skir.ExpressionNode _read(skir.ExpressionBindingId id, String field) =>
    skir.ExpressionNode.createRead(
      binding: id,
      path: skir.ValuePath(
        segments: [skir.PathSegment.createField(name: field)],
      ),
    );

skir.PresentationNode _textNode(String id, skir.ExpressionNode value) =>
    skir.PresentationNode(
      nodeId: id,
      properties: skir.PresentationProperties.defaultInstance,
      element: skir.PresentationElement.createText(
        value: value,
        color: null,
        sizing: null,
        fontWeight: null,
        fontItalic: null,
        fontOpticalSize: null,
        fontSlant: null,
        fontWidth: null,
        textAlignment: null,
        lineHeight: null,
        letterSpacing: null,
        decoration: null,
        semanticLabel: null,
        paragraph: skir.TextParagraph.defaultInstance,
      ),
      header: null,
    );

skir.PresentationNode _slotNode(String id, String slot) =>
    skir.PresentationNode(
      nodeId: id,
      properties: skir.PresentationProperties.defaultInstance,
      element: skir.PresentationElement.createSlot(slotId: slot),
      header: null,
    );

skir.SequencePresentation _sequence(skir.PresentationNode item) =>
    skir.SequencePresentation(
      item: item,
      empty: null,
      separator: null,
      layout: skir.SequenceLayout.wrapChildren(
        skir.ChildrenLayout.createColumn(
          clipOverflow: false,

          spacing: 0,
          mainAxisAlignment: skir.MainAxisAlignment.start,
          crossAxisAlignment: skir.CrossAxisAlignment.start,
        ),
      ),
    );

Future<void> _pump(
  WidgetTester tester,
  skir.PresentationNode node,
  PortablePresentationScope scope,
) => tester.pumpTestApp(
  child: Builder(
    builder: (_) => Scaffold(
      body: PortablePresentationNodeRenderer(node: node, scope: scope),
    ),
  ),
);

skir.TypeDefinitionId _definition(String name) => skir.TypeDefinitionId(
  typeId: skir.TypeId.wrapQualified(
    skir.QualifiedTypeId(namespace: "test", name: name),
  ),
  revision: 1,
);

final _rowBinding = skir.ExpressionBindingId(value: "collection.row");
final _resourceBinding = skir.ExpressionBindingId(value: "collection.resource");
final _lookupBinding = skir.ExpressionBindingId(value: "lookup.key");
final _nestedLookupBinding = skir.ExpressionBindingId(
  value: "lookup.nested.key",
);
final _rootsBinding = skir.ExpressionBindingId(value: "graph.roots");
final _childrenBinding = skir.ExpressionBindingId(value: "graph.children");
final _childBinding = skir.ExpressionBindingId(value: "graph.child");

skir.ExpressionNode _number(double value) =>
    skir.ExpressionNode.wrapLiteral(skir.DataValue.wrapFloat(value));
