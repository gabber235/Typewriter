import "package:typewriter_panel/typewriter_panel.dart";

const builtinStringSingleLinePresentationId = PresentationId(
  namespace: "typewriter",
  name: "string.singleLine",
);

List<PresentationDefinition> builtinPresentationDefinitions() => [
  PresentationDefinition(
    id: builtinStringSingleLinePresentationId,
    target: const StringType(),
    root: const PresentationNode(
      id: "string.singleLine",
      element: TextInputElement(
        control: BoundControl(
          binding: BindingReference(bindingId: BindingId(0)),
        ),
        multiline: false,
      ),
    ),
  ),
  PresentationDefinition(
    id: standardColorPresentationId,
    target: NamedType(standardTypeRefs.color),
    root: const PresentationNode(
      id: "color.default",
      element: ColorInputElement(
        control: BoundControl(
          binding: BindingReference(bindingId: BindingId(0)),
        ),
      ),
    ),
  ),
  PresentationDefinition(
    id: standardColorAlphaPresentationId,
    target: NamedType(standardTypeRefs.color),
    root: const PresentationNode(
      id: "color.alpha",
      element: ColorInputElement(
        control: BoundControl(
          binding: BindingReference(bindingId: BindingId(0)),
        ),
        includeAlpha: true,
      ),
    ),
  ),
  PresentationDefinition(
    id: standardIconifyPresentationId,
    target: NamedType(standardTypeRefs.iconifyIcon),
    root: const PresentationNode(
      id: "iconify.default",
      element: IconInputElement(
        BoundControl(binding: BindingReference(bindingId: BindingId(0))),
      ),
    ),
  ),
  PresentationDefinition(
    id: standardSvgIconPresentationId,
    target: NamedType(standardTypeRefs.svgIcon),
    root: const PresentationNode(
      id: "svg.default",
      element: IconInputElement(
        BoundControl(binding: BindingReference(bindingId: BindingId(0))),
      ),
    ),
  ),
];

extension TypeExpressionDefaultPresentation on TypeExpression {
  PresentationNode generateDefaultPresentation({
    BindingReference binding = const BindingReference(bindingId: BindingId(0)),
    String nodeId = "root",
    bool root = true,
    String? label,
  }) => _DefaultPresentationGenerator().generate(
    this,
    binding,
    nodeId,
    root,
    label,
  );
}

final class _DefaultPresentationGenerator {
  PresentationNode generate(
    TypeExpression type,
    BindingReference binding,
    String id, [
    bool root = true,
    String? label,
  ]) {
    final control = BoundControl(
      binding: binding,
      label: (label ?? id)._presentationLabel.asStringLiteral,
    );
    final element = switch (type) {
      AnyType() => _invalid("Any values do not have a safe default editor"),
      UnitType() || EnumType() => EnumInputElement(control),
      BooleanType() => ToggleInputElement(control),
      StringType() => TextInputElement(control: control),
      BytesType() => BytesInputElement(control),
      IntegerType() ||
      FloatType() ||
      DecimalType() => NumericInputElement(control),
      TimestampType() => DateTimeInputElement(control),
      DurationType() => DurationInputElement(control),
      ListType() => ListInputElement(control: control),
      MapType() => MapInputElement(control: control),
      RecordType() => _record(type, binding, id, control),
      NamedType() => NamedInputElement(control),
      ParameterType() => _invalid(
        "Generic parameters must be resolved before presentation",
      ),
    };
    return PresentationNode(
      id: id,
      element: element,
      header: switch (type) {
        ListType() || MapType() => PresentationHeader(
          binding: binding,
          title: control.label,
          description: control.description,
          initiallyExpanded: root,
        ),
        RecordType() when !root => PresentationHeader(
          binding: binding,
          title: control.label,
          description: control.description,
          initiallyExpanded: false,
        ),
        _ => null,
      },
    );
  }

  RecordInputElement _record(
    RecordType type,
    BindingReference binding,
    String id,
    BoundControl control,
  ) {
    final children = [
      for (final field in type.fields.values)
        _field(field, binding, "$id.${field.name}"),
    ];
    return RecordInputElement(
      control: control,
      fieldPresentation: PresentationNode(
        id: "$id.fields",
        element: ColumnElement(children: children, spacing: 12),
      ),
    );
  }

  PresentationNode _field(TypeField field, BindingReference parent, String id) {
    final binding = parent.at(DataPath.root.field(field.name));
    return PresentationNode(
      id: id,
      element: TypedFieldElement(
        binding: binding,
        expectedType: field.type,
        presentation: generate(
          field.type,
          binding,
          "$id.control",
          false,
          field.name,
        ),
      ),
    );
  }
}

DiagnosticElement _invalid(String message) => DiagnosticElement([
  TypeDiagnostic(code: TypeDiagnosticCode.invalidConstraint, message: message),
]);

extension on String {
  String get _presentationLabel {
    final segment = split(".").last;
    if (segment.isEmpty) return this;
    final spaced = segment.replaceAllMapped(
      RegExp("([a-z0-9])([A-Z])"),
      (match) => "${match.group(1)} ${match.group(2)}",
    );
    return "${spaced[0].toUpperCase()}${spaced.substring(1)}";
  }
}
