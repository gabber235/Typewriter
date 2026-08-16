part of "editor_presentation_codec.dart";

extension SkirPresentationContentDecoder on SkirPresentationDecoder {
  TypeResult<PresentationElement> _text(
    wire.TextContent value,
    PresentationElement Function(TypedExpression) create,
  ) => expressions.decode(value.value).mapValue(create);

  TypeResult<PresentationElement> _icon(wire.IconContent value) =>
      combineResults(
        expressions.decode(value.name),
        _optionalExpression(value.semanticLabel),
        (name, label) => IconElement(name: name, semanticLabel: label),
      );

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
