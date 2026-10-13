import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;

@widgetbook.UseCase(
  name: "Configured actions",
  type: PortablePresentationRenderer,
)
Widget configuredActionsUseCase(BuildContext context) => configuredActionsStory(
  readOnly: context.knobs.boolean(label: "Read only", initialValue: false),
  width: context.knobs.double.slider(
    label: "Action gallery width",
    initialValue: 640,
    min: 320,
    max: 900,
  ),
);

@widgetbook.UseCase(
  name: "Configured projections",
  type: PortablePresentationRenderer,
)
Widget configuredProjectionsUseCase(BuildContext context) =>
    configuredActionsStory(
      projections: true,
      readOnly: context.knobs.boolean(label: "Read only", initialValue: false),
      width: context.knobs.double.slider(
        label: "Projection gallery width",
        initialValue: 800,
        min: 320,
        max: 1000,
      ),
    );

@widgetbook.UseCase(
  name: "Configured displays",
  type: PortablePresentationRenderer,
)
Widget configuredDisplaysUseCase(BuildContext context) =>
    configuredActionsStory(
      displays: true,
      width: context.knobs.double.slider(
        label: "Display gallery width",
        initialValue: 640,
        min: 320,
        max: 900,
      ),
    );

Widget configuredActionsStory({
  bool readOnly = false,
  bool projections = false,
  bool displays = false,
  double width = 640,
}) => FakeApp(
  child: Material(
    child: Center(
      child: SizedBox(
        width: width,
        height: projections ? 650 : 420,
        child: ConfiguredActionGallery(
          readOnly: readOnly,
          projections: projections,
          displays: displays,
        ),
      ),
    ),
  ),
);

class ConfiguredActionGallery extends HookWidget {
  const ConfiguredActionGallery({
    this.readOnly = false,
    this.projections = false,
    this.displays = false,
    super.key,
  });
  final bool readOnly;
  final bool projections;
  final bool displays;
  @override
  Widget build(BuildContext context) {
    final host = useMemoized(
      () => _GalleryHost(
        readOnly: readOnly,
        projections: projections,
        displays: displays,
      ),
      [readOnly, projections, displays],
    );
    useEffect(() => host.dispose, [host]);
    return PortablePresentationRenderer(host: host);
  }
}

final _status = skir.ExpressionBindingId(value: "gallery.status");
final _page = skir.ExpressionBindingId(value: "gallery.page");
final _textType = skir.TypeUse.wrapScalar(skir.ScalarKind.text);
final _action = skir.EditorAction.wrapRealm(
  skir.RealmEditorAction.createReload(),
);
skir.ExpressionNode _literal(String value) =>
    skir.ExpressionNode.wrapLiteral(skir.DataValue.wrapStringValue(value));
skir.ExpressionNode _number(double value) =>
    skir.ExpressionNode.wrapLiteral(skir.DataValue.wrapFloat(value));
skir.PresentationColor _paint(int value) => skir.PresentationColor.wrapValue(
  skir.ExpressionNode.wrapLiteral(skir.DataValue.wrapInteger(value.toString())),
);
skir.PresentationNode _node(String id, skir.PresentationElement element) =>
    skir.PresentationNode(
      nodeId: id,
      properties: skir.PresentationProperties.defaultInstance,
      header: null,
      element: element,
    );

skir.ActionAppearance _appearance(skir.ButtonVariant variant) =>
    (skir.ActionAppearance.mutable()
          ..variant = variant
          ..tooltip = _literal("Keyboard accessible action")
          ..appearance =
              (skir.InputAppearance.mutable()
                    ..density = skir.ControlDensity.compact
                    ..radius = skir.PresentationRadius.small
                    ..iconColor = _paint(0xff7354bf)
                    ..valueStyle = (skir.InputTextStyle.mutable()..weight = 600)
                        .toFrozen())
                  .toFrozen())
        .toFrozen();

skir.PresentationNode _actions() {
  final resetIcon = _node(
    "reset.icon",
    skir.PresentationElement.createIcon(
      name: _literal("material-symbols:restart-alt"),
      color: null,
      size: _number(18),
      semanticLabel: null,
    ),
  );
  final menu = skir.MenuElement.mutable()
    ..label = _literal("Options")
    ..appearance = _appearance(skir.ButtonVariant.text)
    ..popup =
        (skir.PopupAppearance.mutable()
              ..minimumWidth = _number(240)
              ..maximumWidth = _number(300)
              ..maximumExtent = _number(280)
              ..padding = skir.PresentationInsets.wrapAll(12)
              ..radius = skir.PresentationRadius.medium)
            .toFrozen()
    ..items = [
      (skir.MenuItem.mutable()
            ..itemId = "apply"
            ..label = _literal("Apply")
            ..action = _action
            ..description = _literal("Apply this action")
            ..icon = (resetIcon.toMutable()..nodeId = "menu.apply.icon")
                .toFrozen())
          .toFrozen(),
      (skir.MenuItem.mutable()
            ..itemId = "separator"
            ..separator = true)
          .toFrozen(),
      (skir.MenuItem.mutable()
            ..itemId = "blocked"
            ..label = _literal("Unavailable")
            ..action = _action
            ..enabledIf = skir.ExpressionNode.wrapLiteral(
              skir.DataValue.wrapBoolean(false),
            )
            ..disabledReason = _literal("A selection is required"))
          .toFrozen(),
    ];
  return _node(
    "actions",
    skir.PresentationElement.wrapChildren(
      skir.ChildrenElement.createColumn(
        layout: skir.AxisChildrenLayout(
          spacing: 16,
          mainAxisAlignment: skir.MainAxisAlignment.start,
          crossAxisAlignment: skir.CrossAxisAlignment.start,
        ),
        children: [
          skir.AxisChild.wrapFixed(
            _node(
              "reset",
              skir.PresentationElement.wrapButton(
                (skir.ButtonElement.mutable()
                      ..label = _literal("Reset")
                      ..action = _action
                      ..appearance = _appearance(skir.ButtonVariant.outlined)
                      ..icon = resetIcon)
                    .toFrozen(),
              ),
            ),
          ),
          skir.AxisChild.wrapFixed(
            _node(
              "default",
              skir.PresentationElement.wrapButton(
                (skir.ButtonElement.mutable()
                      ..label = _literal("Native default")
                      ..action = _action)
                    .toFrozen(),
              ),
            ),
          ),
          skir.AxisChild.wrapFixed(
            _node(
              "icon",
              skir.PresentationElement.wrapIconButton(
                (skir.IconButtonElement.mutable()
                      ..icon = _literal("mdi:content-save")
                      ..semanticLabel = _literal("Save")
                      ..action = _action
                      ..appearance = _appearance(skir.ButtonVariant.filled))
                    .toFrozen(),
              ),
            ),
          ),
          skir.AxisChild.wrapFixed(
            _node("menu", skir.PresentationElement.wrapMenu(menu.toFrozen())),
          ),
          skir.AxisChild.wrapFixed(
            _node(
              "status",
              skir.PresentationElement.wrapText(
                (skir.TextContent.mutable()
                      ..value = skir.ExpressionNode.createRead(
                        binding: _status,
                        path: editorRootPath,
                      ))
                    .toFrozen(),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

skir.PresentationNode _projections() {
  final control =
      (skir.BoundControl.mutable()
            ..binding = skir.BindingRef(bindingId: _page, path: editorRootPath))
          .toFrozen();
  final graph = _node(
    "graph",
    skir.PresentationElement.wrapPageGraph(
      (skir.PageGraphElement.mutable()
            ..control = control
            ..direction = skir.PageGraphDirection.leftToRight
            ..appearance =
                (skir.PageGraphAppearance.mutable()
                      ..cellSize = _number(60)
                      ..edgeColor = _paint(0xff7354bf)
                      ..cardPadding = skir.PresentationInsets.wrapAll(8))
                    .toFrozen())
          .toFrozen(),
    ),
  );
  final timeline = _node(
    "timeline",
    skir.PresentationElement.wrapPageTimeline(
      (skir.PageTimelineElement.mutable()
            ..control = control
            ..appearance =
                (skir.PageTimelineAppearance.mutable()
                      ..rulerHeight = 44
                      ..trackPadding = 6
                      ..laneHeight = 40
                      ..laneGap = 12
                      ..headerPadding = 8
                      ..gridMajorColor = _paint(0xff7354bf))
                    .toFrozen())
          .toFrozen(),
    ),
  );
  return _node(
    "projections",
    skir.PresentationElement.wrapChildren(
      skir.ChildrenElement.createColumn(
        layout: skir.AxisChildrenLayout(
          spacing: 24,
          mainAxisAlignment: skir.MainAxisAlignment.start,
          crossAxisAlignment: skir.CrossAxisAlignment.stretch,
        ),
        children: [
          skir.AxisChild.createFlexible(
            child: graph,
            flex: 1,
            fit: skir.FlexFit.tight,
          ),
          skir.AxisChild.createFlexible(
            child: timeline,
            flex: 1,
            fit: skir.FlexFit.tight,
          ),
        ],
      ),
    ),
  );
}

class _GalleryHost extends ChangeNotifier
    implements PortablePresentationHost, PortablePageHost {
  _GalleryHost({
    required this.readOnly,
    required bool projections,
    bool displays = false,
  }) : root = displays
           ? _displays()
           : projections
           ? _projections()
           : _actions();
  final skir.PresentationNode root;
  int executed = 0;
  @override
  final bool readOnly;
  @override
  bool get enabled => true;
  @override
  PortablePresentationCapabilities get capabilities =>
      const PortablePresentationCapabilities();
  @override
  PortablePresentationDocument get document => PortablePresentationDocument(
    catalog: CheckedEditorCatalog(
      skir.EditorCatalogWireSnapshot.defaultInstance,
    ),
    root: root,
    bindings: {
      _status: PortablePresentationBinding(
        schema: PortablePresentationBindingSchema.complete(_textType),
        value: skir.DataValue.wrapStringValue("Executed $executed actions"),
      ),
      _page: PortablePresentationBinding(
        schema: PortablePresentationBindingSchema.complete(_textType),
        value: skir.DataValue.wrapStringValue("Page"),
      ),
    },
    budget: skir.EvaluationBudget(maxSteps: 1000, maxCollectionItems: 1000),
  );
  @override
  EditControl? commitControl(
    skir.BindingRef reference, {
    required PortableInvocationContext context,
  }) => null;
  @override
  skir.DataValue? read(
    skir.BindingRef reference, {
    required PortableInvocationContext context,
  }) => document.bindings[reference.bindingId]?.value;
  @override
  skir.TypeUse? expectedType(
    skir.BindingRef reference, {
    required PortableInvocationContext context,
  }) => _textType;
  @override
  skir.ValueLocation? location(
    skir.BindingRef reference, {
    required PortableInvocationContext context,
  }) => null;
  @override
  Future<PortablePresentationWriteResult> write(
    skir.BindingRef reference,
    skir.DataValue value, {
    required PortableInvocationContext context,
  }) async => const PortablePresentationWriteResult.applied();
  @override
  Future<PortablePresentationWriteResult> execute(
    skir.EditorAction action, {
    required PortableInvocationContext context,
  }) async {
    executed++;
    notifyListeners();
    return const PortablePresentationWriteResult.applied();
  }

  @override
  PortablePageProjection projectPage(
    skir.BindingRef source, {
    required PortableInvocationContext context,
  }) {
    final resources = [
      skir.ResourceId(value: "Start"),
      skir.ResourceId(value: "Complete"),
    ];
    return PortablePageProjection(
      entries: [
        for (final indexed in resources.indexed)
          PortablePageEntryProjection(
            resource: indexed.$2,
            occurrence: skir.LinkOccurrence.defaultInstance,
            resourceProjection: PortableResourceProjection(
              resource: indexed.$2,
              configuration: skir.TypeSelection.createComplete(
                definition: skir.TypeDefinitionId(
                  typeId: skir.TypeId.createQualified(
                    namespace: "gallery",
                    name: "entry",
                  ),
                  revision: 1,
                ),
                arguments: [],
              ),
              label: indexed.$2.value,
              value: skir.DataValue.wrapStringValue(indexed.$2.value),
            ),
            graph: PortablePageGraphPlacement(
              x: indexed.$1 * 5,
              y: indexed.$1,
              width: 4,
              height: 1,
            ),
          ),
      ],
      edges: [
        PortablePageEdgeProjection(
          id: "flow",
          source: resources.first,
          target: resources.last,
        ),
      ],
      timeline: {
        for (final indexed in resources.indexed)
          indexed.$2: [
            PortableTimelineCueProjection(
              resource: indexed.$2,
              label: indexed.$2.value,
              placement: PortableTimelinePlacement.segment(
                indexed.$1 * 20,
                indexed.$1 * 20 + 15,
              ),
              children: [],
            ),
          ],
      },
    );
  }

  @override
  PortablePresentationWriteResult moveGraphNodes(
    List<PortableGraphPositionChange> changes, {
    required PortableInvocationContext context,
  }) => const PortablePresentationWriteResult.applied();
  @override
  PortablePresentationWriteResult resizeGraphNodes(
    List<PortableGraphSizeChange> changes, {
    required PortableInvocationContext context,
  }) => const PortablePresentationWriteResult.applied();
  @override
  PortablePresentationWriteResult moveTimelineElements(
    List<PortableTimelineChange> changes, {
    required PortableInvocationContext context,
  }) => const PortablePresentationWriteResult.applied();
  @override
  PortablePresentationWriteResult removePageResource(
    PortablePageEntryProjection entry, {
    required bool delete,
    required PortableInvocationContext context,
  }) => const PortablePresentationWriteResult.applied();
}

skir.PresentationNode _displays() {
  final paint =
      (skir.InputAppearance.mutable()
            ..fill = _paint(0xffe5dcfa)
            ..valueStyle =
                (skir.InputTextStyle.mutable()
                      ..color = _paint(0xff40266b)
                      ..weight = 600)
                    .toFrozen()
            ..density = skir.ControlDensity.compact
            ..padding = skir.PresentationInsets.wrapAll(10)
            ..border = skir.BorderOverride.none
            ..radius = skir.PresentationRadius.medium)
          .toFrozen();
  final display =
      (skir.DisplayAppearance.mutable()
            ..appearance = paint
            ..icon = skir.InputAdornment.none)
          .toFrozen();
  final progress = _node(
    "display.progress",
    skir.PresentationElement.wrapProgress(
      (skir.ProgressContent.mutable()
            ..value = _number(3)
            ..maximum = _number(10)
            ..label = _literal("Progress")
            ..appearance =
                (skir.ProgressAppearance.mutable()
                      ..color = _paint(0xff7354bf)
                      ..backgroundColor = _paint(0xffe5dcfa)
                      ..minimumHeight = _number(12)
                      ..radius = skir.PresentationRadius.small)
                    .toFrozen())
          .toFrozen(),
    ),
  );
  final tabs = _node(
    "display.tabs",
    skir.PresentationElement.wrapTabs(
      (skir.TabsLayout.mutable()
            ..appearance = paint
            ..spacing = 12
            ..contentSpacing = 18
            ..tabs = [
              (skir.TabItem.mutable()
                    ..tabId = "summary"
                    ..label = _literal("Summary")
                    ..child = _node(
                      "summary.body",
                      skir.PresentationElement.wrapText(
                        (skir.TextContent.mutable()
                              ..value = _literal("Summary content"))
                            .toFrozen(),
                      ),
                    ))
                  .toFrozen(),
              (skir.TabItem.mutable()
                    ..tabId = "details"
                    ..label = _literal("Details")
                    ..icon = _node(
                      "details.icon",
                      skir.PresentationElement.createIcon(
                        name: _literal("mdi:information-outline"),
                        semanticLabel: null,
                        color: null,
                        size: _number(18),
                      ),
                    )
                    ..child = _node(
                      "details.body",
                      skir.PresentationElement.wrapText(
                        (skir.TextContent.mutable()
                              ..value = _literal("Detail content"))
                            .toFrozen(),
                      ),
                    ))
                  .toFrozen(),
            ])
          .toFrozen(),
    ),
  );
  return _node(
    "displays",
    skir.PresentationElement.wrapChildren(
      skir.ChildrenElement.createColumn(
        layout: skir.AxisChildrenLayout(
          spacing: 16,
          mainAxisAlignment: skir.MainAxisAlignment.start,
          crossAxisAlignment: skir.CrossAxisAlignment.start,
        ),
        children: [
          skir.AxisChild.wrapFixed(
            _node(
              "display.badge",
              skir.PresentationElement.wrapBadge(
                (skir.BadgeContent.mutable()
                      ..label = _literal("Configured badge")
                      ..options = display)
                    .toFrozen(),
              ),
            ),
          ),
          skir.AxisChild.wrapFixed(
            _node(
              "display.chip",
              skir.PresentationElement.wrapChip(
                (skir.ChipContent.mutable()
                      ..label = _literal("Configured chip")
                      ..options = display)
                    .toFrozen(),
              ),
            ),
          ),
          skir.AxisChild.wrapFixed(
            _node(
              "display.status",
              skir.PresentationElement.wrapStatus(
                (skir.StatusContent.mutable()
                      ..value = _literal("ready")
                      ..fallback =
                          (skir.StatusAppearance.mutable()
                                ..tone = skir.StatusTone.success
                                ..label = _literal("Ready")
                                ..options = display)
                              .toFrozen())
                    .toFrozen(),
              ),
            ),
          ),
          skir.AxisChild.wrapFixed(
            _node(
              "display.progress.width",
              skir.PresentationElement.createPadding(
                child: progress,
                top: 0,
                start: 0,
                end: 0,
                bottom: 0,
              ),
            ),
          ),
          skir.AxisChild.wrapFixed(
            _node(
              "display.divider",
              skir.PresentationElement.wrapDivider(
                (skir.DividerAppearance.mutable()
                      ..color = _paint(0xff7354bf)
                      ..thickness = _number(3)
                      ..space = _number(20)
                      ..indent = _number(4)
                      ..endIndent = _number(8))
                    .toFrozen(),
              ),
            ),
          ),
          skir.AxisChild.wrapFixed(tabs),
          skir.AxisChild.wrapFixed(
            _node(
              "display.tooltip",
              skir.PresentationElement.wrapTooltip(
                (skir.TooltipElement.mutable()
                      ..message = _literal("Configured help")
                      ..child = _node(
                        "help.label",
                        skir.PresentationElement.wrapText(
                          (skir.TextContent.mutable()
                                ..value = _literal("Focus for help"))
                              .toFrozen(),
                        ),
                      )
                      ..appearance =
                          (skir.TooltipAppearance.mutable()
                                ..waitMilliseconds = 0
                                ..showMilliseconds = 3000
                                ..preferBelow = false
                                ..appearance = paint)
                              .toFrozen())
                    .toFrozen(),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
