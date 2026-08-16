part of "editor_presentation_encoder.dart";

extension SkirPresentationContentEncoder on SkirPresentationEncoder {
  TypeResult<wire.PresentationElement> _text(
    TypedExpression value,
    wire.PresentationElement Function(wire.TextContent) wrap,
  ) => expressions
      .encode(value)
      .mapValue((value) => wrap(wire.TextContent(value: value)));

  TypeResult<wire.PresentationElement> _icon(IconElement value) => _pair(
    value.name,
    value.semanticLabel,
    (name, label) =>
        wire.PresentationElement.createIcon(name: name, semanticLabel: label),
  );

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
          .mapValue((text) => wire.PresentationElement.createText(value: text));
}
