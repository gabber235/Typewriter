import "dart:async";

import "package:typewriter_panel/typewriter_panel.dart";

abstract base class DelegatingSearchSource implements SearchSource {
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
  Stream<List<QuerySelectorDefinition>> get selectors => source.selectors;

  @override
  void initialize() => source.initialize();

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

  void onSnapshot(SearchSourceSnapshot snapshot);
}
