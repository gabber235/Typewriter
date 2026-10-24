part of "../portable_presentation_renderer.dart";

/// Captures an appearance declaration with the lexical bindings it was authored
/// under. Each property inherits from the nearest layer defining that property;
/// expressions keep their original bindings after nested control rebinding.
@freezed
abstract class PortableAppearanceLayer with _$PortableAppearanceLayer {
  const factory PortableAppearanceLayer({
    required skir.InputAppearance appearance,
    required Map<skir.ExpressionBindingId, PortableExpressionBinding> bindings,
    required skir.EvaluationBudget budget,
  }) = _PortableAppearanceLayer;
}

@freezed
abstract class _PortableControlStyle with _$PortableControlStyle {
  const factory _PortableControlStyle({
    required InputDecoration decoration,
    required TextStyle valueStyle,
    required TextStyle labelStyle,
    required TextStyle descriptionStyle,
    required TextAlign alignment,
    required double iconSize,
    Color? iconColor,
    EdgeInsetsGeometry? padding,
    bool? dense,
  }) = _ResolvedPortableControlStyle;
}

_PortableControlStyle _controlStyle(
  BuildContext context,
  PortablePresentationScope scope,
  skir.InputAppearance? appearance, {
  PresentationValueEnvironment? environment,
}) {
  final layers = [
    ...scope.appearanceLayers,
    if (appearance != null)
      PortableAppearanceLayer(
        appearance: appearance,
        bindings: scope.bindings,
        budget: scope.budget,
      ),
  ];
  PortableAppearanceLayer? origin<T>(
    T? Function(skir.InputAppearance) property,
  ) {
    for (final layer in layers.reversed) {
      if (property(layer.appearance) != null) return layer;
    }
    return null;
  }

  T? property<T>(T? Function(skir.InputAppearance) select) {
    final layer = origin(select);
    return layer == null ? null : select(layer.appearance);
  }

  PortablePresentationScope evaluation(PortableAppearanceLayer layer) =>
      scope.copyWith(bindings: layer.bindings, budget: layer.budget);
  Color? color(skir.PresentationColor? Function(skir.InputAppearance) select) {
    final layer = origin(select);
    return layer == null
        ? null
        : (environment ?? PresentationValueEnvironment.of(context)).resolve(
            select(layer.appearance)!,
            evaluation(layer),
          );
  }

  TextStyle text(
    TextStyle base,
    skir.InputTextStyle? Function(skir.InputAppearance) select,
  ) {
    final textColor = color((a) => select(a)?.color);
    final weight = property((a) => select(a)?.weight);
    if (weight != null && (weight < 1 || weight > 1000)) {
      throw const PresentationValueFailure(
        "Input font weight must be between 1 and 1000",
      );
    }
    final sizingOrigin = origin((a) => select(a)?.sizing);
    double? size;
    if (sizingOrigin != null) {
      final sizing = _resolveTextSizing(
        evaluation(sizingOrigin),
        select(sizingOrigin.appearance)!.sizing,
      );
      switch (sizing) {
        case _ResolvedValue<ResolvedTextSizing?>(
          value: ExactTextSizing(:final size),
        ):
          return base.copyWith(
            color: textColor,
            fontSize: size,
            fontVariations: weight == null
                ? null
                : [
                    ...?base.fontVariations?.where((v) => v.axis != "wght"),
                    FontVariation.weight(weight.toDouble()),
                  ],
          );
        case _ResolvedFailure(:final message):
          throw PresentationValueFailure(message);
        case _ResolvedValue<ResolvedTextSizing?>(value: FitTextSizing()):
          throw const PresentationValueFailure(
            "Editable input text cannot use fitted sizing",
          );
        default:
          break;
      }
    }
    return base.copyWith(
      color: textColor,
      fontSize: size,
      fontVariations: weight == null
          ? null
          : [
              ...?base.fontVariations?.where((v) => v.axis != "wght"),
              FontVariation.weight(weight.toDouble()),
            ],
    );
  }

  final theme = Theme.of(context);
  final native = theme.inputDecorationTheme;
  final borderOrigin = origin((a) => a.border);
  InputBorder? border;
  if (borderOrigin != null) {
    switch (borderOrigin.appearance.border) {
      case final value when value == skir.BorderOverride.none:
        border = InputBorder.none;
      case skir.BorderOverride_valueWrapper(:final value):
        if (value is! skir.PresentationBorder_allWrapper) {
          throw const PresentationValueFailure(
            "Input borders must use one uniform side",
          );
        }
        border = OutlineInputBorder(
          borderSide: _borderSide(
            context,
            value.value,
            evaluation(borderOrigin),
          ),
        );
      default:
        throw const PresentationValueFailure("The input border is unavailable");
    }
  }
  final radiusOrigin = origin((a) => a.radius);
  if (radiusOrigin != null) {
    final radius = _radius(
      context,
      radiusOrigin.appearance.radius!,
      evaluation(radiusOrigin),
    );
    final current = border ?? native.border;
    border = current is UnderlineInputBorder
        ? current.copyWith(borderRadius: radius)
        : OutlineInputBorder(
            borderSide: border == InputBorder.none
                ? BorderSide.none
                : current?.borderSide ?? const BorderSide(),
            borderRadius: radius ?? BorderRadius.zero,
          );
  }
  final padding = property((a) => a.padding);
  final density = property((a) => a.density);
  final fill = color((a) => a.fill);
  final body = theme.textTheme.bodyMedium ?? DefaultTextStyle.of(context).style;
  final hint = text(native.hintStyle ?? body, (a) => a.placeholderStyle);
  final iconSizeOrigin = origin((a) => a.iconSize);
  final iconSize = iconSizeOrigin == null
      ? 18.0
      : _number(
              evaluation(iconSizeOrigin),
              iconSizeOrigin.appearance.iconSize,
            ) ??
            (throw const PresentationValueFailure(
              "The input icon size is unavailable",
            ));
  if (!iconSize.isFinite || iconSize <= 0) {
    throw const PresentationValueFailure("Input icon size must be positive");
  }
  return _PortableControlStyle(
    decoration: InputDecoration(
      hintStyle: hint,
      isDense: density == null ? null : density == skir.ControlDensity.compact,
      contentPadding: padding == null ? null : _presentationInsets(padding),
      fillColor: fill,
      filled: fill == null ? null : true,
      border: border,
      enabledBorder: borderOrigin == null ? null : border,
      focusedBorder: borderOrigin == null ? null : border,
      disabledBorder: borderOrigin == null ? null : border,
      errorBorder: borderOrigin == null ? null : border,
      focusedErrorBorder: borderOrigin == null ? null : border,
    ),
    valueStyle: text(body, (a) => a.valueStyle),
    labelStyle: text(theme.textTheme.labelLarge ?? body, (a) => a.labelStyle),
    descriptionStyle: text(
      theme.textTheme.bodySmall ?? body,
      (a) => a.descriptionStyle,
    ),
    alignment: switch (property((a) => a.alignment)) {
      final value when value == skir.InputTextAlignment.center =>
        TextAlign.center,
      final value when value == skir.InputTextAlignment.end => TextAlign.end,
      _ => TextAlign.start,
    },
    iconColor: color((a) => a.iconColor),
    iconSize: iconSize,
    padding: padding == null ? null : _presentationInsets(padding),
    dense: density == null ? null : density == skir.ControlDensity.compact,
  );
}

Widget? _entryLeading(
  BuildContext context,
  skir.BoundControl control,
  skir.InputContent? content,
  PortablePresentationScope scope,
  _PortableControlStyle style,
  IconData? defaultIcon,
) {
  final leading = content?.leading;
  if (leading == skir.InputAdornment.none) return null;
  final prefix = switch (leading) {
    skir.InputAdornment_contentWrapper(:final value) => ScopedControlPrefix(
      node: value,
      scope: scope,
    ),
    _ => scope.associationFor(control).prefix,
  };
  if (prefix != null) {
    return IconTheme.merge(
      data: IconThemeData(color: style.iconColor, size: style.iconSize),
      child: DefaultTextStyle.merge(
        style: style.valueStyle.copyWith(
          color: style.iconColor,
          fontSize: style.iconSize,
        ),
        child: Align(
          alignment: Alignment.center,
          widthFactor: 1,
          heightFactor: 1,
          child: prefix.render(scope),
        ),
      ),
    );
  }
  return defaultIcon == null
      ? null
      : Icon(defaultIcon, size: style.iconSize, color: style.iconColor);
}

bool _interactiveAdornment(skir.PresentationNode? node) {
  if (node == null) return false;
  final pending = [node];
  while (pending.isNotEmpty) {
    final current = pending.removeLast();
    if (current.boundControl != null ||
        current.element is skir.PresentationElement_buttonWrapper ||
        current.element is skir.PresentationElement_iconButtonWrapper ||
        current.element is skir.PresentationElement_menuWrapper ||
        current.element is skir.PresentationElement_tabsWrapper ||
        (current.header?.items.isNotEmpty ?? false)) {
      return true;
    }
    pending.addAll(current.nestedPresentationNodes);
  }
  return false;
}

Widget _entryComposition({
  required Widget child,
  Widget? leading,
  Widget? trailing,
}) => leading == null && trailing == null
    ? child
    : Row(
        children: [
          ?leading,
          Expanded(child: child),
          ?trailing,
        ],
      );

Widget? _entrySuffix(
  skir.InputContent? content,
  PortablePresentationScope scope,
) {
  final suffix = content?.suffix;
  if (suffix == null) return null;
  return PortablePresentationNodeRenderer(node: suffix, scope: scope);
}

String? _entryPlaceholder(
  skir.InputContent? content,
  PortablePresentationScope scope,
) => content?.placeholder == null
    ? null
    : switch (_string(scope, content!.placeholder!)) {
        _ResolvedValue(:final value) => value,
        _ResolvedFailure(:final message) => throw PresentationValueFailure(
          message,
        ),
      };

class _PortableControlStateScope extends InheritedWidget {
  const _PortableControlStateScope({
    required this.controller,
    required super.child,
  });
  final WidgetStatesController controller;
  static WidgetStatesController? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<_PortableControlStateScope>()
      ?.controller;
  @override
  bool updateShouldNotify(_PortableControlStateScope oldWidget) =>
      controller != oldWidget.controller;
}

class _PortableControlFrameState extends HookWidget {
  const _PortableControlFrameState({required this.scope, required this.child});
  final PortablePresentationScope scope;
  final Widget child;
  @override
  Widget build(BuildContext context) {
    final controller = useMemoized(WidgetStatesController.new);
    useEffect(() => controller.dispose, [controller]);
    final observation = useWidgetStateObservation(controller);
    return _PortableControlStateScope(
      controller: controller,
      child: ValueListenableBuilder<Set<WidgetState>>(
        valueListenable: observation,
        builder: (context, states, _) => PresentationInteractionScope(
          value: PresentationInteraction.fromWidgetStates(states).copyWith(
            disabled: states.contains(WidgetState.disabled) || !scope.enabled,
            readOnly: scope.readOnly,
            invalid: states.contains(WidgetState.error),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _PortableControlInteraction extends HookWidget {
  const _PortableControlInteraction({
    required this.scope,
    required this.builder,
  });
  final PortablePresentationScope scope;
  final Widget Function(
    BuildContext,
    WidgetStatesController,
    ValueChanged<String?>,
  )
  builder;
  @override
  Widget build(BuildContext context) {
    final inherited = _PortableControlStateScope.maybeOf(context);
    final states = useMemoized(() => inherited ?? WidgetStatesController(), [
      inherited,
    ]);
    useEffect(() => inherited == null ? states.dispose : null, [
      states,
      inherited,
    ]);
    final invalid = useState(false);
    final observedStates = useWidgetStateObservation(states);
    return ValueListenableBuilder<Set<WidgetState>>(
      valueListenable: observedStates,
      builder: (context, values, _) => PresentationInteractionScope(
        value: PresentationInteraction.fromWidgetStates(values).copyWith(
          disabled: values.contains(WidgetState.disabled) || !scope.enabled,
          readOnly: scope.readOnly,
          invalid:
              invalid.value || PortableControlDiagnostics.of(context).invalid,
        ),
        child: Builder(
          builder: (context) {
            try {
              return builder(context, states, (message) {
                if (context.mounted && invalid.value != (message != null)) {
                  invalid.value = message != null;
                  states.update(WidgetState.error, message != null);
                }
              });
            } on PresentationValueFailure catch (failure) {
              return _diagnostic(failure.message);
            } on FormatException catch (failure) {
              return _diagnostic(failure.message);
            }
          },
        ),
      ),
    );
  }
}

Widget _controlSurface(_PortableControlStyle style, Widget child) => Material(
  type: style.decoration.fillColor == null
      ? MaterialType.transparency
      : MaterialType.canvas,
  color: style.decoration.fillColor,
  shape: style.decoration.border,
  textStyle: style.valueStyle,
  child: IconTheme.merge(
    data: IconThemeData(color: style.iconColor, size: style.iconSize),
    child: DefaultTextStyle.merge(style: style.valueStyle, child: child),
  ),
);
