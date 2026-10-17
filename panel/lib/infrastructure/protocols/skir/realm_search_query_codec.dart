import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

/// Preserves the parsed query and its selector expression for Realm evaluation.
///
/// The flat selectors carry selector identities while the expression preserves
/// boolean grouping. This boundary encodes an already parsed query and does not
/// reinterpret text or apply resource specific filtering policy.
skir.RealmSearchQuery encodeRealmSearchQuery(SearchQueryContext query) =>
    skir.RealmSearchQuery(
      normalizedQuery: query.normalizedQuery,
      terms: query.terms,
      selectors: query.selectors.map(
        (selector) => skir.RealmSearchSelector(
          selectorId: selector.selectorId,
          key: selector.key,
          value: selector.value,
        ),
      ),
      selectorExpression: query.selectorExpression == null
          ? null
          : encodeRealmSearchSelectorExpression(query.selectorExpression!),
    );

skir.RealmSearchSelectorExpression encodeRealmSearchSelectorExpression(
  SearchSelectorExpression expression,
) => switch (expression) {
  SearchSelectorLeafExpression(:final selector) =>
    skir.RealmSearchSelectorExpression.wrapSelector(
      skir.RealmSearchSelector(
        selectorId: selector.selectorId,
        key: selector.key,
        value: selector.value,
      ),
    ),
  SearchSelectorBinaryExpression(:final operator, :final left, :final right) =>
    skir.RealmSearchSelectorExpression.createBinary(
      operator_: operator == SearchSelectorOperator.and
          ? skir.RealmSearchSelectorOperator.and
          : skir.RealmSearchSelectorOperator.or,
      left: encodeRealmSearchSelectorExpression(left),
      right: encodeRealmSearchSelectorExpression(right),
    ),
  SearchSelectorNotExpression(:final expression) =>
    skir.RealmSearchSelectorExpression.createNot(
      expression: encodeRealmSearchSelectorExpression(expression),
    ),
};
