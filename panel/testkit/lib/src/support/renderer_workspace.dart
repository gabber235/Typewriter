import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/src/authoring/document_builder.dart";
import "package:typewriter_testkit/src/doubles/realm.dart";
import "package:typewriter_testkit/src/drivers/finders.dart";
import "package:typewriter_testkit/src/drivers/semantics.dart";
import "package:typewriter_testkit/src/shared/editors/presentation/resource_display_fixture.dart";
import "package:typewriter_testkit/src/shared/editors/presentation_builders.dart";
import "package:typewriter_testkit/src/support/portable_operations.dart";
import "package:typewriter_testkit/src/shared/editors/catalog_fixture.dart";

/// An authored document held by a [FakeRealm] that holds every save, edited
/// through a [RealmEditing] binding on [resource]; everything lives until
/// the test ends.
final class RendererWorkspace {
  RendererWorkspace({
    required CheckedEditorCatalog catalog,
    required Map<skir.ResourceId, skir.AuthoringRecord> resources,
    List<skir.LinkProjection> links = const [],
  }) {
    final document = AuthoringDocument(
      catalog: catalog,
      entries: {
        for (final entry in resources.entries)
          entry.key: skir.AuthoringResource(
            id: entry.key,
            content: entry.value,
          ),
      },
      links: links,
    );
    realm = FakeRealm(
      scope: AuthoringScope(
        organizationId: skir.recordId("organization:renderer"),
        realmId: skir.recordId("realm_instance:renderer"),
      ),
      name: "Renderer",
      document: document,
    )..holdSaves = true;
    final submissions = ScopedWorkSession();
    addTearDown(submissions.dispose);
    workspace = RealmEditing(
      persistence: realm.persistence,
      submissions: submissions,
      initial: document,
    );
    binding = workspace.attach(
      RendererWorkspace.resource,
      policy: EditorCommitPolicy.applyResource,
    );
    addTearDown(binding.detach);
    addTearDown(workspace.dispose);
    addTearDown(realm.close);
  }

  /// The resource the workspace edits.
  static final resource = skir.ResourceId(value: "resource:test");

  /// The binding presentations read the resource through.
  static final bindingId = skir.ExpressionBindingId(value: "value");

  /// The link item whose target the catalog knows.
  static final knownLinkItem = skir.ItemId(value: "link:known");

  /// The link item still being authored.
  static final unfinishedLinkItem = skir.ItemId(value: "link:unfinished");

  /// The Realm that holds every save.
  late final FakeRealm realm;

  /// The editing of the document.
  late final RealmEditing workspace;

  /// The editing binding on [resource].
  late final RealmEditingBinding binding;

  /// Saves the draft and returns the edit the Realm received.
  Future<skir.PreparedEdit> submit(WidgetTester tester) async {
    unawaited(binding.save());
    await tester.pump();
    return realm.saves.single.edit;
  }

  /// A workspace host on [resource] showing [material] or no material, that
  /// prepares values through [prepareValue] when given.
  AuthoredPresentationHost host({
    skir.PresentationMaterial? material,
    Future<skir.PreparedValue> Function(skir.ValuePreparationRequest)?
    prepareValue,
  }) {
    final host = AuthoredPresentationHost(
      resource: resource,
      source: workspace.document,
      material: material ?? skir.PresentationMaterial.defaultInstance,
      role: skir.PresentationRole.workspace,
      budget: skir.EvaluationBudget(maxSteps: 100, maxCollectionItems: 100),
      capabilities: const PortablePresentationCapabilities(),
      prepareValue: prepareValue,
      edit: binding,
    );
    addTearDown(host.dispose);
    return host;
  }

  /// A scope whose [bindingId] holds a record with [field] set to [value]
  /// at [resource], over [host].
  PortablePresentationScope _scope(String field, skir.DataValue value) =>
      PortablePresentationScope(
        operations: testPortableOperations(),
        bindings: {
          bindingId: PortableExpressionBinding(
            value: skir.DataValue.createRecord(
              fields: [skir.FieldValue(name: field, value: value)],
            ),
            location: skir.ValueLocation(
              resource: resource,
              path: skir.ValuePath(segments: const []),
            ),
          ),
        },
        budget: skir.EvaluationBudget(maxSteps: 100, maxCollectionItems: 100),
        catalog: workspace.document.catalog,
        queries: PortableExpressionQueries(
          catalog: workspace.document.catalog,
          authored: workspace.document,
        ),
        host: host(),
      );
}

/// A list input over the text list `items` of a [RendererWorkspace], with
/// [label], [description], [prefix], [appearance], [content] and the input
/// defaults [inputDefaults] when given; [allowAdd] offers adding rows.
({Widget widget, RendererWorkspace document}) authoredListInput({
  required skir.DataValue value,
  required bool allowAdd,
  String? label,
  String? description,
  skir.CollectionAppearance? appearance,
  skir.CollectionContent? content,
  skir.InputAppearance? inputDefaults,
  skir.PresentationNode? prefix,
}) {
  final document = RendererWorkspace(
    catalog: _collectionCatalog(),
    resources: {RendererWorkspace.resource: _collectionRecord("items", value)},
  );
  final reference = skir.BindingRef(
    bindingId: RendererWorkspace.bindingId,
    path: skir.ValuePath(
      segments: [skir.PathSegment.createField(name: "items")],
    ),
  );
  final sourceScope = document._scope("items", value);
  return (
    document: document,
    widget: Material(
      child: PortablePresentationNodeRenderer(
        node: presentationNode(
          "collection",
          skir.PresentationElement.wrapListInput(
            skir.ListControl(
              control: skir.BoundControl(
                binding: reference,
                label: label == null
                    ? null
                    : skir.ExpressionNode.wrapLiteral(
                        skir.DataValue.wrapStringValue(label),
                      ),
                description: description == null
                    ? null
                    : skir.ExpressionNode.wrapLiteral(
                        skir.DataValue.wrapStringValue(description),
                      ),
                prefix: prefix,
                semanticLabel: null,
              ),
              itemPresentation: null,
              allowAdd: allowAdd,
              allowRemove: true,
              allowReorder: true,
              itemBinding: declareNamedBinding("item", textTemplate),
              indexBinding: declareNamedBinding("index", int32Template),
              appearance: appearance,
              content: content,
            ),
          ),
        ),
        scope: inputDefaults == null
            ? sourceScope
            : sourceScope.withAppearance(inputDefaults),
      ),
    ),
  );
}

/// A map input over the empty text map `values` of a [RendererWorkspace],
/// labeled [label] when given.
({Widget widget, RendererWorkspace document}) authoredMapInput({
  String? label,
}) {
  final document = RendererWorkspace(
    catalog: _collectionCatalog(),
    resources: {
      RendererWorkspace.resource: _collectionRecord(
        "values",
        skir.DataValue.unfilled,
      ),
    },
  );
  final reference = skir.BindingRef(
    bindingId: RendererWorkspace.bindingId,
    path: skir.ValuePath(
      segments: [skir.PathSegment.createField(name: "values")],
    ),
  );
  return (
    document: document,
    widget: Material(
      child: PortablePresentationNodeRenderer(
        node: presentationNode(
          "map",
          skir.PresentationElement.wrapMapInput(
            skir.MapControl(
              control: skir.BoundControl(
                binding: reference,
                label: label == null
                    ? null
                    : skir.ExpressionNode.wrapLiteral(
                        skir.DataValue.wrapStringValue(label),
                      ),
                description: null,
                prefix: null,
                semanticLabel: null,
              ),
              keyPresentation: null,
              valuePresentation: null,
              allowAdd: true,
              allowRemove: true,
              keyBinding: declareNamedBinding("key", textTemplate),
              valueBinding: declareNamedBinding("map_value", textTemplate),
              appearance: null,
              content: null,
            ),
          ),
        ),
        scope: document._scope("values", skir.DataValue.unfilled),
      ),
    ),
  );
}

/// A collection of links from the node `resource:test` to the nodes
/// [RendererWorkspace.knownLinkItem] targets, shown through a configured
/// reference appearance; the options shape partial links, a missing target,
/// a direct collection, an adaptive appearance and the input styling.
({
  Widget widget,
  RendererWorkspace document,
  CheckedEditorCatalog catalog,
  skir.ResourceId target,
  skir.ResourceId secondTarget,
})
authoredLinkCollection({
  bool withPartialLinks = false,
  bool missingTarget = false,
  bool directCollection = false,
  bool adaptiveAppearance = false,
  String? label,
  skir.CollectionAppearance? collectionAppearance,
  skir.CollectionContent? content,
  skir.InputAppearance? inputAppearance,
  skir.InputContent? inputContent,
  skir.PopupAppearance? popup,
}) {
  final rootDefinition = skir.TypeDefinitionId(
    typeId: skir.TypeId.createQualified(namespace: "test", name: "Node"),
    revision: 1,
  );
  final setDefinition = skir.TypeDefinitionId(
    typeId: skir.TypeId.createQualified(namespace: "test", name: "Links"),
    revision: 1,
  );
  final linkDefinition = skir.TypeDefinitionId(
    typeId: skir.TypeId.createQualified(namespace: "test", name: "NodeLink"),
    revision: 1,
  );
  final sourceEndpoint = skir.EndpointId(value: "test.source");
  final targetEndpoint = skir.EndpointId(value: "test.target");
  final rootUse = skir.NamedTypeUse(
    definition: rootDefinition,
    arguments: const [],
  );
  final setUse = skir.NamedTypeUse(
    definition: setDefinition,
    arguments: const [],
  );
  final linksOwner = skir.FieldOwner(definition: rootDefinition, name: "links");
  final nameOwner = skir.FieldOwner(definition: rootDefinition, name: "name");
  final rootTemplate = skir.TypeTemplate.createNamed(
    definition: rootDefinition,
    arguments: const [],
  );
  final linkTemplate = skir.TypeTemplate.createNamed(
    definition: linkDefinition,
    arguments: const [],
  );
  final setTemplate = skir.TypeTemplate.createNamed(
    definition: setDefinition,
    arguments: const [],
  );
  final appearanceId = skir.PresentationId(
    namespace: "test",
    name: "node.reference.option",
  );
  final appearanceTarget = skir.PresentationTarget.createNamed(
    definition: rootDefinition,
    arguments: const [],
  );
  final appearanceText = presentationNode(
    "node.reference.name",
    textElement(
      skir.ExpressionNode.createInput(
        binding: configuredValueBindingId,
        path: skir.ValuePath(
          segments: [skir.PathSegment.createField(name: "name")],
        ),
      ),
    ),
  );
  final appearanceIcon = presentationNode(
    "node.reference.icon",
    skir.PresentationElement.createIcon(
      name: skir.ExpressionNode.wrapLiteral(
        skir.DataValue.wrapStringValue(
          '<svg xmlns="http://www.w3.org/2000/svg" '
          'viewBox="0 0 24 24"><path d="M4 4h16v16H4z"/></svg>',
        ),
      ),
      semanticLabel: skir.ExpressionNode.wrapLiteral(
        skir.DataValue.wrapStringValue("Node"),
      ),
      color: null,
      size: null,
    ),
  );
  final coloredIcon = coloredIconTile("node.reference.icon", appearanceIcon);
  final appearanceCard = presentationNode(
    "node.reference.card",
    skir.PresentationElement.createAdaptiveLeading(
      leading: coloredIcon,
      center: appearanceText,
      suffix: null,
      padding: skir.PresentationInsets.wrapAll(8),
      compactPadding: skir.PresentationInsets.wrapAll(4),
      gap: 12,
      minimumCenterWidth: 80,
    ),
  );
  final appearanceLayout = presentationNode(
    "node.reference.root",
    skir.PresentationElement.wrapChildren(
      skir.ChildrenElement.createColumn(
        children: [skir.AxisChild.wrapFixed(appearanceCard)],
        layout: skir.AxisChildrenLayout(
          clipOverflow: false,

          spacing: 0,
          mainAxisAlignment: skir.MainAxisAlignment.start,
          crossAxisAlignment: skir.CrossAxisAlignment.start,
        ),
      ),
    ),
  );
  final collectionResourceBinding = skir.ExpressionBindingId(value: "resource");
  final collectionRowBinding = skir.ExpressionBindingId(value: "row");
  final collectionDefinition = skir.PresentationCollectionDefinition(
    sourceId: "nodes",
    rowBinding: declareBinding(collectionRowBinding, rootTemplate),
    key: skir.ExpressionNode.createInput(
      binding: collectionResourceBinding,
      path: skir.ValuePath(segments: const []),
    ),
    selectability: skir.ExpressionNode.wrapLiteral(
      skir.DataValue.wrapBoolean(true),
    ),
    relations: const [],
    projection: skir.PresentationCollectionProjection(
      root: skir.NamedTypeTemplate(
        definition: rootDefinition,
        arguments: const [],
      ),
      resourceBinding: declareBinding(
        collectionResourceBinding,
        skir.TypeUse.wrapNamed(skir.resourceIdType).portableTemplate,
      ),
      fields: const [],
    ),
  );
  final collectionMaterial = skir.PresentationMaterial(
    inheritableNodes: const [],

    provider: skir.PresentationId(namespace: "test", name: "link.collection"),
    target: appearanceTarget,
    role: skir.PresentationRole.inspector,
    layout: _compactCard,
    dependencies: skir.PresentationDependencies(
      contextInputs: const [],

      types: const [],
      presentations: const [],
      conversions: const [],
      capabilities: const [],
      collections: [collectionDefinition],
    ),
    subject: rootTemplate,
  );
  final checked = CheckedEditorCatalog(
    testCatalogSnapshot(
      resourceDisplays: [nameResourceDisplay(rootTemplate)],
      generation: skir.CatalogGeneration(value: "catalog:links"),
      types: [
        publishedType(
          rootDefinition,
          representation: skir.RepresentationTemplate.createRecord(
            fields: [
              skir.FieldDeclaration(
                owner: linksOwner,
                type: setTemplate,
                overrides: const [],
                hasConstructorDefault: false,
              ),
              skir.FieldDeclaration(
                owner: nameOwner,
                type: skir.TypeTemplate.wrapScalar(skir.ScalarKind.text),
                overrides: const [],
                hasConstructorDefault: false,
              ),
            ],
            form: skir.RecordForm.concrete,
          ),
          fields: [
            skir.EffectiveFieldTemplate(
              key: "links",
              owner: linksOwner,
              type: setTemplate,
              rules: const [],
            ),
            skir.EffectiveFieldTemplate(
              key: "name",
              owner: nameOwner,
              type: skir.TypeTemplate.wrapScalar(skir.ScalarKind.text),
              rules: const [],
            ),
          ],
        ),
        publishedType(
          setDefinition,
          representation: skir.RepresentationTemplate.createSequence(
            item: linkTemplate,
            kind: skir.CollectionKind.set_,
          ),
        ),
        publishedType(
          linkDefinition,
          representation: skir.RepresentationTemplate.createLink(
            endpoint: sourceEndpoint,
            target: rootTemplate,
          ),
        ),
      ],
      relations: [
        skir.RelationContract(
          id: skir.RelationId(value: "test.links"),
          first: skir.EndpointDefinition(
            id: sourceEndpoint,
            slot: skir.EndpointSlot.first,
            resource: skir.NamedTypeTemplate(
              definition: rootDefinition,
              arguments: const [],
            ),
            cardinality: skir.EndpointCardinality.many,
            onDelete: skir.RelationDeletePolicy.clear,
          ),
          second: skir.EndpointDefinition(
            id: targetEndpoint,
            slot: skir.EndpointSlot.second,
            resource: skir.NamedTypeTemplate(
              definition: rootDefinition,
              arguments: const [],
            ),
            cardinality: skir.EndpointCardinality.many,
            onDelete: skir.RelationDeletePolicy.clear,
          ),
          families: const [],
        ),
      ],
      presentations: adaptiveAppearance
          ? [
              skir.PresentationDescriptor(
                id: appearanceId,
                owner: skir.DeclarationOwner.defaultInstance,
                target: appearanceTarget,
                roles: [skir.PresentationRole.referencePickerResult],
                priority: 0,
              ),
            ]
          : const [],
      presentationMaterials: adaptiveAppearance
          ? [
              skir.PresentationMaterial(
                inheritableNodes: const [],

                provider: appearanceId,
                target: appearanceTarget,
                role: skir.PresentationRole.referencePickerResult,
                layout: appearanceLayout,
                dependencies: skir.PresentationDependencies.defaultInstance,
                subject: rootTemplate,
              ),
            ]
          : const [],
      endpointBindings: [
        skir.EndpointBindingTemplate(
          endpoint: sourceEndpoint,
          containingResource: skir.NamedTypeTemplate(
            definition: rootDefinition,
            arguments: const [],
          ),
          valueOwner: linkDefinition,
          relativePath: skir.RelativeFieldPattern(
            segments: [
              skir.FieldPatternSegment.createField(name: "links"),
              skir.FieldPatternSegment.items,
            ],
          ),
          target: rootTemplate,
          containsCollection: true,
        ),
      ],
    ),
  );
  final target = skir.ResourceId(value: "resource:target");
  final secondTarget = skir.ResourceId(value: "resource:second-target");
  final items = withPartialLinks
      ? [
          skir.ListItem(
            id: RendererWorkspace.knownLinkItem,
            value: skir.DataValue.createLink(
              endpoint: sourceEndpoint,
              target: skir.LinkTarget(resource: target, opposite: null),
            ),
          ),
          skir.ListItem(
            id: RendererWorkspace.unfinishedLinkItem,
            value: skir.DataValue.unfilled,
          ),
        ]
      : const <skir.ListItem>[];
  final sourceRecord = skir.AuthoringRecord(
    types: const [],
    configuration: skir.TypeSelection.wrapComplete(rootUse),
    fields: [
      skir.FieldValue(
        name: "links",
        value: skir.DataValue.createNamed(
          actualType: setUse,
          payload: skir.DataValue.createSetValue(items: items),
        ),
      ),
    ],
  );
  skir.AuthoringRecord targetRecord(String name) => skir.AuthoringRecord(
    types: const [],
    configuration: skir.TypeSelection.wrapComplete(rootUse),
    fields: [
      skir.FieldValue(
        name: "name",
        value: skir.DataValue.wrapStringValue(name),
      ),
      skir.FieldValue(
        name: "links",
        value: skir.DataValue.createNamed(
          actualType: setUse,
          payload: skir.DataValue.createSetValue(items: const []),
        ),
      ),
    ],
  );
  final document = RendererWorkspace(
    catalog: checked,
    resources: {
      RendererWorkspace.resource: sourceRecord,
      if (!missingTarget) target: targetRecord("Target Alpha"),
      secondTarget: targetRecord("Target Beta"),
    },
  );
  final rootBinding = skir.ExpressionBindingId(value: "root");
  final itemBinding = skir.ExpressionBindingId(value: "item");
  final collectionReference = skir.BindingRef(
    bindingId: rootBinding,
    path: skir.ValuePath(
      segments: [skir.PathSegment.createField(name: "links")],
    ),
  );
  final host = document.host(
    material: adaptiveAppearance ? collectionMaterial : null,
  );
  return (
    document: document,
    catalog: checked,
    target: target,
    secondTarget: secondTarget,
    widget: Material(
      child: PortablePresentationNodeRenderer(
        node: directCollection
            ? presentationNode(
                "links.direct",
                skir.PresentationElement.wrapLinkInput(
                  skir.LinkControl(
                    control: skir.BoundControl(
                      binding: collectionReference,
                      label: label == null
                          ? null
                          : skir.ExpressionNode.wrapLiteral(
                              skir.DataValue.wrapStringValue(label),
                            ),
                      description: null,
                      prefix: null,
                      semanticLabel: null,
                    ),
                    allowReorder: true,
                    candidatePolicy: null,
                    rejectionDisplay: skir.LinkRejectionDisplay.disabled,
                    sourceId: null,
                    appearance: null,
                    content: content,
                    inputAppearance: inputAppearance,
                    inputContent: inputContent,
                    popup: popup,
                  ),
                ),
              )
            : presentationNode(
                "links",
                skir.PresentationElement.wrapSetInput(
                  skir.SetControl(
                    control: presentationControl(collectionReference),
                    itemPresentation: presentationNode(
                      "link.item",
                      skir.PresentationElement.wrapLinkInput(
                        skir.LinkControl(
                          control: presentationControl(
                            skir.BindingRef(
                              bindingId: itemBinding,
                              path: skir.ValuePath(segments: const []),
                            ),
                          ),
                          allowReorder: false,
                          candidatePolicy: null,
                          rejectionDisplay: skir.LinkRejectionDisplay.disabled,
                          sourceId: adaptiveAppearance ? "nodes" : null,
                          appearance: null,
                          content: content,
                          inputAppearance: inputAppearance,
                          inputContent: inputContent,
                          popup: popup,
                        ),
                      ),
                    ),
                    allowAdd: true,
                    allowRemove: true,
                    itemBinding: declareBinding(itemBinding, linkTemplate),
                    appearance: collectionAppearance,
                    content: null,
                  ),
                ),
              ),
        scope: PortablePresentationScope(
          operations: testPortableOperations(),
          bindings: {
            rootBinding: PortableExpressionBinding(
              value: skir.DataValue.createRecord(fields: sourceRecord.fields),
              location: skir.ValueLocation(
                resource: RendererWorkspace.resource,
                path: skir.ValuePath(segments: const []),
              ),
            ),
          },
          budget: skir.EvaluationBudget(maxSteps: 100, maxCollectionItems: 100),
          catalog: checked,
          queries: host.document.queries,
          resourceDiagnostics: host.document.resourceDiagnostics,
          material: adaptiveAppearance ? collectionMaterial : null,
          host: host,
        ),
      ),
    ),
  );
}

/// The surfaces of the collection rows, top to bottom: for each row action
/// with [tooltip], the largest semantics subtree around it that holds no
/// other row's action, without the spacing that follows the row.
List<Rect> collectionRowSurfaces(WidgetTester tester, String tooltip) {
  bool holdsOneRow(SemanticsNode node) =>
      node.descendants
          .where((child) => child.getSemanticsData().tooltip == tooltip)
          .length <=
      1;
  bool onlyAddsSpaceBelow(SemanticsNode node, SemanticsNode parent) {
    final inner = node.screenRect;
    final outer = parent.screenRect;
    return outer.left == inner.left &&
        outer.right == inner.right &&
        outer.top == inner.top &&
        outer.bottom > inner.bottom;
  }

  return [
    for (final action in find.tooltip(tooltip).evaluate())
      () {
        var row = tester.getSemantics(find.byWidget(action.widget));
        for (
          var parent = row.parent;
          parent != null &&
              holdsOneRow(parent) &&
              !onlyAddsSpaceBelow(row, parent);
          parent = parent.parent
        ) {
          row = parent;
        }
        return row.screenRect;
      }(),
  ]..sort((a, b) => a.top.compareTo(b.top));
}

CheckedEditorCatalog _collectionCatalog() {
  final root = skir.TypeDefinitionId(
    typeId: skir.TypeId.createQualified(namespace: "test", name: "Collections"),
    revision: 1,
  );
  final list = skir.TypeDefinitionId(
    typeId: skir.TypeId.createQualified(namespace: "test", name: "TextList"),
    revision: 1,
  );
  final map = skir.TypeDefinitionId(
    typeId: skir.TypeId.createQualified(namespace: "test", name: "TextMap"),
    revision: 1,
  );
  final text = skir.TypeTemplate.wrapScalar(skir.ScalarKind.text);
  final fields = {
    "items": skir.TypeTemplate.createNamed(
      definition: list,
      arguments: const [],
    ),
    "values": skir.TypeTemplate.createNamed(
      definition: map,
      arguments: const [],
    ),
  };
  return CheckedEditorCatalog(
    testCatalogSnapshot(
      generation: skir.CatalogGeneration(value: "catalog:test"),
      types: [
        declaredRecord(root, fields: fields),
        publishedType(
          list,
          representation: skir.RepresentationTemplate.createSequence(
            item: text,
            kind: skir.CollectionKind.list,
          ),
        ),
        publishedType(
          map,
          representation: skir.RepresentationTemplate.createMapping(
            key: text,
            value: text,
          ),
        ),
      ],
    ),
  );
}

skir.AuthoringRecord _collectionRecord(String field, skir.DataValue value) =>
    skir.AuthoringRecord(
      types: const [],
      configuration: skir.TypeSelection.createComplete(
        definition: skir.TypeDefinitionId(
          typeId: skir.TypeId.createQualified(
            namespace: "test",
            name: "Collections",
          ),
          revision: 1,
        ),
        arguments: const [],
      ),
      fields: [skir.FieldValue(name: field, value: value)],
    );

final _compactCard = presentationNode(
  "compact.root",
  textElement(textLiteral("Compact card")),
);
