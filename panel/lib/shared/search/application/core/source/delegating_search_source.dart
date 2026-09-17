import "dart:async";

import "package:typewriter_panel/typewriter_panel.dart";

/// Base for decorators that transform child snapshots while preserving source
/// initialization, query, selector, preview, and disposal ownership.
abstract base class DelegatingSearchSource
    implements SearchSource, SearchSelectorCompletionSource {
  DelegatingSearchSource({required this.source}) {
    _snapshotSubscription = source.snapshots.listen(onSnapshot);
  }

  final SearchSource source;

  final _snapshots = StreamController<SearchSourceSnapshot>.broadcast(
    sync: true,
  );
  StreamSubscription<SearchSourceSnapshot>? _snapshotSubscription;
  bool _disposed = false;

  @override
  Stream<SearchSourceSnapshot> get snapshots => _snapshots.stream;

  @override
  List<QuerySelectorDefinition> get selectors => source.selectors;

  @override
  Future<SearchSelectorCompletionResult> completeSelector(
    SearchSelectorCompletionRequest request,
  ) {
    final child = source;
    if (child is! SearchSelectorCompletionSource) {
      return Future.value(const SearchSelectorCompletionResult());
    }
    return (child as SearchSelectorCompletionSource).completeSelector(request);
  }

  @override
  void initialize(SearchQueryContext context) => source.initialize(context);

  @override
  void search(SearchQueryContext context) => source.search(context);

  @override
  Future<SearchPreviewRequestResult> preview(SearchPreviewRequest request) {
    return source.preview(request);
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    unawaited(_snapshotSubscription?.cancel());
    _snapshotSubscription = null;
    unawaited(_snapshots.close());
    source.dispose();
  }

  void emit(SearchSourceSnapshot snapshot) {
    if (_disposed) return;
    _snapshots.add(snapshot);
  }

  /// Transforms or forwards one child snapshot.
  void onSnapshot(SearchSourceSnapshot snapshot);
}
