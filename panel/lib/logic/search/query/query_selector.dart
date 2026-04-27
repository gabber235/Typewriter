import "package:collection/collection.dart";
import "package:flutter/widgets.dart";
import "package:petitparser/petitparser.dart";
import "package:typewriter_panel/logic/search/query/query.dart";

const quotes = ["'", '"'];

enum QueryMultiplicity { single, multiple }

sealed class QuerySelectorDefinition {
  const QuerySelectorDefinition({
    required this.id,
    this.caseSensitive = false,
    this.multiplicity = QueryMultiplicity.multiple,
    this.color,
  });

  final String id;
  final bool caseSensitive;
  final QueryMultiplicity multiplicity;
  final Color? color;

  Parser<QueryLexerSelectorToken> parser();
  QuerySelectorDefinition merge(QuerySelectorDefinition other);

  List<QueryParseIssue> validate(List<QueryLexerSelectorToken> tokens) {
    assert(
      tokens.none((token) => token.selectorId != id),
      "Can only validate own tokens",
    );

    final issues = <QueryParseIssue>[];

    if (multiplicity == QueryMultiplicity.single && tokens.length > 1) {
      for (final token in tokens.skip(1)) {
        issues.add(
          QueryParseIssue(
            code: QueryIssueCode.multiplicityViolation,
            message: "Selector $id can only appear once",
            severity: QuerySeverity.error,
            range: token.range,
          ),
        );
      }
    }

    return issues;
  }
}

final class KeyValueSelectorDefinition extends QuerySelectorDefinition {
  const KeyValueSelectorDefinition({
    required super.id,
    required this.key,
    super.caseSensitive,
    super.multiplicity,
    super.color,
    this.value = const QuerySelectorValue.freeText(),
  });
  final String key;
  final QuerySelectorValue value;

  @override
  Parser<QueryLexerKeyValueSelectorToken> parser() {
    return (string(key, ignoreCase: !caseSensitive).token() &
            [
              ([whitespace(), pattern("'\"|&()")].toChoiceParser().not() &
                      any())
                  .plus()
                  .flatten(),
              for (final quote in quotes)
                char(quote) &
                    (char(quote).not() & any()).plus().flatten().optional() &
                    char(quote).optional(),
            ].toChoiceParser().token().optional())
        .token()
        .map((token) {
          final data = token.value;
          final raw = token.input;
          final range = token.range;
          assert(data.length == 2, "Expected 2 elements");
          final [Token<String> key, Token<dynamic>? valueToken] = data;
          assert(
            caseSensitive
                ? key.value == this.key
                : key.value.toLowerCase() == this.key.toLowerCase(),
            "Expected key",
          );

          final keyRange = key.range;

          if (valueToken == null) {
            return QueryLexerKeyValueSelectorToken(
              selectorId: id,
              raw: raw,
              range: range,
              keyRange: keyRange,
              issues: [
                QueryParseIssue(
                  code: QueryIssueCode.missingSelectorValue,
                  severity: QuerySeverity.error,
                  message: "Missing value for selector $id",
                  range: keyRange,
                ),
              ],
            );
          }

          final value = valueToken.value;
          final valueRange = valueToken.range;

          if (value is String) {
            return QueryLexerKeyValueSelectorToken(
              selectorId: id,
              raw: raw,
              range: range,
              keyRange: keyRange,
              value: value,
              valueRange: valueRange,
              issues: [
                if (!this.value.isValid(value))
                  QueryParseIssue(
                    code: QueryIssueCode.invalidSelectorValue,
                    severity: QuerySeverity.warning,
                    message: "Value $value is invalid for selector $id",
                    range: valueRange,
                  ),
              ],
            );
          }

          if (value is List) {
            final [String openQuote, String? label, String? closeQuote] = value;

            return QueryLexerKeyValueSelectorToken(
              selectorId: id,
              raw: raw,
              range: range,
              keyRange: keyRange,
              value: label,
              valueRange: valueRange,
              issues: [
                if (closeQuote == null)
                  QueryParseIssue(
                    code: QueryIssueCode.unclosedQuote,
                    severity: QuerySeverity.error,
                    message: "Unclosed quote",
                    range: valueRange,
                  ),
                if (label == null)
                  QueryParseIssue(
                    code: QueryIssueCode.missingSelectorValue,
                    severity: QuerySeverity.error,
                    message: "Missing value for selector $id",
                    range: range,
                  )
                else if (!this.value.isValid(label))
                  QueryParseIssue(
                    code: QueryIssueCode.invalidSelectorValue,
                    severity: QuerySeverity.warning,
                    message: "Value $label is invalid for selector $id",
                    range: valueRange,
                  ),
              ],
            );
          }

          throw UnimplementedError(
            "Unexpected value: $value, ${value.runtimeType}",
          );
        });
  }

  @override
  QuerySelectorDefinition merge(QuerySelectorDefinition other) {
    assert(id == other.id, "Can only merge selectors with same id");
    if (other is! KeyValueSelectorDefinition) {
      return this;
    }
    return KeyValueSelectorDefinition(
      id: id,
      key: key,
      caseSensitive: caseSensitive || other.caseSensitive,
      multiplicity: multiplicity == .single || other.multiplicity == .single
          ? .single
          : .multiple,
      color: color,
      value: value.merge(other.value),
    );
  }
}

extension QuerySelectorDefinitionsX on List<QuerySelectorDefinition> {
  List<QuerySelectorDefinition> merge(List<QuerySelectorDefinition> other) {
    final result = <QuerySelectorDefinition>[];
    final otherById = {for (final s in other) s.id: s};
    for (final s in this) {
      final otherS = otherById.remove(s.id);
      if (otherS == null) {
        result.add(s);
        continue;
      }
      result.add(s.merge(otherS));
    }
    for (final s in otherById.values) {
      result.add(s);
    }
    return result;
  }
}

sealed class QuerySelectorValue {
  const QuerySelectorValue._();

  const factory QuerySelectorValue.freeText() = FreeTextSelectorValue;
  const factory QuerySelectorValue.enumValue(List<String> possibleValues) =
      EnumSelectorValue;

  bool isValid(String value);
  List<String> suggestions(String partial);
  QuerySelectorValue merge(QuerySelectorValue other);
}

class FreeTextSelectorValue extends QuerySelectorValue {
  const FreeTextSelectorValue() : super._();

  @override
  bool isValid(String value) => true;

  @override
  List<String> suggestions(String partial) => [];

  @override
  QuerySelectorValue merge(QuerySelectorValue other) => this;
}

class EnumSelectorValue extends QuerySelectorValue {
  const EnumSelectorValue(this.possibleValues) : super._();

  final List<String> possibleValues;

  @override
  bool isValid(String value) => possibleValues.contains(value);

  @override
  List<String> suggestions(String partial) => possibleValues;

  @override
  QuerySelectorValue merge(QuerySelectorValue other) {
    switch (other) {
      case EnumSelectorValue(possibleValues: final otherValues):
        return EnumSelectorValue({...possibleValues, ...otherValues}.toList());
      case FreeTextSelectorValue():
        return other;
    }
  }
}
