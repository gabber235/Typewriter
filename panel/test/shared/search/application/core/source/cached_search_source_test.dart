// ignore_for_file: cascade_invocations

import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";

import "../support/search_core_test_harness.dart";

void main() {
  group("CachedSearchSource", () {
    test("initializes the inner source once", () {
      final inner = FakeSearchSource();
      final source = inner.cached();
      addTearDown(source.dispose);

      source.initialize();

      expect(inner.initializeCount, 1);
    });

    test("disposes the inner source once", () {
      final inner = FakeSearchSource();
      final source = inner.cached();

      source.dispose();

      expect(inner.disposeCount, 1);
    });

    test("forwards search unchanged", () {
      final inner = FakeSearchSource();
      final source = inner.cached();
      addTearDown(source.dispose);
      final context = queryContext("alpha");

      source.search(context);

      expect(inner.searches, [context]);
    });

    test("forwards selectors unchanged", () {
      final inner = FakeSearchSource();
      final source = inner.cached();
      addTearDown(source.dispose);
      final selectors = <List<QuerySelectorDefinition>>[];
      final subscription = source.selectors.listen(selectors.add);
      addTearDown(subscription.cancel);
      const emitted = [KeyValueSelectorDefinition(id: "tag", key: "#")];

      inner.emitSelectors(emitted);

      expect(selectors, [emitted]);
    });

    test("caches successful preview results by resultId", () async {
      final inner = FakeSearchSource();
      final source = inner.cached();
      addTearDown(source.dispose);
      const request = SearchPreviewRequest(resultId: "alpha");

      final first = await source.preview(request);
      inner.previewResult = const SearchPreviewRequestResult.data(
        data: "changed",
      );
      final second = await source.preview(request);

      expect(first, const SearchPreviewRequestResult.data(data: "preview"));
      expect(second, const SearchPreviewRequestResult.data(data: "preview"));
      expect(inner.previewRequests, [request]);
    });

    test("does not cache preview errors", () async {
      final inner = FakeSearchSource()
        ..previewResult = const SearchPreviewRequestResult.error(
          message: "boom",
        );
      final source = inner.cached();
      addTearDown(source.dispose);
      const request = SearchPreviewRequest(resultId: "alpha");

      final first = await source.preview(request);
      final second = await source.preview(request);

      expect(first, const SearchPreviewRequestResult.error(message: "boom"));
      expect(second, const SearchPreviewRequestResult.error(message: "boom"));
      expect(inner.previewRequests, [request, request]);
    });

    test("preview cache key uses resultId only", () async {
      final inner = FakeSearchSource();
      final source = inner.cached();
      addTearDown(source.dispose);
      final firstRequest = SearchPreviewRequest(
        resultId: "alpha",
        queryContext: queryContext("first"),
      );
      final secondRequest = SearchPreviewRequest(
        resultId: "alpha",
        queryContext: queryContext("second"),
      );

      await source.preview(firstRequest);
      final second = await source.preview(secondRequest);

      expect(second, const SearchPreviewRequestResult.data(data: "preview"));
      expect(inner.previewRequests, [firstRequest]);
    });

    test("loading before any ready snapshot passes through unchanged", () {
      final inner = FakeSearchSource();
      final source = inner.cached();
      addTearDown(source.dispose);
      final snapshots = <SearchSourceSnapshot>[];
      final subscription = source.snapshots.listen(snapshots.add);
      addTearDown(subscription.cancel);
      final loading = SearchSourceSnapshot.loading(
        guidance: const [SearchGuidance(id: "loading", title: "Loading")],
      );

      inner.emitSnapshot(loading);

      expect(snapshots, [loading]);
    });

    test("error before any ready snapshot passes through unchanged", () {
      final inner = FakeSearchSource();
      final source = inner.cached();
      addTearDown(source.dispose);
      final snapshots = <SearchSourceSnapshot>[];
      final subscription = source.snapshots.listen(snapshots.add);
      addTearDown(subscription.cancel);
      final error = errorSnapshot("Network failed");

      inner.emitSnapshot(error);

      expect(snapshots, [error]);
    });

    test("idle before any ready snapshot passes through unchanged", () {
      final inner = FakeSearchSource();
      final source = inner.cached();
      addTearDown(source.dispose);
      final snapshots = <SearchSourceSnapshot>[];
      final subscription = source.snapshots.listen(snapshots.add);
      addTearDown(subscription.cancel);
      final idle = SearchSourceSnapshot.idle(
        guidance: const [SearchGuidance(id: "empty", title: "Start typing")],
      );

      inner.emitSnapshot(idle);

      expect(snapshots, [idle]);
    });

    test("ready snapshot passes through and becomes cache", () {
      final inner = FakeSearchSource();
      final source = inner.cached();
      addTearDown(source.dispose);
      final snapshots = <SearchSourceSnapshot>[];
      final subscription = source.snapshots.listen(snapshots.add);
      addTearDown(subscription.cancel);
      final ready = readySnapshot(nodes: [resultNode("alpha")]);

      inner.emitSnapshot(ready);
      inner.emitSnapshot(SearchSourceSnapshot.loading());

      expect(snapshots.first, ready);
      expect(resultIds(snapshots.last), ["alpha"]);
      expect(resultStaleStates(snapshots.last), [true]);
    });

    test("second ready snapshot replaces previous cache", () {
      final inner = FakeSearchSource();
      final source = inner.cached();
      addTearDown(source.dispose);
      final snapshots = <SearchSourceSnapshot>[];
      final subscription = source.snapshots.listen(snapshots.add);
      addTearDown(subscription.cancel);
      final first = readySnapshot(nodes: [resultNode("alpha")]);
      final second = readySnapshot(nodes: [resultNode("beta")]);

      inner.emitSnapshot(first);
      inner.emitSnapshot(second);
      inner.emitSnapshot(SearchSourceSnapshot.loading());

      expect(resultIds(snapshots.last), ["beta"]);
    });

    test("loading does not replace cache", () {
      final inner = FakeSearchSource();
      final source = inner.cached();
      addTearDown(source.dispose);
      final snapshots = <SearchSourceSnapshot>[];
      final subscription = source.snapshots.listen(snapshots.add);
      addTearDown(subscription.cancel);
      final ready = readySnapshot(nodes: [resultNode("alpha")]);
      final loadingWithDifferentNode = SearchSourceSnapshot.loading(
        nodes: [resultNode("beta")],
      );

      inner.emitSnapshot(ready);
      inner.emitSnapshot(loadingWithDifferentNode);
      inner.emitSnapshot(SearchSourceSnapshot.loading());

      expect(resultIds(snapshots.last), ["alpha"]);
    });

    test("error does not replace cache", () {
      final inner = FakeSearchSource();
      final source = inner.cached();
      addTearDown(source.dispose);
      final snapshots = <SearchSourceSnapshot>[];
      final subscription = source.snapshots.listen(snapshots.add);
      addTearDown(subscription.cancel);
      final ready = readySnapshot(nodes: [resultNode("alpha")]);
      final errorWithDifferentNode = errorSnapshot(
        "Network failed",
        nodes: [resultNode("beta")],
      );

      inner.emitSnapshot(ready);
      inner.emitSnapshot(errorWithDifferentNode);
      inner.emitSnapshot(SearchSourceSnapshot.loading());

      expect(resultIds(snapshots.last), ["alpha"]);
    });

    test("idle does not replace cache", () {
      final inner = FakeSearchSource();
      final source = inner.cached();
      addTearDown(source.dispose);
      final snapshots = <SearchSourceSnapshot>[];
      final subscription = source.snapshots.listen(snapshots.add);
      addTearDown(subscription.cancel);
      final ready = readySnapshot(nodes: [resultNode("alpha")]);
      final idleWithDifferentNode = SearchSourceSnapshot.idle(
        nodes: [resultNode("beta")],
      );

      inner.emitSnapshot(ready);
      inner.emitSnapshot(idleWithDifferentNode);
      inner.emitSnapshot(SearchSourceSnapshot.loading());

      expect(resultIds(snapshots.last), ["alpha"]);
    });

    test("loading after ready emits loading with cached stale nodes", () {
      final inner = FakeSearchSource();
      final source = inner.cached();
      addTearDown(source.dispose);
      final snapshots = <SearchSourceSnapshot>[];
      final subscription = source.snapshots.listen(snapshots.add);
      addTearDown(subscription.cancel);
      final ready = readySnapshot(nodes: [resultNode("alpha")]);

      inner.emitSnapshot(ready);
      inner.emitSnapshot(SearchSourceSnapshot.loading());

      expect(snapshots.last.status, SearchSourceStatus.loading);
      expect(resultIds(snapshots.last), ["alpha"]);
      expect(resultStaleStates(snapshots.last), [true]);
    });

    test("error after ready emits error with cached stale nodes", () {
      final inner = FakeSearchSource();
      final source = inner.cached();
      addTearDown(source.dispose);
      final snapshots = <SearchSourceSnapshot>[];
      final subscription = source.snapshots.listen(snapshots.add);
      addTearDown(subscription.cancel);
      final ready = readySnapshot(nodes: [resultNode("alpha")]);
      final error = errorSnapshot("Network failed");

      inner.emitSnapshot(ready);
      inner.emitSnapshot(error);

      expect(snapshots.last.status, SearchSourceStatus.error);
      expect(resultIds(snapshots.last), ["alpha"]);
      expect(resultStaleStates(snapshots.last), [true]);
      expect(snapshots.last.errorSummaries, error.errorSummaries);
    });

    test("ready then loading then error keeps stale ready results", () {
      final inner = FakeSearchSource();
      final source = inner.cached();
      addTearDown(source.dispose);
      final snapshots = <SearchSourceSnapshot>[];
      final subscription = source.snapshots.listen(snapshots.add);
      addTearDown(subscription.cancel);
      final ready = readySnapshot(nodes: [resultNode("alpha")]);
      final loading = SearchSourceSnapshot.loading(nodes: [resultNode("beta")]);
      final error = errorSnapshot(
        "Network failed",
        nodes: [resultNode("gamma")],
      );

      inner.emitSnapshot(ready);
      inner.emitSnapshot(loading);
      inner.emitSnapshot(error);

      expect(snapshots.map((snapshot) => snapshot.status), [
        SearchSourceStatus.ready,
        SearchSourceStatus.loading,
        SearchSourceStatus.error,
      ]);
      expect(resultIds(snapshots[1]), ["alpha"]);
      expect(resultStaleStates(snapshots[1]), [true]);
      expect(resultIds(snapshots[2]), ["alpha"]);
      expect(resultStaleStates(snapshots[2]), [true]);
      expect(snapshots[2].errorSummaries, error.errorSummaries);
    });

    test("stale marking is recursive through sections", () {
      final inner = FakeSearchSource();
      final source = inner.cached();
      addTearDown(source.dispose);
      final snapshots = <SearchSourceSnapshot>[];
      final subscription = source.snapshots.listen(snapshots.add);
      addTearDown(subscription.cancel);
      final ready = readySnapshot(
        nodes: [
          sectionNode("section", [
            sectionNode("nested", [resultNode("alpha")]),
          ]),
        ],
      );

      inner.emitSnapshot(ready);
      inner.emitSnapshot(SearchSourceSnapshot.loading());

      expect(resultStaleStates(snapshots.last), [true]);
    });

    test("section nodes are preserved while child results become stale", () {
      final inner = FakeSearchSource();
      final source = inner.cached();
      addTearDown(source.dispose);
      final snapshots = <SearchSourceSnapshot>[];
      final subscription = source.snapshots.listen(snapshots.add);
      addTearDown(subscription.cancel);
      final ready = readySnapshot(
        nodes: [
          sectionNode("section", [resultNode("alpha")]),
        ],
      );

      inner.emitSnapshot(ready);
      inner.emitSnapshot(SearchSourceSnapshot.loading());

      final section = snapshots.last.nodes.single as SearchSectionNode;
      expect(section.id, "section");
      expect(section.title, "section");
      expect(resultIds(snapshots.last), ["alpha"]);
      expect(resultStaleStates(snapshots.last), [true]);
    });

    test("already stale result stays stale", () {
      final inner = FakeSearchSource();
      final source = inner.cached();
      addTearDown(source.dispose);
      final snapshots = <SearchSourceSnapshot>[];
      final subscription = source.snapshots.listen(snapshots.add);
      addTearDown(subscription.cancel);
      final ready = SearchSourceSnapshot.ready(
        nodes: [
          SearchNode.result(
            result: searchResult("alpha").copyWith(isStale: true),
          ),
        ],
      );

      inner.emitSnapshot(ready);
      inner.emitSnapshot(SearchSourceSnapshot.loading());

      expect(resultStaleStates(snapshots.last), [true]);
    });

    test("cached actions are included during loading", () {
      final inner = FakeSearchSource();
      final source = inner.cached();
      addTearDown(source.dispose);
      final snapshots = <SearchSourceSnapshot>[];
      final subscription = source.snapshots.listen(snapshots.add);
      addTearDown(subscription.cancel);
      final action = TestSingleAction();
      final ready = readySnapshot(
        nodes: [
          resultNode("alpha", actions: [TestSingleAction]),
        ],
        actions: {TestSingleAction: action},
      );

      inner.emitSnapshot(ready);
      inner.emitSnapshot(SearchSourceSnapshot.loading(actions: const {}));

      expect(snapshots.last.actions, {TestSingleAction: action});
    });

    test("loading uses current guidance with cached nodes and actions", () {
      final inner = FakeSearchSource();
      final source = inner.cached();
      addTearDown(source.dispose);
      final snapshots = <SearchSourceSnapshot>[];
      final subscription = source.snapshots.listen(snapshots.add);
      addTearDown(subscription.cancel);
      const cachedGuidance = SearchGuidance(id: "ready", title: "Ready");
      const loadingGuidance = SearchGuidance(id: "loading", title: "Loading");
      final ready = SearchSourceSnapshot.ready(
        nodes: [resultNode("alpha")],
        guidance: const [cachedGuidance],
      );
      final loading = SearchSourceSnapshot.loading(
        guidance: const [loadingGuidance],
      );

      inner.emitSnapshot(ready);
      inner.emitSnapshot(loading);

      expect(snapshots.last.guidance, const [loadingGuidance]);
      expect(resultIds(snapshots.last), ["alpha"]);
    });

    test("error preserves current error summaries", () {
      final inner = FakeSearchSource();
      final source = inner.cached();
      addTearDown(source.dispose);
      final snapshots = <SearchSourceSnapshot>[];
      final subscription = source.snapshots.listen(snapshots.add);
      addTearDown(subscription.cancel);
      final ready = readySnapshot(nodes: [resultNode("alpha")]);
      final error = errorSnapshot("Network failed");

      inner.emitSnapshot(ready);
      inner.emitSnapshot(error);

      expect(snapshots.last.errorSummaries, error.errorSummaries);
    });

    test("error preserves current error guidance", () {
      final inner = FakeSearchSource();
      final source = inner.cached();
      addTearDown(source.dispose);
      final snapshots = <SearchSourceSnapshot>[];
      final subscription = source.snapshots.listen(snapshots.add);
      addTearDown(subscription.cancel);
      const errorGuidance = SearchGuidance(id: "retry", title: "Try again");
      final ready = readySnapshot(nodes: [resultNode("alpha")]);
      final error = errorSnapshot(
        "Network failed",
        guidance: const [errorGuidance],
      );

      inner.emitSnapshot(ready);
      inner.emitSnapshot(error);

      expect(snapshots.last.guidance, const [errorGuidance]);
    });
  });
}

SearchQueryContext queryContext(String query) {
  return SearchQueryContext(normalizedQuery: query, selectors: const []);
}

SearchSourceSnapshot errorSnapshot(
  String message, {
  List<SearchNode> nodes = const [],
  List<SearchGuidance> guidance = const [],
}) {
  return SearchSourceSnapshot.error(
    nodes: nodes,
    guidance: guidance,
    errorSummaries: [
      SearchErrorSummary(
        id: "error",
        message: message,
        severity: SearchErrorSeverity.error,
      ),
    ],
  );
}

List<String> resultIds(SearchSourceSnapshot snapshot) {
  return resultNodes(snapshot.nodes).map((node) => node.result.id).toList();
}

List<bool> resultStaleStates(SearchSourceSnapshot snapshot) {
  return resultNodes(
    snapshot.nodes,
  ).map((node) => node.result.isStale).toList();
}

List<SearchResultNode> resultNodes(List<SearchNode> nodes) {
  final results = <SearchResultNode>[];
  for (final node in nodes) {
    switch (node) {
      case SearchResultNode():
        results.add(node);
      case SearchSectionNode(:final children):
        results.addAll(resultNodes(children));
    }
  }
  return results;
}

final class TestSingleAction extends SingleSearchAction {
  @override
  String get label => "Test";

  @override
  int get priority => 0;

  @override
  Future<SearchActionResult> execute(SearchResult result) async {
    return SearchActionResult.completed();
  }
}
