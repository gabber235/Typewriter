import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;

@widgetbook.UseCase(
  name: "Scalar controls",
  type: PortablePresentationNodeRenderer,
)
Widget authoredPresentationRendererUseCase(BuildContext context) => FakeApp(
  child: Scaffold(
    body: Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: SizedBox(
          width: context.knobs.double.slider(
            label: "Editor width",
            initialValue: 720,
            min: 360,
            max: 980,
          ),
          child: const AuthoredScalarGallery(),
        ),
      ),
    ),
  ),
);

@widgetbook.UseCase(
  name: "Layouts and actions",
  type: PortablePresentationNodeRenderer,
)
Widget authoredPresentationInteractionUseCase(BuildContext context) =>
    const FakeApp(
      child: Scaffold(
        body: SingleChildScrollView(
          padding: EdgeInsets.all(24),
          child: AuthoredInteractionGallery(),
        ),
      ),
    );

final class AuthoredScalarGallery extends StatefulWidget {
  const AuthoredScalarGallery({super.key});

  @override
  State<AuthoredScalarGallery> createState() => _AuthoredScalarGalleryState();
}

final class _AuthoredScalarGalleryState extends State<AuthoredScalarGallery> {
  final Map<skir.ExpressionBindingId, skir.DataValue> _values = {
    _title: skir.DataValue.wrapStringValue("Quest objective"),
    _count: skir.DataValue.wrapInteger("3"),
    _enabled: skir.DataValue.wrapBoolean(true),
    _intensity: skir.DataValue.wrapFloat(0.35),
    _startsAt: skir.DataValue.wrapTimestamp(DateTime.utc(1965, 4, 9, 10, 30)),
    _duration: skir.DataValue.unfilled,
    _color: skir.DataValue.wrapInteger(0xFF008080.toString()),
    _bytes: skir.DataValue.unfilled,
  };

  late final _host = BoundPresentationHost(
    catalog: skir.EditorCatalogWireSnapshot.defaultInstance
        .asTrustedLocalCatalog(),
    root: () => _gallery,
    bindings: [
      _binding(_title, skir.TypeUse.wrapScalar(skir.ScalarKind.text)),
      _binding(
        _count,
        skir.TypeUse.wrapScalar(
          skir.ScalarKind.createInteger(
            width: skir.IntegerWidth.signedThirtyTwo,
          ),
        ),
      ),
      _binding(_enabled, skir.TypeUse.wrapScalar(skir.ScalarKind.boolean)),
      _binding(
        _intensity,
        skir.TypeUse.wrapScalar(
          skir.ScalarKind.createFloat(width: skir.FloatWidth.sixtyFour),
        ),
      ),
      _binding(_startsAt, skir.TypeUse.wrapScalar(skir.ScalarKind.timestamp)),
      _binding(_duration, skir.TypeUse.wrapScalar(skir.ScalarKind.duration)),
      _binding(
        _color,
        skir.TypeUse.wrapScalar(
          skir.ScalarKind.createInteger(
            width: skir.IntegerWidth.unsignedThirtyTwo,
          ),
        ),
      ),
      _binding(_bytes, skir.TypeUse.wrapScalar(skir.ScalarKind.bytes)),
    ],
    budget: skir.EvaluationBudget(maxSteps: 1000, maxCollectionItems: 1000),
  );

  BoundPresentationBinding _binding(
    skir.ExpressionBindingId id,
    skir.TypeUse use,
  ) => BoundPresentationBinding(
    id: id,
    use: use,
    read: (_) => _values[id],
    write: (_, value) async {
      setState(() => _values[id] = value);
      return const PortablePresentationWriteApplied();
    },
  );

  @override
  void dispose() {
    _host.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PortablePresentationRenderer(host: _host);
  }
}

final class AuthoredInteractionGallery extends StatefulWidget {
  const AuthoredInteractionGallery({super.key});

  @override
  State<AuthoredInteractionGallery> createState() =>
      _AuthoredInteractionGalleryState();
}

final class _AuthoredInteractionGalleryState
    extends State<AuthoredInteractionGallery> {
  late final _transport = ScriptedAuthoringTransport(
    AsyncData(_interactionDraft().toDocument()),
  );
  final _submissions = ScopedWorkSession();
  late final _workspace = RealmEditing(
    persistence: _transport.persistence,
    submissions: _submissions,
    initial: _transport.observation.requireValue,
  );
  late final _binding = _workspace.attach(
    _interactionResource,
    policy: EditorCommitPolicy.applyResource,
  );
  late final _host = AuthoredPresentationHost(
    resource: _interactionResource,
    source: _workspace.document,
    material: skir.PresentationMaterial.defaultInstance,
    role: skir.PresentationRole.workspaceEditor,
    budget: skir.EvaluationBudget(maxSteps: 1000, maxCollectionItems: 1000),
    capabilities: const PortablePresentationCapabilities(),
    edit: _binding,
  );
  void _updated() {
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _operations.onStatus = (status) {
      if (mounted) {
        setState(() => _status = status);
      }
    };
    _workspace.addListener(_updated);
  }

  @override
  void dispose() {
    _workspace.removeListener(_updated);
    _operations.dispose();
    _host.dispose();
    _binding.detach();
    _workspace.dispose();
    _transport.dispose();
    _submissions.dispose();
    super.dispose();
  }

  final _operations = PortableOperationResults();
  String? _status;

  @override
  Widget build(BuildContext context) {
    final record = _workspace.document.resource(_interactionResource)!;
    _host.update(
      source: _workspace.document,
      capabilities: const PortablePresentationCapabilities(),
      available: true,
      readOnly: false,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PortablePresentationNodeRenderer(
          node: _interactionGallery,
          scope: PortablePresentationScope(
            operations: _operations,
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
            reportStatus: (status) => setState(() => _status = status),
            host: _host,
          ),
        ),
        if (_status case final status?) ...[
          const SizedBox(height: 12),
          Text(status, key: const ValueKey("authored.action.status")),
        ],
      ],
    );
  }
}

final _gallery = skir.PresentationNode(
  nodeId: "authored.scalar.gallery",
  properties: skir.PresentationProperties.defaultInstance,
  element: skir.PresentationElement.wrapChildren(
    skir.ChildrenElement.createGrid(
      children: [
        presentationNode(
          "authored.scalar.title",
          skir.PresentationElement.createTextInput(
            control: _control(_title, "Title"),
            content:
                (skir.InputContent.mutable()
                      ..placeholder = textLiteral("Quest objective"))
                    .toFrozen(),
            appearance: null,
            entry: null,
            mappings: null,
            options: skir.TextEditingOptions.defaultInstance,
          ),
        ),
        presentationNode(
          "authored.scalar.count",
          skir.PresentationElement.wrapNumericInput(
            (skir.NumericControl.mutable()..control = _control(_count, "Count"))
                .toFrozen(),
          ),
        ),
        presentationNode(
          "authored.scalar.enabled",
          skir.PresentationElement.wrapToggleInput(
            (skir.ToggleControl.mutable()
                  ..control = _control(_enabled, "Enabled"))
                .toFrozen(),
          ),
        ),
        presentationNode(
          "authored.scalar.intensity",
          skir.PresentationElement.createSliderInput(
            control: _control(_intensity, "Intensity"),
            minimum: literalExpression(skir.DataValue.wrapFloat(0)),
            maximum: literalExpression(skir.DataValue.wrapFloat(1)),
            divisions: literalExpression(skir.DataValue.wrapInteger("20")),
            appearance: null,
            mappings: null,
            options: null,
          ),
        ),
        presentationNode(
          "authored.scalar.startsAt",
          skir.PresentationElement.createDateTimeInput(
            control: _control(_startsAt, "Starts at"),
            includeDate: true,
            includeTime: true,
            appearance: null,
            content: null,
            entry: null,
            mappings: null,
            popup: null,
            options: null,
          ),
        ),
        presentationNode(
          "authored.scalar.duration",
          skir.PresentationElement.wrapDurationInput(
            (skir.DurationControl.mutable()
                  ..control = _control(_duration, "Duration in milliseconds"))
                .toFrozen(),
          ),
        ),
        presentationNode(
          "authored.scalar.color",
          skir.PresentationElement.createColorInput(
            control: _control(_color, "Color"),
            includeAlpha: true,
            appearance: null,
            content: null,
            entry: null,
            mappings: null,
            popup: null,
            options: null,
          ),
        ),
        presentationNode(
          "authored.scalar.bytes",
          skir.PresentationElement.wrapBytesInput(
            (skir.BytesControl.mutable()
                  ..control = _control(_bytes, "Binary payload"))
                .toFrozen(),
          ),
        ),
      ],
      layout: skir.GridChildrenLayout(
        columns: 2,
        horizontalSpacing: 16,
        verticalSpacing: 16,
      ),
    ),
  ),
  header: null,
);

final _interactionGallery = skir.PresentationNode(
  nodeId: "authored.interaction.gallery",
  properties: skir.PresentationProperties.defaultInstance,
  element: skir.PresentationElement.wrapChildren(
    skir.ChildrenElement.createColumn(
      children: [
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
        skir.AxisChild.wrapFixed(
          presentationNode(
            "authored.scalar.interaction.list",
            skir.PresentationElement.createListInput(
              control: _controlRef(_fieldReference("items"), "Items"),
              itemPresentation: _reorderableListItem,
              allowAdd: true,
              allowRemove: true,
              allowReorder: true,
              itemBindingId: skir.ExpressionBindingId(value: "list_item"),
              indexBindingId: skir.ExpressionBindingId(value: "list_index"),
              appearance: null,
              content: null,
            ),
          ),
        ),
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
        skir.AxisChild.wrapFixed(
          presentationNode(
            "authored.scalar.interaction.map",
            skir.PresentationElement.createMapInput(
              control: _controlRef(_fieldReference("metadata"), "Metadata"),
              keyPresentation: null,
              valuePresentation: null,
              allowAdd: true,
              allowRemove: true,
              keyBindingId: skir.ExpressionBindingId(value: "map_key"),
              valueBindingId: skir.ExpressionBindingId(value: "map_value"),
              appearance: null,
              content: null,
            ),
          ),
        ),
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
        label: skir.ExpressionNode.createInput(
          binding: skir.ExpressionBindingId(value: "missing_header_value"),
          path: skir.ValuePath(segments: const []),
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
        definition: skir.ResourceDefinitionId(value: "widgetbook.interaction"),
        content: skir.AuthoringRecord(
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
    definition: skir.TypeDefinition(
      id: id,
      parameters: const [],
      representation: representation,
      parents: const [],
    ),
    display: null,
    status: skir.DeclarationStatus.ready,
    effectiveFields: effective,
    ancestorTemplates: const [],
  );
  return CheckedEditorCatalog(
    skir.EditorCatalogWireSnapshot(
      generation: skir.CatalogGeneration(value: "catalog:interaction_story"),
      types: [
        published(
          root,
          skir.RepresentationTemplate.createRecord(
            abstract_: false,
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
      resourceDefinitions: [
        skir.AuthoringResourceDefinition(
          id: skir.ResourceDefinitionId(value: "widgetbook.interaction"),
          root: root,
          navigationHandler: skir.AuthoringNavigationHandler.generic,
        ),
      ],
      resourceOperations: const [],
      resourceOperationContributions: const [],
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

skir.BoundControl _control(skir.ExpressionBindingId binding, String label) =>
    skir.BoundControl(
      binding: skir.BindingRef(
        bindingId: binding,
        path: skir.ValuePath(segments: const []),
      ),
      label: literalExpression(skir.DataValue.wrapStringValue(label)),
      description: null,
      prefix: null,
      semanticLabel: null,
    );

final _title = skir.ExpressionBindingId(value: "title");
final _count = skir.ExpressionBindingId(value: "count");
final _enabled = skir.ExpressionBindingId(value: "enabled");
final _intensity = skir.ExpressionBindingId(value: "intensity");
final _startsAt = skir.ExpressionBindingId(value: "starts_at");
final _duration = skir.ExpressionBindingId(value: "duration");
final _color = skir.ExpressionBindingId(value: "color");
final _bytes = skir.ExpressionBindingId(value: "bytes");
final _interactionRoot = configuredValueBindingId;
final _listItemBinding = skir.ExpressionBindingId(value: "list_item");
final _interactionResource = skir.ResourceId(value: "interaction:widgetbook");

@widgetbook.UseCase(
  name: "Resource headings and fitted rich text",
  type: PortablePresentationNodeRenderer,
)
Widget resourceHeadingUseCase(BuildContext context) {
  final width = context.knobs.double.slider(
    label: "Width",
    initialValue: 320,
    min: 80,
    max: 800,
  );
  final multiple = context.knobs.boolean(
    label: "Multiple selection",
    initialValue: false,
  );
  final title = context.knobs.string(
    label: "Title",
    initialValue: "A long book title that adapts to its inspector",
  );
  return FakeApp(
    child: Scaffold(
      body: SingleChildScrollView(
        child: Align(
          alignment: Alignment.topLeft,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: SizedBox(
              width: width,
              child: ResourceHeadingGallery(title: title, multiple: multiple),
            ),
          ),
        ),
      ),
    ),
  );
}

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
    final scope = PortablePresentationScope(
      operations: operations,
      bindings: {
        presentationSelectionCountBindingId: PortableExpressionBinding(
          value: skir.DataValue.wrapInteger(multiple ? "2" : "1"),
        ),
      },
      budget: skir.EvaluationBudget(maxSteps: 1000, maxCollectionItems: 100),
    );
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 16,
      children: [
        PortablePresentationNodeRenderer(
          node: title.portableExpression.resourceHeading(
            id: "book.heading",
            color: Colors.blue.portableExpression,
            identifier:
                "book:019d1c2a8f7b7cc18c2a4a7b2fd1e281".portableExpression,
          ),
          scope: scope,
        ),
        const Text("Normal fields and section labels remain visible"),
        PortablePresentationNodeRenderer(
          node: skir.PresentationNode(
            nodeId: "rich",
            properties: skir.PresentationProperties.defaultInstance,
            header: null,
            element: skir.PresentationElement.wrapRichText(rich),
          ),
          scope: scope,
        ),
      ],
    );
  }
}
