import "dart:async";

import "package:flutter/foundation.dart";
import "package:flutter/widgets.dart";
import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";

const testResultType = SearchResultType(
  id: "test-result",
  rowRendererId: "test-row",
  label: "Test result",
);

SearchResult searchResult(String id, {String? title, Object? payload}) {
  return SearchResult(
    id: id,
    type: testResultType,
    payload: payload ?? id,
    title: title ?? id,
  );
}

SearchNode resultNode(String id, {String? title}) {
  return SearchNode.result(result: searchResult(id, title: title));
}

SearchNode sectionNode(String id, List<SearchNode> children) {
  return SearchNode.section(id: id, title: id, children: children);
}

SearchSourceSnapshot readySnapshot({required List<SearchNode> nodes}) {
  return SearchSourceSnapshot.ready(nodes: nodes);
}

SearchSession<void> testSearchSession(
  SearchSource source, {
  SearchSelectionMode selectionMode = SearchSelectionMode.multiple,
}) => SearchSession(
  source: source,
  interaction: SearchInteraction(
    activation: SearchActivation.custom(
      dependencies: const [],
      evaluate: (context, result) => const SearchActivationState.hidden(),
      activate: (context, result) async =>
          const SearchActivationResult.keepOpen(),
    ),
    selectionMode: selectionMode,
  ),
);

final class FakeSearchSource
    implements SearchSource, SearchSelectorCompletionSource {
  FakeSearchSource({this.selectors = const []});

  final _snapshots = StreamController<SearchSourceSnapshot>.broadcast(
    sync: true,
  );
  @override
  final List<QuerySelectorDefinition> selectors;

  int initializeCount = 0;
  int disposeCount = 0;
  final searches = <SearchQueryContext>[];
  final previewRequests = <SearchPreviewRequest>[];
  final completionRequests = <SearchSelectorCompletionRequest>[];
  SearchPreviewRequestResult previewResult =
      const SearchPreviewRequestResult.data(data: "preview");
  SearchSelectorCompletionResult completionResult =
      const SearchSelectorCompletionResult();
  Object? completionError;

  @override
  Stream<SearchSourceSnapshot> get snapshots => _snapshots.stream;

  @override
  void initialize(SearchQueryContext context) {
    initializeCount++;
  }

  @override
  void search(SearchQueryContext context) {
    searches.add(context);
  }

  @override
  Future<SearchPreviewRequestResult> preview(
    SearchPreviewRequest request,
  ) async {
    previewRequests.add(request);
    return previewResult;
  }

  @override
  Future<SearchSelectorCompletionResult> completeSelector(
    SearchSelectorCompletionRequest request,
  ) async {
    completionRequests.add(request);
    final error = completionError;
    if (error != null) Error.throwWithStackTrace(error, StackTrace.current);
    return completionResult;
  }

  void emitSnapshot(SearchSourceSnapshot snapshot) {
    _snapshots.add(snapshot);
  }

  /// Emits a snapshot and pumps both the rebuild and deferred row setup.
  ///
  /// Search result rows use a non-autoplay `flutter_animate` shake effect,
  /// which still schedules a zero-duration initialization timer when mounted.
  /// The second pump consumes that timer so it does not remain pending after
  /// the test completes.
  Future<void> emitSnapshotAndPump(
    WidgetTester tester,
    SearchSourceSnapshot snapshot,
  ) async {
    emitSnapshot(snapshot);
    await tester.pump();
    await tester.pump(Duration.zero);
  }

  SearchQueryContext get lastSearchContext {
    expect(searches, isNotEmpty);
    return searches.last;
  }

  void expectLastSearchContext({
    required String normalizedQuery,
    List<SearchParsedSelector> selectors = const [],
  }) {
    final context = lastSearchContext;
    expect(context.normalizedQuery, normalizedQuery);
    expect(context.selectors, selectors);
  }

  @override
  void dispose() {
    disposeCount++;
    unawaited(_snapshots.close());
  }
}

extension SearchWidgetTesterX on WidgetTester {
  /// Pumps newly mounted search rows and their deferred animation setup.
  ///
  /// Use this after operations such as scrolling that lazily mount result
  /// rows. Their non-autoplay `flutter_animate` shake effect creates a
  /// zero-duration initialization timer that requires one additional pump.
  Future<void> pumpSearchRows() async {
    await pump();
    await pump(Duration.zero);
  }
}

final class NotificationLog {
  NotificationLog(this._notifier) {
    _notifier.addListener(_listener);
  }

  final ChangeNotifier _notifier;
  final events = <int>[];

  int get count => events.length;

  void _listener() {
    events.add(events.length + 1);
  }

  void dispose() {
    _notifier.removeListener(_listener);
  }
}

NotificationLog recordNotifications(ChangeNotifier notifier) {
  return NotificationLog(notifier);
}
