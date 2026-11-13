import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  testWidgets("resource collection lookup binds the selected authored row", (
    tester,
  ) async {
    final fixture = TagGraph();
    final node = skir.PresentationNode(
      nodeId: "lookup",
      properties: skir.PresentationProperties.defaultInstance,
      element: skir.PresentationElement.createCollectionLookup(
        sourceId: "tags",
        key: skir.BindingRef(
          bindingId: TagGraph.lookupBinding,
          path: skir.ValuePath(segments: const []),
        ),
        found: presentationText(
          "found",
          inputExpression(TagGraph.rowBinding, field: "name"),
        ),
        missing: presentationText(
          "missing",
          skir.ExpressionNode.wrapLiteral(
            skir.DataValue.wrapStringValue("Missing"),
          ),
        ),
        loading: null,
      ),
      header: null,
    );

    await tester.showNode(node, fixture.scope);

    expect(find.text("Alpha"), findsOneWidget);
    expect(find.text("Missing"), findsNothing);
  });

  testWidgets(
    "collection graph projects relationship targets and follows a cycle once",
    (tester) async {
      final fixture = TagGraph(cycle: true);
      final rootSlot = presentationSlot("root.slot", "graph.root");
      final childSlot = presentationSlot("child.slot", "graph.child");
      final node = skir.PresentationNode(
        nodeId: "graph",
        properties: skir.PresentationProperties.defaultInstance,
        element: skir.PresentationElement.createCollectionGraph(
          sourceId: "tags",
          roots: portableCall("collection.map", [
            skir.ExpressionNode.createInput(
              binding: TagGraph.rootsBinding,
              path: skir.ValuePath(segments: const []),
            ),
            skir.ExpressionNode.createLambda(
              arity: 1,
              body: portableCall("link.target", [
                skir.ExpressionNode.createLocal(
                  depth: 0,
                  slot: 0,
                  path: skir.ValuePath(segments: const []),
                ),
              ]),
            ),
          ]),
          rootSequence: columnSequence(rootSlot),
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
                    presentationText(
                      "graph.name",
                      inputExpression(TagGraph.rowBinding, field: "name"),
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
            header: null,
          ),
          childrenBinding: declareBinding(
            TagGraph.childrenBinding,
            TagGraph.rowListTemplate,
          ),
          childBinding: declareBinding(
            TagGraph.childBinding,
            TagGraph.rowTemplate,
          ),
          children: columnSequence(childSlot),
        ),
        header: null,
      );

      await tester.showNode(
        node,
        fixture.scope.withValues({
          TagGraph.rootsBinding: skir.DataValue.createSetValue(
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
      final fixture = TagGraph(
        graph: {
          "tag:one": ["Shared"],
          "tag:two": ["Shared"],
          "Shared": ["Leaf1", "Leaf2"],
          "Leaf1": [],
          "Leaf2": [],
        },
      );
      final node = TagGraph.node(disclosure: true);
      final ownerBinding = skir.ExpressionBindingId(value: "invocation.owner");
      PortablePresentationScope scope(
        List<String> roots, {
        String ownerPath = "first",
        String content = "initial",
      }) {
        final base = fixture.scope.withValues({
          TagGraph.rootsBinding: TagGraph.keys(roots),
        });
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

      await tester.showNode(node, scope(["tag:one", "tag:two"]));
      await tester.tap(find.text("Alpha"));
      await tester.pumpAndSettle();
      await tester.tap(find.text("Beta"));
      await tester.pumpAndSettle();
      expect(find.text("Shared"), findsNWidgets(2));
      await tester.tap(find.text("Shared").first);
      await tester.pumpAndSettle();
      expect(find.text("Leaf1"), findsOneWidget);
      expect(find.text("Leaf2"), findsOneWidget);

      await tester.showNode(node, scope(["tag:two", "tag:one"]));
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
      await tester.showNode(
        node,
        scope(["tag:two", "tag:one"], content: "edited"),
      );
      await tester.pumpAndSettle();
      expect(find.text("Leaf1"), findsNWidgets(2));
      await tester.showNode(
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
      final fixture = TagGraph(
        graph: {
          "tag:one": ["Shared", "Shared"],
          "tag:two": ["Shared"],
          "Shared": ["tag:one"],
        },
      );
      await tester.showNode(
        TagGraph.node(),
        fixture.scope.withValues({
          TagGraph.rootsBinding: TagGraph.keys([
            "tag:one",
            "tag:two",
            "tag:one",
          ]),
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
      final fixture = TagGraph(
        graph: {
          "tag:one": ["tag:two"],
          "tag:two": ["Shared"],
          "Shared": [],
        },
      );
      await tester.showNode(TagGraph.node(maximumDepth: 1), fixture.scope);
      expect(find.text("Alpha"), findsOneWidget);
      expect(find.text("Beta"), findsOneWidget);
      expect(find.text("Shared"), findsNothing);

      await tester.showNode(
        TagGraph.node(direction: skir.CollectionGraphDirection.reverse),
        fixture.scope.withValues({
          TagGraph.rootsBinding: TagGraph.keys(["Shared"]),
        }),
      );
      expect(find.text("Alpha"), findsOneWidget);
      expect(find.text("Beta"), findsOneWidget);
      expect(find.text("Shared"), findsOneWidget);

      await tester.showNode(
        TagGraph.node(),
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
      final fixture = TagGraph(
        graph: {
          "tag:one": ["tag:two", "Shared"],
          "tag:two": [],
          "Shared": [],
        },
      );
      final color = skir.PresentationColor.wrapValue(
        skir.ExpressionNode.createConditional(
          test: portableCall("value.equals", [
            inputExpression(TagGraph.rowBinding, field: "name"),
            skir.ExpressionNode.wrapLiteral(
              skir.DataValue.wrapStringValue("Alpha"),
            ),
          ]),
          then: skir.ExpressionNode.wrapLiteral(
            skir.DataValue.wrapInteger("4294901760"),
          ),
          otherwise: skir.ExpressionNode.wrapLiteral(
            skir.DataValue.wrapInteger("4278190335"),
          ),
        ),
      );
      final connector = skir.ConnectorStyle(
        stroke: skir.ConnectorStroke(color: color, width: numberLiteral(2)),
        cornerRadius: numberLiteral(8),
        startMarker: null,
        endMarker: null,
      );
      await tester.showNode(
        TagGraph.node(
          childrenLayout: skir.SequenceLayout.createHierarchy(
            unaryConnector: connector,
            trunkConnector: connector,
            branchConnector: connector,
            itemSpacing: numberLiteral(24),
            indentation: numberLiteral(16),
            leadingSpacing: numberLiteral(16),
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
      final connectors = <Color>[];
      expect(
        tester.renderObject(
          find.byType(PortablePresentationNodeRenderer).first,
        ),
        paints..everything((method, arguments) {
          if (method == #drawPath) {
            final paint = arguments[1] as Paint;
            if (paint.style == PaintingStyle.stroke && paint.strokeWidth == 2) {
              connectors.add(paint.color);
            }
          }
          return true;
        }),
      );
      expect(connectors, const [
        Color(0xffff0000),
        Color(0xff0000ff),
        Color(0xff0000ff),
      ]);
    },
  );

  testWidgets("graph rejects wrongly typed roots and ambiguous keys", (
    tester,
  ) async {
    final fixture = TagGraph();
    await tester.showNode(
      TagGraph.node(),
      fixture.scope.withValues({
        TagGraph.rootsBinding: skir.DataValue.wrapInteger("1"),
      }),
    );
    expect(
      find.text("A collection graph root has the wrong key type"),
      findsOneWidget,
    );
    final duplicate = TagGraph(projected: true, duplicateKey: true);
    await tester.showNode(TagGraph.node(), duplicate.scope);
    expect(
      find.text("The collection graph contains an ambiguous key"),
      findsOneWidget,
    );
  });

  testWidgets("projected collection uses its authored custom key", (
    tester,
  ) async {
    final fixture = TagGraph(projected: true);
    final node = skir.PresentationNode(
      nodeId: "lookup.projected",
      properties: skir.PresentationProperties.defaultInstance,
      element: skir.PresentationElement.createCollectionLookup(
        sourceId: "tags",
        key: skir.BindingRef(
          bindingId: TagGraph.lookupBinding,
          path: skir.ValuePath(segments: const []),
        ),
        found: presentationText(
          "projected.name",
          inputExpression(TagGraph.rowBinding, field: "name"),
        ),
        missing: presentationText(
          "projected.missing",
          skir.ExpressionNode.wrapLiteral(
            skir.DataValue.wrapStringValue("Missing"),
          ),
        ),
        loading: null,
      ),
      header: null,
    );

    await tester.showNode(node, fixture.scope);

    expect(find.text("Alpha"), findsOneWidget);
    expect(find.text("Missing"), findsNothing);
  });

  testWidgets("unfinished lookup key renders the missing presentation", (
    tester,
  ) async {
    final fixture = TagGraph();
    final node = skir.PresentationNode(
      nodeId: "lookup.unfinished",
      properties: skir.PresentationProperties.defaultInstance,
      element: skir.PresentationElement.createCollectionLookup(
        sourceId: "tags",
        key: skir.BindingRef(
          bindingId: TagGraph.lookupBinding,
          path: skir.ValuePath(segments: const []),
        ),
        found: presentationText(
          "unfinished.found",
          inputExpression(TagGraph.rowBinding, field: "name"),
        ),
        missing: presentationText(
          "unfinished.missing",
          skir.ExpressionNode.wrapLiteral(
            skir.DataValue.wrapStringValue("Choose a tag"),
          ),
        ),
        loading: null,
      ),
      header: null,
    );

    await tester.showNode(
      node,
      fixture.scope.withValues({
        TagGraph.lookupBinding: skir.DataValue.unfilled,
      }),
    );

    expect(find.text("Choose a tag"), findsOneWidget);
    expect(find.textContaining("wrong type"), findsNothing);
  });

  testWidgets("unfinished graph roots report unavailable input", (
    tester,
  ) async {
    final fixture = TagGraph();
    final node = skir.PresentationNode(
      nodeId: "graph.unfinished",
      properties: skir.PresentationProperties.defaultInstance,
      element: skir.PresentationElement.createCollectionGraph(
        sourceId: "tags",
        roots: skir.ExpressionNode.createInput(
          binding: TagGraph.rootsBinding,
          path: skir.ValuePath(segments: const []),
        ),
        rootSequence: columnSequence(
          presentationSlot("unfinished.root", "graph.root"),
        ),
        relationId: "next",
        direction: skir.CollectionGraphDirection.forward,
        maximumDepth: 8,
        node: presentationText(
          "unfinished.node",
          inputExpression(TagGraph.rowBinding, field: "name"),
        ),
        childrenBinding: declareBinding(
          TagGraph.childrenBinding,
          TagGraph.rowListTemplate,
        ),
        childBinding: declareBinding(
          TagGraph.childBinding,
          TagGraph.rowTemplate,
        ),
        children: columnSequence(
          presentationSlot("unfinished.child", "graph.child"),
        ),
      ),
      header: null,
    );

    await tester.showNode(
      node,
      fixture.scope.withValues({
        TagGraph.rootsBinding: skir.DataValue.unfilled,
      }),
    );

    expect(
      find.text("The collection graph roots are unavailable"),
      findsOneWidget,
    );
  });

  testWidgets("duplicate projected keys report ambiguity", (tester) async {
    final fixture = TagGraph(projected: true, duplicateKey: true);
    final node = skir.PresentationNode(
      nodeId: "lookup.duplicate",
      properties: skir.PresentationProperties.defaultInstance,
      element: skir.PresentationElement.createCollectionLookup(
        sourceId: "tags",
        key: skir.BindingRef(
          bindingId: TagGraph.lookupBinding,
          path: skir.ValuePath(segments: const []),
        ),
        found: presentationText(
          "duplicate.found",
          inputExpression(TagGraph.rowBinding, field: "name"),
        ),
        missing: presentationText(
          "duplicate.missing",
          skir.ExpressionNode.wrapLiteral(
            skir.DataValue.wrapStringValue("Missing"),
          ),
        ),
        loading: null,
      ),
      header: null,
    );

    await tester.showNode(node, fixture.scope);

    expect(find.text("The collection lookup key is ambiguous"), findsOneWidget);
  });

  testWidgets("nested material keeps a same named source provider scoped", (
    tester,
  ) async {
    final base = TagGraph();
    final original = base.scope.catalog!.snapshot;
    final record = base.document.resources.values.first;
    final type =
        completeUseOf(null, record.configuration)?.definition ??
        (throw StateError("The nested collection fixture must be complete"));
    final nestedProvider = skir.PresentationId(
      namespace: "test",
      name: "nested.collections",
    );
    final nestedDefinition = skir.PresentationCollectionDefinition(
      sourceId: "tags",
      rowBinding: declareBinding(
        TagGraph.rowBinding,
        skir.TypeTemplate.createNamed(definition: type, arguments: const []),
      ),
      key: inputExpression(TagGraph.rowBinding, field: "name"),
      selectability: skir.ExpressionNode.wrapLiteral(
        skir.DataValue.wrapBoolean(true),
      ),
      relations: const [],
      projection: skir.PresentationCollectionProjection(
        root: skir.NamedTypeTemplate(definition: type, arguments: const []),
        resourceBinding: declareBinding(
          TagGraph.resourceBinding,
          skir.TypeUse.wrapNamed(skir.resourceIdType).portableTemplate,
        ),
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
    );
    final nestedLayout = skir.PresentationNode(
      nodeId: "nested.lookup",
      properties: skir.PresentationProperties.defaultInstance,
      element: skir.PresentationElement.createCollectionLookup(
        sourceId: "tags",
        key: skir.BindingRef(
          bindingId: TagGraph.nestedLookupBinding,
          path: skir.ValuePath(segments: const []),
        ),
        found: presentationText(
          "nested.found",
          inputExpression(TagGraph.rowBinding, field: "name"),
        ),
        missing: presentationText(
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
      testCatalogSnapshot(
        generation: original.generation,
        types: original.types,
        relations: original.relations,
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
    final fixture = (
      scope: PortablePresentationScope(
        operations: testPortableOperations(),
        bindings: {
          ...base.scope.bindings,
          TagGraph.nestedLookupBinding: PortableExpressionBinding(
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

    await tester.showNode(fixture.node, fixture.scope);

    expect(find.text("Alpha"), findsOneWidget);
    expect(find.textContaining("wrong type"), findsNothing);
  });
}
