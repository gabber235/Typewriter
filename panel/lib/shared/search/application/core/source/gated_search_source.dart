import "dart:async";

import "package:typewriter_panel/shared/search/application/core/models.dart";
import "package:typewriter_panel/shared/search/application/core/search_source.dart";
import "package:typewriter_panel/shared/search/domain/query/query_selector.dart";

typedef SearchSourceGate = bool Function(SearchQueryContext context);
typedef SearchSourceClosedGuidance =
    SearchGuidance? Function(SearchQueryContext context);

final class GatedSearchSource implements SearchSource {
  GatedSearchSource({
    required this.source,
    required this.isOpen,
    this.closedGuidance,
  }) {
    _snapshotSubscription = source.snapshots.listen(_onSnapshot);
  }

  final SearchSource source;
  final SearchSourceGate isOpen;
  final SearchSourceClosedGuidance? closedGuidance;

  final _snapshots = StreamController<SearchSourceSnapshot>.broadcast(
    sync: true,
  );

  StreamSubscription<SearchSourceSnapshot>? _snapshotSubscription;
  bool _acceptSnapshots = true;

  @override
  Stream<SearchSourceSnapshot> get snapshots => _snapshots.stream;

  @override
  Stream<List<QuerySelectorDefinition>> get selectors => source.selectors;

  @override
  void initialize() {
    source.initialize();
  }

  @override
  void search(SearchQueryContext context) {
    if (isOpen(context)) {
      _acceptSnapshots = true;
      source.search(context);
      return;
    }

    _acceptSnapshots = false;
    final guidance = closedGuidance?.call(context);
    _snapshots.add(SearchSourceSnapshot.idle(guidance: [?guidance]));
  }

  @override
  Future<SearchPreviewRequestResult> preview(SearchPreviewRequest request) {
    final context = request.queryContext;
    if (context == null || !isOpen(context)) {
      return Future.value(
        const SearchPreviewRequestResult.error(
          message: "Preview unavailable while search gate is closed",
        ),
      );
    }

    return source.preview(request);
  }

  @override
  void dispose() {
    unawaited(_snapshotSubscription?.cancel());
    _snapshotSubscription = null;
    unawaited(_snapshots.close());
    source.dispose();
  }

  void _onSnapshot(SearchSourceSnapshot snapshot) {
    if (!_acceptSnapshots) return;
    _snapshots.add(snapshot);
  }
}

extension GatedSearchSourceX on SearchSource {
  SearchSource gated(
    SearchSourceGate isOpen, {
    SearchSourceClosedGuidance? closedGuidance,
  }) {
    return GatedSearchSource(
      source: this,
      isOpen: isOpen,
      closedGuidance: closedGuidance,
    );
  }
}
