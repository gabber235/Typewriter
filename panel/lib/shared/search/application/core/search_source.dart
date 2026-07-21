import "dart:async";

import "package:typewriter_panel/typewriter_panel.dart";

abstract interface class SearchSource {
  Stream<SearchSourceSnapshot> get snapshots;
  Stream<List<QuerySelectorDefinition>> get selectors;

  void initialize();

  void search(SearchQueryContext context);

  Future<SearchPreviewRequestResult> preview(SearchPreviewRequest request);

  void dispose();
}
