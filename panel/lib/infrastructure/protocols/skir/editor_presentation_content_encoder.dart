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

  TypeResult<wire.PresentationElement> _status(StatusElement value) {
    final source = expressions.encode(value.value);
    final cases = value.cases.map(_statusCase).toList();
    final fallback = value.fallback == null
        ? const TypeResult<wire.StatusAppearance?>.success(null)
        : _statusAppearance(value.fallback!).mapValue((item) => item);
    final diagnostics = [
      ...source.diagnostics,
      ...cases.expand((item) => item.diagnostics),
      ...fallback.diagnostics,
    ];
    return diagnostics.isEmpty
        ? TypeResult.success(
            wire.PresentationElement.createStatus(
              value: source.valueOrNull!,
              cases: cases.map((item) => item.valueOrNull!).toList(),
              fallback: fallback.valueOrNull,
            ),
          )
        : TypeResult.failure(diagnostics);
  }

  TypeResult<wire.StatusCase> _statusCase(StatusCase value) => combineResults(
    expressions.values.encode(value.match),
    _statusAppearance(value.appearance),
    (match, appearance) =>
        wire.StatusCase(match: match, appearance: appearance),
  );

  TypeResult<wire.StatusAppearance> _statusAppearance(StatusAppearance value) =>
      _optional(value.label).mapValue(
        (label) =>
            wire.StatusAppearance(tone: value.tone._encode, label: label),
      );

  TypeResult<wire.PresentationElement> _dateTime(DateTimeElement value) =>
      combineResults(
        expressions.encode(value.value),
        expressions.encode(value.format),
        (source, format) => wire.PresentationElement.createDateTime(
          value: source,
          format: format,
          timeZone: value.timeZone._encode,
        ),
      );

  TypeResult<wire.PresentationElement> _relativeTime(
    RelativeTimeElement value,
  ) => expressions
      .encode(value.value)
      .mapValue(
        (source) => wire.PresentationElement.createRelativeTime(
          value: source,
          style: value.style._encode,
          timeZone: value.timeZone._encode,
        ),
      );

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

extension on StatusTone {
  wire.StatusTone get _encode => switch (this) {
    StatusTone.neutral => wire.StatusTone.neutral,
    StatusTone.unknown => wire.StatusTone.unknownStatus,
    StatusTone.information => wire.StatusTone.information,
    StatusTone.success => wire.StatusTone.success,
    StatusTone.warning => wire.StatusTone.warning,
    StatusTone.danger => wire.StatusTone.danger,
    StatusTone.active => wire.StatusTone.active,
    StatusTone.inactive => wire.StatusTone.inactive,
    StatusTone.online => wire.StatusTone.online,
    StatusTone.offline => wire.StatusTone.offline,
    StatusTone.pending => wire.StatusTone.pending,
    StatusTone.inProgress => wire.StatusTone.inProgress,
    StatusTone.paused => wire.StatusTone.paused,
  };
}

extension on DateTimeZone {
  wire.DateTimeZone get _encode => switch (this) {
    DateTimeZone.local => wire.DateTimeZone.local,
    DateTimeZone.utc => wire.DateTimeZone.utc,
  };
}

extension on RelativeTimeStyle {
  wire.RelativeTimeStyle get _encode => switch (this) {
    RelativeTimeStyle.compact => wire.RelativeTimeStyle.compact,
    RelativeTimeStyle.natural => wire.RelativeTimeStyle.natural,
  };
}
