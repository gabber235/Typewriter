// ignore_for_file: sort_constructors_first

import "package:typewriter_panel/logic/search/query/query_models.dart";
import "package:typewriter_panel/logic/search/query/query_selector.dart";

class QueryValidationResult {
  final List<QueryParseIssue> issues;

  const QueryValidationResult(this.issues);
}

QueryValidationResult validateSelectorSemantics({
  required List<QuerySelectorMatch> matches,
  required List<QuerySelectorDefinition> selectors,
  required List<QueryTextTerm> textTerms,
}) {
  final issues = <QueryParseIssue>[];
  final byId = <String, int>{};
  final selectorById = <String, QuerySelectorDefinition>{
    for (final selector in selectors) selector.id: selector,
  };

  for (final match in matches) {
    final count = (byId[match.selectorId] ?? 0) + 1;
    byId[match.selectorId] = count;

    final selector = selectorById[match.selectorId];
    if (selector == null) {
      continue;
    }

    if (count > 1 && selector.multiplicity == QueryMultiplicity.single) {
      issues.add(
        QueryParseIssue(
          code: QueryIssueCode.multiplicityViolation,
          message: "Selector ${match.selectorId} can only appear once",
          severity: QuerySeverity.error,
          range: match.fullRange,
        ),
      );
    }

    if (match case KeyValueSelectorMatch(:final value)) {
      if (selector case KeyValueSelectorDefinition(
        :final valueMode,
        :final suggestionSource,
      )) {
        if (valueMode == QueryValueMode.enumValue &&
            suggestionSource != null &&
            value != null) {
          final values = suggestionSource("");
          final valid = values.any((candidate) => candidate == value);
          if (!valid) {
            issues.add(
              QueryParseIssue(
                code: QueryIssueCode.invalidSelectorValue,
                message:
                    "Value $value is invalid for selector ${match.selectorId}",
                severity: QuerySeverity.warning,
                range: match.valueRange,
              ),
            );
          }
        }
      }
    }
  }

  for (final term in textTerms) {
    final separatorIndex = term.text.indexOf(":");
    if (separatorIndex <= 0) {
      continue;
    }

    final possibleKey = term.text.substring(0, separatorIndex);
    final knownKey = selectors.whereType<KeyValueSelectorDefinition>().any(
      (selector) => selector.matchesKey(possibleKey),
    );

    if (!knownKey) {
      issues.add(
        QueryParseIssue(
          code: QueryIssueCode.unknownSelector,
          message: "Unknown selector key $possibleKey",
          severity: QuerySeverity.warning,
          range: term.range,
        ),
      );
    }
  }

  return QueryValidationResult(List.unmodifiable(issues));
}
