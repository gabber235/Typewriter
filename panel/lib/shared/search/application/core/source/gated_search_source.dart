import "package:typewriter_panel/typewriter_panel.dart";

/// Decides whether a query may reach a child source.
typedef SearchSourceGate = bool Function(SearchQueryContext context);

/// Builds optional guidance emitted when a query is blocked.
typedef SearchSourceClosedGuidance = SearchGuidance? Function(
  SearchQueryContext context,
);

/// Blocks searches and previews until [isOpen] accepts their query context.
///
/// While closed, child snapshots are ignored and an idle snapshot with optional
/// guidance is emitted. Opening the gate does not replay a previous query.
final class GatedSearchSource extends DelegatingSearchSource {
  GatedSearchSource({
    required super.source,
    required this.isOpen,
    this.closedGuidance,
  });

  final SearchSourceGate isOpen;
  final SearchSourceClosedGuidance? closedGuidance;

  bool _acceptSnapshots = true;
  bool _initializationPending = false;

  @override
  void initialize(SearchQueryContext context) {
    // Initialization can start remote work, so it obeys the same gate as edits.
    _initializationPending = true;
    search(context);
  }

  @override
  void search(SearchQueryContext context) {
    if (isOpen(context)) {
      _acceptSnapshots = true;
      if (_initializationPending) {
        _initializationPending = false;
        source.initialize(context);
      } else {
        source.search(context);
      }
      return;
    }

    _acceptSnapshots = false;
    final guidance = closedGuidance?.call(context);
    emit(SearchSourceSnapshot.idle(guidance: [?guidance]));
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
  void onSnapshot(SearchSourceSnapshot snapshot) {
    if (!_acceptSnapshots) return;
    emit(snapshot);
  }
}

/// Adds query dependent access gating to a source.
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
