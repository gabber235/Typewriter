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

  @override
  Widget build(BuildContext context) => PortablePresentationNodeRenderer(
    node: _gallery,
    scope: PortablePresentationScope(
      bindings: {
        for (final entry in _values.entries)
          entry.key: PortableExpressionBinding(value: entry.value),
      },
      budget: skir.EvaluationBudget(maxSteps: 1000, maxCollectionItems: 1000),
      setBinding: (reference, value) {
        setState(() => _values[reference.bindingId] = value);
      },
    ),
  );
}

final class AuthoredInteractionGallery extends StatefulWidget {
  const AuthoredInteractionGallery({super.key});

  @override
  State<AuthoredInteractionGallery> createState() =>
      _AuthoredInteractionGalleryState();
}

final class _AuthoredInteractionGalleryState
    extends State<AuthoredInteractionGallery> {
  late final AuthoredDraft _draft = _interactionDraft();
  String? _status;

  @override
  Widget build(BuildContext context) {
    final record = _draft.resource(_interactionResource)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PortablePresentationNodeRenderer(
          node: _interactionGallery,
          scope: PortablePresentationScope(
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
            setBinding: (reference, value) {
              final location = skir.ValueLocation(
                resource: _interactionResource,
                path: reference.path,
              );
              _draft.set(location, value);
              setState(() {});
            },
            authoring: AuthoredDraftAuthoringDocument(_draft),
            resource: _interactionResource,
            onDraftChanged: () => setState(() {}),
            reportStatus: (status) => setState(() => _status = status),
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
        _node(
          "title",
          skir.PresentationElement.createTextInput(
            control: _control(_title, "Title"),
            multiline: false,
            placeholder: _literal("Quest objective"),
            inputFormatters: const [],
          ),
        ),
        _node(
          "count",
          skir.PresentationElement.wrapNumericInput(_control(_count, "Count")),
        ),
        _node(
          "enabled",
          skir.PresentationElement.wrapToggleInput(
            _control(_enabled, "Enabled"),
          ),
        ),
        _node(
          "intensity",
          skir.PresentationElement.createSliderInput(
            control: _control(_intensity, "Intensity"),
            minimum: _literal(skir.DataValue.wrapFloat(0)),
            maximum: _literal(skir.DataValue.wrapFloat(1)),
            divisions: _literal(skir.DataValue.wrapInteger("20")),
          ),
        ),
        _node(
          "startsAt",
          skir.PresentationElement.createDateTimeInput(
            control: _control(_startsAt, "Starts at"),
            includeDate: true,
            includeTime: true,
          ),
        ),
        _node(
          "duration",
          skir.PresentationElement.wrapDurationInput(
            _control(_duration, "Duration in milliseconds"),
          ),
        ),
        _node(
          "color",
          skir.PresentationElement.createColorInput(
            control: _control(_color, "Color"),
            includeAlpha: true,
          ),
        ),
        _node(
          "bytes",
          skir.PresentationElement.wrapBytesInput(
            _control(_bytes, "Binary payload"),
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
          _node(
            "interaction.status",
            skir.PresentationElement.createTextInput(
              control: _controlRef(_fieldReference("status"), "Status"),
              multiline: false,
              placeholder: null,
              inputFormatters: const [],
            ),
          ),
        ),
        skir.AxisChild.wrapFixed(
          _node(
            "interaction.enabled",
            skir.PresentationElement.wrapToggleInput(
              _controlRef(_fieldReference("enabled"), "Show details"),
            ),
          ),
        ),
        skir.AxisChild.wrapFixed(
          _node(
            "interaction.conditional",
            skir.PresentationElement.createConditional(
              condition: skir.ExpressionNode.createRead(
                binding: _interactionRoot,
                path: _fieldPath("enabled"),
              ),
              whenTrue: _textNode("conditional.visible", "Details are visible"),
              whenFalse: _textNode("conditional.hidden", "Details are hidden"),
            ),
          ),
        ),
        skir.AxisChild.wrapFixed(
          _node(
            "interaction.tabs",
            skir.PresentationElement.createTabs(
              tabs: [
                _tab("general", "General", "General settings"),
                _tab("advanced", "Advanced", "Advanced settings"),
                _tab("history", "History", "Change history"),
                _tab("preview", "Preview", "Preview content"),
              ],
              initiallySelectedTabId: "general",
            ),
          ),
        ),
        skir.AxisChild.wrapFixed(
          _node(
            "interaction.list",
            skir.PresentationElement.createListInput(
              control: _controlRef(_fieldReference("items"), "Items"),
              itemPresentation: _reorderableListItem,
              allowAdd: true,
              allowRemove: true,
              allowReorder: true,
              itemBindingId: skir.ExpressionBindingId(value: "list_item"),
              indexBindingId: skir.ExpressionBindingId(value: "list_index"),
            ),
          ),
        ),
        skir.AxisChild.wrapFixed(
          _node(
            "interaction.add_item",
            skir.PresentationElement.createButton(
              label: _literal("Add item"),
              action: skir.EditorAction.wrapLocal(
                skir.LocalEditorAction.createAppendListItem(
                  target: _fieldReference("items"),
                  value: _literal("Item 4"),
                ),
              ),
            ),
          ),
        ),
        skir.AxisChild.wrapFixed(
          _node(
            "interaction.map",
            skir.PresentationElement.createMapInput(
              control: _controlRef(_fieldReference("metadata"), "Metadata"),
              keyPresentation: null,
              valuePresentation: null,
              allowAdd: true,
              allowRemove: true,
              keyBindingId: skir.ExpressionBindingId(value: "map_key"),
              valueBindingId: skir.ExpressionBindingId(value: "map_value"),
            ),
          ),
        ),
        skir.AxisChild.wrapFixed(
          _node(
            "interaction.add_row",
            skir.PresentationElement.createButton(
              label: _literal("Add entry"),
              action: skir.EditorAction.wrapLocal(
                skir.LocalEditorAction.createInsertMapRow(
                  target: _fieldReference("metadata"),
                  key: _literal("chapter"),
                  value: _literal("Arrival"),
                ),
              ),
            ),
          ),
        ),
        skir.AxisChild.wrapFixed(
          _node(
            "interaction.reload",
            skir.PresentationElement.createButton(
              label: _literal("Reload from Realm"),
              action: skir.EditorAction.wrapRealm(
                skir.RealmEditorAction.createReload(),
              ),
            ),
          ),
        ),
      ],
      layout: skir.AxisChildrenLayout(
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
    title: skir.PresentationHeaderTitle.wrapText(_literal("Quest actions")),
    description: _literal("Portable header actions use the current draft"),
    initiallyExpanded: true,
    items: [
      skir.HeaderItem.createButton(
        itemId: skir.HeaderItemId(namespace: "widgetbook", name: "archive"),
        icon: _literal("archive"),
        label: _literal("Archive"),
        tooltip: _literal("Archive quest"),
        action: skir.EditorAction.wrapLocal(
          skir.LocalEditorAction.createSetValue(
            target: _fieldReference("status"),
            value: _literal("Archived quest"),
          ),
        ),
        priority: _literal(skir.DataValue.wrapInteger("10")),
        visibleIf: null,
        enabledIf: null,
        tone: skir.HeaderActionTone.destructive,
        confirmation: skir.HeaderActionConfirmation(
          title: _literal("Archive quest?"),
          message: _literal(
            "The quest will no longer be available to players.",
          ),
          confirmationLabel: _literal("Archive"),
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
        icon: _literal("edit"),
        label: skir.ExpressionNode.createRead(
          binding: skir.ExpressionBindingId(value: "missing_header_value"),
          path: skir.ValuePath(segments: const []),
        ),
        tooltip: null,
        action: skir.EditorAction.wrapLocal(
          skir.LocalEditorAction.createSetValue(
            target: _fieldReference("status"),
            value: _literal("Unavailable action selected"),
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
  icon: _literal("edit"),
  label: _literal(label),
  tooltip: _literal(label),
  action: skir.EditorAction.wrapLocal(
    skir.LocalEditorAction.createSetValue(
      target: _fieldReference("status"),
      value: _literal("$label selected"),
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
    value: skir.ExpressionNode.createRead(
      binding: _listItemBinding,
      path: skir.ValuePath(segments: const []),
    ),
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
    paragraph: skir.TextParagraph.defaultInstance,
  ),
  header: skir.PresentationHeader(
    binding: skir.BindingRef(
      bindingId: _listItemBinding,
      path: skir.ValuePath(segments: const []),
    ),
    title: skir.PresentationHeaderTitle.wrapText(
      skir.ExpressionNode.createRead(
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
        label: _literal("Reorder item"),
        source: skir.BindingRef(
          bindingId: _listItemBinding,
          path: skir.ValuePath(segments: const []),
        ),
        tooltip: _literal("Reorder item"),
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
  label: _literal(label),
  child: _textNode("tab.$id", content),
);

skir.PresentationNode _textNode(String id, String value) =>
    skir.PresentationNode(
      nodeId: id,
      properties: skir.PresentationProperties.defaultInstance,
      element: skir.PresentationElement.createText(
        value: _literal(value),
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
        paragraph: skir.TextParagraph.defaultInstance,
      ),
      header: null,
    );

AuthoredDraft _interactionDraft() {
  final configuration = _namedType("InteractionStory");
  return AuthoredDraft(
    generation: skir.CatalogGeneration(value: "catalog:interaction_story"),
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
      label: _literal(label),
      description: null,
      prefix: null,
      semanticLabel: null,
    );

skir.PresentationNode _node(String id, skir.PresentationElement element) =>
    skir.PresentationNode(
      nodeId: "authored.scalar.$id",
      properties: skir.PresentationProperties.defaultInstance,
      element: element,
      header: null,
    );

skir.BoundControl _control(skir.ExpressionBindingId binding, String label) =>
    skir.BoundControl(
      binding: skir.BindingRef(
        bindingId: binding,
        path: skir.ValuePath(segments: const []),
      ),
      label: _literal(skir.DataValue.wrapStringValue(label)),
      description: null,
      prefix: null,
      semanticLabel: null,
    );

skir.ExpressionNode _literal(Object value) => skir.ExpressionNode.wrapLiteral(
  value is skir.DataValue
      ? value
      : skir.DataValue.wrapStringValue(value as String),
);

final _title = skir.ExpressionBindingId(value: "title");
final _count = skir.ExpressionBindingId(value: "count");
final _enabled = skir.ExpressionBindingId(value: "enabled");
final _intensity = skir.ExpressionBindingId(value: "intensity");
final _startsAt = skir.ExpressionBindingId(value: "starts_at");
final _duration = skir.ExpressionBindingId(value: "duration");
final _color = skir.ExpressionBindingId(value: "color");
final _bytes = skir.ExpressionBindingId(value: "bytes");
final _interactionRoot = skir.ExpressionBindingId(value: "interaction_root");
final _listItemBinding = skir.ExpressionBindingId(value: "list_item");
final _interactionResource = skir.ResourceId(value: "interaction:widgetbook");
