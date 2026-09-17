import "dart:async";

import "package:rxdart/rxdart.dart";
import "package:typewriter_panel/typewriter_panel.dart";

/// Owns asynchronous selector completion for one query editor session.
///
/// A newer request replaces the previous request. Exhaustive results can serve
/// narrower partials with the same selector and expression scope.
final class QuerySuggestionSession {
  QuerySuggestionSession({
    required this.completeSelector,
    this.debounceDuration = const Duration(milliseconds: 150),
  }) {
    _subscription = _requests
        .debounceTime(debounceDuration)
        .flatMap(_complete)
        .listen(_publish);
  }

  final Future<SearchSelectorCompletionResult> Function(
    SearchSelectorCompletionRequest request,
  )?
  completeSelector;
  final Duration debounceDuration;

  final _requests = PublishSubject<SearchSelectorCompletionRequest>(sync: true);
  final _results = BehaviorSubject<SearchSelectorCompletionResult>.seeded(
    const SearchSelectorCompletionResult(),
    sync: true,
  );
  late final StreamSubscription<_CompletedSelectorRequest> _subscription;

  _CachedSelectorCompletion? _cachedCompletion;
  SearchSelectorCompletionRequest? _activeRequest;
  bool _disposed = false;

  Stream<SearchSelectorCompletionResult> get results => _results.stream;
  SearchSelectorCompletionResult get value => _results.value;

  void update(SearchSelectorCompletionRequest? request) {
    if (_disposed) return;
    _activeRequest = request;
    _results.add(const SearchSelectorCompletionResult());
    final complete = completeSelector;
    if (request == null || complete == null) {
      return;
    }

    final cached = _cachedCompletion;
    if (cached != null && cached.canServe(request)) {
      _results.add(cached.result);
      return;
    }

    _requests.add(request);
  }

  Stream<_CompletedSelectorRequest> _complete(
    SearchSelectorCompletionRequest request,
  ) {
    final complete = completeSelector!;
    return Stream.fromFuture(Future.sync(() => complete(request)))
        .map((result) => _CompletedSelectorRequest(request, result))
        .onErrorReturn(
          _CompletedSelectorRequest(
            request,
            const SearchSelectorCompletionResult(
              warning: "Selector suggestions are temporarily unavailable",
            ),
          ),
        );
  }

  void _publish(_CompletedSelectorRequest completed) {
    if (completed.request != _activeRequest) return;
    if (completed.result.exhaustive) {
      _cachedCompletion = _CachedSelectorCompletion(
        completed.request,
        completed.result,
      );
    }
    _results.add(completed.result);
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    unawaited(_subscription.cancel());
    unawaited(_requests.close());
    unawaited(_results.close());
  }
}

final class _CompletedSelectorRequest {
  const _CompletedSelectorRequest(this.request, this.result);

  final SearchSelectorCompletionRequest request;
  final SearchSelectorCompletionResult result;
}

final class _CachedSelectorCompletion {
  const _CachedSelectorCompletion(this.request, this.result);

  final SearchSelectorCompletionRequest request;
  final SearchSelectorCompletionResult result;

  bool canServe(SearchSelectorCompletionRequest next) =>
      result.exhaustive &&
      request.selectorId == next.selectorId &&
      request.scope == next.scope &&
      next.partial.toLowerCase().startsWith(request.partial.toLowerCase());
}
