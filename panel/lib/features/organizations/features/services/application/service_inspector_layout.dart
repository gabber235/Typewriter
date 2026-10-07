part of "services.dart";

skir.PresentationNode _inspectorNode(
  String id,
  skir.PresentationElement element, {
  skir.PresentationHeader? header,
}) => skir.PresentationNode(
  nodeId: id,
  properties: skir.PresentationProperties.defaultInstance,
  element: element,
  header: header,
);

skir.PresentationHeader _inspectorHeader(
  String title, {
  bool? expanded,
  skir.PresentationInsets? padding,
}) => skir.PresentationHeader(
  binding: null,
  title: skir.PresentationHeaderTitle.wrapText(_portableLiteral(title)),
  description: null,
  initiallyExpanded: expanded,
  items: const [],
  headerPadding: padding ?? skir.PresentationInsets.wrapAll(0),
  contentPadding: skir.PresentationInsets.createOnly(
    top: 4,
    left: 0,
    right: 0,
    bottom: 0,
  ),
);

skir.PresentationNode _inspectorSection(
  String id,
  String title,
  List<skir.PresentationNode> children,
) => _inspectorNode(
  id,
  skir.PresentationElement.createSection(
    child: _inspectorPadding(
      "$id.padding",
      _portableColumn("$id.content", children, spacing: 12),
      top: 4,
    ),
    border: null,
  ),
  header: _inspectorHeader(
    title,
    expanded: true,
    padding: skir.PresentationInsets.createSymmetric(
      horizontal: 12,
      vertical: 10,
    ),
  ),
);

skir.PresentationNode _inspectorPadding(
  String id,
  skir.PresentationNode child, {
  double top = 12,
}) => _inspectorNode(
  id,
  skir.PresentationElement.createPadding(
    child: child,
    top: top,
    start: 12,
    end: 12,
    bottom: 12,
  ),
);

skir.PresentationNode _inspectorCard(
  String id,
  String label,
  Color color,
  List<skir.PresentationNode> children,
) => _inspectorNode(
  id,
  skir.PresentationElement.createContainer(
    backgroundColor: _inspectorColor(color.withAlpha(24)),
    radius: skir.PresentationRadius.medium,
    border: null,
    child: _inspectorPadding(
      "$id.padding",
      _portableColumn("$id.content", [
        _inspectorNode(
          "$id.label",
          skir.PresentationElement.wrapText(
            _inspectorTextContent(
              _portableLiteral(label),
              color: color,
              fontSize: 12,
              fontWeight: 700,
              letterSpacing: 0.6,
            ),
          ),
        ),
        ...children,
      ], spacing: 10),
    ),
  ),
);

skir.PresentationNode _inspectorGrid(
  String id,
  List<skir.PresentationNode> children,
) => _inspectorNode(
  id,
  skir.PresentationElement.wrapChildren(
    skir.ChildrenElement.createGrid(
      children: children,
      layout: skir.GridChildrenLayout(
        columns: 2,
        horizontalSpacing: 12,
        verticalSpacing: 12,
      ),
    ),
  ),
);

skir.PresentationNode _inspectorFact(
  String id,
  String label,
  skir.PresentationElement content,
) => _inspectorNode(id, content, header: _inspectorHeader(label));

skir.TextContent _inspectorTextContent(
  skir.ExpressionNode value, {
  Color? color,
  double? fontSize,
  double? fontWeight,
  double? letterSpacing,
}) => skir.TextContent(
  value: value,
  color: color == null ? null : _inspectorColor(color),
  fontSize: _inspectorNumber(fontSize),
  fontWeight: _inspectorNumber(fontWeight),
  letterSpacing: _inspectorNumber(letterSpacing),
  fontItalic: null,
  fontOpticalSize: null,
  fontSlant: null,
  fontWidth: null,
  textAlignment: null,
  lineHeight: null,
  decoration: null,
  semanticLabel: null,
  paragraph: skir.TextParagraph.defaultInstance,
);

skir.ExpressionNode? _inspectorNumber(double? value) => value == null
    ? null
    : skir.ExpressionNode.wrapLiteral(skir.DataValue.wrapFloat(value));
skir.ExpressionNode _inspectorColor(Color color) =>
    skir.ExpressionNode.wrapLiteral(
      skir.DataValue.wrapInteger(color.toARGB32().toString()),
    );

skir.PresentationNode _inspectorConnectionStatus(
  String id,
  skir.ExpressionBindingId binding,
) => _inspectorNode(
  id,
  skir.PresentationElement.createStatus(
    value: _portableRead(binding),
    cases: [
      _inspectorStatusCase("Connected", "Connected", skir.StatusTone.online),
      _inspectorStatusCase("Offline", "Offline", skir.StatusTone.offline),
    ],
    fallback: skir.StatusAppearance(
      tone: skir.StatusTone.unknownStatus,
      label: null,
    ),
  ),
);

skir.StatusCase _inspectorStatusCase(
  String value,
  String label,
  skir.StatusTone tone,
) => skir.StatusCase(
  match: skir.DataValue.wrapStringValue(value),
  appearance: skir.StatusAppearance(tone: tone, label: _portableLiteral(label)),
);

skir.PresentationNode _inspectorRuntimeStatus(
  String id,
  skir.ExpressionBindingId binding,
) => _inspectorNode(
  id,
  skir.PresentationElement.createStatus(
    value: _portableRead(binding),
    cases: [
      for (final status in TopologyRuntimeStatus.values)
        _inspectorStatusCase(
          status.name,
          childRuntimeStatusLabel(status),
          switch (status) {
            TopologyRuntimeStatus.active => skir.StatusTone.active,
            TopologyRuntimeStatus.staging => skir.StatusTone.inProgress,
            TopologyRuntimeStatus.quiescing => skir.StatusTone.paused,
            TopologyRuntimeStatus.drifted ||
            TopologyRuntimeStatus.rolledBack => skir.StatusTone.warning,
            TopologyRuntimeStatus.failed => skir.StatusTone.danger,
            TopologyRuntimeStatus.absent => skir.StatusTone.inactive,
            TopologyRuntimeStatus.unknown => skir.StatusTone.unknownStatus,
          },
        ),
    ],
    fallback: skir.StatusAppearance(
      tone: skir.StatusTone.unknownStatus,
      label: null,
    ),
  ),
);

skir.PresentationNode _inspectorHostStatus(
  String id,
  skir.ExpressionBindingId binding,
) => _inspectorNode(
  id,
  skir.PresentationElement.createStatus(
    value: _portableRead(binding),
    cases: [
      for (final status in TopologyHostStatus.values)
        _inspectorStatusCase(
          status.name,
          hostRuntimeStatusLabel(status),
          switch (status) {
            TopologyHostStatus.active => skir.StatusTone.active,
            TopologyHostStatus.reconciling => skir.StatusTone.inProgress,
            TopologyHostStatus.drifted => skir.StatusTone.warning,
            TopologyHostStatus.failed => skir.StatusTone.danger,
            TopologyHostStatus.offline => skir.StatusTone.offline,
            TopologyHostStatus.unknown => skir.StatusTone.unknownStatus,
          },
        ),
    ],
    fallback: skir.StatusAppearance(
      tone: skir.StatusTone.unknownStatus,
      label: null,
    ),
  ),
);

skir.PresentationElement _inspectorRelativeTime(
  skir.ExpressionBindingId binding,
) => skir.PresentationElement.createConditional(
  condition: skir.ExpressionNode.createCall(
    operation: skir.OperationId(value: "typewriter.value.is_null"),
    arguments: [_portableRead(binding)],
  ),
  whenTrue: _portableText("${binding.value}.never", _portableLiteral("Never")),
  whenFalse: _inspectorNode(
    "${binding.value}.relative",
    skir.PresentationElement.createRelativeTime(
      value: _portableRead(binding),
      style: skir.RelativeTimeStyle.natural,
      timeZone: skir.DateTimeZone.local,
    ),
  ),
);

skir.PresentationElement _inspectorDateTime(skir.ExpressionBindingId binding) =>
    skir.PresentationElement.createDateTime(
      value: _portableRead(binding),
      format: _portableLiteral("yyyy/MM/dd HH:mm:ss"),
      timeZone: skir.DateTimeZone.local,
    );

skir.PresentationNode _inspectorMessage(
  String id,
  skir.ExpressionBindingId binding,
) => _inspectorNode(
  "$id.visible",
  skir.PresentationElement.createConditional(
    condition: skir.ExpressionNode.createCall(
      operation: skir.OperationId(value: "typewriter.value.neq"),
      arguments: [_portableRead(binding), _portableLiteral("None")],
    ),
    whenTrue: _inspectorFact(
      id,
      "Message",
      skir.PresentationElement.wrapText(
        _inspectorTextContent(_portableRead(binding), color: Colors.redAccent),
      ),
    ),
    whenFalse: null,
  ),
);

skir.PresentationNode _inspectorWorkload(
  String id,
  String title,
  String label,
  Color color,
  skir.ExpressionBindingId binding,
  List<skir.PresentationNode> fields,
) => _inspectorCard(id, title, color, [
  _inspectorNode(
    "$id.mode",
    skir.PresentationElement.createConditional(
      condition: _portableRead(binding),
      whenTrue: _portableColumn("$id.fields", fields, spacing: 12),
      whenFalse: _portableColumn("$id.disabled", const []),
    ),
    header: skir.PresentationHeader(
      binding: _portableReference(binding),
      title: skir.PresentationHeaderTitle.wrapText(_portableLiteral(label)),
      description: null,
      initiallyExpanded: null,
      items: [
        skir.HeaderItem.createBooleanToggle(
          itemId: skir.HeaderItemId(
            namespace: "serviceHost",
            name: "$id.enabled",
          ),
          label: _portableLiteral(label),
          checked: _portableRead(binding),
          action: skir.EditorAction.wrapLocal(
            skir.LocalEditorAction.createSetValue(
              target: _portableReference(binding),
              value: skir.ExpressionNode.createCall(
                operation: skir.OperationId(value: "typewriter.boolean.not"),
                arguments: [_portableRead(binding)],
              ),
            ),
          ),
          tooltip: _portableLiteral(label),
          priority: null,
          visibleIf: null,
          enabledIf: null,
          confirmation: null,
          placement: skir.HeaderActionPlacement.beforeTitle,
        ),
      ],
      headerPadding: skir.PresentationInsets.wrapAll(0),
      contentPadding: skir.PresentationInsets.createOnly(
        top: 8,
        left: 0,
        right: 0,
        bottom: 0,
      ),
    ),
  ),
]);
