// ignore_for_file: sort_constructors_first

import "package:typewriter_panel/logic/search/query/query_models.dart";
import "package:typewriter_panel/logic/search/query/query_selector.dart";

class QuerySuggestionEngine {
  final List<QuerySelectorDefinition> selectors;

  const QuerySuggestionEngine(this.selectors);

  List<QuerySuggestion> suggest(QueryParseResult result, {int maxItems = 8}) {
    final context = result.cursorContext;
    if (context == null) {
      return const <QuerySuggestion>[];
    }

    final items = switch (context) {
      SelectorKeyCursorContext() => _suggestSelectorKeys(context),
      SelectorValueCursorContext() => _suggestSelectorValues(context),
      OperatorCursorContext() => _suggestOperators(context),
      TextTermCursorContext() => const <QuerySuggestion>[],
      UnknownCursorContext() => const <QuerySuggestion>[],
    };

    if (items.length <= maxItems) {
      return items;
    }
    return items.take(maxItems).toList(growable: false);
  }

  List<QuerySuggestion> _suggestSelectorKeys(SelectorKeyCursorContext context) {
    final partial = context.partialKey.toLowerCase();
    final suggestions = <QuerySuggestion>[];

    for (final selector in selectors) {
      if (selector case KeyValueSelectorDefinition(:final key, :final id)) {
        if (!key.toLowerCase().startsWith(partial)) {
          continue;
        }
        suggestions.add(
          SelectorKeySuggestion(
            label: "$key:",
            replaceRange: context.activeRange,
            selectorId: id,
          ),
        );
      }
      if (selector case SymbolSelectorDefinition(:final symbol, :final id)) {
        final shouldInclude = partial.isEmpty || symbol.startsWith(partial);
        if (!shouldInclude) {
          continue;
        }
        suggestions.add(
          SelectorKeySuggestion(
            label: symbol,
            replaceRange: context.activeRange,
            selectorId: id,
          ),
        );
      }
    }

    return suggestions;
  }

  List<QuerySuggestion> _suggestSelectorValues(
    SelectorValueCursorContext context,
  ) {
    final selector = selectors.firstWhere(
      (candidate) => candidate.id == context.selectorId,
      orElse: () => const KeyValueSelectorDefinition(id: "", key: ""),
    );

    if (selector is! KeyValueSelectorDefinition) {
      return const <QuerySuggestion>[];
    }

    final source = selector.suggestionSource;
    if (source == null) {
      return const <QuerySuggestion>[];
    }

    final candidates = source(context.partialValue);
    return candidates
        .where(
          (candidate) => candidate.toLowerCase().startsWith(
            context.partialValue.toLowerCase(),
          ),
        )
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

  List<QuerySuggestion> _suggestOperators(OperatorCursorContext context) {
    const operators = <String>["AND", "OR", "NOT", "&&", "||", "!"];
    final partial = context.partialOperator.toLowerCase();

    return operators
        .where((operator) => operator.toLowerCase().startsWith(partial))
        .map(
          (operator) => OperatorSuggestion(
            label: operator,
            replaceRange: context.activeRange,
            operatorToken: operator,
          ),
        )
        .toList(growable: false);
  }
}
