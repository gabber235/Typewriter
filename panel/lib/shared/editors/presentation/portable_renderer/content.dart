part of "../portable_presentation_renderer.dart";

extension _PortableContentRendering on PortablePresentationNodeRenderer {
  Widget _renderText(
    BuildContext context,
    skir.TextContent content,
    PortablePresentationScope childScope,
  ) {
    final value = _string(childScope, content.value);
    if (value case _ResolvedFailure(:final message)) {
      return _diagnostic(message);
    }
    final text = (value as _ResolvedValue<String>).value;
    final color = _optionalTextColor(context, childScope, content.color);
    if (color case _ResolvedFailure(:final message)) {
      return _diagnostic(message);
    }
    final sizing = _resolveTextSizing(childScope, content.sizing);
    if (sizing case _ResolvedFailure(:final message)) {
      return _diagnostic(message);
    }
    final weight = _optionalTextNumber(
      childScope,
      content.fontWeight,
      name: "Font weight",
      minimum: 1,
      maximum: 1000,
    );
    if (weight case _ResolvedFailure(:final message)) {
      return _diagnostic(message);
    }
    final italic = _optionalTextNumber(
      childScope,
      content.fontItalic,
      name: "Font italic",
      minimum: 0,
      maximum: 1,
    );
    if (italic case _ResolvedFailure(:final message)) {
      return _diagnostic(message);
    }
    final opticalSize = _optionalTextNumber(
      childScope,
      content.fontOpticalSize,
      name: "Font optical size",
      minimumExclusive: 0,
    );
    if (opticalSize case _ResolvedFailure(:final message)) {
      return _diagnostic(message);
    }
    final slant = _optionalTextNumber(
      childScope,
      content.fontSlant,
      name: "Font slant",
      minimumExclusive: -90,
      maximumExclusive: 90,
    );
    if (slant case _ResolvedFailure(:final message)) {
      return _diagnostic(message);
    }
    final width = _optionalTextNumber(
      childScope,
      content.fontWidth,
      name: "Font width",
      minimumExclusive: 0,
    );
    if (width case _ResolvedFailure(:final message)) {
      return _diagnostic(message);
    }
    final alignment = _optionalTextAlignment(childScope, content.textAlignment);
    if (alignment case _ResolvedFailure(:final message)) {
      return _diagnostic(message);
    }
    final lineHeight = _optionalTextNumber(
      childScope,
      content.lineHeight,
      name: "Line height",
      minimum: 0,
    );
    if (lineHeight case _ResolvedFailure(:final message)) {
      return _diagnostic(message);
    }
    final letterSpacing = _optionalTextNumber(
      childScope,
      content.letterSpacing,
      name: "Letter spacing",
    );
    if (letterSpacing case _ResolvedFailure(:final message)) {
      return _diagnostic(message);
    }
    final decoration = _optionalTextDecoration(childScope, content.decoration);
    if (decoration case _ResolvedFailure(:final message)) {
      return _diagnostic(message);
    }
    final semanticLabel = _optionalTextString(
      childScope,
      content.semanticLabel,
      name: "Semantic label",
    );
    if (semanticLabel case _ResolvedFailure(:final message)) {
      return _diagnostic(message);
    }
    final paragraph = content.paragraph;
    return TextSpan(text: text).renderParagraph(
      context,
      sizing: (sizing as _ResolvedValue<ResolvedTextSizing?>).value,
      paragraph: paragraph,
      semanticLabel: (semanticLabel as _ResolvedValue<String?>).value,
      textAlign: (alignment as _ResolvedValue<TextAlign?>).value,
      style: DefaultTextStyle.of(context).style.copyWith(
        color:
            (color as _ResolvedValue<Color?>).value ??
            _paragraphToneColor(context, paragraph.tone),
        fontVariations: [
          if ((weight as _ResolvedValue<double?>).value case final value?)
            FontVariation.weight(value),
          if ((italic as _ResolvedValue<double?>).value case final value?)
            FontVariation.italic(value),
          if ((opticalSize as _ResolvedValue<double?>).value case final value?)
            FontVariation.opticalSize(value),
          if ((slant as _ResolvedValue<double?>).value case final value?)
            FontVariation.slant(value),
          if ((width as _ResolvedValue<double?>).value case final value?)
            FontVariation.width(value),
        ],
        height: (lineHeight as _ResolvedValue<double?>).value,
        letterSpacing: (letterSpacing as _ResolvedValue<double?>).value,
        decoration: (decoration as _ResolvedValue<TextDecoration?>).value,
      ),
    );
  }

  Widget _renderMarkdown(
    BuildContext context,
    skir.TextContent content,
    PortablePresentationScope childScope,
  ) {
    final sizing = _resolveTextSizing(childScope, content.sizing);
    if (sizing case _ResolvedFailure(:final message)) {
      return _diagnostic(message);
    }
    final resolved = (sizing as _ResolvedValue<ResolvedTextSizing?>).value;
    if (resolved is FitTextSizing) {
      return _diagnostic("Markdown does not support fitted text sizing");
    }
    final color = _optionalTextColor(context, childScope, content.color);
    if (color case _ResolvedFailure(:final message)) {
      return _diagnostic(message);
    }
    final foreground =
        (color as _ResolvedValue<Color?>).value ??
        _paragraphToneColor(context, content.paragraph.tone);
    final theme = Theme.of(context);
    final textTheme = theme.textTheme.apply(
      bodyColor: foreground,
      displayColor: foreground,
    );
    final value = _string(childScope, content.value);
    return switch (value) {
      _ResolvedValue(:final value) => MarkdownBody(
        data: value,
        selectable: content.paragraph.selectable,
        styleSheet:
            MarkdownStyleSheet.fromTheme(
              theme.copyWith(textTheme: textTheme),
            ).copyWith(
              p: DefaultTextStyle.of(context).style.copyWith(
                color: foreground,
                fontSize: resolved is ExactTextSizing ? resolved.size : null,
              ),
            ),
      ),
      _ResolvedFailure(:final message) => _diagnostic(message),
    };
  }

  Widget _renderIcon(
    BuildContext context,
    skir.IconContent content,
    PortablePresentationScope childScope,
  ) {
    final name = _string(childScope, content.name);
    if (name case _ResolvedFailure(:final message)) {
      return _diagnostic(message);
    }
    final color = _optionalTextColor(context, childScope, content.color);
    if (color case _ResolvedFailure(:final message)) {
      return _diagnostic(message);
    }
    final iconName = (name as _ResolvedValue<String>).value;
    final label = content.semanticLabel == null
        ? null
        : switch (_string(childScope, content.semanticLabel!)) {
            _ResolvedValue(:final value) => value,
            _ => null,
          };
    return Semantics(
      label: label,
      image: true,
      child: ExcludeSemantics(
        child: Icones(
          iconName,
          color: (color as _ResolvedValue<Color?>).value,
          size: _number(childScope, content.size),
        ),
      ),
    );
  }

  Widget _renderImage(
    skir.ImageContent content,
    PortablePresentationScope childScope,
  ) {
    final source = _string(childScope, content.source);
    if (source case _ResolvedFailure(:final message)) {
      return _diagnostic(message);
    }
    final label = _controlString(content.semanticLabel, childScope);
    return Image.network(
      (source as _ResolvedValue<String>).value,
      semanticLabel: label,
      errorBuilder: (_, _, _) => _diagnostic("The image could not be loaded"),
    );
  }

  Widget _renderBadge(
    BuildContext context,
    skir.BadgeContent content,
    PortablePresentationScope childScope,
  ) {
    final label = _string(childScope, content.label);
    return switch (label) {
      _ResolvedValue(:final value) => DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.secondaryContainer,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: context.spacing.space2,
            vertical: 3,
          ),
          child: Text(value),
        ),
      ),
      _ResolvedFailure(:final message) => _diagnostic(message),
    };
  }

  Widget _renderChip(
    BuildContext context,
    skir.ChipContent content,
    PortablePresentationScope childScope,
  ) {
    final label = _string(childScope, content.label);
    if (label case _ResolvedFailure(:final message)) {
      return _diagnostic(message);
    }
    final resolvedColor = _optionalTextColor(
      context,
      childScope,
      content.color,
    );
    if (resolvedColor case _ResolvedFailure(:final message)) {
      return _diagnostic(message);
    }
    final color =
        (resolvedColor as _ResolvedValue<Color?>).value ??
        Theme.of(context).colorScheme.primary;
    final hsl = HSLColor.fromColor(color);
    final foreground = Theme.of(context).brightness == Brightness.dark
        ? color
        : hsl.withLightness(hsl.lightness.clamp(0.2, 0.4)).toColor();
    return Chip(
      label: Text(
        (label as _ResolvedValue<String>).value,
        style: DefaultTextStyle.of(context).style.copyWith(color: foreground),
      ),
      backgroundColor: color.withValues(alpha: 0.18),
      side: BorderSide(color: color),
    );
  }

  Widget _renderProgress(
    skir.ProgressContent content,
    PortablePresentationScope childScope,
  ) {
    final value = _number(childScope, content.value);
    final maximum = _number(childScope, content.maximum);
    if (value == null || maximum == null || maximum <= 0) {
      return _diagnostic("The progress value is unavailable");
    }
    final label = _controlString(content.label, childScope);
    return Semantics(
      label: label,
      value: value.toString(),
      child: LinearProgressIndicator(value: (value / maximum).clamp(0, 1)),
    );
  }

  Widget _renderStatus(
    BuildContext context,
    skir.StatusContent content,
    PortablePresentationScope childScope,
  ) {
    final result = childScope.evaluate(content.value);
    if (result is! PortableExpressionAvailable) {
      return _diagnostic("The status value is unavailable");
    }
    final appearance =
        content.cases
            .where((candidate) => candidate.match == result.value)
            .firstOrNull
            ?.appearance ??
        content.fallback;
    final tone = appearance?.tone ?? skir.StatusTone.unknownStatus;
    final labelResult = appearance?.label == null
        ? _ResolvedValue(portableExpressionDisplayText(result.value))
        : _string(childScope, appearance!.label!);
    if (labelResult case _ResolvedFailure(:final message)) {
      return _diagnostic(message);
    }
    final label = (labelResult as _ResolvedValue<String>).value;
    final color = _statusColor(context, tone);
    return Semantics(
      label: label,
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_statusIcon(tone), size: 14, color: color),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: DefaultTextStyle.of(context).style
                    .copyWith(color: color),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _renderDateTime(
    BuildContext context,
    skir.DateTimeContent content,
    PortablePresentationScope childScope,
  ) {
    final value = childScope.evaluate(content.value);
    final format = _string(childScope, content.format);
    final timestamp = switch (value) {
      PortableExpressionAvailable(
        value: skir.DataValue_timestampWrapper(:final value),
      ) =>
        value,
      _ => null,
    };
    if (timestamp == null || format is! _ResolvedValue<String>) {
      return _diagnostic("The date and time value is unavailable");
    }
    try {
      final display = content.timeZone == skir.DateTimeZone.utc
          ? timestamp.toUtc()
          : timestamp.toLocal();
      return SelectableText(
        DateFormat(
          format.value,
          Localizations.localeOf(context).toLanguageTag(),
        ).format(display),
      );
    } on FormatException catch (error) {
      return _diagnostic("Invalid date and time format: ${error.message}");
    }
  }

  Widget _renderRelativeTime(
    BuildContext context,
    skir.RelativeTimeContent content,
    PortablePresentationScope childScope,
  ) {
    final value = childScope.evaluate(content.value);
    final timestamp = switch (value) {
      PortableExpressionAvailable(
        value: skir.DataValue_timestampWrapper(:final value),
      ) =>
        value,
      _ => null,
    };
    if (timestamp == null) {
      return _diagnostic("The relative time value is unavailable");
    }
    return HookBuilder(
      builder: (context) {
        final now = clock.now();
        final display = content.timeZone == skir.DateTimeZone.utc
            ? timestamp.toUtc()
            : timestamp.toLocal();
        final displayNow = content.timeZone == skir.DateTimeZone.utc
            ? now.toUtc()
            : now.toLocal();
        final description = describeRelativeTime(
          value: display,
          now: displayNow,
        );
        useRefreshAt(description.nextRefreshAt, now: clock.now);
        final tooltipKey = useMemoized(GlobalKey<TooltipState>.new);
        final label = content.style == skir.RelativeTimeStyle.compact
            ? description.compact
            : description.natural;
        final exact = DateFormat(
          "yyyy/MM/dd HH:mm:ss",
          Localizations.localeOf(context).toLanguageTag(),
        ).format(display);
        return Tooltip(
          key: tooltipKey,
          message: exact,
          child: Focus(
            onFocusChange: (focused) {
              if (!focused) {
                Tooltip.dismissAllToolTips();
                return;
              }
              WidgetsBinding.instance.addPostFrameCallback((_) {
                tooltipKey.currentState?.ensureTooltipVisible();
              });
            },
            child: Semantics(
              label: description.natural,
              child: ExcludeSemantics(child: Text(label)),
            ),
          ),
        );
      },
    );
  }

  Widget _renderTooltip(
    skir.TooltipElement tooltip,
    PortablePresentationScope childScope,
  ) {
    final message = _string(childScope, tooltip.message);
    return switch (message) {
      _ResolvedValue(:final value) => Tooltip(
        message: value,
        child: PortablePresentationNodeRenderer(
          node: tooltip.child,
          scope: childScope,
        ),
      ),
      _ResolvedFailure(:final message) => _diagnostic(message),
    };
  }

  Widget _renderRichText(
    BuildContext context,
    skir.RichTextContent content,
    PortablePresentationScope childScope,
  ) {
    final sizing = _resolveTextSizing(childScope, content.sizing);
    if (sizing case _ResolvedFailure(:final message)) {
      return _diagnostic(message);
    }
    final overall = _resolveTextStyle(context, childScope, content.style);
    if (overall case _ResolvedFailure(:final message)) {
      return _diagnostic(message);
    }
    final spans = <InlineSpan>[];
    for (final run in content.runs) {
      final text = _string(childScope, run.text);
      if (text case _ResolvedFailure(:final message)) {
        return _diagnostic(message);
      }
      final style = _resolveTextStyle(
        context,
        childScope,
        run.style,
        inheritedVariations:
            (overall as _ResolvedValue<TextStyle?>).value?.fontVariations,
      );
      if (style case _ResolvedFailure(:final message)) {
        return _diagnostic(message);
      }
      spans.add(
        TextSpan(
          text: (text as _ResolvedValue<String>).value,
          style: (style as _ResolvedValue<TextStyle?>).value,
        ),
      );
    }
    return TextSpan(children: spans).renderParagraph(
      context,
      sizing: (sizing as _ResolvedValue<ResolvedTextSizing?>).value,
      paragraph: content.paragraph,
      style: DefaultTextStyle.of(context).style
          .copyWith(color: _paragraphToneColor(context, content.paragraph.tone))
          .merge((overall as _ResolvedValue<TextStyle?>).value),
    );
  }
}

extension _PortableParagraphRendering on TextSpan {
  Widget renderParagraph(
    BuildContext context, {
    required ResolvedTextSizing? sizing,
    required skir.TextParagraph paragraph,
    required TextStyle style,
    String? semanticLabel,
    TextAlign? textAlign,
  }) {
    if (paragraph.maxLines != null && paragraph.maxLines! <= 0) {
      return _diagnostic("Maximum text lines must be positive");
    }
    final fontSize = switch (sizing) {
      ExactTextSizing(:final size) => size,
      FitTextSizing(:final maximum) => maximum,
      null => null,
    };
    final resolvedStyle = style.copyWith(fontSize: fontSize);
    final overflow =
        paragraph.overflow == skir.PresentationTextOverflow.ellipsis
        ? TextOverflow.ellipsis
        : TextOverflow.clip;
    final direction = Directionality.of(context);
    final locale = Localizations.maybeLocaleOf(context);
    // The installed fitter approximates nonlinear scaling and does not measure
    // extra accessibility letter spacing. Keep its behavior in one shared path.
    final widget = switch (sizing) {
      FitTextSizing(:final minimum, :final maximum) => AutoSizeText.rich(
        this,
        style: resolvedStyle,
        minFontSize: minimum,
        maxFontSize: maximum,
        maxLines: paragraph.maxLines,
        softWrap: paragraph.softWrap,
        overflow: overflow,
        semanticsLabel: semanticLabel,
        textAlign: textAlign,
        textDirection: direction,
        locale: locale,
      ),
      _ => Text.rich(
        this,
        style: resolvedStyle,
        maxLines: paragraph.maxLines,
        softWrap: paragraph.softWrap,
        overflow: overflow,
        semanticsLabel: semanticLabel,
        textAlign: textAlign,
        textDirection: direction,
        locale: locale,
      ),
    };
    return paragraph.selectable ? SelectionArea(child: widget) : widget;
  }
}
