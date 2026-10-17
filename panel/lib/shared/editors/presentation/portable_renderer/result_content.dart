part of "../portable_presentation_renderer.dart";

/// Adapts a portable result presentation to the shared row owner. Content is
/// read only and the row retains activation and focus behavior. Invalid appearance
/// expressions show feedback alongside the result body rather than replacing it.
final class PortableResultContent extends StatelessWidget {
  const PortableResultContent({
    required this.node,
    required this.scope,
    required this.row,
    required this.fallbackStyle,
    required this.fallbackKindLabel,
    this.appearance,
    this.kindLabelOverride,
    this.fallbackLeading,
    this.fallbackAccent,
    this.footer,
    super.key,
  });

  final skir.PresentationNode node;
  final PortablePresentationScope scope;
  final SearchResultRowContext row;
  final SearchResultDensity fallbackStyle;
  final String fallbackKindLabel;
  final skir.ResultAppearance? appearance;
  final String? kindLabelOverride;
  final Widget? fallbackLeading;
  final Color? fallbackAccent;
  final Widget? footer;

  Color? accent(PortablePresentationScope scope) {
    final expression = appearance?.accent;
    if (expression == null) return null;
    return switch (scope.evaluate(expression)) {
      PortableExpressionAvailable(:final value)
          when value.authoredInteger != null =>
        Color(value.authoredInteger!.toUnsigned(32).toInt()),
      PortableExpressionFailed(:final message) =>
        throw PresentationColorFailure(message),
      PortableExpressionUnavailable() => throw const PresentationColorFailure(
        "The result accent is unavailable",
      ),
      PortableExpressionAvailable() => throw const PresentationColorFailure(
        "The result accent must evaluate to a color",
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final contentScope = scope.withReadOnly(true).withAuthoredLayout(node);
    final errors = <String>[];
    Color? color;
    try {
      color = accent(contentScope);
    } on PresentationColorFailure catch (error) {
      errors.add(error.message);
    } on FormatException catch (error) {
      errors.add(error.message);
    }
    var kind = fallbackKindLabel;
    final kindExpression = appearance?.kindLabel;
    if (kindExpression != null) {
      switch (_string(contentScope, kindExpression)) {
        case _ResolvedValue(:final value):
          kind = value;
        case _ResolvedFailure(:final message):
          errors.add(message);
      }
    }
    final style = appearance?.style;
    final density = switch (style) {
      null => fallbackStyle,
      skir.ResultStyle.compact => SearchResultDensity.compact,
      skir.ResultStyle.card => SearchResultDensity.card,
      _ => fallbackStyle,
    };
    if (style != null &&
        style != skir.ResultStyle.compact &&
        style != skir.ResultStyle.card) {
      errors.add("The result style is unavailable");
    }
    final leadingNode = appearance?.leading;
    final body = PortablePresentationNodeRenderer(
      node: node,
      scope: contentScope,
    );
    return SearchResultRow(
      row: row,
      density: density,
      accent: color ?? fallbackAccent,
      leading: leadingNode == null
          ? fallbackLeading
          : PortablePresentationNodeRenderer(
              node: leadingNode,
              scope: contentScope.withAuthoredLayout(leadingNode),
            ),
      kindLabel: kindLabelOverride ?? kind,
      footer: footer,
      body: errors.isEmpty
          ? body
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              spacing: context.spacing.space1,
              children: [
                body,
                for (final message in errors) _diagnostic(message),
              ],
            ),
    );
  }
}
