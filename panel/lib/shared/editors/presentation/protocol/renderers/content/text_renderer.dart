part of "../../content_renderer.dart";

extension TextElementRendering on TextElement {
  Widget render(PresentationRenderScope scope) {
    final resolved = _resolveTextPresentation(this, scope);
    if (resolved case TypeFailure(:final diagnostics)) {
      return Builder(
        builder: (context) => presentationDiagnostic(context, diagnostics),
      );
    }
    final presentation = resolved.valueOrNull!;
    return SelectableText(
      scope.expressionText(value),
      semanticsLabel: presentation.semanticLabel,
      textAlign: presentation.textAlignment,
      style: TextStyle(
        color: presentation.color,
        fontSize: presentation.fontSize,
        fontVariations: presentation.fontVariations,
        height: presentation.lineHeight,
        letterSpacing: presentation.letterSpacing,
        decoration: presentation.decoration,
      ),
    );
  }
}

TypeResult<_ResolvedTextPresentation> _resolveTextPresentation(
  TextElement element,
  PresentationRenderScope scope,
) {
  final color = resolvePresentationColor(element.color, scope);
  final fontSize = _resolveTextNumber(
    element.fontSize,
    scope,
    name: "Font size",
    minimum: 0,
  );
  final fontVariations = _resolveTextFontVariations(element, scope);
  final textAlignment = _resolveTextAlignment(element.textAlignment, scope);
  final lineHeight = _resolveTextNumber(
    element.lineHeight,
    scope,
    name: "Line height",
    minimum: 0,
  );
  final letterSpacing = _resolveTextNumber(
    element.letterSpacing,
    scope,
    name: "Letter spacing",
  );
  final decoration = _resolveTextDecoration(element.decoration, scope);
  final semanticLabel = _resolveTextString(
    element.semanticLabel,
    scope,
    name: "Semantic label",
  );
  final diagnostics = [
    ...color.diagnostics,
    ...fontSize.diagnostics,
    ...fontVariations.diagnostics,
    ...textAlignment.diagnostics,
    ...lineHeight.diagnostics,
    ...letterSpacing.diagnostics,
    ...decoration.diagnostics,
    ...semanticLabel.diagnostics,
  ];
  return diagnostics.isEmpty
      ? TypeResult.success(
          _ResolvedTextPresentation(
            color: color.valueOrNull,
            fontSize: fontSize.valueOrNull,
            fontVariations: fontVariations.valueOrNull,
            textAlignment: textAlignment.valueOrNull,
            lineHeight: lineHeight.valueOrNull,
            letterSpacing: letterSpacing.valueOrNull,
            decoration: decoration.valueOrNull,
            semanticLabel: semanticLabel.valueOrNull,
          ),
        )
      : TypeResult.failure(diagnostics);
}

TypeResult<List<FontVariation>?> _resolveTextFontVariations(
  TextElement element,
  PresentationRenderScope scope,
) {
  final weight = _resolveTextNumber(
    element.fontWeight,
    scope,
    name: "Font weight",
    minimum: 1,
    maximum: 1000,
  );
  final italic = _resolveTextNumber(
    element.fontItalic,
    scope,
    name: "Font italic",
    minimum: 0,
    maximum: 1,
  );
  final opticalSize = _resolveTextNumber(
    element.fontOpticalSize,
    scope,
    name: "Font optical size",
    minimumExclusive: 0,
  );
  final slant = _resolveTextNumber(
    element.fontSlant,
    scope,
    name: "Font slant",
    minimumExclusive: -90,
    maximumExclusive: 90,
  );
  final width = _resolveTextNumber(
    element.fontWidth,
    scope,
    name: "Font width",
    minimumExclusive: 0,
  );
  final diagnostics = [
    ...weight.diagnostics,
    ...italic.diagnostics,
    ...opticalSize.diagnostics,
    ...slant.diagnostics,
    ...width.diagnostics,
  ];
  if (diagnostics.isNotEmpty) return TypeResult.failure(diagnostics);

  final variations = <FontVariation>[
    if (weight.valueOrNull case final value?) FontVariation.weight(value),
    if (italic.valueOrNull case final value?) FontVariation.italic(value),
    if (opticalSize.valueOrNull case final value?)
      FontVariation.opticalSize(value),
    if (slant.valueOrNull case final value?) FontVariation.slant(value),
    if (width.valueOrNull case final value?) FontVariation.width(value),
  ];
  return TypeResult.success(variations.isEmpty ? null : variations);
}

TypeResult<TextAlign?> _resolveTextAlignment(
  TypedExpression? expression,
  PresentationRenderScope scope,
) {
  final result = _resolveTextString(expression, scope, name: "Text alignment");
  if (result case TypeFailure(:final diagnostics)) {
    return TypeResult.failure(diagnostics);
  }
  return switch (result.valueOrNull) {
    null => const TypeResult.success(null),
    "start" => const TypeResult.success(TextAlign.start),
    "center" => const TypeResult.success(TextAlign.center),
    "end" => const TypeResult.success(TextAlign.end),
    "justify" => const TypeResult.success(TextAlign.justify),
    _ => _invalidTextStyle(
      'Text alignment must be "start", "center", "end", or "justify"',
    ),
  };
}

TypeResult<TextDecoration?> _resolveTextDecoration(
  TypedExpression? expression,
  PresentationRenderScope scope,
) {
  final result = _resolveTextString(expression, scope, name: "Text decoration");
  if (result case TypeFailure(:final diagnostics)) {
    return TypeResult.failure(diagnostics);
  }
  return switch (result.valueOrNull) {
    null => const TypeResult.success(null),
    "none" => const TypeResult.success(TextDecoration.none),
    "underline" => const TypeResult.success(TextDecoration.underline),
    "strikethrough" => const TypeResult.success(TextDecoration.lineThrough),
    _ => _invalidTextStyle(
      'Text decoration must be "none", "underline", or "strikethrough"',
    ),
  };
}

TypeResult<double?> _resolveTextNumber(
  TypedExpression? expression,
  PresentationRenderScope scope, {
  required String name,
  double? minimum,
  double? maximum,
  double? minimumExclusive,
  double? maximumExclusive,
}) {
  if (expression == null) return const TypeResult.success(null);
  final result = scope.evaluate(expression);
  if (result case TypeFailure(:final diagnostics)) {
    return TypeResult.failure(diagnostics);
  }
  final value = switch (result.valueOrNull) {
    FloatValue(:final value) => value,
    IntegerValue(:final value) => value.toDouble(),
    _ => null,
  };
  if (value == null || !value.isFinite) {
    return _invalidTextStyle("$name must evaluate to a finite number");
  }
  if (minimum != null && value < minimum) {
    return _invalidTextStyle("$name must be at least $minimum");
  }
  if (maximum != null && value > maximum) {
    return _invalidTextStyle("$name must be at most $maximum");
  }
  if (minimumExclusive != null && value <= minimumExclusive) {
    return _invalidTextStyle("$name must be greater than $minimumExclusive");
  }
  if (maximumExclusive != null && value >= maximumExclusive) {
    return _invalidTextStyle("$name must be less than $maximumExclusive");
  }
  return TypeResult.success(value);
}

TypeResult<String?> _resolveTextString(
  TypedExpression? expression,
  PresentationRenderScope scope, {
  required String name,
}) {
  if (expression == null) return const TypeResult.success(null);
  final result = scope.evaluate(expression);
  if (result case TypeFailure(:final diagnostics)) {
    return TypeResult.failure(diagnostics);
  }
  return switch (result.valueOrNull) {
    StringValue(:final value) => TypeResult.success(value),
    _ => _invalidTextStyle("$name must evaluate to text"),
  };
}

TypeFailure<T> _invalidTextStyle<T>(String message) => TypeFailure([
  TypeDiagnostic(code: TypeDiagnosticCode.invalidValue, message: message),
]);

final class _ResolvedTextPresentation {
  const _ResolvedTextPresentation({
    required this.color,
    required this.fontSize,
    required this.fontVariations,
    required this.textAlignment,
    required this.lineHeight,
    required this.letterSpacing,
    required this.decoration,
    required this.semanticLabel,
  });

  final Color? color;
  final double? fontSize;
  final List<FontVariation>? fontVariations;
  final TextAlign? textAlignment;
  final double? lineHeight;
  final double? letterSpacing;
  final TextDecoration? decoration;
  final String? semanticLabel;
}
