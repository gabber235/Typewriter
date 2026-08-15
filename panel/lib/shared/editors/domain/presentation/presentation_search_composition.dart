part of "presentation_element.dart";

extension SearchProviderComposition on SearchProvider {
  SearchProvider gated({
    required TypedExpression condition,
    TypedExpression? guidance,
  }) => SearchProvider.gate(
    condition: condition,
    guidance: guidance,
    child: this,
  );

  SearchProvider debounced(Duration duration) =>
      SearchProvider.debounce(duration: duration, child: this);

  SearchProvider cached({
    required int capacity,
    bool retainStaleResults = true,
  }) => SearchProvider.cache(
    capacity: capacity,
    retainStaleResults: retainStaleResults,
    child: this,
  );

  SearchProvider ranked(List<SearchRankingField> fields) =>
      SearchProvider.rank(fields: fields, child: this);

  SearchProvider limited(TypedExpression maximum) =>
      SearchProvider.limit(maximum: maximum, child: this);

  SearchProvider distinct() => SearchProvider.distinct(child: this);

  SearchProvider withHistory({
    required String key,
    required TypedExpression label,
    required int capacity,
  }) => SearchProvider.history(
    key: key,
    label: label,
    capacity: capacity,
    child: this,
  );

  SearchProvider inSection({
    required String id,
    required TypedExpression label,
  }) => SearchProvider.section(id: id, label: label, child: this);
}
