part of "services.dart";

const _dashboardSectionSpacing = 16.0;
const _dashboardFieldSpacing = 12.0;

PresentationNode _dashboardSection({
  required String id,
  required String title,
  required String description,
  required Color color,
  required List<PresentationNode> children,
}) => PresentationNode(
  id: id,
  header: PresentationHeader(
    title: title.asStringLiteral.asHeaderTitle,
    description: description.asStringLiteral,
    headerPadding: const PresentationInsets.symmetric(
      horizontal: 12,
      vertical: 10,
    ),
    contentPadding: const PresentationInsets.all(0),
    initiallyExpanded: true,
  ),
  element: SectionElement(
    border: PresentationBorder.sides(
      start: PresentationBorderSide(color: color.asColorLiteral, width: 3),
    ),
    child: PresentationNode(
      id: "$id.content",
      element: PaddingElement(
        top: 4,
        start: 12,
        end: 12,
        bottom: 12,
        child: PresentationNode(
          id: "$id.layout",
          element: ColumnElement(
            spacing: _dashboardFieldSpacing,
            crossAxisAlignment: PresentationCrossAxisAlignment.start,
            children: children,
          ),
        ),
      ),
    ),
  ),
);

PresentationNode _dashboardCard({
  required String id,
  required String label,
  required Color color,
  required List<PresentationNode> children,
}) => PresentationNode(
  id: id,
  element: ContainerElement(
    backgroundColor: color.asColorLiteral.withAlpha(24),
    radius: const PresentationRadius.medium(),
    child: PresentationNode(
      id: "$id.padding",
      element: PaddingElement(
        top: 12,
        start: 12,
        end: 12,
        bottom: 12,
        child: PresentationNode(
          id: "$id.content",
          element: ColumnElement(
            spacing: 10,
            crossAxisAlignment: PresentationCrossAxisAlignment.start,
            children: [
              PresentationNode(
                id: "$id.label",
                element: TextElement(
                  label.asStringLiteral,
                  color: color.asColorLiteral,
                  fontSize: 12.asFloatLiteral,
                  fontWeight: 700.asFloatLiteral,
                  letterSpacing: 0.6.asFloatLiteral,
                ),
              ),
              ...children,
            ],
          ),
        ),
      ),
    ),
  ),
);

PresentationNode _dashboardGrid({
  required String id,
  required List<PresentationNode> children,
}) => PresentationNode(
  id: id,
  element: GridElement(
    columns: 2,
    horizontalSpacing: 12,
    verticalSpacing: 12,
    children: children,
  ),
);

PresentationNode _readOnlyField({
  required String id,
  required String label,
  TypedExpression? value,
  PresentationElement? content,
  TypedExpression? color,
}) => PresentationNode(
  id: id,
  properties: const PresentationProperties(readOnly: true),
  header: PresentationHeader(
    title: label.asStringLiteral.asHeaderTitle,
    headerPadding: const PresentationInsets.all(0),
    contentPadding: const PresentationInsets.only(top: 4),
  ),
  element: content ?? TextElement(value!, color: color),
);

PresentationNode _statusElement({
  required String id,
  required TypedExpression value,
  required Map<String, StatusTone> tones,
}) => PresentationNode(
  id: id,
  element: StatusElement(
    value: value,
    cases: [
      for (final entry in tones.entries)
        StatusCase(
          match: StringValue(entry.key),
          appearance: StatusAppearance(tone: entry.value),
        ),
    ],
  ),
);

PresentationNode _whenValueIsPresent({
  required String id,
  required TypedExpression value,
  required PresentationNode child,
}) => PresentationNode(
  id: id,
  element: ConditionalElement(
    condition: value.compare(
      ComparisonOperator.notEqual,
      "None".asStringLiteral,
    ),
    whenTrue: child,
  ),
);

PresentationElement _dateTimeContent(TypedExpression value) => DateTimeElement(
  value: value,
  format: "yyyy/MM/dd HH:mm:ss".asStringLiteral,
);

PresentationElement _optionalRelativeTimeContent({
  required BindingReference binding,
  required BindingId scopeBindingId,
}) => PolymorphicMatchElement(
  binding: binding,
  scopeBindingId: scopeBindingId,
  cases: [
    PolymorphicMatchCase(
      type: standardTypeRefs.someOf(const TimestampType()),
      child: PresentationNode(
        id: "${scopeBindingId.value}.relativeTime",
        element: RelativeTimeElement(
          value: TypedExpression(
            resultType: const TimestampType(),
            expression: BindingExpression(
              BindingReference(
                bindingId: scopeBindingId,
                path: DataPath.root.field("value"),
              ),
            ),
          ),
        ),
      ),
    ),
  ],
  fallback: PresentationNode(
    id: "${scopeBindingId.value}.never",
    element: TextElement("Never".asStringLiteral),
  ),
);

DataPath _hostPath(String section, String field) =>
    DataPath.root.field(section).field(field);

DataPath _configurationPath(String field) =>
    _hostPath(_HostInspectorFields.configuration, field);

BoundControl _configurationControl(String field, String label) =>
    _hostControl(_configurationPath(field), label);

TypedExpression _configurationExpression(String field, TypeExpression type) =>
    _hostExpression(_configurationPath(field), type);

BoundControl _hostControl(DataPath path, String label) => BoundControl(
  binding: BindingReference(bindingId: const BindingId(0), path: path),
  label: label.asStringLiteral,
);

TypedExpression _hostExpression(DataPath path, TypeExpression type) =>
    TypedExpression(
      resultType: type,
      expression: BindingExpression(
        BindingReference(bindingId: const BindingId(0), path: path),
      ),
    );

TypedExpression _fieldExpression(String name, TypeExpression type) =>
    TypedExpression(
      resultType: type,
      expression: BindingExpression(
        BindingReference(
          bindingId: const BindingId(0),
          path: DataPath.root.field(name),
        ),
      ),
    );

DataValue _optionalTimestamp(DateTime? value) {
  const type = TimestampType();
  return value == null
      ? PolymorphicValue(
          concreteType: standardTypeRefs.noneOf(type),
          value: const UnitValue(),
        )
      : PolymorphicValue(
          concreteType: standardTypeRefs.someOf(type),
          value: RecordValue({"value": TimestampValue(value)}),
        );
}
