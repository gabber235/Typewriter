import "package:typewriter_panel/typewriter_panel.dart";

typedef SearchSourceGate = bool Function(SearchQueryContext context);
typedef SearchSourceClosedGuidance =
    SearchGuidance? Function(SearchQueryContext context);

final class GatedSearchSource extends DelegatingSearchSource {
  GatedSearchSource({
    required super.source,
    required this.isOpen,
    this.closedGuidance,
  });

  final SearchSourceGate isOpen;
  final SearchSourceClosedGuidance? closedGuidance;

  bool _acceptSnapshots = true;

  @override
  void search(SearchQueryContext context) {
    if (isOpen(context)) {
      _acceptSnapshots = true;
      source.search(context);
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
