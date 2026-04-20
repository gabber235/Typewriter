import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:typewriter_panel/logic/search/query/query.dart";
import "package:typewriter_panel/main.dart";
import "package:typewriter_panel/widgets/app/components/decorated_text_field.dart";
import "package:typewriter_panel/widgets/generic/components/anchored_overlay/anchored_overlay.dart";
import "package:typewriter_panel/widgets/generic/components/anchored_overlay/anchored_overlay_config.dart";

class QueryBar extends HookWidget {
  const QueryBar({
    required this.query,
    required this.onQueryChanged,
    required this.selectors,
    this.inputDecoration = const InputDecoration(hintText: "Search"),
    super.key,
  });

  final String query;
  final void Function(String) onQueryChanged;
  final List<QuerySelectorDefinition> selectors;
  final InputDecoration inputDecoration;

  @override
  Widget build(BuildContext context) {
    final controller = useMemoized(
      () => _QueryBarTextEditingController(text: query),
      const [],
    );
    final focusNode = useFocusNode();

    useEffect(() {
      return controller.dispose;
    }, [controller]);

    useListenable(controller);
    useListenable(focusNode);

    useEffect(() {
      if (!focusNode.hasFocus && controller.text != query) {
        controller.value = TextEditingValue(
          text: query,
          selection: TextSelection.collapsed(offset: query.length),
        );
      }
      return null;
    }, [controller, query]);

    final queryEngine = useMemoized(() => Query(selectors), [selectors]);
    final suggestionEngine = useMemoized(
      () => QuerySuggestionEngine(selectors),
      [selectors],
    );

    final cursorOffset = controller.selection.isValid
        ? controller.selection.extentOffset.clamp(0, controller.text.length)
        : controller.text.length;

    final parseResult = useMemoized(
      () => queryEngine.parse(controller.text, cursorOffset: cursorOffset),
      [queryEngine, controller.text, cursorOffset],
    );

    final suggestions = useMemoized(
      () => _computeSuggestions(suggestionEngine, parseResult, maxItems: 8),
      [suggestionEngine, parseResult],
    );

    final activeSuggestionIndex = useState<int?>(null);
    final dismissedSignature = useState<String?>(null);
    final currentSignature = "${controller.text}|$cursorOffset";
    final helperVisible = _shouldShowHelperRow(suggestions);
    final helperBadges = _helperBadgeData(suggestions);
    final popupSuggestionsVisible =
        suggestions.isNotEmpty &&
        !helperVisible &&
        dismissedSignature.value != currentSignature;
    final popupVisible = focusNode.hasFocus && popupSuggestionsVisible;

    useEffect(() {
      controller.updateParseResult(parseResult);
      return null;
    }, [controller, parseResult]);

    useEffect(() {
      final activeIndex = activeSuggestionIndex.value;
      if (!popupSuggestionsVisible) {
        activeSuggestionIndex.value = null;
        return null;
      }

      if (activeIndex == null) {
        return null;
      }

      if (activeIndex >= suggestions.length) {
        activeSuggestionIndex.value = 0;
      }

      return null;
    }, [popupSuggestionsVisible, suggestions, activeSuggestionIndex]);

    void applySuggestion(QuerySuggestion suggestion) {
      final before = controller.text.substring(
        0,
        suggestion.replaceRange.start,
      );
      final after = controller.text.substring(suggestion.replaceRange.end);
      final nextText = "$before${suggestion.label}$after";
      final caretOffset = before.length + suggestion.label.length;
      controller.value = TextEditingValue(
        text: nextText,
        selection: TextSelection.collapsed(offset: caretOffset),
      );
      dismissedSignature.value = null;
      onQueryChanged(nextText);
    }

    void acceptActiveOrFirstSuggestion() {
      if (!popupSuggestionsVisible) {
        return;
      }

      final currentIndex = activeSuggestionIndex.value;
      final selectionIndex = switch (currentIndex) {
        null => 0,
        _ => currentIndex,
      };
      applySuggestion(suggestions[selectionIndex]);
    }

    void selectNextSuggestion() {
      if (!popupSuggestionsVisible) {
        return;
      }

      final currentIndex = activeSuggestionIndex.value;
      if (currentIndex == null) {
        activeSuggestionIndex.value = 0;
        return;
      }

      activeSuggestionIndex.value = (currentIndex + 1) % suggestions.length;
    }

    void selectPreviousSuggestion() {
      if (!popupSuggestionsVisible) {
        return;
      }

      final currentIndex = activeSuggestionIndex.value;
      if (currentIndex == null) {
        activeSuggestionIndex.value = suggestions.length - 1;
        return;
      }

      activeSuggestionIndex.value =
          (currentIndex - 1 + suggestions.length) % suggestions.length;
    }

    void dismissSuggestions() {
      activeSuggestionIndex.value = null;
      dismissedSignature.value = currentSignature;
    }

    final shortcuts = useMemoized(() {
      if (!popupSuggestionsVisible) {
        return const <ShortcutActivator, Intent>{};
      }

      return <ShortcutActivator, Intent>{
        const SingleActivator(LogicalKeyboardKey.arrowUp):
            const _PreviousSuggestionIntent(),
        const SingleActivator(LogicalKeyboardKey.arrowDown):
            const _NextSuggestionIntent(),
        const SingleActivator(LogicalKeyboardKey.enter):
            const _AcceptSuggestionIntent(),
        const SingleActivator(LogicalKeyboardKey.numpadEnter):
            const _AcceptSuggestionIntent(),
        const SingleActivator(LogicalKeyboardKey.escape):
            const _DismissSuggestionsIntent(),
        for (final activator in shortcutsFor(PreviousFocusIntent))
          activator: const _PreviousSuggestionIntent(),
        for (final activator in shortcutsFor(NextFocusIntent))
          activator: const _NextSuggestionIntent(),
      };
    }, [popupSuggestionsVisible]);

    final actions = <Type, Action<Intent>>{
      _PreviousSuggestionIntent: CallbackAction<_PreviousSuggestionIntent>(
        onInvoke: (_) {
          selectPreviousSuggestion();
          return null;
        },
      ),
      _NextSuggestionIntent: CallbackAction<_NextSuggestionIntent>(
        onInvoke: (_) {
          selectNextSuggestion();
          return null;
        },
      ),
      _AcceptSuggestionIntent: CallbackAction<_AcceptSuggestionIntent>(
        onInvoke: (_) {
          acceptActiveOrFirstSuggestion();
          return null;
        },
      ),
      if (popupSuggestionsVisible) ...{
        _DismissSuggestionsIntent: CallbackAction<_DismissSuggestionsIntent>(
          onInvoke: (_) {
            dismissSuggestions();
            return null;
          },
        ),
        DismissIntent: CallbackAction<DismissIntent>(
          onInvoke: (_) {
            dismissSuggestions();
            return null;
          },
        ),
      },
    };

    return Shortcuts(
      shortcuts: shortcuts,
      child: Actions(
        actions: actions,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 4,
          children: [
            AnchoredOverlayPortal(
              visible: popupVisible,
              config: const AnchoredOverlayConfig(
                preferredSide: AnchoredOverlaySide.bottom,
                spacing: 4,
                sharedAxisConstraintMode: SharedAxisConstraintMode.matchAnchor,
              ),
              child: DecoratedTextField(
                focusNode: focusNode,
                controller: controller,
                decoration: inputDecoration,
                onChanged: (value) {
                  dismissedSignature.value = null;
                  onQueryChanged(value);
                },
                onSubmitted: (_) => acceptActiveOrFirstSuggestion(),
              ),
              overlayBuilder: (context, _) => _buildSuggestionPanel(
                context: context,
                suggestions: suggestions,
                activeSuggestionIndex: activeSuggestionIndex.value,
                onTapSuggestion: applySuggestion,
                onHoverIndex: (index) {
                  activeSuggestionIndex.value = index;
                },
              ),
            ),
            if (helperVisible) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Wrap(
                  key: const ValueKey("query_bar_helper"),
                  spacing: 6,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      "You can use:",
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Wrap(
                      key: const ValueKey("query_bar_helper_badges"),
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (
                          var index = 0;
                          index < helperBadges.labels.length;
                          index++
                        )
                          _buildHelperBadge(
                            context,
                            helperBadges.labels[index],
                            key: ValueKey("query_bar_helper_badge_$index"),
                          ),
                        if (helperBadges.hiddenCount > 0)
                          _buildHelperBadge(
                            context,
                            "+${helperBadges.hiddenCount}",
                            key: const ValueKey(
                              "query_bar_helper_badge_overflow",
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PreviousSuggestionIntent extends Intent {
  const _PreviousSuggestionIntent();
}

class _NextSuggestionIntent extends Intent {
  const _NextSuggestionIntent();
}

class _AcceptSuggestionIntent extends Intent {
  const _AcceptSuggestionIntent();
}

class _DismissSuggestionsIntent extends Intent {
  const _DismissSuggestionsIntent();
}

Widget _buildSuggestionPanel({
  required BuildContext context,
  required List<QuerySuggestion> suggestions,
  required int? activeSuggestionIndex,
  required ValueChanged<QuerySuggestion> onTapSuggestion,
  required ValueChanged<int> onHoverIndex,
}) {
  return Material(
    key: ValueKey(suggestions.key),
    elevation: 2,
    color: Theme.of(context).colorScheme.surface,
    borderRadius: BorderRadius.circular(8),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Container(
        key: const ValueKey("query_bar_suggestions"),
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: suggestions.length,
          itemBuilder: (context, index) {
            final suggestion = suggestions[index];
            final isActive = activeSuggestionIndex == index;

            return InkWell(
              key: ValueKey("query_bar_suggestion_$index"),
              onTap: () => onTapSuggestion(suggestion),
              onHover: (hovering) {
                if (hovering) {
                  onHoverIndex(index);
                }
              },
              child: Container(
                color: isActive
                    ? Theme.of(context).colorScheme.primaryContainer
                    : null,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        suggestion.label,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _suggestionTypeLabel(suggestion),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    ),
  );
}

String _suggestionTypeLabel(QuerySuggestion suggestion) {
  return switch (suggestion) {
    SelectorKeySuggestion() => "Selector",
    SelectorValueSuggestion() => "Value",
    OperatorSuggestion() => "Operator",
  };
}

bool _isSelectorOrOperatorSuggestion(QuerySuggestion suggestion) {
  return switch (suggestion) {
    SelectorKeySuggestion() => true,
    OperatorSuggestion() => true,
    _ => false,
  };
}

bool _shouldShowHelperRow(List<QuerySuggestion> suggestions) {
  if (suggestions.isEmpty) {
    return false;
  }

  return suggestions.every(_isSelectorOrOperatorSuggestion);
}

_HelperBadgeData _helperBadgeData(
  List<QuerySuggestion> suggestions, {
  int maxItems = 8,
}) {
  assert(maxItems > 0, "maxItems must be greater than zero");

  final uniqueLabels = <String>[];
  final seenLabels = <String>{};

  for (final suggestion in suggestions) {
    if (!_isSelectorOrOperatorSuggestion(suggestion)) {
      continue;
    }

    if (seenLabels.add(suggestion.label)) {
      uniqueLabels.add(suggestion.label);
    }
  }

  if (uniqueLabels.length <= maxItems) {
    return _HelperBadgeData(labels: uniqueLabels, hiddenCount: 0);
  }

  return _HelperBadgeData(
    labels: uniqueLabels.take(maxItems).toList(growable: false),
    hiddenCount: uniqueLabels.length - maxItems,
  );
}

Widget _buildHelperBadge(BuildContext context, String label, {Key? key}) {
  final colors = Theme.of(context).colorScheme;

  return Container(
    key: key,
    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
    decoration: BoxDecoration(
      color: colors.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(4),
    ),
    child: Text(
      label,
      style: Theme.of(
        context,
      ).textTheme.labelSmall?.copyWith(color: colors.onSurfaceVariant),
    ),
  );
}

class _HelperBadgeData {
  const _HelperBadgeData({required this.labels, required this.hiddenCount});

  final List<String> labels;
  final int hiddenCount;
}

List<QuerySuggestion> _computeSuggestions(
  QuerySuggestionEngine suggestionEngine,
  QueryParseResult parseResult, {
  int maxItems = 8,
}) {
  final directSuggestions = suggestionEngine.suggest(
    parseResult,
    maxItems: maxItems,
  );
  if (directSuggestions.isNotEmpty) {
    return directSuggestions;
  }

  final cursorContext = parseResult.cursorContext;
  if (cursorContext case TextTermCursorContext()) {
    final keySuggestions = suggestionEngine.suggest(
      _copyParseResultWithContext(
        parseResult,
        SelectorKeyCursorContext(
          cursorOffset: cursorContext.cursorOffset,
          activeRange: cursorContext.activeRange,
          partialKey: cursorContext.partialText,
        ),
      ),
      maxItems: maxItems,
    );

    final operatorSuggestions = suggestionEngine.suggest(
      _copyParseResultWithContext(
        parseResult,
        OperatorCursorContext(
          cursorOffset: cursorContext.cursorOffset,
          activeRange: cursorContext.activeRange,
          partialOperator: cursorContext.partialText,
        ),
      ),
      maxItems: maxItems,
    );

    return _mergeSuggestions(
      keySuggestions,
      operatorSuggestions,
      maxItems: maxItems,
    );
  }

  if (cursorContext case UnknownCursorContext()) {
    return suggestionEngine.suggest(
      _copyParseResultWithContext(
        parseResult,
        SelectorKeyCursorContext(
          cursorOffset: cursorContext.cursorOffset,
          activeRange: cursorContext.activeRange,
          partialKey: "",
        ),
      ),
      maxItems: maxItems,
    );
  }

  return directSuggestions;
}

List<QuerySuggestion> _mergeSuggestions(
  List<QuerySuggestion> first,
  List<QuerySuggestion> second, {
  required int maxItems,
}) {
  final merged = <QuerySuggestion>[];
  final seen = <String>{};

  for (final suggestion in [...first, ...second]) {
    final key = [
      suggestion.runtimeType,
      suggestion.label,
      suggestion.replaceRange.start,
      suggestion.replaceRange.end,
    ].join(":");

    if (seen.add(key)) {
      merged.add(suggestion);
    }

    if (merged.length >= maxItems) {
      break;
    }
  }

  return merged;
}

QueryParseResult _copyParseResultWithContext(
  QueryParseResult source,
  QueryCursorContext context,
) {
  return QueryParseResult(
    expression: source.expression,
    selectorMatches: source.selectorMatches,
    textTerms: source.textTerms,
    leftoverText: source.leftoverText,
    issues: source.issues,
    cursorContext: context,
  );
}

class _QueryBarTextEditingController extends TextEditingController {
  _QueryBarTextEditingController({super.text});

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
    final theme = Theme.of(context);

    final keyStyle = TextStyle(color: theme.colorScheme.primary);
    final valueStyle = TextStyle(color: theme.colorScheme.secondary);
    final operatorStyle = TextStyle(
      color: theme.colorScheme.onSurface,
      fontWeight: FontWeight.w600,
    );
    final termStyle = TextStyle(color: theme.colorScheme.onSurface);
    final warningStyle = TextStyle(
      color: theme.colorScheme.tertiary,
      decoration: TextDecoration.underline,
      decorationColor: theme.colorScheme.tertiary,
    );
    final errorStyle = TextStyle(
      color: theme.colorScheme.error,
      decoration: TextDecoration.underline,
      decorationColor: theme.colorScheme.error,
    );

    final tokenRanges = <_StyledRange>[];

    for (final match in _parseResult.selectorMatches) {
      switch (match) {
        case SymbolSelectorMatch(:final symbolRange, :final tokenRange):
          _addClampedRange(
            tokenRanges,
            symbolRange,
            _TokenStylePriority.selectorKey,
            keyStyle,
          );
          _addClampedRange(
            tokenRanges,
            tokenRange,
            _TokenStylePriority.selectorValue,
            valueStyle,
          );
        case KeyValueSelectorMatch(:final keyRange, :final valueRange):
          _addClampedRange(
            tokenRanges,
            keyRange,
            _TokenStylePriority.selectorKey,
            keyStyle,
          );
          if (valueRange != null) {
            _addClampedRange(
              tokenRanges,
              valueRange,
              _TokenStylePriority.selectorValue,
              valueStyle,
            );
          }
      }
    }

    for (final term in _parseResult.textTerms) {
      _addClampedRange(
        tokenRanges,
        term.range,
        _TokenStylePriority.textTerm,
        termStyle,
      );
    }

    for (final operatorRange in _findOperatorRanges(text)) {
      _addClampedRange(
        tokenRanges,
        operatorRange,
        _TokenStylePriority.operator,
        operatorStyle,
      );
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

    if (text.isEmpty) {
      return TextSpan(text: text, style: baseStyle);
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

  List<QueryRange> _findOperatorRanges(String input) {
    final ranges = <QueryRange>[];
    final expression = RegExp(
      r"\b(?:AND|OR|NOT)\b|&&|\|\||!",
      caseSensitive: false,
    );

    for (final match in expression.allMatches(input)) {
      if (match.start < match.end) {
        ranges.add(QueryRange(match.start, match.end));
      }
    }

    return ranges;
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

enum _TokenStylePriority {
  textTerm,
  operator,
  selectorValue,
  selectorKey,
  warningIssue,
  errorIssue,
}
