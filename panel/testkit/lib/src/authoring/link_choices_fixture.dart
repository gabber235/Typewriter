import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/src/authoring/realm_world.dart";
import "package:typewriter_testkit/src/core/test_world.dart";
import "package:typewriter_testkit/src/support/portable_operations.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";

/// A draft of a source resource whose wrapper record links to target
/// resources with a back reference, and an existing and an empty target.
/// The flags vary the shape of the wrapper and of its inverse link.
final class LinkChoicesFixture {
  factory LinkChoicesFixture({
    bool incompatibleInverse = false,
    bool directCollection = false,
    bool abstractWrapper = false,
    bool nestedCollection = false,
  }) {
    final generation = skir.CatalogGeneration(value: "catalog:links");
    final node = testTypeId("Node");
    final wrapper = testTypeId("Wrapper");
    final abstractForm = testTypeId("AbstractWrapper");
    final sourceLink = testTypeId("SourceLink");
    final targetLink = testTypeId("TargetLink");
    final links = testTypeId("Links");
    final sourceEndpoint = skir.EndpointId(value: "test.source");
    final targetEndpoint = skir.EndpointId(value: "test.target");
    final nodeTemplate = skir.TypeTemplate.createNamed(
      definition: node,
      arguments: const [],
    );
    final nodeUse = skir.NamedTypeUse(definition: node, arguments: const []);
    final wrapperUse = skir.NamedTypeUse(
      definition: wrapper,
      arguments: const [],
    );
    final wrapperSelection = skir.TypeSelection.wrapComplete(wrapperUse);
    final sourceField = skir.FieldOwner(definition: node, name: "source");
    final wrapperField = skir.FieldOwner(definition: node, name: "wrapper");
    final backField = skir.FieldOwner(definition: wrapper, name: "back");
    final labelField = skir.FieldOwner(definition: wrapper, name: "label");
    skir.FieldDeclaration declaration(
      skir.FieldOwner owner,
      skir.TypeTemplate type,
    ) => skir.FieldDeclaration(
      owner: owner,
      type: type,
      overrides: const [],
      hasConstructorDefault: false,
    );
    final sourceLinkTemplate = skir.TypeTemplate.createNamed(
      definition: sourceLink,
      arguments: const [],
    );
    final wrapperTemplate = skir.TypeTemplate.createNamed(
      definition: abstractWrapper ? abstractForm : wrapper,
      arguments: const [],
    );
    final targetLinkTemplate = skir.TypeTemplate.createNamed(
      definition: targetLink,
      arguments: const [],
    );
    final linksTemplate = skir.TypeTemplate.createNamed(
      definition: links,
      arguments: const [],
    );
    final textTemplate = skir.TypeTemplate.wrapScalar(skir.ScalarKind.text);
    final snapshot = testCatalogSnapshot(
      generation: generation,
      types: [
        if (abstractWrapper)
          publishedDefinition(
            skir.TypeDefinition(
              id: abstractForm,
              parameters: const [],
              representation: skir.RepresentationTemplate.createRecord(
                fields: const [],
                abstract_: true,
              ),
              parents: const [],
            ),
            const [],
          ),
        publishedDefinition(
          skir.TypeDefinition(
            id: links,
            parameters: const [],
            representation: skir.RepresentationTemplate.createSequence(
              item: targetLinkTemplate,
              kind: skir.CollectionKind.list,
            ),
            parents: const [],
          ),
          const [],
        ),
        publishedDefinition(
          skir.TypeDefinition(
            id: node,
            parameters: const [],
            representation: skir.RepresentationTemplate.createRecord(
              fields: [
                declaration(sourceField, sourceLinkTemplate),
                declaration(
                  wrapperField,
                  directCollection ? linksTemplate : wrapperTemplate,
                ),
              ],
              abstract_: false,
            ),
            parents: const [],
          ),
          [
            skir.EffectiveFieldTemplate(
              key: "source",
              owner: sourceField,
              type: sourceLinkTemplate,
              rules: const [],
            ),
            skir.EffectiveFieldTemplate(
              key: "wrapper",
              owner: wrapperField,
              type: directCollection ? linksTemplate : wrapperTemplate,
              rules: const [],
            ),
          ],
        ),
        publishedDefinition(
          skir.TypeDefinition(
            id: wrapper,
            parameters: const [],
            representation: skir.RepresentationTemplate.createRecord(
              fields: [
                declaration(
                  backField,
                  nestedCollection ? linksTemplate : targetLinkTemplate,
                ),
                declaration(labelField, textTemplate),
              ],
              abstract_: false,
            ),
            parents: abstractWrapper
                ? [
                    skir.NamedTypeTemplate(
                      definition: abstractForm,
                      arguments: const [],
                    ),
                  ]
                : const [],
          ),
          [
            skir.EffectiveFieldTemplate(
              key: "back",
              owner: backField,
              type: nestedCollection ? linksTemplate : targetLinkTemplate,
              rules: const [],
            ),
            skir.EffectiveFieldTemplate(
              key: "label",
              owner: labelField,
              type: textTemplate,
              rules: const [],
            ),
          ],
        ),
        for (final link in [
          (sourceLink, sourceEndpoint),
          (targetLink, targetEndpoint),
        ])
          publishedDefinition(
            skir.TypeDefinition(
              id: link.$1,
              parameters: const [],
              representation: skir.RepresentationTemplate.createLink(
                endpoint: link.$2,
                target: incompatibleInverse && link.$1 == targetLink
                    ? wrapperTemplate
                    : nodeTemplate,
              ),
              parents: const [],
            ),
            const [],
          ),
      ],
      relations: [
        skir.RelationContract(
          id: skir.RelationId(value: "test.links"),
          first: skir.EndpointDefinition(
            id: sourceEndpoint,
            slot: skir.EndpointSlot.first,
            resource: skir.NamedTypeTemplate(
              definition: node,
              arguments: const [],
            ),
            cardinality: (directCollection || nestedCollection)
                ? skir.EndpointCardinality.many
                : skir.EndpointCardinality.one,
            onDelete: skir.RelationDeletePolicy.clear,
          ),
          second: skir.EndpointDefinition(
            id: targetEndpoint,
            slot: skir.EndpointSlot.second,
            resource: skir.NamedTypeTemplate(
              definition: node,
              arguments: const [],
            ),
            cardinality: (directCollection || nestedCollection)
                ? skir.EndpointCardinality.one
                : skir.EndpointCardinality.many,
            onDelete: skir.RelationDeletePolicy.clear,
          ),
          families: const [],
        ),
      ],
      endpointBindings: [
        skir.EndpointBindingTemplate(
          endpoint: sourceEndpoint,
          containingResource: skir.NamedTypeTemplate(
            definition: node,
            arguments: const [],
          ),
          valueOwner: node,
          relativePath: skir.RelativeFieldPattern(
            segments: [skir.FieldPatternSegment.createField(name: "source")],
          ),
          target: nodeTemplate,
          containsCollection: false,
        ),
        if (!abstractWrapper)
          skir.EndpointBindingTemplate(
            endpoint: targetEndpoint,
            containingResource: skir.NamedTypeTemplate(
              definition: node,
              arguments: const [],
            ),
            valueOwner: directCollection ? node : wrapper,
            relativePath: skir.RelativeFieldPattern(
              segments: [
                skir.FieldPatternSegment.createField(name: "wrapper"),
                if (directCollection)
                  skir.FieldPatternSegment.items
                else
                  skir.FieldPatternSegment.createField(name: "back"),
              ],
            ),
            target: incompatibleInverse ? wrapperTemplate : nodeTemplate,
            containsCollection: directCollection,
          ),
      ],
    );
    final source = skir.ResourceId(value: "resource:source");
    final existingTarget = skir.ResourceId(value: "resource:existing");
    final emptyTarget = skir.ResourceId(value: "resource:empty");
    skir.AuthoringRecord record(skir.DataValue wrapperValue) =>
        skir.AuthoringRecord(
          configuration: skir.TypeSelection.wrapComplete(nodeUse),
          fields: [
            skir.FieldValue(name: "source", value: skir.DataValue.unfilled),
            skir.FieldValue(
              name: "wrapper",
              value: directCollection
                  ? skir.DataValue.createNamed(
                      actualType: skir.NamedTypeUse(
                        definition: links,
                        arguments: const [],
                      ),
                      payload: skir.DataValue.createListValue(items: const []),
                    )
                  : wrapperValue,
            ),
          ],
        );
    final authored = skir.AuthoringState(
      confirmedObservation: skir.AuthoringObservationId(value: "fixture:saved"),
      generation: generation,
      resources: [
        skir.AuthoringResource(
          id: source,
          content: record(skir.DataValue.unfilled),
        ),
        skir.AuthoringResource(
          id: existingTarget,
          content: record(
            skir.DataValue.createNamed(
              actualType: wrapperUse,
              payload: skir.DataValue.createRecord(
                fields: [
                  skir.FieldValue(
                    name: "back",
                    value: nestedCollection
                        ? skir.DataValue.createNamed(
                            actualType: skir.NamedTypeUse(
                              definition: links,
                              arguments: const [],
                            ),
                            payload: skir.DataValue.createListValue(
                              items: const [],
                            ),
                          )
                        : skir.DataValue.unfilled,
                  ),
                  skir.FieldValue(
                    name: "label",
                    value: skir.DataValue.wrapStringValue("existing"),
                  ),
                ],
              ),
            ),
          ),
        ),
        skir.AuthoringResource(
          id: emptyTarget,
          content: record(skir.DataValue.unfilled),
        ),
      ],
      links: const [],
      findings: const [],
    );
    final checked = CheckedEditorCatalog(snapshot);
    return LinkChoicesFixture._(
      draft: AuthoringEdit.fromState(authored, catalog: checked),
      catalog: checked,
      source: skir.ValueLocation(
        resource: source,
        path: editorRootPath.field("source"),
      ),
      existingTarget: existingTarget,
      emptyTarget: emptyTarget,
      nestedLinkPath: skir.ValuePath(
        segments: [
          skir.PathSegment.createField(name: "wrapper"),
          skir.PathSegment.createField(name: "back"),
        ],
      ),
      wrapperUse: wrapperUse,
      wrapperSelection: wrapperSelection,
    );
  }

  LinkChoicesFixture._({
    required this.draft,
    required this.catalog,
    required this.source,
    required this.existingTarget,
    required this.emptyTarget,
    required this.nestedLinkPath,
    required this.wrapperUse,
    required this.wrapperSelection,
  });

  final AuthoringEdit draft;
  final CheckedEditorCatalog catalog;
  final skir.ValueLocation source;
  final skir.ResourceId existingTarget;
  final skir.ResourceId emptyTarget;
  final skir.ValuePath nestedLinkPath;
  final skir.NamedTypeUse wrapperUse;
  final skir.TypeSelection wrapperSelection;
}

/// Showing and reading the link choices of a [LinkChoicesFixture].
extension LinkChoicesViews on LinkChoicesFixture {
  /// Mounts editing of [source] in a world serving the draft, shows its
  /// link control, [readOnly] or not, and returns every location the link
  /// field builder received. The builder shows a control through [wrap], or
  /// as it is without one.
  Future<List<skir.ValueLocation>> showWrappedLinkControl(
    WidgetTester tester, {
    bool readOnly = false,
    Widget Function(Widget control)? wrap,
  }) async {
    final world = testWorld(adaServing(draft.toDocument()));
    final binding = await world.mountEditing(tester, source.resource);
    final wrapped = <skir.ValueLocation>[];
    await tester.pumpWidget(
      linkControl(
        world: world,
        binding: binding,
        readOnly: readOnly,
        linkFieldBuilder: (context, location, control) {
          wrapped.add(location);
          return wrap == null ? control : wrap(control);
        },
      ),
    );
    await tester.pumpAndSettle();
    return wrapped;
  }

  /// The source's link control over [binding], shown in a panel over
  /// [world]: [source] or the fixture's source field, its presentation host
  /// disposed with the test.
  Widget linkControl({
    required World world,
    required RealmEditingBinding binding,
    skir.ValueLocation? source,
    Future<skir.PreparedValue> Function(skir.ValuePreparationRequest)?
    prepareValue,
    Widget Function(BuildContext, skir.ValueLocation, Widget)? linkFieldBuilder,
    bool readOnly = false,
  }) {
    source ??= this.source;
    final root = skir.ExpressionBindingId(value: "configured_value");
    final record = draft.resource(source.resource)!;
    final budget = skir.EvaluationBudget(
      maxSteps: 100,
      maxCollectionItems: 100,
    );
    final host = AuthoredPresentationHost(
      resource: source.resource,
      source: binding.document,
      material: skir.PresentationMaterial.defaultInstance,
      role: skir.PresentationRole.workspace,
      budget: budget,
      capabilities: const PortablePresentationCapabilities(),
      prepareValue: prepareValue,
      edit: binding,
    );
    addTearDown(host.dispose);
    return PanelStage.world(
      world,
      at: PanelLocation.component(
        Scaffold(
          body: PortableResourcesInteractionScope(
            itemBuilder: (context, view, member, child) => child,
            layoutBuilder: (context, view, child) => child,
            linkFieldBuilder: linkFieldBuilder,
            child: PortablePresentationNodeRenderer(
              node: skir.PresentationNode(
                nodeId: "link",
                properties: skir.PresentationProperties.defaultInstance,
                element: skir.PresentationElement.wrapLinkInput(
                  skir.LinkControl(
                    control: skir.BoundControl(
                      binding: skir.BindingRef(
                        bindingId: root,
                        path: source.path,
                      ),
                      label: null,
                      description: null,
                      prefix: null,
                      semanticLabel: null,
                    ),
                    allowReorder: false,
                    candidatePolicy: null,
                    rejectionDisplay: skir.LinkRejectionDisplay.disabled,
                    sourceId: null,
                    appearance: null,
                    content: null,
                    inputAppearance: null,
                    inputContent: null,
                    popup: null,
                  ),
                ),
                header: null,
              ),
              scope: PortablePresentationScope(
                operations: testPortableOperations(),
                bindings: {
                  root: PortableExpressionBinding(
                    value: skir.DataValue.createRecord(fields: record.fields),
                    location: skir.ValueLocation(
                      resource: source.resource,
                      path: skir.ValuePath(segments: const []),
                    ),
                  ),
                },
                budget: budget,
                catalog: catalog,
                host: host,
                readOnly: readOnly,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// The resources the links in [resource]'s `wrapper.back` lead to.
  List<skir.ResourceId?> backLinks(
    AuthoringDocument document,
    skir.ResourceId resource,
  ) {
    final back = document.valueAt(
      authoredFieldLocation(resource, ["wrapper", "back"]),
    );
    return [
      for (final item in back?.authoredItems ?? const <skir.ListItem>[])
        item.value.authoredLink?.target.resource,
    ];
  }
}

/// The picker row that links [target] with the counterpart [choice], found by
/// what it announces.
Finder linkChoice(skir.ResourceId target, String choice) =>
    find.bySemanticsLabel(
      RegExp(
        "^${RegExp.escape(target.value)}: "
        "${RegExp.escape(choice)}",
      ),
    );
