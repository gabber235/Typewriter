// ignore_for_file: sort_constructors_first

import "package:typewriter_panel/shared/search/domain/query/query_models.dart";
import "package:typewriter_panel/shared/search/domain/query/query_selector.dart";
import "package:typewriter_panel/shared/utilities/string.dart";

class QuerySuggestionEngine {
  const QuerySuggestionEngine(this.selectors);

  final List<QuerySelectorDefinition> selectors;

  List<QuerySuggestion> suggest(QueryParseResult result, {int maxItems = 8}) {
    final context = result.cursorContext;
    if (context == null) {
      return const <QuerySuggestion>[];
    }

    final items = switch (context) {
      SelectorKeyCursorContext() => _suggestSelectorKeys(result, context),
      SelectorValueCursorContext() => _suggestSelectorValues(result, context),
      OperatorCursorContext() => _suggestOperators(result, context),
      UnknownCursorContext() => _suggestUnknown(result, context),
    };

    if (items.length <= maxItems) {
      return items;
    }
    return items.take(maxItems).toList(growable: false);
  }

  List<QuerySuggestion> _suggestOperators(
    QueryParseResult result,
    OperatorCursorContext context, {
    List<QueryOperatorType>? types,
  }) {
    final partial = context.partialOperator.toLowerCase();

    return QueryOperator.allTokens(types)
        .where((token) => token.toLowerCase().startsWith(partial))
        .map((operator) {
          return OperatorSuggestion(
            label: operator,
            replaceRange: context.activeRange,
            operatorToken: operator,
          );
        })
        .toList(growable: false);
  }

  List<QuerySuggestion> _suggestSelectorKeys(
    QueryParseResult result,
    SelectorKeyCursorContext context,
  ) {
    final partial = context.partialKey.toLowerCase();
    return selectors
        .whereType<KeyValueSelectorDefinition>()
        .where((selector) => selector.key.toLowerCase().startsWith(partial))
        .where(
          (selector) =>
              selector.multiplicity != .single ||
              !result.selectors.any((s) => s.selectorId == selector.id),
        )
        .map(
          (selector) => SelectorKeySuggestion(
            label: selector.key,
            replaceRange: context.activeRange,
            selectorId: selector.id,
          ),
        )
        .toList(growable: false);
  }

  List<QuerySuggestion> _suggestSelectorValues(
    QueryParseResult result,
    SelectorValueCursorContext context,
  ) {
    final selector = selectors
        .whereType<KeyValueSelectorDefinition>()
        .firstWhere(
          (candidate) => candidate.id == context.selectorId,
          orElse: () => const KeyValueSelectorDefinition(id: "", key: ""),
        );

    final value = selector.value;
    final partialValue = context.partialValue.toLowerCase();

    final candidates = value.suggestions(context.partialValue);
    return candidates
        .where((candidate) {
          final candidateValue = candidate.toLowerCase();
          return partialValue != candidateValue &&
              candidateValue.startsWith(partialValue);
        })
        .map(
          (candidate) => SelectorValueSuggestion(
            label: candidate,
            replaceRange: context.activeRange,
            selectorId: context.selectorId,
            value: candidate,
          ),
        )
        .toList(growable: false);
  }

  List<QuerySuggestion> _suggestUnknown(
    QueryParseResult result,
    UnknownCursorContext context,
  ) {
    var actualAfter = QueryOperator.allTokens()
        .fold(
          result.queryAfter,
          (previous, op) =>
              previous.replacePrefix(op, "", caseSensitive: false),
        )
        .trimLeft();

    while (true) {
      final newAfter = QueryOperator.allTokens([.prefix])
          .fold(
            actualAfter,
            (previous, op) =>
                previous.replacePrefix(op, "", caseSensitive: false),
          )
          .trimLeft();

      if (actualAfter == newAfter) {
        break;
      }
      actualAfter = newAfter;
    }

    final isAtExpressionBorder = switch (context.side) {
      QuerySide.before => context.activeRange.end >= result.queryBefore.length,
      QuerySide.expression => true,
      QuerySide.after =>
        context.activeRange.start <= (result.raw.length - actualAfter.length),
    };

    if (!isAtExpressionBorder) {
      return const <QuerySuggestion>[];
    }

    var partialKey = context.partial;
    var activeRange = context.activeRange;

    while (true) {
      final newPartialKey = QueryOperator.allTokens([.prefix])
          .fold(
            partialKey,
            (previous, op) =>
                previous.replacePrefix(op, "", caseSensitive: false),
          )
          .trimLeft();

      if (partialKey == newPartialKey) {
        break;
      }
      final diff = partialKey.replaceSuffix(newPartialKey, "");
      partialKey = newPartialKey;
      activeRange = activeRange.copyWith(
        start: activeRange.start + diff.length,
      );
    }

    final suggestions = <QuerySuggestion>[
      ..._suggestSelectorKeys(
        result,
        SelectorKeyCursorContext(
          cursorOffset: context.cursorOffset,
          activeRange: activeRange,
          partialKey: partialKey,
        ),
      ),
    ];

    if (context.side == .after) {
      final startsWithNonPostfixOperator =
          QueryOperator.allTokens([.prefix, .group]).any(
            (token) =>
                result.queryAfter.toLowerCase().startsWith(token.toLowerCase()),
          );

      final operatorType = startsWithNonPostfixOperator
          ? QueryOperatorType.prefix
          : null;

      suggestions.addAll(
        _suggestOperators(
          result,
          OperatorCursorContext(
            cursorOffset: context.cursorOffset,
            activeRange: context.activeRange,
            partialOperator: context.partial,
          ),
          types: operatorType != null ? [operatorType] : null,
        ),
      );
    }

    return suggestions;
  }
}
