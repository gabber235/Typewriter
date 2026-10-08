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
