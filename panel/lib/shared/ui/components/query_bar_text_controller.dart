part of "query_bar.dart";

class _QueryBarTextEditingController extends TextEditingController {
  _QueryBarTextEditingController({required this.selectors, super.text})
    : _selectorsById = Map.fromEntries(selectors.map((e) => MapEntry(e.id, e)));

  final List<QuerySelectorDefinition> selectors;
  final Map<String, QuerySelectorDefinition> _selectorsById;
  QueryParseResult _parseResult = QueryParseResult.empty();

  void updateParseResult(QueryParseResult result) {
    _parseResult = result;
    notifyListeners();
  }

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    required bool withComposing,
    TextStyle? style,
  }) {
    final baseStyle = style ?? DefaultTextStyle.of(context).style;

    if (text.isEmpty) {
      return TextSpan(text: text, style: baseStyle);
    }

    final theme = Theme.of(context);

    final operatorStyle = baseStyle.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
      fontVariations: [.weight(900)],
    );
    final warningStyle = baseStyle.copyWith(
      color: theme.colorScheme.tertiary,
      decoration: TextDecoration.underline,
      decorationStyle: TextDecorationStyle.wavy,
      decorationColor: theme.colorScheme.tertiary,
    );
    final errorStyle = baseStyle.copyWith(
      color: theme.colorScheme.error,
      decoration: TextDecoration.underline,
      decorationStyle: TextDecorationStyle.wavy,
      decorationColor: theme.colorScheme.error,
    );

    final tokenRanges = <_StyledRange>[];

    for (final match in _parseResult.tokens) {
      switch (match) {
        case QueryLexerSelectorToken(:final selectorId, :final range):
          _addClampedRange(
            tokenRanges,
            range,
            _TokenStylePriority.selector,
            baseStyle.copyWith(
              color:
                  _selectorsById[selectorId]?.color ??
                  theme.colorScheme.primary,
              fontVariations: [.weight(600)],
            ),
          );
        case QueryLexerOperatorToken() || QueryLexerNegationToken():
          _addClampedRange(
            tokenRanges,
            match.range,
            _TokenStylePriority.operator,
            operatorStyle,
          );
      }
    }

    final issueRanges = <_StyledRange>[];
    for (final issue in _parseResult.issues) {
      final range = issue.range;
      if (range == null) {
        continue;
      }

      final issueStyle = switch (issue.severity) {
        QuerySeverity.error => errorStyle,
        QuerySeverity.warning => warningStyle,
      };

      final priority = switch (issue.severity) {
        QuerySeverity.error => _TokenStylePriority.errorIssue,
        QuerySeverity.warning => _TokenStylePriority.warningIssue,
      };

      _addClampedRange(issueRanges, range, priority, issueStyle);
    }

    final boundaries = <int>{0, text.length};
    for (final range in tokenRanges.followedBy(issueRanges)) {
      boundaries
        ..add(range.range.start)
        ..add(range.range.end);
    }

    final sorted = boundaries.toList()..sort();
    final spans = <TextSpan>[];

    for (var i = 0; i < sorted.length - 1; i++) {
      final start = sorted[i];
      final end = sorted[i + 1];
      if (start >= end) {
        continue;
      }

      final segmentRange = QueryRange(start, end);
      final segmentStyle = _resolveSegmentStyle(
        segmentRange,
        baseStyle,
        tokenRanges,
        issueRanges,
      );
      spans.add(
        TextSpan(text: text.substring(start, end), style: segmentStyle),
      );
    }

    return TextSpan(style: baseStyle, children: spans);
  }

  TextStyle _resolveSegmentStyle(
    QueryRange segment,
    TextStyle baseStyle,
    List<_StyledRange> tokenRanges,
    List<_StyledRange> issueRanges,
  ) {
    final activeIssue = _highestPriorityOverlap(issueRanges, segment);
    if (activeIssue != null) {
      return baseStyle.merge(activeIssue.style);
    }

    final activeToken = _highestPriorityOverlap(tokenRanges, segment);
    if (activeToken != null) {
      return baseStyle.merge(activeToken.style);
    }

    return baseStyle;
  }

  _StyledRange? _highestPriorityOverlap(
    List<_StyledRange> ranges,
    QueryRange segment,
  ) {
    _StyledRange? best;
    for (final range in ranges) {
      if (!_overlaps(range.range, segment)) {
        continue;
      }

      if (best == null || range.priority.index > best.priority.index) {
        best = range;
      }
    }
    return best;
  }

  bool _overlaps(QueryRange a, QueryRange b) {
    return a.start < b.end && b.start < a.end;
  }

  void _addClampedRange(
    List<_StyledRange> output,
    QueryRange range,
    _TokenStylePriority priority,
    TextStyle style,
  ) {
    final clampedStart = range.start.clamp(0, text.length);
    final clampedEnd = range.end.clamp(0, text.length);

    if (clampedStart >= clampedEnd) {
      return;
    }

    output.add(
      _StyledRange(
        range: QueryRange(clampedStart, clampedEnd),
        priority: priority,
        style: style,
      ),
    );
  }
}

class _StyledRange {
  const _StyledRange({
    required this.range,
    required this.priority,
    required this.style,
  });

  final QueryRange range;
  final _TokenStylePriority priority;
  final TextStyle style;
}

enum _TokenStylePriority { operator, selector, warningIssue, errorIssue }
