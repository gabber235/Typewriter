import "dart:async";

import "package:typewriter_panel/typewriter_panel.dart";

/// Produces the result tree and actions consumed by the search UI.
///
/// A source owns its external work and publishes immutable snapshots. The
/// caller initializes it once, may issue multiple searches, and must dispose it
/// to release subscriptions and other resources. [selectors] describes the
/// query syntax available to the source, while [preview] resolves detail for a
/// selected result without changing the result snapshot.
abstract interface class SearchSource {
  /// Emits source state changes, including loading, ready, idle, and error state.
  Stream<SearchSourceSnapshot> get snapshots;

  /// Static query syntax and selector ownership exposed by this source.
  List<QuerySelectorDefinition> get selectors;

  /// Starts source owned initialization.
  void initialize(SearchQueryContext context);

  /// Starts or replaces the search for [context].
  void search(SearchQueryContext context);

  /// Loads detail for [request].
  Future<SearchPreviewRequestResult> preview(SearchPreviewRequest request);

  /// Releases source resources and prevents further output.
  void dispose();
}

/// Optional capability for sources whose selector values come from live data.
abstract interface class SearchSelectorCompletionSource {
  Future<SearchSelectorCompletionResult> completeSelector(
    SearchSelectorCompletionRequest request,
  );
}
