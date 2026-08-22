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
    for (final padding in [headerPadding, contentPadding])
      if (padding != null &&
          padding.values.any((value) => !value.isFinite || value < 0))
        _invalid("Header padding must be finite and nonnegative"),
  ];
}

extension on PresentationInsets {
  List<double> get values => switch (this) {
    PresentationInsetsAll(:final value) => [value],
    PresentationInsetsSymmetric(:final horizontal, :final vertical) => [
      horizontal,
      vertical,
    ],
    PresentationInsetsOnly(
      :final top,
      :final left,
      :final right,
      :final bottom,
    ) =>
      [top, left, right, bottom],
  };
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
    if (element case TextInputElement(:final inputFormatters)) {
      for (final formatter in inputFormatters) {
        if (formatter.pattern case final pattern?) {
          try {
            RegExp(pattern);
          } on FormatException {
            diagnostics.add(
              _invalid("Text input formatter pattern is malformed"),
            );
          }
        }
      }
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
    if (element case StatusElement(
      :final value,
      :final cases,
      :final fallback,
    )) {
      final matches = <DataValue>{};
      for (final item in cases) {
        diagnostics.addAll(
          item.match.validateAgainst(value.resultType, registry: registry),
        );
        if (!matches.add(item.match)) {
          diagnostics.add(_invalid("Status cases must have unique values"));
        }
        diagnostics.addAll(item.appearance._validateLabel());
      }
      diagnostics.addAll(fallback?._validateLabel() ?? const []);
    }
    if (element case DateTimeElement(:final value, :final format)) {
      if (value.resultType is! TimestampType) {
        diagnostics.add(
          _invalid("Date time value must declare a timestamp result"),
        );
      }
      if (format.resultType is! StringType) {
        diagnostics.add(
          _invalid("Date time format must declare a string result"),
        );
      } else if (format
              .evaluate(context, registry: registry, budget: budget)
              .valueOrNull
          case StringValue(:final value)) {
        if (dateTimePatternError(value) != null) {
          diagnostics.add(_invalid("Date time format is malformed"));
        }
      }
    }
    if (element case RelativeTimeElement(
      :final value,
    ) when value.resultType is! TimestampType) {
      diagnostics.add(
        _invalid("Relative time value must declare a timestamp result"),
      );
    }
    final border = switch (element) {
      SectionElement(:final border) ||
      ContainerElement(:final border) => border,
      _ => null,
    };
    if (border != null) {
      if (border.sides.isEmpty) {
        diagnostics.add(_invalid("Presentation border must contain a side"));
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
    if (element case CollectionGraphElement(
      :final node,
      :final rootSequence,
      :final children,
    )) {
      final nodeSlots = node.presentationSlotIds;
      final rootSlots = rootSequence.item.presentationSlotIds;
      final childSlots = children.item.presentationSlotIds;
      if (rootSlots.length != 1) {
        diagnostics.add(
          _invalid("Collection graph root template must contain one slot"),
        );
      }
      if (nodeSlots.length != 1 || childSlots.length != 1) {
        diagnostics.add(
          _invalid("Collection graph templates must contain one logical slot"),
        );
      } else if (nodeSlots.single != childSlots.single) {
        diagnostics.add(_invalid("Collection graph child slots must match"));
      }
    }
    if (element case PresentationAnchorElement(:final anchors)) {
      final identifiers = <String>{};
      for (final anchor in anchors) {
        if (anchor.id.isEmpty) {
          diagnostics.add(_invalid("Anchor identifier must not be empty"));
        } else if (!identifiers.add(anchor.id)) {
          diagnostics.add(
            _invalid("Duplicate local anchor identifier: ${anchor.id}"),
          );
        }
        if (anchor.groupIds.any((group) => group.isEmpty)) {
          diagnostics.add(
            _invalid("Anchor group identifier must not be empty"),
          );
        }
      }
    }
    if (element case ConnectionLayerElement(:final connections)) {
      for (final connection in connections) {
        if (connection case AnchoredConnectionBundle(:final trunkMarkers)) {
          if (trunkMarkers.any(
            (marker) => marker.scope == ConnectionExpressionScope.target,
          )) {
            diagnostics.add(
              _invalid("Bundle trunk markers cannot use a target scope"),
            );
          }
        }
      }
    }
    final sequences = switch (element) {
      RepeatedElement(:final presentation) => [presentation],
      CollectionGraphElement(:final rootSequence, :final children) => [
        rootSequence,
        children,
      ],
      _ => const <SequencePresentation>[],
    };
    for (final sequence in sequences) {
      final standardLayout = switch (sequence.layout) {
        PresentationStandardSequenceLayout(:final layout) => layout,
        PresentationHierarchySequenceLayout() => null,
      };
      if (sequence.separator != null &&
          sequence.layout is PresentationHierarchySequenceLayout) {
        diagnostics.add(
          _invalid("Hierarchy sequences do not support separators"),
        );
      } else if (sequence.separator != null &&
          (standardLayout is PresentationGridLayout ||
              standardLayout is PresentationStackLayout)) {
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
    PolymorphicMatchElement(:final cases, :final fallback) => {
      for (final item in cases) ...item.child.presentationSlotIds,
      ...?fallback?.presentationSlotIds,
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
      TextElement(
        :final value,
        :final color,
        :final fontSize,
        :final fontWeight,
        :final fontItalic,
        :final fontOpticalSize,
        :final fontSlant,
        :final fontWidth,
        :final textAlignment,
        :final lineHeight,
        :final letterSpacing,
        :final decoration,
        :final semanticLabel,
      ) =>
        [
          value,
          ?color,
          ?fontSize,
          ?fontWeight,
          ?fontItalic,
          ?fontOpticalSize,
          ?fontSlant,
          ?fontWidth,
          ?textAlignment,
          ?lineHeight,
          ?letterSpacing,
          ?decoration,
          ?semanticLabel,
        ],
      MarkdownElement(:final value, :final color) => [value, ?color],
      IconElement(
        :final name,
        :final semanticLabel,
        :final color,
        :final size,
      ) =>
        [name, ?semanticLabel, ?color, ?size],
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
      StatusElement(:final value, :final cases, :final fallback) => [
        value,
        for (final item in cases) ?item.appearance.label,
        ?fallback?.label,
      ],
      DateTimeElement(:final value, :final format) => [value, format],
      RelativeTimeElement(:final value) => [value],
      SectionElement(:final border?) => border.colors,
      ContainerElement(:final border, :final backgroundColor, :final radius) =>
        [...?border?.colors, ?backgroundColor, ...radius.expressions],
      PresentationAnchorElement(:final anchors) => [
        for (final anchor in anchors) ...[
          ?anchor.visibleIf,
          ...?anchor.offset?.expressions,
        ],
      ],
      ConnectionLayerElement(:final connections) => [
        for (final connection in connections) ?connection.visibleIf,
      ],
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

extension on StatusAppearance {
  List<TypeDiagnostic> _validateLabel() =>
      label != null && label!.resultType is! StringType
      ? [_invalid("Status label must declare a string result")]
      : const [];
}

extension on TextInputFormat {
  String? get pattern => switch (this) {
    ReplaceTextInputFormat(:final pattern) ||
    AllowTextInputFormat(:final pattern) ||
    DenyTextInputFormat(:final pattern) => pattern,
    _ => null,
  };
}

extension on PresentationRadius {
  List<TypedExpression> get expressions => switch (this) {
    CustomPresentationRadius(:final value) => [value],
    _ => const [],
  };
}

extension on PresentationOffset {
  List<TypedExpression> get expressions => [x, y];
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
