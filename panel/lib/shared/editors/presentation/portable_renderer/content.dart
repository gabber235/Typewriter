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
    final icon = _icon(childScope, content.name);
    if (icon case _ResolvedFailure(:final message)) {
      return _diagnostic(message);
    }
    final color = _optionalTextColor(context, childScope, content.color);
    if (color case _ResolvedFailure(:final message)) {
      return _diagnostic(message);
    }
    final iconValue = (icon as _ResolvedValue<IconValue>).value;
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
        child: Icones.value(
          iconValue,
          color: (color as _ResolvedValue<Color?>).value,
          size: _number(childScope, content.size),
        ),
      ),
    );
  }

  Widget _renderImage(
    BuildContext context,
    skir.ImageContent content,
    PortablePresentationScope childScope,
  ) {
    final source = _string(childScope, content.source);
    if (source case _ResolvedFailure(:final message)) {
      return _diagnostic(message);
    }
    final label = _controlString(content.semanticLabel, childScope);
    final options = content.options;
    final image = Image.network(
      (source as _ResolvedValue<String>).value,
      semanticLabel: label,
      width: _displayDimension(childScope, options?.width, positive: true),
      height: _displayDimension(childScope, options?.height, positive: true),
      fit: switch (options?.fit) {
        final value when value == skir.ImageFit.contain => BoxFit.contain,
        final value when value == skir.ImageFit.cover => BoxFit.cover,
        final value when value == skir.ImageFit.fill => BoxFit.fill,
        final value when value == skir.ImageFit.fitWidth => BoxFit.fitWidth,
        final value when value == skir.ImageFit.fitHeight => BoxFit.fitHeight,
        final value when value == skir.ImageFit.none => BoxFit.none,
        final value when value == skir.ImageFit.scaleDown => BoxFit.scaleDown,
        null => null,
        _ => throw const PresentationValueFailure("Image fit is unavailable"),
      },
      alignment: options?.alignment == null
          ? Alignment.center
          : _presentationAlignment(options!.alignment!),
      errorBuilder: (_, _, _) => _diagnostic("The image could not be loaded"),
    );
    return options?.radius == null
        ? image
        : ClipRRect(
            borderRadius:
                _radius(context, options!.radius!, childScope) ??
                BorderRadius.zero,
            child: image,
          );
  }

  Widget _renderBadge(
    BuildContext context,
    skir.BadgeContent content,
    PortablePresentationScope childScope,
  ) {
    final label = _string(childScope, content.label);
    if (label case _ResolvedFailure(:final message)) {
      return _diagnostic(message);
    }
    final options = content.options;
    final style = _controlStyle(context, childScope, options?.appearance);
    final icon = _displayIcon(context, childScope, options, style);
    final border = style.decoration.border;
    return DecoratedBox(
      decoration: BoxDecoration(
        color:
            style.decoration.fillColor ??
            Theme.of(context).colorScheme.secondaryContainer,
        border:
            _hasControlAppearance(
              childScope,
              options?.appearance,
              (a) => a.border,
            )
            ? Border.fromBorderSide(border?.borderSide ?? BorderSide.none)
            : null,
        borderRadius:
            _hasControlAppearance(
                  childScope,
                  options?.appearance,
                  (a) => a.radius,
                ) &&
                border is OutlineInputBorder
            ? border.borderRadius
            : BorderRadius.circular(999),
      ),
      child: Padding(
        padding:
            style.padding ??
            EdgeInsets.symmetric(
              horizontal: style.dense == true ? 6 : context.spacing.space2,
              vertical: style.dense == true ? 2 : 3,
            ),
        child: _displayLabel(
          (label as _ResolvedValue<String>).value,
          icon,
          style.valueStyle,
        ),
      ),
    );
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
    final options = content.options;
    final style = _controlStyle(context, childScope, options?.appearance);
    final border = style.decoration.border;
    return Chip(
      label: Text(
        (label as _ResolvedValue<String>).value,
        style: style.valueStyle.copyWith(
          color:
              _hasControlAppearance(
                childScope,
                options?.appearance,
                (a) => a.valueStyle?.color,
              )
              ? style.valueStyle.color
              : foreground,
        ),
      ),
      avatar: _displayIcon(context, childScope, options, style),
      backgroundColor:
          style.decoration.fillColor ?? color.withValues(alpha: 0.18),
      padding: style.padding,
      visualDensity: style.dense == null
          ? null
          : style.dense!
          ? VisualDensity.compact
          : VisualDensity.standard,
      side:
          _hasControlAppearance(
            childScope,
            options?.appearance,
            (a) => a.border,
          )
          ? border?.borderSide ?? BorderSide.none
          : BorderSide(color: color),
      shape:
          _hasControlAppearance(
                childScope,
                options?.appearance,
                (a) => a.radius,
              ) &&
              border is OutlineInputBorder
          ? RoundedRectangleBorder(borderRadius: border.borderRadius)
          : null,
    );
  }

  Widget _renderProgress(
    BuildContext context,
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
      child: LinearProgressIndicator(
        value: (value / maximum).clamp(0, 1),
        color: _color(context, childScope, content.appearance?.color),
        backgroundColor: _color(
          context,
          childScope,
          content.appearance?.backgroundColor,
        ),
        minHeight: _displayDimension(
          childScope,
          content.appearance?.minimumHeight,
          positive: true,
        ),
        borderRadius: content.appearance?.radius == null
            ? null
            : _radius(context, content.appearance!.radius!, childScope),
      ),
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
    final options = appearance?.options;
    final style = _controlStyle(context, childScope, options?.appearance);
    final icon = _displayIcon(
      context,
      childScope,
      options,
      style,
      fallback: Icon(
        _statusIcon(tone),
        size:
            _hasControlAppearance(
              childScope,
              options?.appearance,
              (a) => a.iconSize,
            )
            ? style.iconSize
            : 14,
        color: style.iconColor ?? color,
      ),
    );
    final text = style.valueStyle.copyWith(
      color:
          _hasControlAppearance(
            childScope,
            options?.appearance,
            (a) => a.valueStyle?.color,
          )
          ? style.valueStyle.color
          : color,
    );
    final border = style.decoration.border;
    return Semantics(
      label: label,
      child: ExcludeSemantics(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: style.decoration.fillColor,
            border:
                _hasControlAppearance(
                  childScope,
                  options?.appearance,
                  (a) => a.border,
                )
                ? Border.fromBorderSide(border?.borderSide ?? BorderSide.none)
                : null,
            borderRadius:
                _hasControlAppearance(
                      childScope,
                      options?.appearance,
                      (a) => a.radius,
                    ) &&
                    border is OutlineInputBorder
                ? border.borderRadius
                : null,
          ),
          child: Padding(
            padding: style.padding ?? EdgeInsets.zero,
            child: _displayLabel(
              label,
              icon,
              text,
              gap: style.dense == true ? 4 : 6,
            ),
          ),
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
      return _styledTimeFace(
        context,
        childScope,
        content.options,
        SelectableText(
          DateFormat(
            format.value,
            Localizations.localeOf(context).toLanguageTag(),
          ).format(display),
        ),
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
        final description = display.describeRelativeTo(now: displayNow);
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
              child: ExcludeSemantics(
                child: _styledTimeFace(
                  context,
                  childScope,
                  content.options,
                  Text(label),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _renderTooltip(
    BuildContext context,
    skir.TooltipElement tooltip,
    PortablePresentationScope childScope,
  ) {
    final message = _string(childScope, tooltip.message);
    if (message case _ResolvedFailure(:final message)) {
      return _diagnostic(message);
    }
    final options = tooltip.appearance;
    final style = _controlStyle(context, childScope, options?.appearance);
    Duration? duration(int? milliseconds) {
      if (milliseconds == null) return null;
      if (milliseconds < 0) {
        throw const PresentationValueFailure(
          "Tooltip duration must be nonnegative",
        );
      }
      return Duration(milliseconds: milliseconds);
    }

    final border = style.decoration.border;
    final theme = Theme.of(context);
    final native = theme.tooltipTheme;
    final nativeDecoration = native.decoration is BoxDecoration
        ? native.decoration! as BoxDecoration
        : BoxDecoration(
            color: context.colors.surfaceRaised,
            borderRadius: context.shapes.mediumBorderRadius,
          );
    final hasPaint =
        _hasControlAppearance(childScope, options?.appearance, (a) => a.fill) ||
        _hasControlAppearance(
          childScope,
          options?.appearance,
          (a) => a.border,
        ) ||
        _hasControlAppearance(childScope, options?.appearance, (a) => a.radius);
    final decoration = !hasPaint
        ? null
        : nativeDecoration.copyWith(
            color: style.decoration.fillColor,
            border:
                _hasControlAppearance(
                  childScope,
                  options?.appearance,
                  (a) => a.border,
                )
                ? Border.fromBorderSide(border?.borderSide ?? BorderSide.none)
                : null,
            borderRadius:
                _hasControlAppearance(
                      childScope,
                      options?.appearance,
                      (a) => a.radius,
                    ) &&
                    border is OutlineInputBorder
                ? border.borderRadius
                : null,
          );
    final nativeText =
        native.textStyle ??
        theme.textTheme.bodyMedium!.copyWith(
          color: context.colors.contentPrimary,
        );
    final text = _nativeAppearanceTextStyle(
      childScope,
      options?.appearance,
      style,
    );
    final tooltipKey = GlobalKey<TooltipState>();
    return Tooltip(
      key: tooltipKey,
      message: (message as _ResolvedValue<String>).value,
      textStyle: text == null ? null : nativeText.merge(text),
      padding:
          style.padding ??
          (style.dense == true ? const EdgeInsets.all(6) : null),
      decoration: decoration,
      waitDuration: duration(options?.waitMilliseconds),
      showDuration: duration(options?.showMilliseconds),
      preferBelow: options?.preferBelow,
      child: Focus(
        skipTraversal: _hasFocusableContent(tooltip.child),
        onFocusChange: (focused) {
          if (!focused) {
            Tooltip.dismissAllToolTips();
            return;
          }
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => tooltipKey.currentState?.ensureTooltipVisible(),
          );
        },
        child: PortablePresentationNodeRenderer(
          node: tooltip.child,
          scope: childScope,
        ),
      ),
    );
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

bool _hasControlAppearance<T>(
  PortablePresentationScope scope,
  skir.InputAppearance? local,
  T? Function(skir.InputAppearance) select,
) =>
    (local != null && select(local) != null) ||
    scope.appearanceLayers.any((layer) => select(layer.appearance) != null);

double? _displayDimension(
  PortablePresentationScope scope,
  skir.ExpressionNode? expression, {
  bool positive = false,
}) {
  if (expression == null) return null;
  final value = _number(scope, expression);
  if (value == null || !value.isFinite || (positive ? value <= 0 : value < 0)) {
    throw const PresentationValueFailure(
      "Display dimensions must be finite and within their allowed range",
    );
  }
  return value;
}

Widget? _displayIcon(
  BuildContext context,
  PortablePresentationScope scope,
  skir.DisplayAppearance? options,
  _PortableControlStyle style, {
  Widget? fallback,
}) {
  final adornment = options?.icon;
  if (adornment == skir.InputAdornment.none) return null;
  final content = switch (adornment) {
    skir.InputAdornment_contentWrapper(:final value) =>
      PortablePresentationNodeRenderer(node: value, scope: scope),
    _ => fallback,
  };
  return content == null
      ? null
      : IconTheme.merge(
          data: IconThemeData(color: style.iconColor, size: style.iconSize),
          child: content,
        );
}

Widget _displayLabel(
  String label,
  Widget? icon,
  TextStyle style, {
  double gap = 6,
}) => icon == null
    ? Text(label, style: style)
    : Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          icon,
          SizedBox(width: gap),
          Flexible(child: Text(label, style: style)),
        ],
      );

TextStyle? _nativeAppearanceTextStyle(
  PortablePresentationScope scope,
  skir.InputAppearance? appearance,
  _PortableControlStyle resolved,
) {
  if (!_hasControlAppearance(scope, appearance, (a) => a.valueStyle)) {
    return null;
  }
  return _sparsePresentationTextStyle(
    color: _hasControlAppearance(scope, appearance, (a) => a.valueStyle?.color)
        ? resolved.valueStyle.color
        : null,
    fontSize:
        _hasControlAppearance(scope, appearance, (a) => a.valueStyle?.sizing)
        ? resolved.valueStyle.fontSize
        : null,
    fontVariations:
        _hasControlAppearance(scope, appearance, (a) => a.valueStyle?.weight)
        ? resolved.valueStyle.fontVariations
        : null,
  );
}

bool _hasFocusableContent(skir.PresentationNode node) {
  if (node.boundControl != null ||
      node.header != null ||
      node.element is skir.PresentationElement_buttonWrapper ||
      node.element is skir.PresentationElement_iconButtonWrapper ||
      node.element is skir.PresentationElement_menuWrapper ||
      node.element is skir.PresentationElement_tabsWrapper) {
    return true;
  }
  return node.nestedPresentationNodes.any(_hasFocusableContent);
}

Widget _styledTimeFace(
  BuildContext context,
  PortablePresentationScope scope,
  skir.DisplayAppearance? options,
  Widget child,
) {
  if (options == null && scope.appearanceLayers.isEmpty) return child;
  final style = _controlStyle(context, scope, options?.appearance);
  final text = _nativeAppearanceTextStyle(scope, options?.appearance, style);
  var content = text == null
      ? child
      : DefaultTextStyle.merge(style: text, child: child);
  final icon = _displayIcon(context, scope, options, style);
  if (icon != null) {
    content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        icon,
        SizedBox(width: style.dense == true ? 4 : 6),
        Flexible(child: content),
      ],
    );
  }
  final border = style.decoration.border;
  return DecoratedBox(
    decoration: BoxDecoration(
      color: style.decoration.fillColor,
      border: _hasControlAppearance(scope, options?.appearance, (a) => a.border)
          ? Border.fromBorderSide(border?.borderSide ?? BorderSide.none)
          : null,
      borderRadius:
          _hasControlAppearance(scope, options?.appearance, (a) => a.radius) &&
              border is OutlineInputBorder
          ? border.borderRadius
          : null,
    ),
    child: Padding(
      padding:
          style.padding ??
          (style.dense == null
              ? EdgeInsets.zero
              : EdgeInsets.symmetric(vertical: style.dense! ? 2 : 6)),
      child: content,
    ),
  );
}
