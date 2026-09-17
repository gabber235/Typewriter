import "package:collection/collection.dart";
import "package:typewriter_panel/typewriter_panel.dart";

/// Projects selector expressions onto the predicates a source can evaluate.
extension SearchSelectorExpressionProjection on SearchSelectorExpression {
  SearchSelectorExpression? projectFor(Set<String> selectorIds) {
    final projection = _project(this, selectorIds);
    return projection.constant == false ? null : projection.expression;
  }

  bool canMatch(Set<String> selectorIds) =>
      _project(this, selectorIds).constant != false;
}

extension SearchQueryContextProjection on SearchQueryContext {
  /// Returns the query this selector owner can evaluate, or null when its
  /// result domain cannot satisfy the expression.
  SearchQueryContext? projectFor(Set<String> selectorIds) {
    final expression = selectorExpression;
    if (expression == null) return this;

    final projection = _project(expression, selectorIds);
    if (projection.constant == false) return null;
    final projectedExpression = projection.expression;

    return copyWith(
      selectorExpression: projectedExpression,
      selectors: projectedExpression?.selectors ?? const [],
    );
  }
}

extension SearchSelectorCompletionRequestProjection
    on SearchSelectorCompletionRequest {
  SearchSelectorCompletionRequest? projectFor(Set<String> selectorIds) {
    if (!selectorIds.contains(selectorId)) return null;
    final expression = scope;
    if (expression == null) return this;

    final projection = _project(expression, selectorIds);
    if (projection.constant == false) return null;

    return SearchSelectorCompletionRequest(
      selectorId: selectorId,
      partial: partial,
      scope: projection.expression,
    );
  }
}

extension SearchSelectorExpressionValues on SearchSelectorExpression {
  List<SearchParsedSelector> get selectors => switch (this) {
    SearchSelectorLeafExpression(:final selector) => [selector],
    SearchSelectorBinaryExpression(:final left, :final right) => [
      ...left.selectors,
      ...right.selectors,
    ],
    SearchSelectorNotExpression(:final expression) => expression.selectors,
  };
}

/// Builds the dynamic completion request owned by the selector value at the
/// cursor. AND siblings constrain it. OR siblings do not.
extension QueryParseCompletion on QueryParseResult {
  SearchSelectorCompletionRequest? completionRequest(
    List<QuerySelectorDefinition> definitions,
  ) {
    final cursor = cursorContext;
    if (cursor is! SelectorValueCursorContext) return null;
    final definition = definitions
        .whereType<KeyValueSelectorDefinition>()
        .where((item) => item.id == cursor.selectorId)
        .firstOrNull;
    if (definition == null || definition.value is! SourceBackedSelectorValue) {
      return null;
    }

    final expression = this.expression;
    if (expression == null) return null;
    final definitionsById = {
      for (final item in definitions.whereType<KeyValueSelectorDefinition>())
        item.id: item,
    };
    final scope = _completionScope(
      expression,
      cursor.keyRange,
      definitionsById,
    );
    if (!scope.found) return null;

    return SearchSelectorCompletionRequest(
      selectorId: cursor.selectorId,
      partial: cursor.partialValue,
      scope: scope.expression,
    );
  }
}

typedef _CompletionScope = ({bool found, SearchSelectorExpression? expression});

_CompletionScope _completionScope(
  QueryLexerToken token,
  QueryRange activeKeyRange,
  Map<String, KeyValueSelectorDefinition> definitions,
) {
  switch (token) {
    case QueryLexerKeyValueSelectorToken(:final keyRange):
      return (found: keyRange == activeKeyRange, expression: null);
    case QueryLexerNegationToken(:final token):
      return _completionScope(token, activeKeyRange, definitions);
    case QueryLexerOperatorToken(:final type, :final left, :final right):
      final leftScope = _completionScope(left, activeKeyRange, definitions);
      if (leftScope.found) {
        return (
          found: true,
          expression: type == QueryLexerOperatorType.and
              ? _and(
                  leftScope.expression,
                  _toSearchExpression(right, definitions),
                )
              : leftScope.expression,
        );
      }

      final rightScope = _completionScope(right, activeKeyRange, definitions);
      if (!rightScope.found) return (found: false, expression: null);
      return (
        found: true,
        expression: type == QueryLexerOperatorType.and
            ? _and(
                rightScope.expression,
                _toSearchExpression(left, definitions),
              )
            : rightScope.expression,
      );
  }
}

SearchSelectorExpression? _toSearchExpression(
  QueryLexerToken token,
  Map<String, KeyValueSelectorDefinition> definitions,
) {
  return switch (token) {
    QueryLexerKeyValueSelectorToken(:final selectorId, :final value)
        when value != null && definitions.containsKey(selectorId) =>
      SearchSelectorExpression.leaf(
        SearchParsedSelector(
          selectorId: selectorId,
          key: definitions[selectorId]!.key,
          value: value,
        ),
      ),
    QueryLexerKeyValueSelectorToken() => null,
    QueryLexerNegationToken(:final token) => switch (_toSearchExpression(
      token,
      definitions,
    )) {
      final expression? => SearchSelectorExpression.not(expression),
      null => null,
    },
    QueryLexerOperatorToken(:final type, :final left, :final right) => switch ((
      _toSearchExpression(left, definitions),
      _toSearchExpression(right, definitions),
    )) {
      (final left?, final right?) => SearchSelectorExpression.binary(
        operator: type == QueryLexerOperatorType.and
            ? SearchSelectorOperator.and
            : SearchSelectorOperator.or,
        left: left,
        right: right,
      ),
      _ => null,
    },
  };
}

SearchSelectorExpression? _and(
  SearchSelectorExpression? left,
  SearchSelectorExpression? right,
) {
  if (left == null) return right;
  if (right == null) return left;
  return SearchSelectorExpression.binary(
    operator: SearchSelectorOperator.and,
    left: left,
    right: right,
  );
}

class _Projection {
  const _Projection.expression(this.expression) : constant = null;
  const _Projection.constant(this.constant) : expression = null;

  final bool? constant;
  final SearchSelectorExpression? expression;
}

_Projection _project(
  SearchSelectorExpression expression,
  Set<String> selectorIds,
) {
  return switch (expression) {
    SearchSelectorLeafExpression(:final selector) =>
      selectorIds.contains(selector.selectorId)
          ? _Projection.expression(expression)
          : const _Projection.constant(false),
    SearchSelectorNotExpression(:final expression) => _not(
      _project(expression, selectorIds),
    ),
    SearchSelectorBinaryExpression(
      :final operator,
      :final left,
      :final right,
    ) =>
      _binary(
        operator,
        _project(left, selectorIds),
        _project(right, selectorIds),
      ),
  };
}

_Projection _not(_Projection value) {
  final constant = value.constant;
  if (constant != null) return _Projection.constant(!constant);
  return _Projection.expression(
    SearchSelectorExpression.not(value.expression!),
  );
}

_Projection _binary(
  SearchSelectorOperator operator,
  _Projection left,
  _Projection right,
) {
  return switch (operator) {
    SearchSelectorOperator.and => _andProjection(left, right),
    SearchSelectorOperator.or => _orProjection(left, right),
  };
}

_Projection _andProjection(_Projection left, _Projection right) {
  if (left.constant == false || right.constant == false) {
    return const _Projection.constant(false);
  }
  if (left.constant == true) return right;
  if (right.constant == true) return left;
  return _Projection.expression(
    SearchSelectorExpression.binary(
      operator: SearchSelectorOperator.and,
      left: left.expression!,
      right: right.expression!,
    ),
  );
}

_Projection _orProjection(_Projection left, _Projection right) {
  if (left.constant == true || right.constant == true) {
    return const _Projection.constant(true);
  }
  if (left.constant == false) return right;
  if (right.constant == false) return left;
  return _Projection.expression(
    SearchSelectorExpression.binary(
      operator: SearchSelectorOperator.or,
      left: left.expression!,
      right: right.expression!,
    ),
  );
}
