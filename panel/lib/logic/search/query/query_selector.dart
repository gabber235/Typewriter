// ignore_for_file: sort_constructors_first

enum QueryMultiplicity { single, multiple }

enum QueryValueMode { freeText, enumValue }

typedef QueryValueSuggestionsProvider = List<String> Function(String partial);

sealed class QuerySelectorDefinition {
  final String id;
  final bool caseSensitive;
  final QueryMultiplicity multiplicity;
  final QueryValueSuggestionsProvider? suggestionSource;

  const QuerySelectorDefinition({
    required this.id,
    this.caseSensitive = false,
    this.multiplicity = QueryMultiplicity.multiple,
    this.suggestionSource,
  });
}

final class SymbolSelectorDefinition extends QuerySelectorDefinition {
  final String symbol;

  const SymbolSelectorDefinition({
    required super.id,
    required this.symbol,
    super.caseSensitive,
    super.multiplicity,
    super.suggestionSource,
  });
}

final class KeyValueSelectorDefinition extends QuerySelectorDefinition {
  final String key;
  final QueryValueMode valueMode;

  const KeyValueSelectorDefinition({
    required super.id,
    required this.key,
    this.valueMode = QueryValueMode.freeText,
    super.caseSensitive,
    super.multiplicity,
    super.suggestionSource,
  });

  bool matchesKey(String candidate) {
    if (caseSensitive) {
      return key == candidate;
    }
    return key.toLowerCase() == candidate.toLowerCase();
  }

  bool hasSuggestedValue(String candidate) {
    final suggestions = suggestionSource;
    if (suggestions == null) {
      return true;
    }
    final values = suggestions("");
    return values.any((value) => value == candidate);
  }
}
