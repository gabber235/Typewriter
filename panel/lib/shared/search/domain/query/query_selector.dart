import "package:collection/collection.dart";
import "package:flutter/widgets.dart";
import "package:freezed_annotation/freezed_annotation.dart";
import "package:petitparser/petitparser.dart";
import "package:typewriter_panel/typewriter_panel.dart";

part "query_selector.freezed.dart";

const quotes = ["'", '"'];

/// Whether a selector may occur once or repeatedly in one query.
enum QueryMultiplicity { single, multiple }

/// Grammar and validation policy for one selector.
///
/// Definitions are merged by selector ID when sources contribute additional
/// selector capabilities. The merged definition is the parser authority used
/// by both query execution and suggestions.
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

  /// Builds the parser for this selector's key and value syntax.
  Parser<QueryLexerToken> parser();

  /// Combines compatible definitions with the same selector ID.
  QuerySelectorDefinition merge(QuerySelectorDefinition other);

  /// Validates cross occurrence constraints such as multiplicity.
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

/// Selector represented as a key with an optional value.
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
    if (other is! KeyValueSelectorDefinition ||
        id != other.id ||
        key != other.key ||
        caseSensitive != other.caseSensitive ||
        multiplicity != other.multiplicity ||
        value.runtimeType != other.value.runtimeType) {
      throw StateError("Conflicting definitions for selector $id");
    }
    return KeyValueSelectorDefinition(
      id: id,
      key: key,
      caseSensitive: caseSensitive,
      multiplicity: multiplicity,
      color: color,
      value: value.merge(other.value),
    );
  }
}

extension QuerySelectorDefinitionsX on List<QuerySelectorDefinition> {
  /// Merges definitions by ID while preserving the first list's ordering.
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

@freezed
/// Validation and suggestion policy for a selector value.
sealed class QuerySelectorValue with _$QuerySelectorValue {
  const factory QuerySelectorValue.freeText() = FreeTextSelectorValue;

  const factory QuerySelectorValue.enumValue(List<String> possibleValues) =
      EnumSelectorValue;

  const factory QuerySelectorValue.sourceBacked() = SourceBackedSelectorValue;

  const QuerySelectorValue._();

  /// Whether [value] is accepted by this policy.
  bool isValid(String value) => switch (this) {
    FreeTextSelectorValue() => true,
    EnumSelectorValue(:final possibleValues) => possibleValues.contains(value),
    SourceBackedSelectorValue() => true,
  };

  /// Returns candidate values. Free text deliberately has no candidates.
  List<String> suggestions(String partial) => switch (this) {
    FreeTextSelectorValue() => const [],
    EnumSelectorValue(:final possibleValues) => possibleValues,
    SourceBackedSelectorValue() => const [],
  };

  /// Combines value policies, with free text taking precedence.
  QuerySelectorValue merge(QuerySelectorValue other) {
    return switch ((this, other)) {
      (FreeTextSelectorValue(), FreeTextSelectorValue()) => this,
      (SourceBackedSelectorValue(), SourceBackedSelectorValue()) => this,
      (
        EnumSelectorValue(possibleValues: final values),
        EnumSelectorValue(possibleValues: final otherValues),
      ) =>
        QuerySelectorValue.enumValue({...values, ...otherValues}.toList()),
      _ => throw StateError("Cannot merge incompatible selector values"),
    };
  }
}
