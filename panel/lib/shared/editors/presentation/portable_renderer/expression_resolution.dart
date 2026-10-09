part of "../portable_presentation_renderer.dart";

sealed class _Resolved<T> {
  const _Resolved();
}

final class _ResolvedValue<T> extends _Resolved<T> {
  const _ResolvedValue(this.value);

  final T value;
}

final class _ResolvedFailure<T> extends _Resolved<T> {
  const _ResolvedFailure(this.message);

  final String message;
}

_Resolved<bool> _boolean(
  PortablePresentationScope scope,
  skir.ExpressionNode? expressionNode, {
  bool fallback = false,
}) {
  if (expressionNode == null) return _ResolvedValue(fallback);
  return switch (scope.evaluate(expressionNode)) {
    PortableExpressionAvailable(:final value)
        when value.authoredPayload is skir.DataValue_booleanWrapper =>
      _ResolvedValue(
        (value.authoredPayload as skir.DataValue_booleanWrapper).value,
      ),
    PortableExpressionAvailable() => const _ResolvedFailure(
      "The presentation condition is not boolean",
    ),
    PortableExpressionUnavailable() => const _ResolvedFailure(
      "The presentation condition is unavailable",
    ),
    PortableExpressionFailed(:final message) => _ResolvedFailure(message),
  };
}

_Resolved<String> _string(
  PortablePresentationScope scope,
  skir.ExpressionNode expressionNode,
) => switch (scope.evaluate(expressionNode)) {
  PortableExpressionAvailable(:final value) when value.authoredString != null =>
    _ResolvedValue(value.authoredString!),
  PortableExpressionAvailable() => const _ResolvedFailure(
    "The presentation value is not text",
  ),
  PortableExpressionUnavailable() => const _ResolvedFailure(
    "The presentation value is unavailable",
  ),
  PortableExpressionFailed(:final message) => _ResolvedFailure(message),
};

Widget _diagnostic(String message) => Builder(
  builder: (context) => Text(
    message,
    style: context.theme.textTheme.bodyMedium?.copyWith(
      color: context.colors.danger,
    ),
  ),
);

String? _controlString(
  skir.ExpressionNode? value,
  PortablePresentationScope scope,
) {
  if (value == null) return null;
  return switch (_string(scope, value)) {
    _ResolvedValue(:final value) => value,
    _ResolvedFailure() => null,
  };
}

Widget? _controlText(
  skir.ExpressionNode? value,
  PortablePresentationScope scope,
) {
  final text = _controlString(value, scope);
  return text == null ? null : Text(text);
}

double? _number(PortablePresentationScope scope, skir.ExpressionNode? value) {
  if (value == null) return null;
  return switch (scope.evaluate(value)) {
    PortableExpressionAvailable(value: final result) =>
      switch (result.authoredPayload) {
        skir.DataValue_integerWrapper(:final value) => double.tryParse(value),
        skir.DataValue_floatWrapper(:final value) => value,
        skir.DataValue_decimalWrapper(:final value) => double.tryParse(value),
        _ => null,
      },
    _ => null,
  };
}

double? _dataNumber(skir.DataValue? value) => switch (value) {
  skir.DataValue_integerWrapper(:final value) => double.tryParse(value),
  skir.DataValue_floatWrapper(:final value) => value,
  skir.DataValue_decimalWrapper(:final value) => double.tryParse(value),
  _ => null,
};

Color? _color(PortablePresentationScope scope, skir.ExpressionNode? value) {
  if (value == null) return null;
  return switch (scope.evaluate(value)) {
    PortableExpressionAvailable(value: final result)
        when result.authoredInteger != null =>
      Color(result.authoredInteger!.toUnsigned(32).toInt()),
    _ => null,
  };
}

_Resolved<Color?> _optionalTextColor(
  PortablePresentationScope scope,
  skir.ExpressionNode? expressionNode,
) {
  if (expressionNode == null) return const _ResolvedValue(null);
  return switch (scope.evaluate(expressionNode)) {
    PortableExpressionAvailable(value: final value)
        when value.authoredInteger != null =>
      _ResolvedValue(Color(value.authoredInteger!.toUnsigned(32).toInt())),
    PortableExpressionAvailable() => const _ResolvedFailure(
      "Text color must evaluate to a color",
    ),
    PortableExpressionUnavailable() => const _ResolvedFailure(
      "Text color is unavailable",
    ),
    PortableExpressionFailed(:final message) => _ResolvedFailure(message),
  };
}

_Resolved<double?> _optionalTextNumber(
  PortablePresentationScope scope,
  skir.ExpressionNode? expressionNode, {
  required String name,
  double? minimum,
  double? maximum,
  double? minimumExclusive,
  double? maximumExclusive,
}) {
  if (expressionNode == null) return const _ResolvedValue(null);
  final evaluated = scope.evaluate(expressionNode);
  if (evaluated case PortableExpressionFailed(:final message)) {
    return _ResolvedFailure(message);
  }
  if (evaluated is PortableExpressionUnavailable) {
    return _ResolvedFailure("$name is unavailable");
  }
  final value = _dataNumber((evaluated as PortableExpressionAvailable).value);
  if (value == null || !value.isFinite) {
    return _ResolvedFailure("$name must evaluate to a finite number");
  }
  if (minimum != null && value < minimum) {
    return _ResolvedFailure("$name must be at least $minimum");
  }
  if (maximum != null && value > maximum) {
    return _ResolvedFailure("$name must be at most $maximum");
  }
  if (minimumExclusive != null && value <= minimumExclusive) {
    return _ResolvedFailure("$name must be greater than $minimumExclusive");
  }
  if (maximumExclusive != null && value >= maximumExclusive) {
    return _ResolvedFailure("$name must be less than $maximumExclusive");
  }
  return _ResolvedValue(value);
}

_Resolved<String?> _optionalTextString(
  PortablePresentationScope scope,
  skir.ExpressionNode? expressionNode, {
  required String name,
}) {
  if (expressionNode == null) return const _ResolvedValue(null);
  return switch (scope.evaluate(expressionNode)) {
    PortableExpressionAvailable(:final value)
        when value.authoredString != null =>
      _ResolvedValue(value.authoredString),
    PortableExpressionAvailable() => _ResolvedFailure(
      "$name must evaluate to text",
    ),
    PortableExpressionUnavailable() => _ResolvedFailure("$name is unavailable"),
    PortableExpressionFailed(:final message) => _ResolvedFailure(message),
  };
}

_Resolved<TextAlign?> _optionalTextAlignment(
  PortablePresentationScope scope,
  skir.ExpressionNode? expressionNode,
) {
  final resolved = _optionalTextString(
    scope,
    expressionNode,
    name: "Text alignment",
  );
  if (resolved case _ResolvedFailure(:final message)) {
    return _ResolvedFailure(message);
  }
  return switch ((resolved as _ResolvedValue<String?>).value) {
    null => const _ResolvedValue(null),
    "start" => const _ResolvedValue(TextAlign.start),
    "center" => const _ResolvedValue(TextAlign.center),
    "end" => const _ResolvedValue(TextAlign.end),
    "justify" => const _ResolvedValue(TextAlign.justify),
    _ => const _ResolvedFailure(
      "Text alignment must be start, center, end, or justify",
    ),
  };
}

_Resolved<TextDecoration?> _optionalTextDecoration(
  PortablePresentationScope scope,
  skir.ExpressionNode? expressionNode,
) {
  final resolved = _optionalTextString(
    scope,
    expressionNode,
    name: "Text decoration",
  );
  if (resolved case _ResolvedFailure(:final message)) {
    return _ResolvedFailure(message);
  }
  return switch ((resolved as _ResolvedValue<String?>).value) {
    null => const _ResolvedValue(null),
    "none" => const _ResolvedValue(TextDecoration.none),
    "underline" => const _ResolvedValue(TextDecoration.underline),
    "strikethrough" => const _ResolvedValue(TextDecoration.lineThrough),
    _ => const _ResolvedFailure(
      "Text decoration must be none, underline, or strikethrough",
    ),
  };
}

_Resolved<ResolvedTextSizing?> _resolveTextSizing(
  PortablePresentationScope scope,
  skir.TextSizing? sizing,
) {
  if (sizing == null) return const _ResolvedValue(null);
  switch (sizing) {
    case skir.TextSizing_exactWrapper(:final value):
      final size = _optionalTextNumber(
        scope,
        value,
        name: "Font size",
        minimumExclusive: 0,
      );
      return switch (size) {
        _ResolvedValue(:final value) => _ResolvedValue(
          ResolvedTextSizing.exact(value!),
        ),
        _ResolvedFailure(:final message) => _ResolvedFailure(message),
      };
    case skir.TextSizing_fitWrapper(:final value):
      final min = _optionalTextNumber(
        scope,
        value.minimum,
        name: "Minimum font size",
        minimumExclusive: 0,
      );
      if (min case _ResolvedFailure(:final message)) {
        return _ResolvedFailure(message);
      }
      final max = _optionalTextNumber(
        scope,
        value.maximum,
        name: "Maximum font size",
        minimumExclusive: 0,
      );
      if (max case _ResolvedFailure(:final message)) {
        return _ResolvedFailure(message);
      }
      final minimum = (min as _ResolvedValue<double?>).value!;
      final maximum = (max as _ResolvedValue<double?>).value!;
      if (minimum > maximum) {
        return const _ResolvedFailure(
          "Minimum font size must not exceed maximum font size",
        );
      }
      if (minimum % 1 != 0 || maximum % 1 != 0) {
        return const _ResolvedFailure(
          "Fit bounds must be whole logical font sizes",
        );
      }
      return _ResolvedValue(
        ResolvedTextSizing.fit(minimum: minimum, maximum: maximum),
      );
    case skir.TextSizing_unknown():
      return const _ResolvedFailure("Unknown text sizing policy");
  }
}

_Resolved<TextStyle?> _resolveTextStyle(
  PortablePresentationScope scope,
  skir.TextStyleOverride? style, {
  List<FontVariation>? inheritedVariations,
}) {
  if (style == null) return const _ResolvedValue(null);
  final color = _optionalTextColor(scope, style.color);
  if (color case _ResolvedFailure(:final message)) {
    return _ResolvedFailure(message);
  }
  final weight = _optionalTextNumber(
    scope,
    style.fontWeight,
    name: "Font weight",
    minimum: 1,
    maximum: 1000,
  );
  if (weight case _ResolvedFailure(:final message)) {
    return _ResolvedFailure(message);
  }
  final italic = _optionalTextNumber(
    scope,
    style.fontItalic,
    name: "Font italic",
    minimum: 0,
    maximum: 1,
  );
  if (italic case _ResolvedFailure(:final message)) {
    return _ResolvedFailure(message);
  }
  final decoration = _optionalTextDecoration(scope, style.decoration);
  if (decoration case _ResolvedFailure(:final message)) {
    return _ResolvedFailure(message);
  }
  final weightValue = (weight as _ResolvedValue<double?>).value;
  final italicValue = (italic as _ResolvedValue<double?>).value;
  final variations = [
    for (final variation in inheritedVariations ?? <FontVariation>[])
      if ((variation.axis != "wght" || weightValue == null) &&
          (variation.axis != "ital" || italicValue == null))
        variation,
    if (weightValue != null) FontVariation.weight(weightValue),
    if (italicValue != null) FontVariation.italic(italicValue),
  ];
  return _ResolvedValue(
    TextStyle(
      color: (color as _ResolvedValue<Color?>).value,
      fontVariations: variations.isEmpty ? null : variations,
      decoration: (decoration as _ResolvedValue<TextDecoration?>).value,
    ),
  );
}
