import "dart:async";

import "package:typewriter_panel/typewriter_panel.dart";

final class FixedStorySearchSource implements SearchSource {
  FixedStorySearchSource({
    required this.snapshot,
    this.sourceSelectors = const [],
  });

  final SearchSourceSnapshot snapshot;
  final List<QuerySelectorDefinition> sourceSelectors;
  final _snapshots = StreamController<SearchSourceSnapshot>.broadcast(
    sync: true,
  );
  var _disposed = false;

  @override
  Stream<SearchSourceSnapshot> get snapshots => _snapshots.stream;

  @override
  List<QuerySelectorDefinition> get selectors => sourceSelectors;

  @override
  void initialize(SearchQueryContext context) {
    scheduleMicrotask(() {
      if (_disposed) return;
      _snapshots.add(snapshot);
    });
  }

  @override
  void search(SearchQueryContext context) {
    if (!_disposed) _snapshots.add(snapshot);
  }

  @override
  Future<SearchPreviewRequestResult> preview(
    SearchPreviewRequest request,
  ) async => const SearchPreviewRequestResult.error(
    message: "Story results render directly",
  );

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    unawaited(_snapshots.close());
  }
}
