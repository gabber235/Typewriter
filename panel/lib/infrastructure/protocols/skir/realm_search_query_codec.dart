import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/search.dart"
    as wire;
import "package:typewriter_panel/typewriter_panel.dart";

wire.RealmSearchQuery encodeRealmSearchQuery(SearchQueryContext query) =>
    wire.RealmSearchQuery(
      normalizedQuery: query.normalizedQuery,
      terms: query.terms,
      selectors: query.selectors.map(
        (selector) => wire.RealmSearchSelector(
          selectorId: selector.selectorId,
          key: selector.key,
          value: selector.value,
        ),
      ),
      selectorExpression: query.selectorExpression == null
          ? null
          : encodeRealmSearchSelectorExpression(query.selectorExpression!),
    );

wire.RealmSearchSelectorExpression encodeRealmSearchSelectorExpression(
  SearchSelectorExpression expression,
) => switch (expression) {
  SearchSelectorLeafExpression(:final selector) =>
    wire.RealmSearchSelectorExpression.wrapSelector(
      wire.RealmSearchSelector(
        selectorId: selector.selectorId,
        key: selector.key,
        value: selector.value,
      ),
    ),
  SearchSelectorBinaryExpression(:final operator, :final left, :final right) =>
    wire.RealmSearchSelectorExpression.createBinary(
      operator_: operator == SearchSelectorOperator.and
          ? wire.RealmSearchSelectorOperator.and
          : wire.RealmSearchSelectorOperator.or,
      left: encodeRealmSearchSelectorExpression(left),
      right: encodeRealmSearchSelectorExpression(right),
    ),
  SearchSelectorNotExpression(:final expression) =>
    wire.RealmSearchSelectorExpression.createNot(
      expression: encodeRealmSearchSelectorExpression(expression),
    ),
};
