import "dart:async";

import "package:typewriter_panel/logic/search/core/models.dart";
import "package:typewriter_panel/logic/search/core/search_source.dart";
import "package:typewriter_panel/logic/search/query/query_selector.dart";

final class DebouncedSearchSource implements SearchSource {
  DebouncedSearchSource({required this.source, required this.duration});

  final SearchSource source;
  final Duration duration;

  Timer? _timer;
  SearchQueryContext? _pendingContext;

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
    return source.preview(request);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _timer = null;
    _pendingContext = null;
    source.dispose();
  }
}

extension DebouncedSearchSourceX on SearchSource {
  SearchSource debounced(Duration duration) {
    return DebouncedSearchSource(source: this, duration: duration);
  }
}
