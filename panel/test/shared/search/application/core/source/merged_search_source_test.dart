// ignore_for_file: cascade_invocations

import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";

import "../support/search_core_test_harness.dart";

void main() {
  group("MergedSearchSource", () {
    test("initializes, searches, and disposes every child once", () {
      final first = FakeSearchSource();
      final second = FakeSearchSource();
      final source = [first, second].merged();

      source.initialize();
      source.search(queryContext("home"));
      source.dispose();
      source.dispose();

      expect(first.initializeCount, 1);
      expect(second.initializeCount, 1);
      expect(first.searches, [queryContext("home")]);
      expect(second.searches, [queryContext("home")]);
      expect(first.disposeCount, 1);
      expect(second.disposeCount, 1);
    });

    test("keeps partial results visible while another child loads", () {
      final first = FakeSearchSource();
      final second = FakeSearchSource();
      final source = [first, second].merged();
      addTearDown(source.dispose);
      final snapshots = <SearchSourceSnapshot>[];
      final subscription = source.snapshots.listen(snapshots.add);
      addTearDown(subscription.cancel);
      source.initialize();

      first.emitSnapshot(readySnapshot(nodes: [resultNode("local")]));
      second.emitSnapshot(SearchSourceSnapshot.loading());

      expect(snapshots.last.status, SearchSourceStatus.loading);
      expect(resultIds(snapshots.last), ["local"]);
    });

    test("does not mix snapshots from different queries", () {
      final first = FakeSearchSource();
      final second = FakeSearchSource();
      final source = [first, second].merged();
      addTearDown(source.dispose);
      final snapshots = <SearchSourceSnapshot>[];
      final subscription = source.snapshots.listen(snapshots.add);
      addTearDown(subscription.cancel);
      source.initialize();
      source.search(queryContext("old"));
      first.emitSnapshot(readySnapshot(nodes: [resultNode("old first")]));
      second.emitSnapshot(readySnapshot(nodes: [resultNode("old second")]));

      source.search(queryContext("new"));
      first.emitSnapshot(SearchSourceSnapshot.loading());

      expect(resultIds(snapshots.last), isEmpty);
      expect(snapshots.last.status, SearchSourceStatus.loading);
    });

    test("merges actions guidance diagnostics and selectors", () {
      final first = FakeSearchSource();
      final second = FakeSearchSource();
      final source = [first, second].merged();
      addTearDown(source.dispose);
      final snapshots = <SearchSourceSnapshot>[];
      final selectors = <List<QuerySelectorDefinition>>[];
      final snapshotSubscription = source.snapshots.listen(snapshots.add);
      final selectorSubscription = source.selectors.listen(selectors.add);
      addTearDown(snapshotSubscription.cancel);
      addTearDown(selectorSubscription.cancel);
      source.initialize();
      final action = TestSingleAction(
        result: const SearchActionResult.completed(),
      );

      first.emitSelectors(const [
        KeyValueSelectorDefinition(id: "tag", key: "tag:"),
      ]);
      second.emitSelectors(const [
        KeyValueSelectorDefinition(id: "world", key: "world:"),
      ]);
      first.emitSnapshot(
        SearchSourceSnapshot.ready(
          nodes: [resultNode("first")],
          actions: {TestSingleAction: action},
          guidance: const [SearchGuidance(id: "first", title: "First")],
        ),
      );
      second.emitSnapshot(
        SearchSourceSnapshot.ready(
          nodes: [resultNode("second")],
          errorSummaries: const [
            SearchErrorSummary(
              id: "partial",
              message: "Web unavailable",
              severity: SearchErrorSeverity.warning,
            ),
          ],
        ),
      );

      expect(selectors.last.map((selector) => selector.id), ["tag", "world"]);
      expect(resultIds(snapshots.last), ["first", "second"]);
      expect(snapshots.last.actions, {TestSingleAction: action});
      expect(snapshots.last.guidance.single.id, "first");
      expect(snapshots.last.errorSummaries.single.id, "partial");
      expect(snapshots.last.status, SearchSourceStatus.ready);
    });

    test("all empty errors produce an error snapshot", () {
      final first = FakeSearchSource();
      final second = FakeSearchSource();
      final source = [first, second].merged();
      addTearDown(source.dispose);
      final snapshots = <SearchSourceSnapshot>[];
      final subscription = source.snapshots.listen(snapshots.add);
      addTearDown(subscription.cancel);
      source.initialize();

      first.emitSnapshot(errorSnapshot("first", "First failed"));
      second.emitSnapshot(errorSnapshot("second", "Second failed"));

      expect(snapshots.last.status, SearchSourceStatus.error);
      expect(snapshots.last.errorSummaries, hasLength(2));
    });

    test("preview is routed to the child that produced the result", () async {
      final first = FakeSearchSource();
      final second = FakeSearchSource()
        ..previewResult = const SearchPreviewRequestResult.data(data: "second");
      final source = [first, second].merged();
      addTearDown(source.dispose);
      source.initialize();
      first.emitSnapshot(readySnapshot(nodes: [resultNode("first")]));
      second.emitSnapshot(readySnapshot(nodes: [resultNode("second")]));
      const request = SearchPreviewRequest(resultId: "second");

      final preview = await source.preview(request);

      expect(preview, const SearchPreviewRequestResult.data(data: "second"));
      expect(first.previewRequests, isEmpty);
      expect(second.previewRequests, [request]);
    });

    test("local and global limits compose differently", () {
      final localFirst = FakeSearchSource();
      final localSecond = FakeSearchSource();
      final globalFirst = FakeSearchSource();
      final globalSecond = FakeSearchSource();
      final locallyLimited = [
        localFirst.limited(1),
        localSecond.limited(1),
      ].merged();
      final globallyLimited = [globalFirst, globalSecond].merged().limited(1);
      addTearDown(locallyLimited.dispose);
      addTearDown(globallyLimited.dispose);
      final localSnapshots = <SearchSourceSnapshot>[];
      final globalSnapshots = <SearchSourceSnapshot>[];
      final localSubscription = locallyLimited.snapshots.listen(
        localSnapshots.add,
      );
      final globalSubscription = globallyLimited.snapshots.listen(
        globalSnapshots.add,
      );
      addTearDown(localSubscription.cancel);
      addTearDown(globalSubscription.cancel);
      locallyLimited.initialize();
      globallyLimited.initialize();

      localFirst.emitSnapshot(readySnapshot(nodes: [resultNode("one")]));
      localSecond.emitSnapshot(readySnapshot(nodes: [resultNode("two")]));
      globalFirst.emitSnapshot(readySnapshot(nodes: [resultNode("one")]));
      globalSecond.emitSnapshot(readySnapshot(nodes: [resultNode("two")]));

      expect(resultIds(localSnapshots.last), ["one", "two"]);
      expect(resultIds(globalSnapshots.last), ["one"]);
    });

    test("outer distinct removes duplicates from merged sections", () {
      final first = FakeSearchSource();
      final second = FakeSearchSource();
      final source = [
        first.inSection(id: "first", title: "First"),
        second.inSection(id: "second", title: "Second"),
      ].merged().distinct();
      addTearDown(source.dispose);
      final snapshots = <SearchSourceSnapshot>[];
      final subscription = source.snapshots.listen(snapshots.add);
      addTearDown(subscription.cancel);
      source.initialize();

      first.emitSnapshot(readySnapshot(nodes: [resultNode("same")]));
      second.emitSnapshot(readySnapshot(nodes: [resultNode("same")]));

      expect(resultIds(snapshots.last), ["same"]);
      expect(snapshots.last.nodes, hasLength(1));
      expect((snapshots.last.nodes.single as SearchSectionNode).id, "first");
    });
  });
}

SearchQueryContext queryContext(String query) {
  return SearchQueryContext(normalizedQuery: query, selectors: const []);
}

SearchSourceSnapshot errorSnapshot(String id, String message) {
  return SearchSourceSnapshot.error(
    errorSummaries: [
      SearchErrorSummary(
        id: id,
        message: message,
        severity: SearchErrorSeverity.error,
      ),
    ],
  );
}

List<String> resultIds(SearchSourceSnapshot snapshot) {
  return snapshot.nodes
      .walk()
      .whereType<SearchResultNode>()
      .map((node) => node.result.id)
      .toList();
}
