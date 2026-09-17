import "dart:async";

import "package:typewriter_panel/typewriter_panel.dart";

/// Delays search and preview requests until input has been quiet for [duration].
///
/// A newer request supersedes a pending preview with an explicit error result.
/// Disposal cancels timers and completes any pending preview request.
final class DebouncedSearchSource
    implements SearchSource, SearchSelectorCompletionSource {
  DebouncedSearchSource({required this.source, required this.duration});

  final SearchSource source;
  final Duration duration;

  Timer? _timer;
  SearchQueryContext? _pendingContext;

  Timer? _previewTimer;
  SearchPreviewRequest? _pendingPreviewRequest;
  Completer<SearchPreviewRequestResult>? _pendingPreviewCompleter;
  bool _disposed = false;

  @override
  Stream<SearchSourceSnapshot> get snapshots => source.snapshots;

  @override
  List<QuerySelectorDefinition> get selectors => source.selectors;

  @override
  void initialize(SearchQueryContext context) {
    source.initialize(context);
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
  void dispose() {
    if (_disposed) return;
    _disposed = true;
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

/// Adds input debouncing to a source.
extension DebouncedSearchSourceX on SearchSource {
  SearchSource debounced(Duration duration) {
    return DebouncedSearchSource(source: this, duration: duration);
  }
}
