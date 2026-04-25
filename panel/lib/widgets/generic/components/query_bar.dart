import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_animate/flutter_animate.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:typewriter_panel/logic/search/query/query.dart";
import "package:typewriter_panel/main.dart";
import "package:typewriter_panel/utils/context.dart";
import "package:typewriter_panel/widgets/app/components/decorated_text_field.dart";
import "package:typewriter_panel/widgets/generic/components/anchored_overlay/anchored_overlay.dart";
import "package:typewriter_panel/widgets/generic/components/anchored_overlay/anchored_overlay_config.dart";
import "package:typewriter_panel/widgets/generic/components/shortcut_display.dart";

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
      () => _QueryBarTextEditingController(text: query, selectors: selectors),
      [selectors],
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

    final cursorOffset = controller.selection.isCollapsed
        ? controller.selection.baseOffset
        : null;

    final parseResult = useMemoized(
      () => queryEngine.parse(controller.text, cursorOffset: cursorOffset),
      [queryEngine, controller.text, cursorOffset],
    );

    final suggestions = useMemoized(
      () => suggestionEngine.suggest(parseResult, maxItems: 100),
      [suggestionEngine, parseResult],
    );

    final activeSuggestionIndex = useState<int?>(null);
    final dismissedSignature = useState<String?>(null);
    final currentSignature = "${controller.text}|$cursorOffset";
    final helperVisible = _shouldShowHelperRow(suggestions);
    final helperBadges = _helperBadgeData(suggestions, maxItems: 20);
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
      if (suggestions.isEmpty) {
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
      return <ShortcutActivator, Intent>{
        const SingleActivator(LogicalKeyboardKey.enter):
            const _AcceptSuggestionIntent(),
        const SingleActivator(LogicalKeyboardKey.numpadEnter):
            const _AcceptSuggestionIntent(),
        if (popupSuggestionsVisible) ...{
          const SingleActivator(LogicalKeyboardKey.arrowUp):
              const _PreviousSuggestionIntent(),
          const SingleActivator(LogicalKeyboardKey.arrowDown):
              const _NextSuggestionIntent(),
          const SingleActivator(LogicalKeyboardKey.escape):
              const _DismissSuggestionsIntent(),
          for (final activator in shortcutsFor(PreviousFocusIntent))
            activator: const _PreviousSuggestionIntent(),
          for (final activator in shortcutsFor(NextFocusIntent))
            activator: const _NextSuggestionIntent(),
        },
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
        child: AnimatedSize(
          duration: 300.ms,
          curve: Curves.easeInOut,
          alignment: Alignment.topCenter,
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
                  sharedAxisConstraintMode:
                      SharedAxisConstraintMode.matchAnchor,
                ),
                child: DecoratedTextField(
                  focusNode: focusNode,
                  controller: controller,
                  decoration: inputDecoration.copyWith(
                    errorText: parseResult.issues.isNotEmpty
                        ? parseResult.issues.first.message
                        : null,
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 8,
                    ),
                  ),
                  maxLines: null,
                  inputFormatters: [
                    FilteringTextInputFormatter.deny(RegExp(r"[\n\r]")),
                  ],
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
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text.rich(
                    TextSpan(
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      children: [
                        TextSpan(text: "You can use: "),
                        for (final label in helperBadges.labels) ...[
                          WidgetSpan(
                            alignment: PlaceholderAlignment.middle,
                            child: _buildHelperBadge(
                              context,
                              label,
                              key: ValueKey("query_bar_helper_badge_$label"),
                            ),
                          ),
                          const TextSpan(text: ", "),
                        ],
                        if (helperBadges.hiddenCount > 0)
                          WidgetSpan(
                            alignment: PlaceholderAlignment.middle,
                            child: _buildHelperBadge(
                              context,
                              "+${helperBadges.hiddenCount}",
                              key: const ValueKey(
                                "query_bar_helper_badge_overflow",
                              ),
                            ),
                          ),
                        const TextSpan(text: "to filter results."),
                        if (context.isTablet || context.isDesktop) ...[
                          const TextSpan(text: " Press "),
                          WidgetSpan(
                            alignment: PlaceholderAlignment.middle,
                            child: ShortcutDisplay(
                              shortcut: SingleActivator(
                                LogicalKeyboardKey.enter,
                              ),
                            ),
                          ),
                          const TextSpan(text: " to select first result."),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
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
  final theme = Theme.of(context);
  final menuStyle = theme.dropdownMenuTheme.menuStyle ?? const MenuStyle();
  final states = <WidgetState>{};
  final shape =
      menuStyle.shape?.resolve(states) ??
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(6));
  final padding =
      menuStyle.padding?.resolve(states) ??
      const EdgeInsets.symmetric(horizontal: 4, vertical: 4);
  final elevation = menuStyle.elevation?.resolve(states) ?? 1;
  final backgroundColor =
      menuStyle.backgroundColor?.resolve(states) ?? theme.colorScheme.surface;

  return Material(
    key: ValueKey(suggestions.key),
    elevation: elevation,
    color: backgroundColor,
    shape: shape,
    clipBehavior: Clip.antiAlias,
    child: Padding(
      padding: padding,
      child: Container(
        key: const ValueKey("query_bar_suggestions"),
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: suggestions.length,
          itemBuilder: (context, index) {
            final suggestion = suggestions[index];
            final isActive = activeSuggestionIndex == index;

            return MouseRegion(
              key: ValueKey("query_bar_suggestion_$index"),
              onEnter: (_) => onHoverIndex(index),
              child: MenuItemButton(
                style: _suggestionItemStyle(context, isActive: isActive),
                trailingIcon: Text(
                  _suggestionTypeLabel(suggestion),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                requestFocusOnHover: false,
                onPressed: () => onTapSuggestion(suggestion),
                child: Text(suggestion.label, overflow: TextOverflow.ellipsis),
              ),
            );
          },
        ),
      ),
    ),
  );
}

ButtonStyle? _suggestionItemStyle(
  BuildContext context, {
  required bool isActive,
}) {
  if (!isActive) {
    return null;
  }

  final themeStyle = MenuButtonTheme.of(context).style;
  final defaultStyle = const MenuItemButton().defaultStyleOf(context);

  Color? resolveFocusedColor(WidgetStateProperty<Color?>? property) {
    return property?.resolve(<WidgetState>{WidgetState.focused});
  }

  final focusedForegroundColor = resolveFocusedColor(
    themeStyle?.foregroundColor ?? defaultStyle.foregroundColor,
  );
  final focusedIconColor = resolveFocusedColor(
    themeStyle?.iconColor ?? defaultStyle.iconColor,
  );
  final focusedOverlayColor = resolveFocusedColor(
    themeStyle?.overlayColor ?? defaultStyle.overlayColor,
  );
  final focusedBackgroundColor =
      resolveFocusedColor(themeStyle?.backgroundColor) ??
      Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.12);

  return (themeStyle ?? const ButtonStyle()).copyWith(
    backgroundColor: WidgetStatePropertyAll<Color>(focusedBackgroundColor),
    foregroundColor: focusedForegroundColor == null
        ? null
        : WidgetStatePropertyAll<Color>(focusedForegroundColor),
    iconColor: focusedIconColor == null
        ? null
        : WidgetStatePropertyAll<Color>(focusedIconColor),
    overlayColor: focusedOverlayColor == null
        ? null
        : WidgetStatePropertyAll<Color>(focusedOverlayColor),
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

    final operatorStyle = TextStyle(
      color: theme.colorScheme.onSurfaceVariant,
      fontVariations: [.weight(900)],
    );
    final warningStyle = TextStyle(
      color: theme.colorScheme.tertiary,
      decoration: TextDecoration.underline,
      decorationStyle: TextDecorationStyle.wavy,
      decorationColor: theme.colorScheme.tertiary,
    );
    final errorStyle = TextStyle(
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
            TextStyle(
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
