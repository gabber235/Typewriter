import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";

skir.DataValue _placementValue(skir.NamedTypeUse use, {String width = "0"}) =>
    skir.DataValue.createNamed(
      actualType: use,
      payload: skir.DataValue.createRecord(
        fields: [
          skir.FieldValue(
            name: "width",
            value: skir.DataValue.wrapInteger(width),
          ),
        ],
      ),
    );

skir.PublishedType _publishedRecord({
  required skir.TypeDefinitionId definition,
  required List<skir.FieldDeclaration> fields,
  required List<skir.EffectiveFieldTemplate> effectiveFields,
}) => publishedType(
  definition,
  representation: skir.RepresentationTemplate.createRecord(
    fields: fields,
    form: skir.RecordForm.concrete,
  ),
  fields: effectiveFields,
);

/// A catalog where Shelves own Quest Books and each Book owns Entries, an
/// abstract record that SimpleMessage refines; [manyEntries] adds 26 more
/// Entry kinds and [reversedOwnership] declares the Book's ownership with
/// its endpoints swapped.
CheckedEditorCatalog shelfCatalog({
  bool reversedOwnership = false,
  bool manyEntries = false,
}) {
  final book = testTypeId("Book");
  final entry = testTypeId("Entry");
  final owner = skir.EndpointDefinition(
    id: skir.EndpointId(value: "book.entries.book"),
    slot: reversedOwnership
        ? skir.EndpointSlot.second
        : skir.EndpointSlot.first,
    resource: skir.NamedTypeTemplate(definition: book, arguments: const []),
    cardinality: skir.EndpointCardinality.one,
    onDelete: skir.RelationDeletePolicy.clear,
  );
  final child = skir.EndpointDefinition(
    id: skir.EndpointId(value: "book.entries.entry"),
    slot: reversedOwnership
        ? skir.EndpointSlot.first
        : skir.EndpointSlot.second,
    resource: skir.NamedTypeTemplate(definition: entry, arguments: const []),
    cardinality: skir.EndpointCardinality.many,
    onDelete: skir.RelationDeletePolicy.cascade,
  );
  return testCheckedCatalog(
    generation: skir.CatalogGeneration(value: "catalog:test"),
    types: [
      declaredRecord(
        book,
        searchKey: "book",
        display: skir.TypeDisplay(
          name: "Quest Book",
          description: "A reusable quest collection",
          icon: skir.Icon.wrapIconify("material-symbols:book"),
          color: skir.Color(argb: 0xff3f51b5.toSigned(32)),
        ),
      ),
      declaredRecord(testTypeId("Shelf"), searchKey: "shelf"),
      declaredRecord(entry, open: true),
      declaredRecord(
        testTypeId("SimpleMessage"),
        parents: [
          skir.NamedTypeTemplate(definition: entry, arguments: const []),
        ],
      ),
      if (manyEntries) ...[
        for (var index = 0; index < 25; index++)
          declaredRecord(
            testTypeId("Entry$index"),
            parents: [
              skir.NamedTypeTemplate(definition: entry, arguments: const []),
            ],
          ),
        declaredRecord(
          testTypeId("ZMessage"),
          parents: [
            skir.NamedTypeTemplate(definition: entry, arguments: const []),
          ],
        ),
      ],
    ],
    relations: [
      // A shelf owns Books, which makes them creatable resources.
      skir.RelationContract(
        id: skir.RelationId(value: "shelf.books"),
        first: skir.EndpointDefinition(
          id: skir.EndpointId(value: "shelf.books.shelf"),
          slot: skir.EndpointSlot.first,
          resource: skir.NamedTypeTemplate(
            definition: testTypeId("Shelf"),
            arguments: const [],
          ),
          cardinality: skir.EndpointCardinality.one,
          onDelete: skir.RelationDeletePolicy.cascade,
        ),
        second: skir.EndpointDefinition(
          id: skir.EndpointId(value: "shelf.books.book"),
          slot: skir.EndpointSlot.second,
          resource: skir.NamedTypeTemplate(
            definition: book,
            arguments: const [],
          ),
          cardinality: skir.EndpointCardinality.many,
          onDelete: skir.RelationDeletePolicy.clear,
        ),
        families: [skir.resourceOwnershipFamily],
      ),
      skir.RelationContract(
        id: skir.RelationId(value: "book.entries"),
        first: reversedOwnership ? child : owner,
        second: reversedOwnership ? owner : child,
        families: [skir.resourceOwnershipFamily],
      ),
    ],
    realmRoot: skir.TypeDefinitionId.defaultInstance,
  );
}

/// A draft of one resource, with the catalog that types it: the shapes of
/// authored record the editing and presentation tests start from.
final class AuthoredDraft {
  /// A draft of one resource whose text field [fieldName] holds [title], or
  /// [initial] when given, typed as [namedText] when given; [requireTitle]
  /// adds a rule that the title is not blank and [inspectorLayout] replaces
  /// the inspector presentation.
  factory AuthoredDraft.titled({
    String title = "Original",
    bool requireTitle = false,
    String fieldName = "title",
    skir.DataValue? initial,
    skir.NamedTypeUse? namedText,
    skir.PresentationNode? inspectorLayout,
  }) {
    final generation = skir.CatalogGeneration(value: "catalog:1");
    final fieldType = namedText == null
        ? skir.TypeTemplate.wrapScalar(skir.ScalarKind.text)
        : skir.TypeTemplate.createNamed(
            definition: namedText.definition,
            arguments: const [],
          );
    final definition = skir.TypeDefinitionId(
      typeId: skir.TypeId.wrapQualified(
        skir.QualifiedTypeId(namespace: "test", name: "Message"),
      ),
      revision: 1,
    );
    final presentationId = skir.PresentationId(
      namespace: "test",
      name: "message.editor",
    );
    final ruleOrigin = skir.RuleOrigin(owner: definition, ordinal: 0);
    final titleRule = skir.RuleId(origin: ruleOrigin, localIndex: 0);
    final layout =
        inspectorLayout ??
        skir.PresentationNode(
          nodeId: "message.title",
          properties: skir.PresentationProperties.defaultInstance,
          element: textInputElement(
            skir.BindingRef(
              bindingId: configuredValueBindingId,
              path: skir.ValuePath(
                segments: [skir.PathSegment.createField(name: fieldName)],
              ),
            ),
          ),
          header: null,
        );
    final headerLayout = skir.PresentationNode(
      nodeId: "message.header",
      properties: skir.PresentationProperties.defaultInstance,
      element: textElement(
        skir.ExpressionNode.createInput(
          binding: configuredValueBindingId,
          path: skir.ValuePath(
            segments: [skir.PathSegment.createField(name: fieldName)],
          ),
        ),
      ),
      header: null,
    );
    final graphLayout = skir.PresentationNode(
      nodeId: "message.graph",
      properties: skir.PresentationProperties.defaultInstance,
      element: skir.PresentationElement.createAdaptiveLeading(
        leading: skir.PresentationNode(
          nodeId: "message.graph.icon.color",
          properties: skir.PresentationProperties.defaultInstance,
          element: skir.PresentationElement.createContainer(
            foregroundColor: null,
            transition: null,
            shadows: const [],
            child: skir.PresentationNode(
              nodeId: "message.graph.icon.padding",
              properties: skir.PresentationProperties.defaultInstance,
              element: skir.PresentationElement.createPadding(
                child: skir.PresentationNode(
                  nodeId: "message.graph.icon",
                  properties: skir.PresentationProperties.defaultInstance,
                  element: skir.PresentationElement.createIcon(
                    name: skir.ExpressionNode.wrapLiteral(
                      skir.DataValue.wrapStringValue(
                        '<svg xmlns="http://www.w3.org/2000/svg" '
                        'viewBox="0 0 24 24">'
                        ' <path d="M4 4h16v16H4z"/></svg>',
                      ),
                    ),
                    semanticLabel: skir.ExpressionNode.wrapLiteral(
                      skir.DataValue.wrapStringValue("Tag"),
                    ),
                    color: null,
                    size: null,
                  ),
                  header: null,
                ),
                top: 6,
                start: 6,
                end: 6,
                bottom: 6,
              ),
              header: null,
            ),
            border: null,
            backgroundColor: skir.PresentationColor.wrapValue(
              skir.ExpressionNode.wrapLiteral(
                skir.DataValue.wrapInteger("4288585374"),
              ),
            ),
            radius: skir.PresentationRadius.none,
          ),
          header: null,
        ),
        center: headerLayout,
        suffix: null,
        padding: skir.PresentationInsets.wrapAll(8),
        compactPadding: skir.PresentationInsets.wrapAll(4),
        gap: 12,
        minimumCenterWidth: 80,
      ),
      header: null,
    );
    final generatedGraphLayout = skir.PresentationNode(
      nodeId: "message.graph.root",
      properties: skir.PresentationProperties.defaultInstance,
      element: skir.PresentationElement.wrapChildren(
        skir.ChildrenElement.createColumn(
          children: [skir.AxisChild.wrapFixed(graphLayout)],
          layout: skir.AxisChildrenLayout(
            clipOverflow: false,

            spacing: 0,
            mainAxisAlignment: skir.MainAxisAlignment.start,
            crossAxisAlignment: skir.CrossAxisAlignment.start,
          ),
        ),
      ),
      header: null,
    );
    final checked = CheckedEditorCatalog(
      testCatalogSnapshot(
        generation: generation,
        types: [
          if (namedText != null)
            publishedType(
              namedText.definition,
              representation: skir.RepresentationTemplate.createScalar(
                kind: skir.ScalarKind.text,
              ),
            ),
          declaredRecord(
            definition,
            fields: {fieldName: fieldType},
            rules: {
              fieldName: requireTitle ? [titleRule] : const [],
            },
          ),
        ],
        presentations: [
          typePresentation(presentationId, definition, [
            skir.PresentationRole.workspace,
            skir.PresentationRole.inspector,
            skir.PresentationRole.item,
          ]),
        ],
        presentationMaterials: [
          typeMaterial(
            presentationId,
            definition,
            skir.PresentationRole.workspace,
            layout,
          ),
          typeMaterial(
            presentationId,
            definition,
            skir.PresentationRole.inspector,
            skir.PresentationNode(
              nodeId: "message.inspector",
              properties: skir.PresentationProperties.defaultInstance,
              header: null,
              element: skir.PresentationElement.wrapChildren(
                skir.ChildrenElement.createColumn(
                  children: [
                    skir.AxisChild.wrapFixed(headerLayout),
                    skir.AxisChild.wrapFixed(layout),
                  ],
                  layout: skir.AxisChildrenLayout.defaultInstance,
                ),
              ),
            ),
          ),
          typeMaterial(
            presentationId,
            definition,
            skir.PresentationRole.item,
            generatedGraphLayout,
          ),
        ],
        configuration: requireTitle
            ? [
                skir.ConfigurationRecipe(
                  origin: ruleOrigin,
                  relativePath: skir.RelativeFieldPattern(
                    segments: [
                      skir.FieldPatternSegment.createField(name: fieldName),
                    ],
                  ),
                  representationCondition: skir.RepresentationKind.text,
                  rules: [
                    skir.OwnedRule(
                      id: titleRule,
                      descriptor: skir.RuleDescriptor(
                        // Not blank: the trimmed text is not empty.
                        predicate: portableCall("boolean.not", [
                          portableCall("value.equals", [
                            portableCall("text.trim_start", [
                              portableCall("text.trim_end", [
                                skir.ExpressionNode.createInput(
                                  binding: configuredValueBindingId,
                                  path: skir.ValuePath(segments: const []),
                                ),
                              ]),
                            ]),
                            skir.ExpressionNode.wrapLiteral(
                              skir.DataValue.wrapStringValue(""),
                            ),
                          ]),
                        ]),
                      ),
                      diagnostic: skir.DiagnosticTemplate(
                        code: "non_blank",
                        message: "Title must not be blank",
                        severity: skir.DiagnosticSeverity.error,
                        targets: [
                          skir.RelativeFieldPattern(
                            segments: [
                              skir.FieldPatternSegment.createField(
                                name: fieldName,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ]
            : const [],
      ),
    );
    final resource = skir.ResourceId(value: "message:one");
    final record = skir.AuthoringRecord(
      configuration: skir.TypeSelection.createComplete(
        definition: definition,
        arguments: const [],
      ),
      fields: [
        skir.FieldValue(
          name: fieldName,
          value: initial ?? skir.DataValue.wrapStringValue(title),
        ),
      ],
    );
    final draft = AuthoringEdit(
      generation: generation,
      resources: [skir.AuthoringResource(id: resource, content: record)],
      links: const [],
      catalog: checked,
    );
    return AuthoredDraft._(resource: resource, draft: draft, catalog: checked);
  }

  /// A draft of one Repeating resource whose integer field [fieldName] must
  /// be at least [minimum], in a catalog of [generation] and a saved state
  /// [snapshot], holding [initial] when given.
  factory AuthoredDraft.numeric({
    required String generation,
    required String snapshot,
    required int minimum,
    skir.DataValue? initial,
    String fieldName = "repetitions",
  }) {
    final catalogGeneration = skir.CatalogGeneration(value: generation);
    final definition = skir.TypeDefinitionId(
      typeId: skir.TypeId.createQualified(namespace: "test", name: "Repeating"),
      revision: 1,
    );
    final presentationId = skir.PresentationId(
      namespace: "test",
      name: "repeating.inspector",
    );
    final ruleOrigin = skir.RuleOrigin(owner: definition, ordinal: 0);
    final ruleId = skir.RuleId(origin: ruleOrigin, localIndex: 0);
    final configured = skir.ExpressionBindingId(value: "configured_value");
    final path = skir.ValuePath(
      segments: [skir.PathSegment.createField(name: fieldName)],
    );
    final checked = CheckedEditorCatalog(
      testCatalogSnapshot(
        generation: catalogGeneration,
        types: [
          declaredRecord(
            definition,
            fields: {
              fieldName: skir.TypeTemplate.wrapScalar(
                skir.ScalarKind.createInteger(
                  width: skir.IntegerWidth.signedThirtyTwo,
                ),
              ),
            },
            rules: {
              fieldName: [ruleId],
            },
          ),
        ],
        presentations: [
          typePresentation(presentationId, definition, [
            skir.PresentationRole.inspector,
          ]),
        ],
        presentationMaterials: [
          typeMaterial(
            presentationId,
            definition,
            skir.PresentationRole.inspector,
            skir.PresentationNode(
              nodeId: fieldName,
              properties: skir.PresentationProperties.defaultInstance,
              element: skir.PresentationElement.wrapNumericInput(
                (skir.NumericControl.mutable()
                      ..control = skir.BoundControl(
                        binding: skir.BindingRef(
                          bindingId: configuredValueBindingId,
                          path: path,
                        ),
                        label: null,
                        description: null,
                        prefix: null,
                        semanticLabel: null,
                      ))
                    .toFrozen(),
              ),
              header: null,
            ),
          ),
        ],
        configuration: [
          skir.ConfigurationRecipe(
            origin: ruleOrigin,
            relativePath: skir.RelativeFieldPattern(
              segments: [skir.FieldPatternSegment.createField(name: fieldName)],
            ),
            representationCondition: skir.RepresentationKind.integer,
            rules: [
              skir.OwnedRule(
                id: ruleId,
                descriptor: skir.RuleDescriptor(
                  // value >= minimum: the comparison is not -1.
                  predicate: portableCall("boolean.not", [
                    portableCall("value.equals", [
                      portableCall("value.compare", [
                        skir.ExpressionNode.createInput(
                          binding: configured,
                          path: skir.ValuePath(segments: const []),
                        ),
                        skir.ExpressionNode.wrapLiteral(
                          skir.DataValue.wrapInteger(minimum.toString()),
                        ),
                      ]),
                      skir.ExpressionNode.wrapLiteral(
                        skir.DataValue.wrapInteger("-1"),
                      ),
                    ]),
                  ]),
                ),
                diagnostic: skir.DiagnosticTemplate(
                  code: "minimum",
                  message: "Must be at least $minimum",
                  severity: skir.DiagnosticSeverity.error,
                  targets: const [],
                ),
              ),
            ],
          ),
        ],
      ),
    );
    final resource = skir.ResourceId(value: "repeating:one");
    final record = skir.AuthoringRecord(
      configuration: skir.TypeSelection.createComplete(
        definition: definition,
        arguments: const [],
      ),
      fields: [
        skir.FieldValue(
          name: fieldName,
          value: initial ?? skir.DataValue.wrapInteger("2"),
        ),
      ],
    );
    return AuthoredDraft._(
      resource: resource,
      catalog: checked,
      draft: AuthoringEdit(
        generation: catalogGeneration,
        resources: [skir.AuthoringResource(id: resource, content: record)],
        links: const [],
        catalog: checked,
      ),
    );
  }

  /// A draft of one SequencePage whose elements show as an empty graph.
  factory AuthoredDraft.pageGraph() {
    final generation = skir.CatalogGeneration(value: "catalog:page");
    final definition = skir.TypeDefinitionId(
      typeId: skir.TypeId.createQualified(
        namespace: "test",
        name: "SequencePage",
      ),
      revision: 1,
    );
    final presentationId = skir.PresentationId(
      namespace: "test",
      name: "sequence.editor",
    );
    final elementsDefinition = skir.TypeDefinitionId(
      typeId: skir.TypeId.createQualified(
        namespace: "test",
        name: "PageElements",
      ),
      revision: 1,
    );
    final elementsType = skir.TypeTemplate.createNamed(
      definition: elementsDefinition,
      arguments: const [],
    );
    final checked = CheckedEditorCatalog(
      testCatalogSnapshot(
        generation: generation,
        types: [
          declaredRecord(definition, fields: {"elements": elementsType}),
          declaredCollection(elementsDefinition, skir.ScalarKind.text),
        ],
        presentations: [
          typePresentation(presentationId, definition, [
            skir.PresentationRole.workspace,
          ]),
        ],
        presentationMaterials: [
          typeMaterial(
            presentationId,
            definition,
            skir.PresentationRole.workspace,
            skir.PresentationNode(
              nodeId: "generated.root",
              properties: skir.PresentationProperties.defaultInstance,
              element: skir.PresentationElement.wrapChildren(
                skir.ChildrenElement.createColumn(
                  children: [
                    skir.AxisChild.wrapFixed(
                      elementsGraphNode("sequence.graph", textTemplate),
                    ),
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
          ),
        ],
      ),
    );
    final resource = skir.ResourceId(value: "page:empty");
    final record = skir.AuthoringRecord(
      configuration: skir.TypeSelection.createComplete(
        definition: definition,
        arguments: const [],
      ),
      fields: [
        skir.FieldValue(name: "elements", value: skir.DataValue.unfilled),
      ],
    );
    final draft = AuthoringEdit(
      generation: generation,
      resources: [skir.AuthoringResource(id: resource, content: record)],
      links: const [],
      catalog: checked,
    );
    return AuthoredDraft._(resource: resource, draft: draft, catalog: checked);
  }

  /// A draft of one Tag whose integer placement width carries a local rule:
  /// the rule checks [predicate], or that the width is positive, and reports
  /// at [targets], or at the width itself. With [collection], the Tag holds a
  /// list of two placements instead of one.
  factory AuthoredDraft.nestedRule({
    bool collection = false,
    List<skir.RelativeFieldPattern>? targets,
    skir.ExpressionNode? predicate,
  }) {
    final generation = skir.CatalogGeneration(value: "catalog:nested_rules");
    final tag = testTypeId("Tag");
    final placement = testTypeId("GraphPlacement");
    final placementList = testTypeId("GraphPlacementList");
    final rootFieldName = collection ? "placements" : "placement";
    final placementOwner = skir.FieldOwner(
      definition: tag,
      name: rootFieldName,
    );
    final widthOwner = skir.FieldOwner(definition: placement, name: "width");
    final placementTemplate = skir.TypeTemplate.createNamed(
      definition: placement,
      arguments: const [],
    );
    final placementListTemplate = skir.TypeTemplate.createNamed(
      definition: placementList,
      arguments: const [],
    );
    final integer = skir.TypeTemplate.wrapScalar(
      skir.ScalarKind.createInteger(width: skir.IntegerWidth.signedThirtyTwo),
    );
    final ruleOrigin = skir.RuleOrigin(
      owner: collection ? tag : placement,
      ordinal: 0,
    );
    final ruleId = skir.RuleId(origin: ruleOrigin, localIndex: 0);
    final subjectPattern = skir.RelativeFieldPattern(
      segments: collection
          ? [
              skir.FieldPatternSegment.createField(name: "placements"),
              skir.FieldPatternSegment.items,
              skir.FieldPatternSegment.createField(name: "width"),
            ]
          : [skir.FieldPatternSegment.createField(name: "width")],
    );
    final checked = CheckedEditorCatalog(
      testCatalogSnapshot(
        generation: generation,
        types: [
          _publishedRecord(
            definition: tag,
            fields: [
              skir.FieldDeclaration(
                owner: placementOwner,
                type: collection ? placementListTemplate : placementTemplate,
                overrides: const [],
                hasConstructorDefault: false,
              ),
            ],
            effectiveFields: [
              skir.EffectiveFieldTemplate(
                key: rootFieldName,
                owner: placementOwner,
                type: collection ? placementListTemplate : placementTemplate,
                rules: const [],
              ),
            ],
          ),
          _publishedRecord(
            definition: placement,
            fields: [
              skir.FieldDeclaration(
                owner: widthOwner,
                type: integer,
                overrides: const [],
                hasConstructorDefault: false,
              ),
            ],
            effectiveFields: [
              skir.EffectiveFieldTemplate(
                key: "width",
                owner: widthOwner,
                type: integer,
                rules: [ruleId],
              ),
            ],
          ),
          if (collection)
            publishedType(
              placementList,
              representation: skir.RepresentationTemplate.createSequence(
                item: placementTemplate,
                kind: skir.CollectionKind.list,
              ),
            ),
        ],
        configuration: [
          skir.ConfigurationRecipe(
            origin: ruleOrigin,
            relativePath: subjectPattern,
            representationCondition: skir.RepresentationKind.integer,
            rules: [
              skir.OwnedRule(
                id: ruleId,
                descriptor: skir.RuleDescriptor(
                  predicate:
                      predicate ??
                      portableCall("value.equals", [
                        portableCall("value.compare", [
                          skir.ExpressionNode.createInput(
                            binding: skir.ExpressionBindingId(
                              value: "configured_value",
                            ),
                            path: skir.ValuePath(segments: const []),
                          ),
                          skir.ExpressionNode.wrapLiteral(
                            skir.DataValue.wrapInteger("0"),
                          ),
                        ]),
                        skir.ExpressionNode.wrapLiteral(
                          skir.DataValue.wrapInteger("1"),
                        ),
                      ]),
                ),
                diagnostic: skir.DiagnosticTemplate(
                  code: "positive",
                  message: "Must be positive",
                  severity: skir.DiagnosticSeverity.error,
                  targets: targets ?? [subjectPattern],
                ),
              ),
            ],
          ),
        ],
      ),
    );
    final resource = skir.ResourceId(value: "tag:nested_rules");
    final placementUse = skir.NamedTypeUse(
      definition: placement,
      arguments: const [],
    );
    final draft = AuthoringEdit(
      generation: generation,
      resources: [
        skir.AuthoringResource(
          id: resource,
          content: skir.AuthoringRecord(
            configuration: skir.TypeSelection.createComplete(
              definition: tag,
              arguments: const [],
            ),
            fields: [
              skir.FieldValue(
                name: rootFieldName,
                value: collection
                    ? skir.DataValue.createNamed(
                        actualType: skir.NamedTypeUse(
                          definition: placementList,
                          arguments: const [],
                        ),
                        payload: skir.DataValue.createListValue(
                          items: [
                            skir.ListItem(
                              id: skir.ItemId(value: "first"),
                              value: _placementValue(placementUse),
                            ),
                            skir.ListItem(
                              id: skir.ItemId(value: "second"),
                              value: _placementValue(placementUse, width: "1"),
                            ),
                          ],
                        ),
                      )
                    : _placementValue(placementUse),
              ),
            ],
          ),
        ),
      ],
      links: const [],
      catalog: checked,
    );
    return AuthoredDraft._(resource: resource, draft: draft, catalog: checked);
  }

  AuthoredDraft._({
    required this.resource,
    required this.draft,
    required this.catalog,
  });

  /// The resource the draft holds.
  final skir.ResourceId resource;

  /// The draft, which tests may edit.
  final AuthoringEdit draft;

  /// The catalog that types the draft.
  final CheckedEditorCatalog catalog;

  /// This page's saved document holding [child] in its elements, typed by both
  /// catalogs; [childMaterials] replace the child's presentations and [types]
  /// add published types.
  AuthoringDocument holding(
    AuthoredDraft child, {
    List<skir.PresentationMaterial>? childMaterials,
    List<skir.PublishedType> types = const [],
  }) {
    final pageType = catalog.snapshot.types.first.definition.id;
    final childType = child.catalog.snapshot.types.first.definition.id;
    final relation = skir.RelationContract(
      id: skir.RelationId(value: "test.page.elements"),
      first: skir.EndpointDefinition(
        id: skir.EndpointId(value: "test.page.elements.page"),
        slot: skir.EndpointSlot.first,
        resource: skir.NamedTypeTemplate(
          definition: pageType,
          arguments: const [],
        ),
        cardinality: skir.EndpointCardinality.one,
        onDelete: skir.RelationDeletePolicy.clear,
      ),
      second: skir.EndpointDefinition(
        id: skir.EndpointId(value: "test.page.elements.child"),
        slot: skir.EndpointSlot.second,
        resource: skir.NamedTypeTemplate(
          definition: childType,
          arguments: const [],
        ),
        cardinality: skir.EndpointCardinality.many,
        onDelete: skir.RelationDeletePolicy.clear,
      ),
      families: const [],
    );
    final wire = catalog.snapshot.toMutable()
      ..types = [
        ...catalog.snapshot.types,
        ...child.catalog.snapshot.types,
        ...types,
      ]
      ..presentations = [
        ...catalog.snapshot.presentations,
        ...child.catalog.snapshot.presentations,
      ]
      ..presentationMaterials = [
        ...catalog.snapshot.presentationMaterials,
        ...childMaterials ?? child.catalog.snapshot.presentationMaterials,
      ]
      ..configuration = child.catalog.snapshot.configuration
      ..relations = [relation];
    return AuthoringEdit(
      generation: catalog.snapshot.generation,
      catalog: CheckedEditorCatalog(wire.toFrozen()),
      resources: [
        ...draft.toDocument().entries.values,
        ...child.draft.toDocument().entries.values,
      ],
      links: [
        skir.LinkProjection(
          contract: relation.id,
          first: resource,
          second: child.resource,
          firstLocation: editorRootPath.field("elements"),
          secondLocation: null,
        ),
      ],
    ).toDocument();
  }
}

/// The inspector layout of a Book in sections, showing its title editor
/// only when [showTitleEditor].
skir.PresentationNode bookSectionsLayout({required bool showTitleEditor}) {
  skir.BindingRef binding(String field) => skir.BindingRef(
    bindingId: configuredValueBindingId,
    path: editorRootPath.field(field),
  );
  return skir.PresentationNode(
    nodeId: "book.sections",
    properties: skir.PresentationProperties.defaultInstance,
    header: null,
    element: skir.PresentationElement.wrapChildren(
      skir.ChildrenElement.createColumn(
        layout: skir.AxisChildrenLayout(
          clipOverflow: false,

          spacing: 12,
          mainAxisAlignment: skir.MainAxisAlignment.start,
          crossAxisAlignment: skir.CrossAxisAlignment.stretch,
        ),
        children: [
          for (final (field, title) in [
            ("title", "Title"),
            ("icon", "Icon"),
            ("color", "Color"),
            ("tags", "Direct Tags"),
            (null, "Effective Tags"),
          ])
            skir.AxisChild.wrapFixed(
              skir.PresentationNode(
                nodeId: "section.${field ?? 'effectiveTags'}",
                properties: skir.PresentationProperties.defaultInstance,
                header: skir.PresentationHeader(
                  binding: field == null ? null : binding(field),
                  title: skir.PresentationHeaderTitle.wrapText(
                    skir.ExpressionNode.wrapLiteral(
                      skir.DataValue.wrapStringValue(title),
                    ),
                  ),
                  description: null,
                  initiallyExpanded: null,
                  items: const [],
                  headerPadding: null,
                  contentPadding: null,
                ),
                element: field == "title" && showTitleEditor
                    ? textInputElement(binding("title"))
                    : skir.PresentationElement.createSpacer(
                        width: null,
                        height: null,
                      ),
              ),
            ),
        ],
      ),
    ),
  );
}

/// The text [value], wrapped as the named text [type] when given.
skir.DataValue textValue(String value, {skir.NamedTypeUse? type}) =>
    type == null
    ? skir.DataValue.wrapStringValue(value)
    : skir.DataValue.createNamed(
        actualType: type,
        payload: skir.DataValue.wrapStringValue(value),
      );
