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

  TypeResult<PresentationElement> _status(wire.StatusContent value) {
    final source = expressions.decode(value.value);
    final cases = value.cases.map(_statusCase).toList();
    final fallback = value.fallback == null
        ? const TypeResult<StatusAppearance?>.success(null)
        : _statusAppearance(value.fallback!).mapValue((item) => item);
    final diagnostics = [
      ...source.diagnostics,
      ...cases.expand((item) => item.diagnostics),
      ...fallback.diagnostics,
    ];
    return diagnostics.isEmpty
        ? TypeResult.success(
            StatusElement(
              value: source.valueOrNull!,
              cases: cases.map((item) => item.valueOrNull!).toList(),
              fallback: fallback.valueOrNull,
            ),
          )
        : TypeResult.failure(diagnostics);
  }

  TypeResult<StatusCase> _statusCase(wire.StatusCase value) => combineResults(
    expressions.valueCodec.decode(value.match),
    _statusAppearance(value.appearance),
    (match, appearance) => StatusCase(match: match, appearance: appearance),
  );

  TypeResult<StatusAppearance> _statusAppearance(wire.StatusAppearance value) =>
      _optionalExpression(value.label).mapValue(
        (label) => StatusAppearance(tone: value.tone._decode, label: label),
      );

  TypeResult<PresentationElement> _dateTime(wire.DateTimeContent value) =>
      combineResults(
        expressions.decode(value.value),
        expressions.decode(value.format),
        (source, format) => DateTimeElement(
          value: source,
          format: format,
          timeZone: value.timeZone._decode,
        ),
      );

  TypeResult<PresentationElement> _relativeTime(
    wire.RelativeTimeContent value,
  ) => expressions
      .decode(value.value)
      .mapValue(
        (source) => RelativeTimeElement(
          value: source,
          style: value.style._decode,
          timeZone: value.timeZone._decode,
        ),
      );
}

extension on wire.StatusTone {
  StatusTone get _decode => switch (this) {
    wire.StatusTone.neutral => StatusTone.neutral,
    wire.StatusTone.unknownStatus ||
    wire.StatusTone_unknown() => StatusTone.unknown,
    wire.StatusTone.information => StatusTone.information,
    wire.StatusTone.success => StatusTone.success,
    wire.StatusTone.warning => StatusTone.warning,
    wire.StatusTone.danger => StatusTone.danger,
    wire.StatusTone.active => StatusTone.active,
    wire.StatusTone.inactive => StatusTone.inactive,
    wire.StatusTone.online => StatusTone.online,
    wire.StatusTone.offline => StatusTone.offline,
    wire.StatusTone.pending => StatusTone.pending,
    wire.StatusTone.inProgress => StatusTone.inProgress,
    wire.StatusTone.paused => StatusTone.paused,
  };
}

extension on wire.DateTimeZone {
  DateTimeZone get _decode => switch (this) {
    wire.DateTimeZone.local => DateTimeZone.local,
    wire.DateTimeZone.utc => DateTimeZone.utc,
    wire.DateTimeZone_unknown() => DateTimeZone.local,
  };
}

extension on wire.RelativeTimeStyle {
  RelativeTimeStyle get _decode => switch (this) {
    wire.RelativeTimeStyle.compact => RelativeTimeStyle.compact,
    wire.RelativeTimeStyle.natural => RelativeTimeStyle.natural,
    wire.RelativeTimeStyle_unknown() => RelativeTimeStyle.compact,
  };
}
