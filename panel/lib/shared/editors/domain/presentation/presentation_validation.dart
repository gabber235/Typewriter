import "package:typewriter_panel/typewriter_panel.dart";

extension PresentationNodeValidation on PresentationNode {
  List<TypeDiagnostic> validatePresentation(
    ExpressionContext context, {
    required TypeRegistry? registry,
    ExpressionBudget budget = const ExpressionBudget(),
  }) => [
    if (properties.enabledIf case final expression?)
      ...expression._evaluateBoolean(context, budget, registry),
    ...element._validatePresentation(context, budget, registry),
  ];
}

extension on PresentationElement {
  List<TypeDiagnostic> _validatePresentation(
    ExpressionContext context,
    ExpressionBudget budget,
    TypeRegistry? registry,
  ) {
    final element = this;
    final control = _boundControl;
    final expressions = <TypedExpression>[
      ..._presentationExpressions,
      if (control != null) ...[?control.label, ?control.description],
    ];
    final diagnostics = <TypeDiagnostic>[
      for (final expression in expressions)
        ...expression
            .evaluate(context, registry: registry, budget: budget)
            .diagnostics,
    ];
    if (element case TypedFieldElement(:final binding, :final expectedType)) {
      final resolved = context.bindings.resolve(binding);
      diagnostics.addAll(resolved.diagnostics);
      final actual = resolved.valueOrNull?.type;
      if (actual != null && !typeExpressionsEqual(actual, expectedType)) {
        diagnostics.add(_invalid("Typed field does not match its binding"));
      }
    }
    if (control == null) return diagnostics;
    final binding = context.bindings.resolve(control.binding);
    diagnostics.addAll(binding.diagnostics);
    final type = binding.valueOrNull?.type;
    if (type != null && !element._acceptsControl(type)) {
      diagnostics.add(_invalid("Control does not accept its binding type"));
    }
    return diagnostics;
  }
}

extension on PresentationElement {
  List<TypedExpression> get _presentationExpressions {
    final element = this;
    return switch (element) {
      TextualContentElement(:final value) => [value],
      IconElement(:final name, :final semanticLabel) => [name, ?semanticLabel],
      ImageElement(:final source, :final semanticLabel) => [
        source,
        ?semanticLabel,
      ],
      BadgeElement(:final label) => [label],
      ProgressElement(:final value, :final maximum, :final label) => [
        value,
        maximum,
        ?label,
      ],
      SectionElement(:final title, :final description) => [title, ?description],
      TabsElement(:final tabs) => [for (final tab in tabs) tab.label],
      ConditionalElement(:final condition) => [condition],
      RepeatedElement(:final source) => [source],
      SelectInputElement(:final options) => [
        for (final option in options) ...[option.label, option.value],
      ],
      SliderInputElement(:final minimum, :final maximum, :final divisions) => [
        minimum,
        maximum,
        ?divisions,
      ],
      SpacerElement(:final width, :final height) => [?width, ?height],
      CollapsibleElement(:final title) => [title],
      PolymorphicInputElement(:final concreteTypes) => [
        for (final concreteType in concreteTypes) concreteType.label,
      ],
      ButtonElement(:final label) => [label],
      IconButtonElement(:final icon, :final semanticLabel) => [
        icon,
        semanticLabel,
      ],
      MenuElement(:final label, :final items) => [
        ?label,
        for (final item in items) item.label,
      ],
      TooltipElement(:final message) => [message],
      _ => const [],
    };
  }

  BoundControl? get _boundControl => switch (this) {
    TextInputElement(:final control) ||
    NumericInputElement(:final control) ||
    ToggleInputElement(:final control) ||
    SelectInputElement(:final control) ||
    SliderInputElement(:final control) ||
    SimpleInputElement(:final control) ||
    ColorInputElement(:final control) ||
    ListInputElement(:final control) ||
    MapInputElement(:final control) ||
    RecordInputElement(:final control) ||
    PolymorphicInputElement(:final control) => control,
    _ => null,
  };

  bool _acceptsControl(TypeExpression type) => switch (this) {
    TextInputElement() => type is StringType,
    NumericInputElement() || SliderInputElement() =>
      type is IntegerType || type is FloatType || type is DecimalType,
    ToggleInputElement() => type is BooleanType,
    DateTimeInputElement() => type is TimestampType,
    DurationInputElement() => type is DurationType,
    BytesInputElement() => type is BytesType,
    EnumInputElement() => type is EnumType || type is UnitType,
    NamedInputElement() => type is NamedType,
    ListInputElement() => type is ListType,
    MapInputElement() => type is MapType,
    RecordInputElement() => type is RecordType,
    PolymorphicInputElement() => type is NamedType,
    ColorInputElement() => type is NamedType,
    SelectInputElement() => true,
    _ => true,
  };
}

extension on TypedExpression {
  List<TypeDiagnostic> _evaluateBoolean(
    ExpressionContext context,
    ExpressionBudget budget,
    TypeRegistry? registry,
  ) {
    if (resultType is! BooleanType) {
      return [_invalid("Presentation condition must declare a boolean result")];
    }
    return evaluate(context, registry: registry, budget: budget).diagnostics;
  }
}

TypeDiagnostic _invalid(String message) =>
    TypeDiagnostic(code: TypeDiagnosticCode.invalidValue, message: message);
