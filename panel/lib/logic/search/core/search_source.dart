import "dart:async";

import "package:typewriter_panel/logic/search/core/models.dart";
import "package:typewriter_panel/logic/search/query/query_selector.dart";

abstract interface class SearchSource {
  Stream<SearchSourceSnapshot> get snapshots;
  Stream<List<QuerySelectorDefinition>> get selectors;

  void initialize();

  void search(SearchQueryContext context);

  Future<SearchPreviewRequestResult> preview(SearchPreviewRequest request);

  void dispose();
}
