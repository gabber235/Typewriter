part of "editor_presentation_encoder.dart";

extension SkirPresentationContentEncoder on SkirPresentationEncoder {
  TypeResult<wire.PresentationElement> _text(TextElement value) {
    final text = expressions.encode(value.value);
    final color = _optional(value.color);
    final fontSize = _optional(value.fontSize);
    final fontWeight = _optional(value.fontWeight);
    final fontItalic = _optional(value.fontItalic);
    final fontOpticalSize = _optional(value.fontOpticalSize);
    final fontSlant = _optional(value.fontSlant);
    final fontWidth = _optional(value.fontWidth);
    final textAlignment = _optional(value.textAlignment);
    final lineHeight = _optional(value.lineHeight);
    final letterSpacing = _optional(value.letterSpacing);
    final decoration = _optional(value.decoration);
    final semanticLabel = _optional(value.semanticLabel);
    final diagnostics = [
      ...text.diagnostics,
      ...color.diagnostics,
      ...fontSize.diagnostics,
      ...fontWeight.diagnostics,
      ...fontItalic.diagnostics,
      ...fontOpticalSize.diagnostics,
      ...fontSlant.diagnostics,
      ...fontWidth.diagnostics,
      ...textAlignment.diagnostics,
      ...lineHeight.diagnostics,
      ...letterSpacing.diagnostics,
      ...decoration.diagnostics,
      ...semanticLabel.diagnostics,
    ];
    return diagnostics.isEmpty
        ? TypeResult.success(
            wire.PresentationElement.createText(
              value: text.valueOrNull!,
              color: color.valueOrNull,
              fontSize: fontSize.valueOrNull,
              fontWeight: fontWeight.valueOrNull,
              fontItalic: fontItalic.valueOrNull,
              fontOpticalSize: fontOpticalSize.valueOrNull,
              fontSlant: fontSlant.valueOrNull,
              fontWidth: fontWidth.valueOrNull,
              textAlignment: textAlignment.valueOrNull,
              lineHeight: lineHeight.valueOrNull,
              letterSpacing: letterSpacing.valueOrNull,
              decoration: decoration.valueOrNull,
              semanticLabel: semanticLabel.valueOrNull,
            ),
          )
        : TypeResult.failure(diagnostics);
  }

  TypeResult<wire.PresentationElement> _markdown(MarkdownElement value) =>
      combineResults(
        expressions.encode(value.value),
        _optional(value.color),
        (text, color) => wire.PresentationElement.createMarkdown(
          value: text,
          color: color,
          fontSize: null,
          fontWeight: null,
          fontItalic: null,
          fontOpticalSize: null,
          fontSlant: null,
          fontWidth: null,
          textAlignment: null,
          lineHeight: null,
          letterSpacing: null,
          decoration: null,
          semanticLabel: null,
        ),
      );

  TypeResult<wire.PresentationElement> _icon(IconElement value) {
    final name = expressions.encode(value.name);
    final label = _optional(value.semanticLabel);
    final color = _optional(value.color);
    final size = _optional(value.size);
    final diagnostics = [
      ...name.diagnostics,
      ...label.diagnostics,
      ...color.diagnostics,
      ...size.diagnostics,
    ];
    return diagnostics.isEmpty
        ? TypeResult.success(
            wire.PresentationElement.createIcon(
              name: name.valueOrNull!,
              semanticLabel: label.valueOrNull,
              color: color.valueOrNull,
              size: size.valueOrNull,
            ),
          )
        : TypeResult.failure(diagnostics);
  }

  TypeResult<wire.PresentationElement> _image(ImageElement value) => _pair(
    value.source,
    value.semanticLabel,
    (source, label) => wire.PresentationElement.createImage(
      source: source,
      semanticLabel: label,
    ),
  );

  TypeResult<wire.PresentationElement> _badge(BadgeElement value) => expressions
      .encode(value.label)
      .mapValue(
        (label) => wire.PresentationElement.createBadge(
          label: label,
          tone: value.tone,
        ),
      );

  TypeResult<wire.PresentationElement> _chip(ChipElement value) =>
      combineResults(
        expressions.encode(value.label),
        _optional(value.color),
        (label, color) =>
            wire.PresentationElement.createChip(label: label, color: color),
      );

  TypeResult<wire.PresentationElement> _progress(ProgressElement value) {
    final progress = expressions.encode(value.value);
    final maximum = expressions.encode(value.maximum);
    final label = _optional(value.label);
    final diagnostics = [
      ...progress.diagnostics,
      ...maximum.diagnostics,
      ...label.diagnostics,
    ];
    return diagnostics.isEmpty
        ? TypeResult.success(
            wire.PresentationElement.createProgress(
              value: progress.valueOrNull!,
              maximum: maximum.valueOrNull!,
              label: label.valueOrNull,
            ),
          )
        : TypeResult.failure(diagnostics);
  }

  TypeResult<wire.PresentationElement> _pair(
    TypedExpression first,
    TypedExpression? second,
    wire.PresentationElement Function(
      wire_expression.TypedExpression,
      wire_expression.TypedExpression?,
    )
    create,
  ) => combineResults(expressions.encode(first), _optional(second), create);

  TypeResult<wire.PresentationElement> _diagnostic(DiagnosticElement value) =>
      expressions
          .encode(
            value.diagnostics
                .map((item) => item.message)
                .join("\n")
                .asStringLiteral,
          )
          .mapValue(
            (text) => wire.PresentationElement.createText(
              value: text,
              color: null,
              fontSize: null,
              fontWeight: null,
              fontItalic: null,
              fontOpticalSize: null,
              fontSlant: null,
              fontWidth: null,
              textAlignment: null,
              lineHeight: null,
              letterSpacing: null,
              decoration: null,
              semanticLabel: null,
            ),
          );
}
