import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/stories/authoring/presentation/realm_story.dart";
import "package:widgetbook_workspace/support/story.dart";

/// The quest layouts the story shows, by knob label: the gallery nodes each
/// one keeps below the quest's action header.
const _layouts = <String, Set<String>>{
  "Every layout": {
    "status",
    "enabled",
    "conditional",
    "tabs",
    "list",
    "add_item",
    "map",
    "add_row",
    "reload",
  },
  "Toggle": {"status", "enabled", "conditional"},
  "Tabs": {"tabs"},
  "List": {"list", "add_item"},
  "Map": {"map", "add_row"},
  "Realm action": {"reload"},
};

@widgetbook.UseCase(
  name: "Layouts and actions",
  type: PortablePresentationNodeRenderer,
)
Widget authoredPresentationInteractionUseCase(BuildContext context) {
  final layout = context.knobs.object.dropdown(
    label: "Layout",
    options: _layouts.keys.toList(),
  );
  final readOnly = context.knobs.boolean(label: "Read only");
  final width = context.knobs.double.slider(
    label: "Width",
    initialValue: 640,
    min: 320,
    max: 980,
  );
  return Story(
    [
      signedIn(ada, organization: acme),
      realmServing(_interactionDraft().toDocument()),
    ],
    at: PanelLocation.component(
      SizedBox(
        width: width,
        height: 860,
        child: RealmEditingScene(
          builder: (context, workspace, _) => SingleChildScrollView(
            padding: EdgeInsets.all(context.spacing.space3),
            child: _InteractionGallery(
              workspace: workspace,
              sections: _layouts[layout]!,
              readOnly: readOnly,
            ),
          ),
        ),
      ),
    ),
  );
}

/// The quest gallery over the panel's editing of the story Realm, with the
/// outcome of its last action below it, as the panel announces it.
final class _InteractionGallery extends HookWidget {
  const _InteractionGallery({
    required this.workspace,
    required this.sections,
    required this.readOnly,
  });

  final RealmEditing workspace;
  final Set<String> sections;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    final binding = useMemoized(
      () => workspace.attach(
        _interactionResource,
        policy: EditorCommitPolicy.applyResource,
      ),
      [workspace],
    );
    useEffect(() => binding.detach, [binding]);
    final host = useMemoized(
      () => AuthoredPresentationHost(
        resource: _interactionResource,
        source: workspace.document,
        material: skir.PresentationMaterial.defaultInstance,
        role: skir.PresentationRole.workspace,
        budget: skir.EvaluationBudget(maxSteps: 1000, maxCollectionItems: 1000),
        capabilities: const PortablePresentationCapabilities(),
        edit: binding,
      ),
      [binding],
    );
    useEffect(() => host.dispose, [host]);
    final operations = useMemoized(PortableOperationResults.new);
    useEffect(() => operations.dispose, [operations]);
    final status = useState<String?>(null);
    useEffect(() {
      operations.onStatus = (message) => status.value = message;
      return null;
    }, [operations]);
    final record = workspace.document.resource(_interactionResource)!;
    host.update(
      source: workspace.document,
      capabilities: const PortablePresentationCapabilities(),
      available: true,
      readOnly: readOnly,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PortablePresentationNodeRenderer(
          node: _interactionGallery(sections.contains),
          scope: PortablePresentationScope(
            operations: operations,
            bindings: {
              _interactionRoot: PortableExpressionBinding(
                value: skir.DataValue.createRecord(fields: record.fields),
                location: skir.ValueLocation(
                  resource: _interactionResource,
                  path: skir.ValuePath(segments: const []),
                ),
              ),
            },
            budget: skir.EvaluationBudget(
              maxSteps: 1000,
              maxCollectionItems: 1000,
            ),
            resource: _interactionResource,
            reportStatus: (message) => status.value = message,
            host: host,
          ),
        ),
        if (status.value case final message?) ...[
          SizedBox(height: context.spacing.space3),
          Semantics(liveRegion: true, child: Text(message)),
        ],
      ],
    );
  }
}

skir.PresentationNode _interactionGallery(
  bool Function(String node) show,
) => skir.PresentationNode(
  nodeId: "authored.interaction.gallery",
  properties: skir.PresentationProperties.defaultInstance,
  element: skir.PresentationElement.wrapChildren(
    skir.ChildrenElement.createColumn(
      children: [
        if (show("status"))
          skir.AxisChild.wrapFixed(
            presentationNode(
              "authored.scalar.interaction.status",
              skir.PresentationElement.createTextInput(
                control: _controlRef(_fieldReference("status"), "Status"),
                appearance: null,
                content: null,
                entry: null,
                mappings: null,
                options: skir.TextEditingOptions.defaultInstance,
              ),
            ),
          ),
        if (show("enabled"))
          skir.AxisChild.wrapFixed(
            presentationNode(
              "authored.scalar.interaction.enabled",
              skir.PresentationElement.wrapToggleInput(
                (skir.ToggleControl.mutable()
                      ..control = _controlRef(
                        _fieldReference("enabled"),
                        "Show details",
                      ))
                    .toFrozen(),
              ),
            ),
          ),
        if (show("conditional"))
          skir.AxisChild.wrapFixed(
            presentationNode(
              "authored.scalar.interaction.conditional",
              skir.PresentationElement.createConditional(
                condition: skir.ExpressionNode.createInput(
                  binding: _interactionRoot,
                  path: _fieldPath("enabled"),
                ),
                whenTrue: presentationText(
                  "conditional.visible",
                  textLiteral("Details are visible"),
                ),
                whenFalse: presentationText(
                  "conditional.hidden",
                  textLiteral("Details are hidden"),
                ),
              ),
            ),
          ),
        if (show("tabs"))
          skir.AxisChild.wrapFixed(
            presentationNode(
              "authored.scalar.interaction.tabs",
              skir.PresentationElement.createTabs(
                tabs: [
                  _tab("general", "General", "General settings"),
                  _tab("advanced", "Advanced", "Advanced settings"),
                  _tab("history", "History", "Change history"),
                  _tab("preview", "Preview", "Preview content"),
                ],
                initiallySelectedTabId: "general",
                appearance: null,
                spacing: null,
                contentSpacing: null,
              ),
            ),
          ),
        if (show("list"))
          skir.AxisChild.wrapFixed(
            presentationNode(
              "authored.scalar.interaction.list",
              skir.PresentationElement.createListInput(
                control: _controlRef(_fieldReference("items"), "Items"),
                itemPresentation: _reorderableListItem,
                allowAdd: true,
                allowRemove: true,
                allowReorder: true,
                itemBinding: declareNamedBinding("list_item", textTemplate),
                indexBinding: declareNamedBinding("list_index", int32Template),
                appearance: null,
                content: null,
              ),
            ),
          ),
        if (show("add_item"))
          skir.AxisChild.wrapFixed(
            presentationNode(
              "authored.scalar.interaction.add_item",
              skir.PresentationElement.createButton(
                label: textLiteral("Add item"),
                action: skir.EditorAction.wrapLocal(
                  skir.LocalEditorAction.createAppendListItem(
                    target: _fieldReference("items"),
                    value: textLiteral("Item 4"),
                  ),
                ),
                appearance: null,
                icon: null,
              ),
            ),
          ),
        if (show("map"))
          skir.AxisChild.wrapFixed(
            presentationNode(
              "authored.scalar.interaction.map",
              skir.PresentationElement.createMapInput(
                control: _controlRef(_fieldReference("metadata"), "Metadata"),
                keyPresentation: null,
                valuePresentation: null,
                allowAdd: true,
                allowRemove: true,
                keyBinding: declareNamedBinding("map_key", textTemplate),
                valueBinding: declareNamedBinding("map_value", textTemplate),
                appearance: null,
                content: null,
              ),
            ),
          ),
        if (show("add_row"))
          skir.AxisChild.wrapFixed(
            presentationNode(
              "authored.scalar.interaction.add_row",
              skir.PresentationElement.createButton(
                label: textLiteral("Add entry"),
                action: skir.EditorAction.wrapLocal(
                  skir.LocalEditorAction.createInsertMapRow(
                    target: _fieldReference("metadata"),
                    key: textLiteral("chapter"),
                    value: textLiteral("Arrival"),
                  ),
                ),
                appearance: null,
                icon: null,
              ),
            ),
          ),
        if (show("reload"))
          skir.AxisChild.wrapFixed(
            presentationNode(
              "authored.scalar.interaction.reload",
              skir.PresentationElement.createButton(
                label: textLiteral("Reload from Realm"),
                action: skir.EditorAction.wrapRealm(
                  skir.RealmEditorAction.createReload(),
                ),
                appearance: null,
                icon: null,
              ),
            ),
          ),
      ],
      layout: skir.AxisChildrenLayout(
        clipOverflow: false,

        spacing: 16,
        mainAxisAlignment: skir.MainAxisAlignment.start,
        crossAxisAlignment: skir.CrossAxisAlignment.stretch,
      ),
    ),
  ),
  header: skir.PresentationHeader(
    binding: skir.BindingRef(
      bindingId: _interactionRoot,
      path: skir.ValuePath(segments: const []),
    ),
    title: skir.PresentationHeaderTitle.wrapText(textLiteral("Quest actions")),
    description: textLiteral("Portable header actions use the current draft"),
    initiallyExpanded: true,
    items: [
      skir.HeaderItem.createButton(
        itemId: skir.HeaderItemId(namespace: "widgetbook", name: "archive"),
        icon: textLiteral("archive"),
        label: textLiteral("Archive"),
        tooltip: textLiteral("Archive quest"),
        action: skir.EditorAction.wrapLocal(
          skir.LocalEditorAction.createSetValue(
            target: _fieldReference("status"),
            value: textLiteral("Archived quest"),
          ),
        ),
        priority: literalExpression(skir.DataValue.wrapInteger("10")),
        visibleIf: null,
        enabledIf: null,
        tone: skir.HeaderActionTone.destructive,
        confirmation: skir.HeaderActionConfirmation(
          title: textLiteral("Archive quest?"),
          message: textLiteral(
            "The quest will no longer be available to players.",
          ),
          confirmationLabel: textLiteral("Archive"),
        ),
        placement: skir.HeaderActionPlacement.end,
      ),
      _statusHeaderButton(
        "duplicate",
        "Duplicate",
        skir.HeaderActionPlacement.afterTitle,
      ),
      _statusHeaderButton(
        "preview",
        "Preview",
        skir.HeaderActionPlacement.afterTitle,
      ),
      _statusHeaderButton(
        "schedule",
        "Schedule",
        skir.HeaderActionPlacement.end,
      ),
      _statusHeaderButton("publish", "Publish", skir.HeaderActionPlacement.end),
      _statusHeaderButton(
        "copy_link",
        "Copy link",
        skir.HeaderActionPlacement.end,
      ),
      _statusHeaderButton("history", "History", skir.HeaderActionPlacement.end),
      skir.HeaderItem.createButton(
        itemId: skir.HeaderItemId(
          namespace: "widgetbook",
          name: "unavailable_label",
        ),
        icon: textLiteral("material-symbols:edit"),
        // A field the quest does not have: the label is missing data.
        label: skir.ExpressionNode.createInput(
          binding: _interactionRoot,
          path: editorRootPath.field("missing_header_value"),
        ),
        tooltip: null,
        action: skir.EditorAction.wrapLocal(
          skir.LocalEditorAction.createSetValue(
            target: _fieldReference("status"),
            value: textLiteral("Unavailable action selected"),
          ),
        ),
        priority: null,
        visibleIf: null,
        enabledIf: null,
        tone: skir.HeaderActionTone.neutral,
        confirmation: null,
        placement: skir.HeaderActionPlacement.end,
      ),
    ],
    headerPadding: skir.PresentationInsets.createSymmetric(
      horizontal: 8,
      vertical: 4,
    ),
    contentPadding: skir.PresentationInsets.wrapAll(8),
  ),
);

skir.HeaderItem _statusHeaderButton(
  String name,
  String label,
  skir.HeaderActionPlacement placement,
) => skir.HeaderItem.createButton(
  itemId: skir.HeaderItemId(namespace: "widgetbook", name: name),
  icon: textLiteral("material-symbols:edit"),
  label: textLiteral(label),
  tooltip: textLiteral(label),
  action: skir.EditorAction.wrapLocal(
    skir.LocalEditorAction.createSetValue(
      target: _fieldReference("status"),
      value: textLiteral("$label selected"),
    ),
  ),
  priority: null,
  visibleIf: null,
  enabledIf: null,
  tone: skir.HeaderActionTone.neutral,
  confirmation: null,
  placement: placement,
);

final _reorderableListItem = skir.PresentationNode(
  nodeId: "interaction.list.item",
  properties: skir.PresentationProperties.defaultInstance,
  element: skir.PresentationElement.createText(
    value: skir.ExpressionNode.createInput(
      binding: _listItemBinding,
      path: skir.ValuePath(segments: const []),
    ),
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
  header: skir.PresentationHeader(
    binding: skir.BindingRef(
      bindingId: _listItemBinding,
      path: skir.ValuePath(segments: const []),
    ),
    title: skir.PresentationHeaderTitle.wrapText(
      skir.ExpressionNode.createInput(
        binding: _listItemBinding,
        path: skir.ValuePath(segments: const []),
      ),
    ),
    description: null,
    initiallyExpanded: false,
    items: [
      skir.HeaderItem.createReorderHandle(
        itemId: skir.HeaderItemId(
          namespace: "widgetbook",
          name: "reorder_item",
        ),
        label: textLiteral("Reorder item"),
        source: skir.BindingRef(
          bindingId: _listItemBinding,
          path: skir.ValuePath(segments: const []),
        ),
        tooltip: textLiteral("Reorder item"),
        visibleIf: null,
        enabledIf: null,
      ),
    ],
    headerPadding: null,
    contentPadding: null,
  ),
);

skir.TabItem _tab(String id, String label, String content) => skir.TabItem(
  tabId: id,
  label: textLiteral(label),
  child: presentationText("tab.$id", textLiteral(content)),
  icon: null,
);

AuthoringEdit _interactionDraft() {
  final configuration = _namedType("InteractionStory");
  final catalog = _interactionCatalog();
  return AuthoringEdit(
    generation: catalog.snapshot.generation,
    catalog: catalog,
    resources: [
      skir.AuthoringResource(
        id: _interactionResource,
        content: skir.AuthoringRecord(
          types: const [],
          configuration: skir.TypeSelection.wrapComplete(configuration),
          fields: [
            skir.FieldValue(
              name: "status",
              value: skir.DataValue.wrapStringValue("Active quest"),
            ),
            skir.FieldValue(
              name: "enabled",
              value: skir.DataValue.wrapBoolean(true),
            ),
            skir.FieldValue(
              name: "items",
              value: skir.DataValue.createNamed(
                actualType: _namedType("StoryList"),
                payload: skir.DataValue.createListValue(
                  items: [
                    _listItem("one", "Item 1"),
                    _listItem("two", "Item 2"),
                    _listItem("three", "Item 3"),
                  ],
                ),
              ),
            ),
            skir.FieldValue(
              name: "metadata",
              value: skir.DataValue.createNamed(
                actualType: _namedType("StoryMap"),
                payload: skir.DataValue.createMapValue(
                  rows: [
                    _mapRow("intro", "intro", "Welcome"),
                    _mapRow("outro", "outro", "Farewell"),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ],
    links: const [],
  );
}

CheckedEditorCatalog _interactionCatalog() {
  final root = _namedType("InteractionStory").definition;
  final list = _namedType("StoryList").definition;
  final map = _namedType("StoryMap").definition;
  final text = skir.TypeTemplate.wrapScalar(skir.ScalarKind.text);
  final fields = {
    "status": text,
    "enabled": skir.TypeTemplate.wrapScalar(skir.ScalarKind.boolean),
    "items": skir.TypeTemplate.createNamed(
      definition: list,
      arguments: const [],
    ),
    "metadata": skir.TypeTemplate.createNamed(
      definition: map,
      arguments: const [],
    ),
  };
  skir.PublishedType published(
    skir.TypeDefinitionId id,
    skir.RepresentationTemplate representation, {
    List<skir.EffectiveFieldTemplate> effective = const [],
  }) => skir.PublishedType(
    searchKey: null,
    placementField: null,
    definition: skir.TypeDefinition(
      id: id,
      parameters: const [],
      representation: representation,
      parents: const [],
    ),
    display: defaultTypeDisplay(""),
    status: skir.DeclarationStatus.ready,
    effectiveFields: effective,
    ancestorTemplates: const [],
  );
  return CheckedEditorCatalog(
    skir.EditorCatalog(
      resourceDisplays: const [],
      generation: skir.CatalogGeneration(value: "catalog:interaction_story"),
      types: [
        published(
          root,
          skir.RepresentationTemplate.createRecord(
            form: skir.RecordForm.concrete,
            fields: [
              for (final field in fields.entries)
                skir.FieldDeclaration(
                  owner: skir.FieldOwner(definition: root, name: field.key),
                  type: field.value,
                  overrides: const [],
                  hasConstructorDefault: false,
                ),
            ],
          ),
          effective: [
            for (final field in fields.entries)
              skir.EffectiveFieldTemplate(
                key: field.key,
                owner: skir.FieldOwner(definition: root, name: field.key),
                type: field.value,
                rules: const [],
              ),
          ],
        ),
        published(
          list,
          skir.RepresentationTemplate.createSequence(
            item: text,
            kind: skir.CollectionKind.list,
          ),
        ),
        published(
          map,
          skir.RepresentationTemplate.createMapping(key: text, value: text),
        ),
      ],
      realmRoot: skir.TypeDefinitionId.defaultInstance,
      resourceOperations: const [],
      relations: const [],
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
}

skir.ListItem _listItem(String id, String value) => skir.ListItem(
  id: skir.ItemId(value: id),
  value: skir.DataValue.wrapStringValue(value),
);

skir.MapRow _mapRow(String id, String key, String value) => skir.MapRow(
  id: skir.ItemId(value: id),
  key: skir.DataValue.wrapStringValue(key),
  value: skir.DataValue.wrapStringValue(value),
);

skir.NamedTypeUse _namedType(String name) => skir.NamedTypeUse(
  definition: skir.TypeDefinitionId(
    typeId: skir.TypeId.wrapQualified(
      skir.QualifiedTypeId(namespace: "widgetbook", name: name),
    ),
    revision: 1,
  ),
  arguments: const [],
);

skir.ValuePath _fieldPath(String name) =>
    skir.ValuePath(segments: [skir.PathSegment.createField(name: name)]);

skir.BindingRef _fieldReference(String name) =>
    skir.BindingRef(bindingId: _interactionRoot, path: _fieldPath(name));

skir.BoundControl _controlRef(skir.BindingRef reference, String label) =>
    skir.BoundControl(
      binding: reference,
      label: textLiteral(label),
      description: null,
      prefix: null,
      semanticLabel: null,
    );

final _interactionRoot = configuredValueBindingId;
final _listItemBinding = skir.ExpressionBindingId(value: "list_item");
final _interactionResource = skir.ResourceId(value: "interaction:widgetbook");

@widgetbook.UseCase(
  name: "Resource heading",
  type: PortablePresentationNodeRenderer,
)
Widget resourceHeadingUseCase(BuildContext context) {
  return _headingStory(
    context,
    ResourceHeadingGallery(
      title: context.knobs.string(
        label: "Title",
        initialValue: "A long book title adapts its inspector",
      ),
      multiple: context.knobs.boolean(label: "Multiple selection"),
    ),
  );
}

@widgetbook.UseCase(
  name: "Fitted rich text",
  type: PortablePresentationNodeRenderer,
)
Widget fittedRichTextUseCase(BuildContext context) {
  return _headingStory(context, const FittedRichText());
}

Widget _headingStory(BuildContext context, Widget child) => Story(
  const [],
  at: PanelLocation.component(
    SizedBox(
      width: context.knobs.double.slider(
        label: "Width",
        initialValue: 320,
        min: 80,
        max: 800,
      ),
      child: child,
    ),
  ),
);

/// A resource heading as an inspector shows it for one selected resource or
/// several.
final class ResourceHeadingGallery extends HookWidget {
  const ResourceHeadingGallery({
    this.title = "A long book title that adapts to its inspector",
    this.multiple = false,
    super.key,
  });
  final String title;
  final bool multiple;

  @override
  Widget build(BuildContext context) {
    final operations = useMemoized(PortableOperationResults.new);
    useEffect(() => operations.dispose, [operations]);
    return PortablePresentationNodeRenderer(
      node: title.portableExpression.resourceHeading(
        id: "book.heading",
        color: Colors.blue.portableExpression,
        identifier: "book:019d1c2a8f7b7cc18c2a4a7b2fd1e281".portableExpression,
      ),
      scope: PortablePresentationScope(
        operations: operations,
        bindings: {
          panelSelectionCountInput.binding.id: PortableExpressionBinding(
            value: skir.DataValue.wrapInteger(multiple ? "2" : "1"),
          ),
        },
        budget: skir.EvaluationBudget(maxSteps: 1000, maxCollectionItems: 100),
      ),
    );
  }
}

/// Authored rich text that fits between 18 and 32 points within two lines.
final class FittedRichText extends HookWidget {
  const FittedRichText({super.key});

  @override
  Widget build(BuildContext context) {
    final operations = useMemoized(PortableOperationResults.new);
    useEffect(() => operations.dispose, [operations]);
    final rich =
        (skir.RichTextContent.mutable()
              ..runs = [
                skir.TextRun(
                  text: "Rich text with ".portableExpression,
                  style: null,
                ),
                skir.TextRun(
                  text: "authored emphasis".portableExpression,
                  style: skir.TextStyleOverride(
                    color: skir.PresentationColor.wrapValue(
                      Colors.orange.portableExpression,
                    ),
                    fontWeight: skir.ExpressionNode.wrapLiteral(
                      skir.DataValue.wrapFloat(700),
                    ),
                    fontItalic: null,
                    decoration: null,
                  ),
                ),
              ]
              ..sizing = skir.TextSizing.createFit(
                minimum: skir.ExpressionNode.wrapLiteral(
                  skir.DataValue.wrapFloat(18),
                ),
                maximum: skir.ExpressionNode.wrapLiteral(
                  skir.DataValue.wrapFloat(32),
                ),
              )
              ..paragraph = skir.TextParagraph(
                maxLines: 2,
                overflow: skir.PresentationTextOverflow.ellipsis,
                softWrap: true,
                selectable: true,
                tone: skir.PresentationTextTone.primary,
              ))
            .toFrozen();
    return PortablePresentationNodeRenderer(
      node: skir.PresentationNode(
        nodeId: "rich",
        properties: skir.PresentationProperties.defaultInstance,
        header: null,
        element: skir.PresentationElement.wrapRichText(rich),
      ),
      scope: PortablePresentationScope(
        operations: operations,
        bindings: const {},
        budget: skir.EvaluationBudget(maxSteps: 1000, maxCollectionItems: 100),
      ),
    );
  }
}
