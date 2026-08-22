part of "../../content_renderer.dart";

extension DateTimeElementRendering on DateTimeElement {
  Widget render(BuildContext context, PresentationRenderScope scope) {
    final source = scope.evaluate(value);
    final resolvedFormat = scope.evaluate(format);
    final diagnostics = [...source.diagnostics, ...resolvedFormat.diagnostics];
    if (diagnostics.isNotEmpty) {
      return presentationDiagnostic(context, diagnostics);
    }
    final sourceValue = source.valueOrNull;
    if (sourceValue is! TimestampValue) {
      return presentationDiagnostic(context, [
        const TypeDiagnostic(
          code: TypeDiagnosticCode.invalidValue,
          message: "Date time value must evaluate to a timestamp",
        ),
      ]);
    }
    final formatValue = resolvedFormat.valueOrNull;
    if (formatValue is! StringValue) {
      return presentationDiagnostic(context, [
        const TypeDiagnostic(
          code: TypeDiagnosticCode.invalidValue,
          message: "Date time format must evaluate to a string",
        ),
      ]);
    }
    final timestamp = sourceValue.value;
    final pattern = formatValue.value;
    if (dateTimePatternError(pattern) case final error?) {
      return presentationDiagnostic(context, [
        TypeDiagnostic(
          code: TypeDiagnosticCode.invalidValue,
          message: "Invalid date time format: $error",
        ),
      ]);
    }
    try {
      final locale = Localizations.localeOf(context).toLanguageTag();
      final text = DateFormat(pattern, locale).format(
        timeZone == DateTimeZone.utc ? timestamp.toUtc() : timestamp.toLocal(),
      );
      return SelectableText(text);
    } on FormatException catch (error) {
      return presentationDiagnostic(context, [
        TypeDiagnostic(
          code: TypeDiagnosticCode.invalidValue,
          message: "Invalid date time format: ${error.message}",
        ),
      ]);
    }
  }
}

extension RelativeTimeElementRendering on RelativeTimeElement {
  Widget render(BuildContext context, PresentationRenderScope scope) =>
      _RelativeTimeContent(element: this, scope: scope);
}

class _RelativeTimeContent extends HookWidget {
  const _RelativeTimeContent({
    required this.element,
    required this.scope,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final RelativeTimeElement element;
  final PresentationRenderScope scope;
  final DateTime Function() _now;

  @override
  Widget build(BuildContext context) {
    final result = scope.evaluate(element.value);
    if (result case TypeFailure(:final diagnostics)) {
      return presentationDiagnostic(context, diagnostics);
    }
    final sourceValue = result.valueOrNull;
    if (sourceValue is! TimestampValue) {
      return presentationDiagnostic(context, [
        const TypeDiagnostic(
          code: TypeDiagnosticCode.invalidValue,
          message: "Relative time value must evaluate to a timestamp",
        ),
      ]);
    }
    final value = sourceValue.value;
    final now = _now();
    final displayValue = element.timeZone == DateTimeZone.utc
        ? value.toUtc()
        : value.toLocal();
    final displayNow = element.timeZone == DateTimeZone.utc
        ? now.toUtc()
        : now.toLocal();
    final description = describeRelativeTime(
      value: displayValue,
      now: displayNow,
    );
    useRefreshAt(description.nextRefreshAt, now: _now);
    final label = element.style == RelativeTimeStyle.compact
        ? description.compact
        : description.natural;
    final exact = DateFormat(
      "yyyy/MM/dd HH:mm:ss",
      Localizations.localeOf(context).toLanguageTag(),
    ).format(displayValue);

    return _FocusableTooltip(
      message: exact,
      child: Semantics(
        label: description.natural,
        child: ExcludeSemantics(child: Text(label)),
      ),
    );
  }
}

class _FocusableTooltip extends StatefulWidget {
  const _FocusableTooltip({required this.message, required this.child});

  final String message;
  final Widget child;

  @override
  State<_FocusableTooltip> createState() => _FocusableTooltipState();
}

class _FocusableTooltipState extends State<_FocusableTooltip> {
  final _tooltipKey = GlobalKey<TooltipState>();

  @override
  Widget build(BuildContext context) => FocusableActionDetector(
    onShowFocusHighlight: (focused) {
      if (focused) _tooltipKey.currentState?.ensureTooltipVisible();
    },
    child: Tooltip(
      key: _tooltipKey,
      message: widget.message,
      child: widget.child,
    ),
  );
}
