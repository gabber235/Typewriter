import "package:typewriter_panel/typewriter_panel.dart";

extension PresentationNodeValidation on PresentationNode {
  List<TypeDiagnostic> validatePresentation(
    ExpressionContext context, {
    required TypeRegistry? registry,
    ExpressionBudget budget = const ExpressionBudget(),
  }) => [
    if (properties.enabledIf case final expression?)
      ...expression._evaluateBoolean(context, budget, registry),
    ...?header?._validatePresentation(context, budget, registry),
    ...element._validatePresentation(context, budget, registry),
  ];
}

extension on PresentationHeader {
  List<TypeDiagnostic> _validatePresentation(
    ExpressionContext context,
    ExpressionBudget budget,
    TypeRegistry? registry,
  ) => [
    if (title case PresentationHeaderTextTitle(:final value))
      ...value
          .evaluate(context, registry: registry, budget: budget)
          .diagnostics,
    if (title case PresentationHeaderNodeTitle(:final node))
      ...node.validatePresentation(context, registry: registry, budget: budget),
    if (description case final value?)
      ...value
          .evaluate(context, registry: registry, budget: budget)
          .diagnostics,
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
      if (control != null) ...[
        ?control.label,
        ?control.description,
        ?control.semanticLabel,
      ],
    ];
    final diagnostics = <TypeDiagnostic>[
      for (final expression in expressions)
        ...expression
            .evaluate(context, registry: registry, budget: budget)
            .diagnostics,
    ];
    if (element case DateTimeInputElement(
      includeDate: false,
      includeTime: false,
    )) {
      diagnostics.add(
        _invalid("Date and time control must enable at least one part"),
      );
    }
    if (element case ChipElement(:final label, :final color)) {
      if (label.resultType is! StringType) {
        diagnostics.add(_invalid("Chip label must declare a string result"));
      }
      if (color != null &&
          !typeExpressionsEqual(
            color.resultType,
            NamedType(standardTypeRefs.color),
          )) {
        diagnostics.add(_invalid("Chip color must declare the Color type"));
      }
    }
    if (element case SectionElement(:final border?)) {
      if (border.sides.isEmpty) {
        diagnostics.add(_invalid("Section border must contain a side"));
      }
      for (final side in border.sides) {
        if (!side.width.isFinite || side.width <= 0) {
          diagnostics.add(
            _invalid("Section border width must be finite and positive"),
          );
        }
      }
      for (final color in border.colors) {
        if (!typeExpressionsEqual(
          color.resultType,
          NamedType(standardTypeRefs.color),
        )) {
          diagnostics.add(
            _invalid("Section border color must declare the Color type"),
          );
        }
      }
    }
    if (element case PaddingElement(
      :final top,
      :final start,
      :final end,
      :final bottom,
    )) {
      if ([
        top,
        start,
        end,
        bottom,
      ].any((value) => !value.isFinite || value < 0)) {
        diagnostics.add(_invalid("Padding must be finite and nonnegative"));
      }
    }
    if (element case PresentationSlotElement(
      :final slotId,
    ) when slotId.isEmpty) {
      diagnostics.add(_invalid("Presentation slot ID must not be empty"));
    }
    if (element case CollectionGraphElement(:final node)) {
      final slots = node.presentationSlotIds;
      if (slots.isEmpty) {
        diagnostics.add(_invalid("Collection graph node must contain a slot"));
      }
      if (slots.length > 1) {
        diagnostics.add(
          _invalid("Collection graph node contains distinct slot identifiers"),
        );
      }
    }
    final sequences = switch (element) {
      RepeatedElement(:final presentation) => [presentation],
      _ => const <SequencePresentation>[],
    };
    for (final sequence in sequences) {
      if (sequence.separator != null &&
          (sequence.layout is PresentationGridLayout ||
              sequence.layout is PresentationStackLayout)) {
        diagnostics.add(
          _invalid("Grid and stack sequences do not support separators"),
        );
      }
    }
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

extension PresentationSlotDiscovery on PresentationNode {
  Set<String> get presentationSlotIds => {
    if (header?.title case PresentationHeaderNodeTitle(:final node))
      ...node.presentationSlotIds,
    ...element._presentationSlotIds,
  };
}

extension on PresentationElement {
  Set<String> get _presentationSlotIds => switch (this) {
    PresentationSlotElement(:final slotId) => {slotId},
    ChildrenLayoutElement(:final children) ||
    GridElement(:final children) ||
    StackElement(
      :final children,
    ) => {for (final child in children) ...child.presentationSlotIds},
    SingleChildLayoutElement(:final child) => child.presentationSlotIds,
    TypedFieldElement(:final presentation) =>
      presentation?.presentationSlotIds ?? const {},
    ConditionalElement(:final whenTrue, :final whenFalse) => {
      ...whenTrue.presentationSlotIds,
      ...?whenFalse?.presentationSlotIds,
    },
    RepeatedElement(:final presentation) => {
      ...presentation.item.presentationSlotIds,
      ...?presentation.empty?.presentationSlotIds,
      ...?presentation.separator?.presentationSlotIds,
    },
    ScopedBindingElement(:final child) => child.presentationSlotIds,
    CollectionLookupElement(:final found, :final missing, :final loading) => {
      ...found.presentationSlotIds,
      ...missing.presentationSlotIds,
      ...?loading?.presentationSlotIds,
    },
    CollectionGraphElement() => const {},
    SearchInputElement(:final summary) =>
      summary?.presentationSlotIds ?? const {},
    ListInputElement(:final itemPresentation) =>
      itemPresentation?.presentationSlotIds ?? const {},
    MapInputElement(:final keyPresentation, :final valuePresentation) => {
      ...?keyPresentation?.presentationSlotIds,
      ...?valuePresentation?.presentationSlotIds,
    },
    RecordInputElement(:final fieldPresentation) =>
      fieldPresentation?.presentationSlotIds ?? const {},
    PolymorphicInputElement(:final concreteTypes) => {
      for (final type in concreteTypes)
        ...?type.presentation?.presentationSlotIds,
    },
    TabsElement(:final tabs) => {
      for (final tab in tabs) ...tab.child.presentationSlotIds,
    },
    TooltipElement(:final child) => child.presentationSlotIds,
    _ => const {},
  };
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
      ChipElement(:final label, :final color) => [label, ?color],
      ProgressElement(:final value, :final maximum, :final label) => [
        value,
        maximum,
        ?label,
      ],
      SectionElement(:final border?) => border.colors,
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

extension on PresentationBorder {
  List<PresentationBorderSide> get sides => switch (this) {
    PresentationBorderAll(:final side) => [side],
    PresentationBorderSides(
      :final top,
      :final start,
      :final end,
      :final bottom,
    ) =>
      [top, start, end, bottom].nonNulls.toList(),
  };

  List<TypedExpression> get colors => switch (this) {
    PresentationBorderAll(:final side) => [?side.color],
    PresentationBorderSides(
      :final top,
      :final start,
      :final end,
      :final bottom,
    ) =>
      [?top?.color, ?start?.color, ?end?.color, ?bottom?.color],
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
