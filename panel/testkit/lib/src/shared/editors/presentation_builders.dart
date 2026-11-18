/// Builders for portable presentation trees in tests and Widgetbook stories.
///
/// Nodes keep default properties and no header. Callers needing more detail
/// adjust the result through `toMutable()` or build the element themselves.
library;

import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

/// A literal expression for [value].
skir.ExpressionNode literalExpression(skir.DataValue value) =>
    skir.ExpressionNode.wrapLiteral(value);

/// A literal text expression.
skir.ExpressionNode textLiteral(String value) =>
    literalExpression(skir.DataValue.wrapStringValue(value));

/// A literal floating point expression.
skir.ExpressionNode numberLiteral(double value) =>
    literalExpression(skir.DataValue.wrapFloat(value));

/// A literal integer expression.
skir.ExpressionNode integerLiteral(int value) =>
    literalExpression(skir.DataValue.wrapInteger("$value"));

/// The scalar type template of [kind].
skir.TypeTemplate scalarTemplate(skir.ScalarKind kind) =>
    skir.TypeTemplate.wrapScalar(kind);

/// The text type template.
final textTemplate = scalarTemplate(skir.ScalarKind.text);

/// The type template of a signed 32 bit integer, the type of collection
/// indexes.
final int32Template = scalarTemplate(
  skir.ScalarKind.createInteger(width: skir.IntegerWidth.signedThirtyTwo),
);

/// Declares the binding [id] of type [type].
skir.BindingDeclaration declareBinding(
  skir.ExpressionBindingId id,
  skir.TypeTemplate type,
) => skir.BindingDeclaration(id: id, type: type);

/// Declares the binding named [id] of type [type].
skir.BindingDeclaration declareNamedBinding(
  String id,
  skir.TypeTemplate type,
) => declareBinding(skir.ExpressionBindingId(value: id), type);

/// Reads [binding] at [path], or at the single [field] below its root.
skir.ExpressionNode inputExpression(
  skir.ExpressionBindingId binding, {
  String? field,
  skir.ValuePath? path,
}) {
  assert(field == null || path == null, "Supply either a field or a path.");
  return skir.ExpressionNode.createInput(
    binding: binding,
    path:
        path ?? (field == null ? editorRootPath : editorRootPath.field(field)),
  );
}

/// Reads the local in [slot] at lexical [depth].
skir.ExpressionNode localExpression(
  int slot, {
  int depth = 0,
  skir.ValuePath? path,
}) => skir.ExpressionNode.createLocal(
  depth: depth,
  slot: slot,
  path: path ?? editorRootPath,
);

/// Reads field [name] from [source].
skir.ExpressionNode fieldExpression(skir.ExpressionNode source, String name) =>
    skir.ExpressionNode.createField(
      source: source,
      path: skir.ValuePath(
        segments: [skir.PathSegment.createField(name: name)],
      ),
    );

/// A presentation node with default properties and no header.
skir.PresentationNode presentationNode(
  String id,
  skir.PresentationElement element,
) =>
    (skir.PresentationNode.mutable()
          ..nodeId = id
          ..element = element)
        .toFrozen();

/// A column of fixed children.
skir.PresentationNode presentationColumn(
  String id,
  List<skir.PresentationNode> children, {
  skir.AxisChildrenLayout? layout,
}) => presentationNode(
  id,
  skir.PresentationElement.wrapChildren(
    skir.ChildrenElement.createColumn(
      children: [for (final child in children) skir.AxisChild.wrapFixed(child)],
      layout: layout ?? skir.AxisChildrenLayout.defaultInstance,
    ),
  ),
);

/// A text element showing [value], sized by [sizing] and laid out as
/// [paragraph] when given, with default styling otherwise.
skir.PresentationNode presentationText(
  String id,
  skir.ExpressionNode value, {
  skir.TextSizing? sizing,
  skir.TextParagraph? paragraph,
}) {
  final content = skir.TextContent.mutable()
    ..value = value
    ..sizing = sizing;
  if (paragraph != null) content.paragraph = paragraph;
  return presentationNode(
    id,
    skir.PresentationElement.wrapText(content.toFrozen()),
  );
}

/// A text element showing [value], unstyled and laid out as the default
/// paragraph unless given.
skir.PresentationElement textElement(
  skir.ExpressionNode value, {
  skir.PresentationColor? color,
  skir.TextSizing? sizing,
  skir.ExpressionNode? fontWeight,
  skir.ExpressionNode? fontItalic,
  skir.ExpressionNode? fontOpticalSize,
  skir.ExpressionNode? fontSlant,
  skir.ExpressionNode? fontWidth,
  skir.ExpressionNode? textAlignment,
  skir.ExpressionNode? lineHeight,
  skir.ExpressionNode? letterSpacing,
  skir.ExpressionNode? decoration,
  skir.ExpressionNode? semanticLabel,
  skir.TextParagraph? paragraph,
}) {
  final content = skir.TextContent.mutable()
    ..value = value
    ..color = color
    ..sizing = sizing
    ..fontWeight = fontWeight
    ..fontItalic = fontItalic
    ..fontOpticalSize = fontOpticalSize
    ..fontSlant = fontSlant
    ..fontWidth = fontWidth
    ..textAlignment = textAlignment
    ..lineHeight = lineHeight
    ..letterSpacing = letterSpacing
    ..decoration = decoration
    ..semanticLabel = semanticLabel;
  if (paragraph != null) content.paragraph = paragraph;
  return skir.PresentationElement.wrapText(content.toFrozen());
}

/// The node `[id].color`: [icon] padded by 6 on every side as the node
/// `[id].padding`, on the grey tile color an entry icon sits on.
skir.PresentationNode coloredIconTile(String id, skir.PresentationNode icon) =>
    presentationNode(
      "$id.color",
      skir.PresentationElement.createContainer(
        foregroundColor: null,
        transition: null,
        shadows: const [],
        child: presentationNode(
          "$id.padding",
          skir.PresentationElement.createPadding(
            child: icon,
            top: 6,
            start: 6,
            end: 6,
            bottom: 6,
          ),
        ),
        border: null,
        backgroundColor: skir.PresentationColor.wrapValue(
          skir.ExpressionNode.wrapLiteral(
            skir.DataValue.wrapInteger("4288585374"),
          ),
        ),
        radius: skir.PresentationRadius.none,
      ),
    );

/// A plain number input over [binding], labeled [label] when given.
skir.PresentationElement numericInputElement(
  skir.BindingRef binding, {
  String? label,
}) => skir.PresentationElement.wrapNumericInput(
  (skir.NumericControl.mutable()
        ..control =
            (skir.BoundControl.mutable()
                  ..binding = binding
                  ..label = label == null ? null : textLiteral(label))
                .toFrozen())
      .toFrozen(),
);

/// A plain text input over [binding], labeled [label] when given.
skir.PresentationElement textInputElement(
  skir.BindingRef binding, {
  String? label,
}) => skir.PresentationElement.createTextInput(
  control:
      (skir.BoundControl.mutable()
            ..binding = binding
            ..label = label == null ? null : textLiteral(label))
          .toFrozen(),
  appearance: null,
  content: null,
  entry: null,
  mappings: null,
  options: skir.TextEditingOptions.defaultInstance,
);

/// [list], a list input node, with the header of its item presentation
/// replaced by what [transform] makes of it.
skir.PresentationNode withListItemHeader(
  skir.PresentationNode list,
  skir.PresentationHeader Function(skir.PresentationHeader header) transform,
) {
  final control =
      (list.element! as skir.PresentationElement_listInputWrapper).value;
  final item = control.itemPresentation!;
  return (list.toMutable()
        ..element = skir.PresentationElement.wrapListInput(
          (control.toMutable()
                ..itemPresentation =
                    (item.toMutable()..header = transform(item.header!))
                        .toFrozen())
              .toFrozen(),
        ))
      .toFrozen();
}

/// A neutral header button [label] with a square icon at the end of the
/// header, which runs [action].
skir.HeaderItem headerButton(
  String id,
  String label,
  skir.EditorAction action,
) => skir.HeaderItem.createButton(
  itemId: skir.HeaderItemId(namespace: "fixture", name: id),
  icon: textLiteral(
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24"> '
    '<path d="M4 4h16v16H4z"/></svg>',
  ),
  label: textLiteral(label),
  tooltip: null,
  action: action,
  priority: null,
  visibleIf: null,
  enabledIf: null,
  tone: skir.HeaderActionTone.neutral,
  confirmation: null,
  placement: skir.HeaderActionPlacement.end,
);

/// A presentation number fixed at [value].
skir.PresentationNumber presentationNumber(double value) =>
    skir.PresentationNumber.wrapValue(numberLiteral(value));

/// A presentation number that is [value] while [match] holds and [fallback]
/// otherwise.
skir.PresentationNumber stateNumber(
  double fallback, {
  required skir.PresentationStateMatch match,
  required double value,
}) => skir.PresentationNumber.createStates(
  rules: [
    skir.PresentationStateNumberRule(match: match, value: numberLiteral(value)),
  ],
  fallback: numberLiteral(fallback),
);

/// A presentation color fixed at [color].
skir.PresentationColor presentationColor(Color color) =>
    skir.PresentationColor.wrapValue(color.portableExpression);

/// A state rule that paints [color] while every [required] interaction state
/// holds and no [excluded] one does.
skir.PresentationStateColorRule stateColorRule(
  List<skir.PresentationInteractionState> required,
  Color color, {
  List<skir.PresentationInteractionState> excluded = const [],
}) => skir.PresentationStateColorRule(
  match: skir.PresentationStateMatch(required_: required, excluded: excluded),
  color: presentationColor(color),
);

/// The definition of the type [name], revision [revision], in [namespace].
skir.TypeDefinitionId typeDefinition(
  String name, {
  String namespace = "test",
  int revision = 1,
}) => skir.TypeDefinitionId(
  typeId: skir.TypeId.createQualified(namespace: namespace, name: name),
  revision: revision,
);

/// The type [key] that the resource [resource] declares itself.
skir.TypeDefinitionId contentTypeDefinition(String resource, String key) =>
    skir.TypeDefinitionId(
      typeId: skir.TypeId.createContent(
        resource: skir.ResourceId(value: resource),
        key: skir.ContentKey.wrapGenerated(key),
      ),
      revision: 1,
    );

/// A record declaration [id] with no fields, as a resource declares one.
skir.TypeDefinition contentRecordDeclaration(skir.TypeDefinitionId id) =>
    skir.TypeDefinition(
      id: id,
      parameters: const [],
      representation: skir.RepresentationTemplate.createRecord(
        fields: const [],
        form: skir.RecordForm.concrete,
      ),
      parents: const [],
    );

/// A use of the type [name] in [namespace] without type arguments.
skir.NamedTypeUse namedTypeUse(String name, {String namespace = "test"}) =>
    skir.NamedTypeUse(
      definition: typeDefinition(name, namespace: namespace),
      arguments: const [],
    );

/// A template naming the type [name] in [namespace] without type arguments.
skir.TypeTemplate namedTypeTemplate(String name, {String namespace = "test"}) =>
    skir.TypeTemplate.createNamed(
      definition: typeDefinition(name, namespace: namespace),
      arguments: const [],
    );

/// A control over [reference], labeled [label] when given.
skir.BoundControl presentationControl(
  skir.BindingRef reference, {
  String? label,
}) => skir.BoundControl(
  binding: reference,
  label: label == null ? null : textLiteral(label),
  description: null,
  prefix: null,
  semanticLabel: null,
);

/// A slot [slot] a caller fills, as node [id].
skir.PresentationNode presentationSlot(String id, String slot) =>
    presentationNode(id, skir.PresentationElement.createSlot(slotId: slot));

/// A sequence of [item] laid out as an unspaced column aligned to the start.
skir.SequencePresentation columnSequence(skir.PresentationNode item) =>
    skir.SequencePresentation(
      item: item,
      empty: null,
      separator: null,
      layout: skir.SequenceLayout.wrapChildren(
        skir.ChildrenLayout.createColumn(
          clipOverflow: false,
          spacing: 0,
          mainAxisAlignment: skir.MainAxisAlignment.start,
          crossAxisAlignment: skir.CrossAxisAlignment.start,
        ),
      ),
    );

/// Supplying binding values to a presentation scope.
extension SuppliedValues on PortablePresentationScope {
  /// This scope with [values] bound as a caller supplies them.
  PortablePresentationScope withValues(
    Map<skir.ExpressionBindingId, skir.DataValue> values,
  ) => copyWith(
    bindings: {
      ...bindings,
      for (final MapEntry(:key, :value) in values.entries)
        key: PortableExpressionBinding(value: value),
    },
  );
}

/// A toggle input over [binding] with nothing configured.
skir.PresentationElement toggleInputElement(skir.BindingRef binding) =>
    skir.PresentationElement.wrapToggleInput(
      (skir.ToggleControl.mutable()..control = presentationControl(binding))
          .toFrozen(),
    );

/// A color input over [binding] without alpha and with nothing configured.
skir.PresentationElement colorInputElement(skir.BindingRef binding) =>
    skir.PresentationElement.wrapColorInput(
      skir.ColorControl(
        control: presentationControl(binding),
        includeAlpha: false,
        appearance: null,
        content: null,
        entry: null,
        mappings: null,
        popup: null,
        options: null,
      ),
    );

/// Node [id] laying out the resources of the configured value's `elements`
/// field as a left to right graph whose items are [item].
skir.PresentationNode elementsGraphNode(String id, skir.TypeTemplate item) =>
    skir.PresentationNode(
      nodeId: id,
      properties: skir.PresentationProperties.defaultInstance,
      header: null,
      element: skir.PresentationElement.createResources(
        control: presentationControl(
          skir.BindingRef(
            bindingId: configuredValueBindingId,
            path: editorRootPath.field("elements"),
          ),
        ),
        layout: skir.ResourcesLayout.createGraph(
          direction: skir.GraphDirection.leftToRight,
          appearance: null,
        ),
        order: null,
        itemBinding: declareNamedBinding("resources.item", item),
      ),
    );

/// A search over [control] through [provider] that picks one value, or
/// several when [multiple], reading its query from [queryBinding] and its
/// summary from [summaryBinding] in a popup at most [maximumExtent] pixels
/// tall; nothing else is configured.
skir.SearchControl searchControl({
  required skir.BoundControl control,
  required skir.SearchProvider provider,
  required skir.BindingDeclaration queryBinding,
  required skir.BindingDeclaration summaryBinding,
  required int maximumExtent,
  bool multiple = false,
}) => skir.SearchControl(
  control: control,
  selectionMode: multiple
      ? skir.SearchSelectionMode.multiple
      : skir.SearchSelectionMode.single,
  queryBinding: queryBinding,
  summaryBinding: summaryBinding,
  maximumExtent: skir.ExpressionNode.wrapLiteral(
    skir.DataValue.wrapInteger("$maximumExtent"),
  ),
  provider: provider,
  summary: null,
  placeholder: null,
  customValue: null,
  initialQuery: null,
  appearance: null,
  content: null,
  popup: null,
  popupSide: null,
  emptyText: null,
  loadingText: null,
  empty: null,
  loading: null,
);
