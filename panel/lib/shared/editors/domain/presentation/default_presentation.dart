/// Fallback presentation construction for types without a named presentation.
///
/// The generated tree binds its root to binding zero, recursively maps record
/// fields to child bindings, and chooses controls from the resolved type. It
/// is a safe editing fallback, not a replacement for domain specific catalog
/// presentations.
library;

import "package:typewriter_panel/typewriter_panel.dart";

/// Builds the fallback editor tree used when no catalog presentation is selected.
extension TypeExpressionDefaultPresentation on TypeExpression {
  PresentationNode generateDefaultPresentation({
    BindingReference binding = const BindingReference(bindingId: BindingId(0)),
    String nodeId = "root",
    bool root = true,
    String? label,
    TypeRegistry? registry,
  }) =>
      _DefaultPresentationGenerator(registry)
          .generate(this, binding, nodeId, root, label);
}

final class _DefaultPresentationGenerator {
  const _DefaultPresentationGenerator(this.registry);

  final TypeRegistry? registry;

  PresentationNode generate(
    TypeExpression type,
    BindingReference binding,
    String id, [
    bool root = true,
    String? label,
  ]) {
    final control = BoundControl(
      binding: binding,
      label: label?._presentationLabel.asStringLiteral,
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
      TimestampType() => DateTimeInputElement(control: control),
      DurationType() => DurationInputElement(control),
      ListType(element: ReferenceType()) => ReferenceInputElement(
        control: control,
        allowReorder: true,
      ),
      ListType() => ListInputElement(control: control),
      MapType() => MapInputElement(control: control),
      RecordType() => _record(type, binding, id, control),
      NamedType(:final reference)
          when reference.id == const TypeId.option() &&
              reference.arguments.singleOrNull is ReferenceType =>
        ReferenceInputElement(control: control),
      NamedType() => _named(type, control),
      ReferenceType() => ReferenceInputElement(control: control),
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
          title: control.label?.asHeaderTitle,
          description: control.description,
          initiallyExpanded: root,
        ),
        RecordType() when !root => PresentationHeader(
          binding: binding,
          title: control.label?.asHeaderTitle,
          description: control.description,
          initiallyExpanded: false,
        ),
        _ => null,
      },
    );
  }

  PresentationElement _named(NamedType type, BoundControl control) {
    final resolved = registry?.resolve(type).valueOrNull;
    if (resolved == null || resolved.isConcrete) {
      return NamedInputElement(control);
    }
    final concreteTypes = registry!
        .concreteDescendantsOf(type.reference)
        .map(
          (reference) => ConcreteTypePresentation(
            type: reference,
            label:
                (registry!.definition(reference)?.displayName ??
                        _typeLabel(reference.id))
                    .asStringLiteral,
          ),
        )
        .toList();
    if (concreteTypes.isEmpty) {
      return _invalid("Abstract type has no concrete choices");
    }
    return PolymorphicInputElement(
      control: control,
      concreteTypes: concreteTypes,
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
        element: ColumnElement(
          children: children.map(PresentationAxisChild.fixed).toList(),
          spacing: 12,
        ),
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

String _typeLabel(TypeId id) => switch (id) {
  QualifiedTypeId(:final name) => name._presentationLabel,
  _ => id.displayName._presentationLabel,
};

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
