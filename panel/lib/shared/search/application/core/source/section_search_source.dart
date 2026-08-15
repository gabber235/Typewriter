import "dart:async";

import "package:typewriter_panel/typewriter_panel.dart";

final class SectionSearchSource implements SearchSource {
  SectionSearchSource({
    required this.source,
    required this.id,
    required this.title,
    this.subtitle,
  }) : assert(id.isNotEmpty),
       assert(title.isNotEmpty) {
    _snapshotSubscription = source.snapshots.listen(_onSnapshot);
  }

  final SearchSource source;
  final String id;
  final String title;
  final String? subtitle;

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

  void _onSnapshot(SearchSourceSnapshot snapshot) {
    if (snapshot.nodes.isEmpty) {
      _snapshots.add(snapshot);
      return;
    }

    _snapshots.add(
      snapshot.copyWith(
        nodes: [
          SearchNode.section(
            id: id,
            title: title,
            subtitle: subtitle,
            children: snapshot.nodes,
          ),
        ],
      ),
    );
  }
}

extension SectionSearchSourceX on SearchSource {
  SearchSource inSection({
    required String id,
    required String title,
    String? subtitle,
  }) {
    return SectionSearchSource(
      source: this,
      id: id,
      title: title,
      subtitle: subtitle,
    );
  }
}
