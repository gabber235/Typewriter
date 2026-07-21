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

SearchResult searchResult(
  String id, {
  List<Type> actions = const [],
  String? title,
  Object? payload,
}) {
  return SearchResult(
    id: id,
    type: testResultType,
    payload: payload ?? id,
    actions: actions,
    title: title ?? id,
  );
}

SearchNode resultNode(
  String id, {
  List<Type> actions = const [],
  String? title,
}) {
  return SearchNode.result(
    result: searchResult(id, actions: actions, title: title),
  );
}

SearchNode sectionNode(String id, List<SearchNode> children) {
  return SearchNode.section(id: id, title: id, children: children);
}

SearchSourceSnapshot readySnapshot({
  required List<SearchNode> nodes,
  Map<Type, SearchAction> actions = const {},
}) {
  return SearchSourceSnapshot.ready(nodes: nodes, actions: actions);
}

final class FakeSearchSource implements SearchSource {
  final _snapshots = StreamController<SearchSourceSnapshot>.broadcast(
    sync: true,
  );
  final _selectors = StreamController<List<QuerySelectorDefinition>>.broadcast(
    sync: true,
  );

  int initializeCount = 0;
  int disposeCount = 0;
  final searches = <SearchQueryContext>[];
  final previewRequests = <SearchPreviewRequest>[];
  SearchPreviewRequestResult previewResult =
      const SearchPreviewRequestResult.data(data: "preview");

  @override
  Stream<SearchSourceSnapshot> get snapshots => _snapshots.stream;

  @override
  Stream<List<QuerySelectorDefinition>> get selectors => _selectors.stream;

  @override
  void initialize() {
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

  void emitSelectors(List<QuerySelectorDefinition> selectors) {
    _selectors.add(selectors);
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
    unawaited(_selectors.close());
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

final class TestSingleAction extends SingleSearchAction {
  TestSingleAction({this.result, this.onExecute, this.throwError = false});

  final SearchActionResult? result;
  final Future<SearchActionResult> Function(SearchResult result)? onExecute;
  final bool throwError;
  final executedResults = <SearchResult>[];
  final completer = Completer<SearchActionResult>();

  @override
  String get label => "Single";

  @override
  int get priority => 0;

  @override
  Future<SearchActionResult> execute(SearchResult result) async {
    executedResults.add(result);
    if (throwError) {
      throw StateError("boom");
    }
    final callback = onExecute;
    if (callback != null) {
      return callback(result);
    }
    final immediate = this.result;
    if (immediate != null) {
      return immediate;
    }
    return completer.future;
  }
}

final class TestRepeatedAction extends RepeatedSearchAction {
  TestRepeatedAction({this.onExecute});

  final Future<SearchActionResult> Function(SearchResult result)? onExecute;
  final executedResults = <SearchResult>[];

  @override
  String get label => "Repeated";

  @override
  int get priority => 0;

  @override
  Future<SearchActionResult> execute(SearchResult result) async {
    executedResults.add(result);
    return onExecute?.call(result) ?? const SearchActionResult.completed();
  }
}

final class TestBatchAction extends BatchSearchAction {
  TestBatchAction({this.result = const SearchActionResult.completed()});

  final SearchActionResult result;
  final batches = <List<SearchResult>>[];

  @override
  String get label => "Batch";

  @override
  int get priority => 0;

  @override
  Future<SearchActionResult> executeBatch(List<SearchResult> results) async {
    batches.add(List.unmodifiable(results));
    return result;
  }
}
