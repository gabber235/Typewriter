import "dart:async";

import "package:typewriter_panel/shared/search/application/core/models.dart";
import "package:typewriter_panel/shared/search/application/core/search_source.dart";
import "package:typewriter_panel/shared/search/domain/query/query_selector.dart";

final class DebouncedSearchSource implements SearchSource {
  DebouncedSearchSource({required this.source, required this.duration});

  final SearchSource source;
  final Duration duration;

  Timer? _timer;
  SearchQueryContext? _pendingContext;

  Timer? _previewTimer;
  SearchPreviewRequest? _pendingPreviewRequest;
  Completer<SearchPreviewRequestResult>? _pendingPreviewCompleter;

  @override
  Stream<SearchSourceSnapshot> get snapshots => source.snapshots;

  @override
  Stream<List<QuerySelectorDefinition>> get selectors => source.selectors;

  @override
  void initialize() {
    source.initialize();
  }

  @override
  void search(SearchQueryContext context) {
    _pendingContext = context;
    _timer?.cancel();
    _timer = Timer(duration, () {
      final context = _pendingContext;
      if (context == null) return;
      _pendingContext = null;
      source.search(context);
    });
  }

  @override
  Future<SearchPreviewRequestResult> preview(SearchPreviewRequest request) {
    final pendingCompleter = _pendingPreviewCompleter;
    if (pendingCompleter != null && !pendingCompleter.isCompleted) {
      pendingCompleter.complete(
        const SearchPreviewRequestResult.error(
          message: "Preview request superseded by a newer request",
        ),
      );
    }

    _pendingPreviewRequest = request;
    _previewTimer?.cancel();

    final completer = Completer<SearchPreviewRequestResult>();
    _pendingPreviewCompleter = completer;

    _previewTimer = Timer(duration, () async {
      final pendingRequest = _pendingPreviewRequest;
      final activeCompleter = _pendingPreviewCompleter;
      _pendingPreviewRequest = null;
      _pendingPreviewCompleter = null;

      if (pendingRequest == null || activeCompleter == null) return;

      try {
        final result = await source.preview(pendingRequest);
        if (!activeCompleter.isCompleted) {
          activeCompleter.complete(result);
        }
      } catch (error, stackTrace) {
        if (!activeCompleter.isCompleted) {
          activeCompleter.completeError(error, stackTrace);
        }
      }
    });

    return completer.future;
  }

  @override
  void dispose() {
    _timer?.cancel();
    _timer = null;
    _pendingContext = null;

    _previewTimer?.cancel();
    _previewTimer = null;
    _pendingPreviewRequest = null;
    final pendingCompleter = _pendingPreviewCompleter;
    _pendingPreviewCompleter = null;
    if (pendingCompleter != null && !pendingCompleter.isCompleted) {
      pendingCompleter.complete(
        const SearchPreviewRequestResult.error(
          message: "Preview request cancelled",
        ),
      );
    }

    source.dispose();
  }
}

extension DebouncedSearchSourceX on SearchSource {
  SearchSource debounced(Duration duration) {
    return DebouncedSearchSource(source: this, duration: duration);
  }
}
