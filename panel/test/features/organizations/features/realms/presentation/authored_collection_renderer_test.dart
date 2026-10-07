import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/authoring.dart"
    as authoring;
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/binding.dart"
    as binding;
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/catalog.dart"
    as catalog;
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/expression.dart"
    as expression;
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/presentation.dart"
    as presentation;
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/type_catalog.dart"
    as types;
import "package:typewriter_panel/typewriter_panel.dart";

import "../../../../../support/test_utils.dart";

void main() {
  testWidgets("resource collection lookup binds the selected authored row", (
    tester,
  ) async {
    final fixture = _fixture();
    final node = presentation.PresentationNode(
      nodeId: "lookup",
      properties: presentation.PresentationProperties.defaultInstance,
      element: presentation.PresentationElement.createCollectionLookup(
        sourceId: "tags",
        key: binding.BindingRef(
          bindingId: _lookupBinding,
          path: types.ValuePath(segments: const []),
        ),
        found: _textNode("found", _read(_rowBinding, "name")),
        missing: _textNode(
          "missing",
          expression.ExpressionNode.wrapLiteral(
            types.DataValue.wrapStringValue("Missing"),
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
      final node = presentation.PresentationNode(
        nodeId: "graph",
        properties: presentation.PresentationProperties.defaultInstance,
        element: presentation.PresentationElement.createCollectionGraph(
          sourceId: "tags",
          roots: expression.ExpressionNode.createCollection(
            operation: types.OperationId(value: "typewriter.collection.map"),
            input: expression.ExpressionNode.createRead(
              binding: _rootsBinding,
              path: types.ValuePath(segments: const []),
            ),
            bindings: [types.ExpressionBindingId(value: "root.link")],
            arguments: const [],
            body: expression.ExpressionNode.createCall(
              operation: types.OperationId(value: "typewriter.link.target"),
              arguments: [
                expression.ExpressionNode.createRead(
                  binding: types.ExpressionBindingId(value: "root.link"),
                  path: types.ValuePath(segments: const []),
                ),
              ],
            ),
          ),
          rootSequence: _sequence(rootSlot),
          relationId: "next",
          direction: presentation.CollectionGraphDirection.forward,
          maximumDepth: 8,
          node: presentation.PresentationNode(
            nodeId: "graph.node",
            properties: presentation.PresentationProperties.defaultInstance,
            element: presentation.PresentationElement.wrapChildren(
              presentation.ChildrenElement.createColumn(
                children: [
                  presentation.AxisChild.wrapFixed(
                    _textNode("graph.name", _read(_rowBinding, "name")),
                  ),
                  presentation.AxisChild.wrapFixed(childSlot),
                ],
                layout: presentation.AxisChildrenLayout(
                  spacing: 0,
                  mainAxisAlignment: presentation.MainAxisAlignment.start,
                  crossAxisAlignment: presentation.CrossAxisAlignment.start,
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
          _rootsBinding: types.DataValue.createSetValue(
            items: [
              types.ListItem(
                id: types.ItemId(value: "selected.tag"),
                value: types.DataValue.createLink(
                  endpoint: types.EndpointId(value: "book.tags"),
                  target: types.LinkTarget(
                    resource: types.ResourceId(value: "tag:one"),
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

  testWidgets("projected collection uses its authored custom key", (
    tester,
  ) async {
    final fixture = _fixture(projected: true);
    final node = presentation.PresentationNode(
      nodeId: "lookup.projected",
      properties: presentation.PresentationProperties.defaultInstance,
      element: presentation.PresentationElement.createCollectionLookup(
        sourceId: "tags",
        key: binding.BindingRef(
          bindingId: _lookupBinding,
          path: types.ValuePath(segments: const []),
        ),
        found: _textNode("projected.name", _read(_rowBinding, "name")),
        missing: _textNode(
          "projected.missing",
          expression.ExpressionNode.wrapLiteral(
            types.DataValue.wrapStringValue("Missing"),
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
    final node = presentation.PresentationNode(
      nodeId: "lookup.unfinished",
      properties: presentation.PresentationProperties.defaultInstance,
      element: presentation.PresentationElement.createCollectionLookup(
        sourceId: "tags",
        key: binding.BindingRef(
          bindingId: _lookupBinding,
          path: types.ValuePath(segments: const []),
        ),
        found: _textNode("unfinished.found", _read(_rowBinding, "name")),
        missing: _textNode(
          "unfinished.missing",
          expression.ExpressionNode.wrapLiteral(
            types.DataValue.wrapStringValue("Choose a tag"),
          ),
        ),
        loading: null,
      ),
      header: null,
    );

    await _pump(
      tester,
      node,
      fixture.scope.withValues({_lookupBinding: types.DataValue.unfilled}),
    );

    expect(find.text("Choose a tag"), findsOneWidget);
    expect(find.textContaining("wrong type"), findsNothing);
  });

  testWidgets("unfinished graph roots report unavailable input", (
    tester,
  ) async {
    final fixture = _fixture();
    final node = presentation.PresentationNode(
      nodeId: "graph.unfinished",
      properties: presentation.PresentationProperties.defaultInstance,
      element: presentation.PresentationElement.createCollectionGraph(
        sourceId: "tags",
        roots: expression.ExpressionNode.createRead(
          binding: _rootsBinding,
          path: types.ValuePath(segments: const []),
        ),
        rootSequence: _sequence(_slotNode("unfinished.root", "graph.root")),
        relationId: "next",
        direction: presentation.CollectionGraphDirection.forward,
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
      fixture.scope.withValues({_rootsBinding: types.DataValue.unfilled}),
    );

    expect(
      find.text("The collection graph roots are unavailable"),
      findsOneWidget,
    );
  });

  testWidgets("duplicate projected keys report ambiguity", (tester) async {
    final fixture = _fixture(projected: true, duplicateKey: true);
    final node = presentation.PresentationNode(
      nodeId: "lookup.duplicate",
      properties: presentation.PresentationProperties.defaultInstance,
      element: presentation.PresentationElement.createCollectionLookup(
        sourceId: "tags",
        key: binding.BindingRef(
          bindingId: _lookupBinding,
          path: types.ValuePath(segments: const []),
        ),
        found: _textNode("duplicate.found", _read(_rowBinding, "name")),
        missing: _textNode(
          "duplicate.missing",
          expression.ExpressionNode.wrapLiteral(
            types.DataValue.wrapStringValue("Missing"),
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

({PortablePresentationScope scope, presentation.PresentationNode node})
_nestedMaterialFixture() {
  final base = _fixture();
  final original = base.scope.catalog!.snapshot;
  final record = base.scope.authoring!.resources.values.first;
  final type = switch (record.configuration) {
    types.TypeSelection_completeWrapper(:final value) => value.definition,
    _ => throw StateError("The nested collection fixture must be complete"),
  };
  final nestedProvider = types.PresentationId(
    namespace: "test",
    name: "nested.collections",
  );
  final nestedDefinition = presentation.PresentationCollectionDefinition(
    sourceId: "tags",
    rowType: types.TypeTemplate.createNamed(
      definition: type,
      arguments: const [],
    ),
    rowBindingId: _rowBinding,
    key: _read(_rowBinding, "name"),
    selectability: expression.ExpressionNode.wrapLiteral(
      types.DataValue.wrapBoolean(true),
    ),
    relations: const [],
    projection: presentation.PresentationCollectionProjection(
      root: types.NamedTypeTemplate(definition: type, arguments: const []),
      resourceBindingId: _resourceBinding,
      fields: [
        presentation.PresentationCollectionProjectionField(
          target: types.ValuePath(
            segments: [types.PathSegment.createField(name: "name")],
          ),
          source:
              presentation.PresentationCollectionProjectionValue.createContent(
                segments: [types.PathSegment.createField(name: "name")],
              ),
        ),
      ],
    ),
    resources: null,
  );
  final nestedLayout = presentation.PresentationNode(
    nodeId: "nested.lookup",
    properties: presentation.PresentationProperties.defaultInstance,
    element: presentation.PresentationElement.createCollectionLookup(
      sourceId: "tags",
      key: binding.BindingRef(
        bindingId: _nestedLookupBinding,
        path: types.ValuePath(segments: const []),
      ),
      found: _textNode("nested.found", _read(_rowBinding, "name")),
      missing: _textNode(
        "nested.missing",
        expression.ExpressionNode.wrapLiteral(
          types.DataValue.wrapStringValue("Missing"),
        ),
      ),
      loading: null,
    ),
    header: null,
  );
  final nestedMaterial = catalog.PresentationMaterial(
    provider: nestedProvider,
    target: catalog.PresentationTarget.createNamed(
      definition: type,
      arguments: const [],
    ),
    role: catalog.PresentationRole.inspector,
    layout: nestedLayout,
    dependencies: presentation.PresentationDependencies(
      types: const [],
      presentations: const [],
      conversions: const [],
      capabilities: const [],
      collections: [nestedDefinition],
    ),
    subject: types.TypeTemplate.createNamed(
      definition: type,
      arguments: const [],
    ),
  );
  final checked = CheckedEditorCatalog(
    catalog.EditorCatalogWireSnapshot(
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
      initialization: original.initialization,
      endpointBindings: original.endpointBindings,
      capabilities: original.capabilities,
      recommendations: original.recommendations,
      roleFallbacks: original.roleFallbacks,
    ),
  );
  final resource = base.scope.authoring!.resources.keys.first;
  return (
    scope: PortablePresentationScope(
      bindings: {
        ...base.scope.bindings,
        _nestedLookupBinding: PortableExpressionBinding(
          value: types.DataValue.wrapStringValue("Alpha"),
        ),
      },
      budget: base.scope.budget,
      setBinding: base.scope.setBinding,
      authoring: base.scope.authoring,
      catalog: checked,
      resource: resource,
      material: base.material,
    ),
    node: presentation.PresentationNode(
      nodeId: "outer.invocation",
      properties: presentation.PresentationProperties.defaultInstance,
      element: presentation.PresentationElement.createInvocation(
        presentationId: nestedProvider,
        arguments: const [],
      ),
      header: null,
    ),
  );
}

({PortablePresentationScope scope, catalog.PresentationMaterial material})
_fixture({
  bool cycle = false,
  bool projected = false,
  bool duplicateKey = false,
}) {
  final type = _definition("Tag");
  final list = _definition("List");
  final listParameter = types.ParameterKey(owner: list, index: 0);
  final listOfText = types.NamedTypeUse(
    definition: list,
    arguments: [types.TypeUse.wrapScalar(types.ScalarKind.text)],
  );
  final listOfTextTemplate = types.TypeTemplate.createNamed(
    definition: list,
    arguments: [types.TypeTemplate.wrapScalar(types.ScalarKind.text)],
  );
  final generation = types.CatalogGeneration(value: "catalog:collections");
  final published = catalog.PublishedType(
    display: null,
    definition: types.TypeDefinition(
      id: type,
      parameters: const [],
      representation: types.RepresentationTemplate.createRecord(
        fields: [
          _field(
            type,
            "name",
            types.TypeTemplate.wrapScalar(types.ScalarKind.text),
          ),
          _field(type, "next", listOfTextTemplate),
        ],
        abstract_: false,
      ),
      parents: const [],
    ),
    status: catalog.DeclarationStatus.ready,
    effectiveFields: [
      _effective(
        type,
        "name",
        types.TypeTemplate.wrapScalar(types.ScalarKind.text),
      ),
      _effective(type, "next", listOfTextTemplate),
    ],
    ancestorTemplates: const [],
  );
  final checked = CheckedEditorCatalog(
    catalog.EditorCatalogWireSnapshot(
      generation: generation,
      types: [
        published,
        catalog.PublishedType(
          display: null,
          definition: types.TypeDefinition(
            id: list,
            parameters: [
              types.TypeParameter(
                key: listParameter,
                name: "T",
                bounds: const [],
              ),
            ],
            representation: types.RepresentationTemplate.createSequence(
              item: types.TypeTemplate.wrapParameter(listParameter),
              kind: types.CollectionKind.list,
            ),
            parents: const [],
          ),
          status: catalog.DeclarationStatus.ready,
          effectiveFields: const [],
          ancestorTemplates: const [],
        ),
      ],
      relations: const [],
      resourceDefinitions: [
        catalog.AuthoringResourceDefinition(
          id: catalog.ResourceDefinitionId(value: "test.tag"),
          root: type,
          navigationHandler: "",
        ),
      ],
      presentations: const [],
      presentationMaterials: const [],
      configuration: const [],
      diagnostics: const [],
      initialization: const [],
      endpointBindings: const [],
      capabilities: const [],
      recommendations: const [],
      roleFallbacks: const [],
    ),
  );
  final one = types.ResourceId(value: "tag:one");
  final two = types.ResourceId(value: "tag:two");
  final snapshot = authoring.AuthoringState(
    generation: generation,
    resources: [
      _resource(one, type, listOfText, "Alpha", [two]),
      _resource(
        two,
        type,
        listOfText,
        duplicateKey ? "Alpha" : "Beta",
        cycle ? [one] : const [],
      ),
    ],
    links: const [],
    findings: const [],
  );
  final draft = AuthoredDraft.fromState(snapshot, catalog: checked);
  final definition = presentation.PresentationCollectionDefinition(
    sourceId: "tags",
    rowType: types.TypeTemplate.createNamed(
      definition: type,
      arguments: const [],
    ),
    rowBindingId: _rowBinding,
    key: projected
        ? _read(_rowBinding, "name")
        : expression.ExpressionNode.createRead(
            binding: _resourceBinding,
            path: types.ValuePath(segments: const []),
          ),
    selectability: expression.ExpressionNode.wrapLiteral(
      types.DataValue.wrapBoolean(true),
    ),
    relations: [
      presentation.PresentationCollectionRelationDefinition(
        relationId: "next",
        targets: _read(_rowBinding, "next"),
      ),
    ],
    projection: projected
        ? presentation.PresentationCollectionProjection(
            root: types.NamedTypeTemplate(
              definition: type,
              arguments: const [],
            ),
            resourceBindingId: _resourceBinding,
            fields: [
              presentation.PresentationCollectionProjectionField(
                target: types.ValuePath(
                  segments: [types.PathSegment.createField(name: "name")],
                ),
                source:
                    presentation
                        .PresentationCollectionProjectionValue.createContent(
                      segments: [types.PathSegment.createField(name: "name")],
                    ),
              ),
            ],
          )
        : null,
    resources: projected
        ? null
        : presentation.PresentationResourceCollection(
            root: type,
            resourceBindingId: _resourceBinding,
            appearance: null,
          ),
  );
  final provider = types.PresentationId(namespace: "test", name: "collections");
  final target = catalog.PresentationTarget.createNamed(
    definition: type,
    arguments: const [],
  );
  final material = catalog.PresentationMaterial(
    provider: provider,
    target: target,
    role: catalog.PresentationRole.inspector,
    layout: _slotNode("material", "unused"),
    dependencies: presentation.PresentationDependencies(
      types: const [],
      presentations: const [],
      conversions: const [],
      capabilities: const [],
      collections: [definition],
    ),
    subject: types.TypeTemplate.createNamed(
      definition: type,
      arguments: const [],
    ),
  );
  return (
    material: material,
    scope: PortablePresentationScope(
      bindings: {
        _lookupBinding: PortableExpressionBinding(
          value: types.DataValue.wrapStringValue(
            projected ? "Alpha" : one.value,
          ),
        ),
        _rootsBinding: PortableExpressionBinding(
          value: _values([one], listOfText),
        ),
      },
      budget: expression.EvaluationBudget(
        maxSteps: 1000,
        maxCollectionItems: 1000,
      ),
      setBinding: (_, _) {},
      authoring: AuthoredDraftAuthoringDocument(draft),
      catalog: checked,
      material: material,
    ),
  );
}

authoring.AuthoringResource _resource(
  types.ResourceId id,
  types.TypeDefinitionId type,
  types.NamedTypeUse listType,
  String name,
  List<types.ResourceId> next,
) => authoring.AuthoringResource(
  id: id,
  definition: catalog.ResourceDefinitionId(value: "test.tag"),
  content: types.AuthoringRecord(
    configuration: types.TypeSelection.createComplete(
      definition: type,
      arguments: const [],
    ),
    fields: [
      types.FieldValue(
        name: "name",
        value: types.DataValue.wrapStringValue(name),
      ),
      types.FieldValue(name: "next", value: _values(next, listType)),
    ],
  ),
);

types.DataValue _values(
  List<types.ResourceId> values,
  types.NamedTypeUse listType,
) => types.DataValue.createNamed(
  actualType: listType,
  payload: types.DataValue.createListValue(
    items: [
      for (final indexed in values.indexed)
        types.ListItem(
          id: types.ItemId(value: "item:${indexed.$1}"),
          value: types.DataValue.wrapStringValue(indexed.$2.value),
        ),
    ],
  ),
);

types.FieldDeclaration _field(
  types.TypeDefinitionId type,
  String name,
  types.TypeTemplate fieldType,
) => types.FieldDeclaration(
  owner: types.FieldOwner(definition: type, name: name),
  type: fieldType,
  overrides: const [],
  hasConstructorDefault: false,
);

catalog.EffectiveFieldTemplate _effective(
  types.TypeDefinitionId type,
  String name,
  types.TypeTemplate fieldType,
) => catalog.EffectiveFieldTemplate(
  key: name,
  owner: types.FieldOwner(definition: type, name: name),
  type: fieldType,
  rules: const [],
);

expression.ExpressionNode _read(types.ExpressionBindingId id, String field) =>
    expression.ExpressionNode.createRead(
      binding: id,
      path: types.ValuePath(
        segments: [types.PathSegment.createField(name: field)],
      ),
    );

presentation.PresentationNode _textNode(
  String id,
  expression.ExpressionNode value,
) => presentation.PresentationNode(
  nodeId: id,
  properties: presentation.PresentationProperties.defaultInstance,
  element: presentation.PresentationElement.createText(
    value: value,
    color: null,
    fontSize: null,
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
    paragraph: presentation.TextParagraph.defaultInstance,
  ),
  header: null,
);

presentation.PresentationNode _slotNode(String id, String slot) =>
    presentation.PresentationNode(
      nodeId: id,
      properties: presentation.PresentationProperties.defaultInstance,
      element: presentation.PresentationElement.createSlot(slotId: slot),
      header: null,
    );

presentation.SequencePresentation _sequence(
  presentation.PresentationNode item,
) => presentation.SequencePresentation(
  item: item,
  empty: null,
  separator: null,
  layout: presentation.SequenceLayout.wrapChildren(
    presentation.ChildrenLayout.createColumn(
      spacing: 0,
      mainAxisAlignment: presentation.MainAxisAlignment.start,
      crossAxisAlignment: presentation.CrossAxisAlignment.start,
    ),
  ),
);

Future<void> _pump(
  WidgetTester tester,
  presentation.PresentationNode node,
  PortablePresentationScope scope,
) => tester.pumpTestApp(
  child: Builder(
    builder: (_) => Scaffold(
      body: PortablePresentationNodeRenderer(node: node, scope: scope),
    ),
  ),
);

types.TypeDefinitionId _definition(String name) => types.TypeDefinitionId(
  typeId: types.TypeId.wrapQualified(
    types.QualifiedTypeId(namespace: "test", name: name),
  ),
  revision: 1,
);

final _rowBinding = types.ExpressionBindingId(value: "collection.row");
final _resourceBinding = types.ExpressionBindingId(
  value: "collection.resource",
);
final _lookupBinding = types.ExpressionBindingId(value: "lookup.key");
final _nestedLookupBinding = types.ExpressionBindingId(
  value: "lookup.nested.key",
);
final _rootsBinding = types.ExpressionBindingId(value: "graph.roots");
final _childrenBinding = types.ExpressionBindingId(value: "graph.children");
final _childBinding = types.ExpressionBindingId(value: "graph.child");
