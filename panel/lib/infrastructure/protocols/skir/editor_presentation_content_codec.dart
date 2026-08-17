part of "editor_presentation_codec.dart";

extension SkirPresentationContentDecoder on SkirPresentationDecoder {
  TypeResult<PresentationElement> _text(wire.TextContent value) {
    final text = expressions.decode(value.value);
    final color = _optionalExpression(value.color);
    final fontSize = _optionalExpression(value.fontSize);
    final fontWeight = _optionalExpression(value.fontWeight);
    final fontItalic = _optionalExpression(value.fontItalic);
    final fontOpticalSize = _optionalExpression(value.fontOpticalSize);
    final fontSlant = _optionalExpression(value.fontSlant);
    final fontWidth = _optionalExpression(value.fontWidth);
    final textAlignment = _optionalExpression(value.textAlignment);
    final lineHeight = _optionalExpression(value.lineHeight);
    final letterSpacing = _optionalExpression(value.letterSpacing);
    final decoration = _optionalExpression(value.decoration);
    final semanticLabel = _optionalExpression(value.semanticLabel);
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
            TextElement(
              text.valueOrNull!,
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

  TypeResult<PresentationElement> _markdown(wire.TextContent value) =>
      combineResults(
        expressions.decode(value.value),
        _optionalExpression(value.color),
        (text, color) => MarkdownElement(text, color: color),
      );

  TypeResult<PresentationElement> _icon(wire.IconContent value) {
    final name = expressions.decode(value.name);
    final label = _optionalExpression(value.semanticLabel);
    final color = _optionalExpression(value.color);
    final size = _optionalExpression(value.size);
    final diagnostics = [
      ...name.diagnostics,
      ...label.diagnostics,
      ...color.diagnostics,
      ...size.diagnostics,
    ];
    return diagnostics.isEmpty
        ? TypeResult.success(
            IconElement(
              name: name.valueOrNull!,
              semanticLabel: label.valueOrNull,
              color: color.valueOrNull,
              size: size.valueOrNull,
            ),
          )
        : TypeResult.failure(diagnostics);
  }

  TypeResult<PresentationElement> _image(wire.ImageContent value) =>
      combineResults(
        expressions.decode(value.source),
        _optionalExpression(value.semanticLabel),
        (source, label) => ImageElement(source: source, semanticLabel: label),
      );

  TypeResult<PresentationElement> _badge(wire.BadgeContent value) => expressions
      .decode(value.label)
      .mapValue((label) => BadgeElement(label: label, tone: value.tone));

  TypeResult<PresentationElement> _chip(wire.ChipContent value) =>
      combineResults(
        expressions.decode(value.label),
        _optionalExpression(value.color),
        (label, color) => ChipElement(label: label, color: color),
      );

  TypeResult<PresentationElement> _progress(wire.ProgressContent value) {
    final progress = expressions.decode(value.value);
    final maximum = expressions.decode(value.maximum);
    final label = _optionalExpression(value.label);
    final diagnostics = [
      ...progress.diagnostics,
      ...maximum.diagnostics,
      ...label.diagnostics,
    ];
    return diagnostics.isEmpty
        ? TypeResult.success(
            ProgressElement(
              value: progress.valueOrNull!,
              maximum: maximum.valueOrNull!,
              label: label.valueOrNull,
            ),
          )
        : TypeResult.failure(diagnostics);
  }
}
