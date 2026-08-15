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
  final _selectors = StreamController<List<QuerySelectorDefinition>>.broadcast(
    sync: true,
  );
  var _disposed = false;

  @override
  Stream<SearchSourceSnapshot> get snapshots => _snapshots.stream;

  @override
  Stream<List<QuerySelectorDefinition>> get selectors => _selectors.stream;

  @override
  void initialize() {
    scheduleMicrotask(() {
      if (_disposed) return;
      _selectors.add(sourceSelectors);
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
    unawaited(_selectors.close());
  }
}
