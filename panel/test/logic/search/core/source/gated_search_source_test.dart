// ignore_for_file: cascade_invocations

import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/logic/search/search.dart";

import "../search_core_test_harness.dart";

void main() {
  group("GatedSearchSource", () {
    test("initializes the inner source once", () {
      final inner = FakeSearchSource();
      final source = inner.gated((context) => true);
      addTearDown(source.dispose);

      source.initialize();

      expect(inner.initializeCount, 1);
    });

    test("disposes the inner source once", () {
      final inner = FakeSearchSource();
      final source = inner.gated((context) => true);

      source.dispose();

      expect(inner.disposeCount, 1);
    });

    test("forwards selectors while open or closed", () {
      final inner = FakeSearchSource();
      final source = inner.gated((context) => false);
      addTearDown(source.dispose);
      final selectors = <List<QuerySelectorDefinition>>[];
      final subscription = source.selectors.listen(selectors.add);
      addTearDown(subscription.cancel);
      const emitted = [KeyValueSelectorDefinition(id: "tag", key: "#")];

      source.search(queryContext("alpha"));
      inner.emitSelectors(emitted);

      expect(selectors, [emitted]);
    });

    test("open gate forwards search with same context", () {
      final inner = FakeSearchSource();
      final source = inner.gated((context) => true);
      addTearDown(source.dispose);
      final context = queryContext("alpha");

      source.search(context);

      expect(inner.searches, [context]);
    });

    test("open gate forwards inner snapshots", () {
      final inner = FakeSearchSource();
      final source = inner.gated((context) => true);
      addTearDown(source.dispose);
      final snapshots = <SearchSourceSnapshot>[];
      final subscription = source.snapshots.listen(snapshots.add);
      addTearDown(subscription.cancel);
      final snapshot = readySnapshot(nodes: [resultNode("alpha")]);

      source.search(queryContext("alpha"));
      inner.emitSnapshot(snapshot);

      expect(snapshots, [snapshot]);
    });

    test("open gate forwards preview requests", () async {
      final inner = FakeSearchSource();
      final source = inner.gated((context) => true);
      addTearDown(source.dispose);
      final request = SearchPreviewRequest(
        resultId: "alpha",
        queryContext: queryContext("alpha"),
      );

      final result = await source.preview(request);

      expect(result, inner.previewResult);
      expect(inner.previewRequests, [request]);
    });

    test("closed gate returns preview error without calling inner", () async {
      final inner = FakeSearchSource();
      final source = inner.gated((context) => false);
      addTearDown(source.dispose);
      final request = SearchPreviewRequest(
        resultId: "alpha",
        queryContext: queryContext("alpha"),
      );

      final result = await source.preview(request);

      expect(
        result,
        const SearchPreviewRequestResult.error(
          message: "Preview unavailable while search gate is closed",
        ),
      );
      expect(inner.previewRequests, isEmpty);
    });

    test("missing preview queryContext returns gate error", () async {
      final inner = FakeSearchSource();
      final source = inner.gated((context) => true);
      addTearDown(source.dispose);

      final result = await source.preview(
        const SearchPreviewRequest(resultId: "alpha"),
      );

      expect(
        result,
        const SearchPreviewRequestResult.error(
          message: "Preview unavailable while search gate is closed",
        ),
      );
      expect(inner.previewRequests, isEmpty);
    });

    test("closed gate blocks search", () {
      final inner = FakeSearchSource();
      final source = inner.gated((context) => false);
      addTearDown(source.dispose);

      source.search(queryContext("alpha"));

      expect(inner.searches, isEmpty);
    });

    test("closed gate emits empty idle snapshot", () {
      final inner = FakeSearchSource();
      final source = inner.gated((context) => false);
      addTearDown(source.dispose);
      final snapshots = <SearchSourceSnapshot>[];
      final subscription = source.snapshots.listen(snapshots.add);
      addTearDown(subscription.cancel);

      source.search(queryContext("alpha"));

      expect(snapshots, hasLength(1));
      expect(snapshots.single.status, SearchSourceStatus.idle);
      expect(snapshots.single.nodes, isEmpty);
      expect(snapshots.single.errorSummaries, isEmpty);
    });

    test("closed gate without guidance emits no guidance", () {
      final inner = FakeSearchSource();
      final source = inner.gated((context) => false);
      addTearDown(source.dispose);
      final snapshots = <SearchSourceSnapshot>[];
      final subscription = source.snapshots.listen(snapshots.add);
      addTearDown(subscription.cancel);

      source.search(queryContext("alpha"));

      expect(snapshots.single.guidance, isEmpty);
    });

    test("closed gate with guidance function emits returned guidance", () {
      final inner = FakeSearchSource();
      final guidance = SearchGuidance(
        id: "disabled",
        title: "Search disabled",
        description: "Choose realm first",
        visibility: SearchGuidanceVisibility.always,
      );
      final source = inner.gated(
        (context) => false,
        closedGuidance: (context) => guidance,
      );
      addTearDown(source.dispose);
      final snapshots = <SearchSourceSnapshot>[];
      final subscription = source.snapshots.listen(snapshots.add);
      addTearDown(subscription.cancel);

      source.search(queryContext("alpha"));

      expect(snapshots.single.guidance, [guidance]);
    });

    test("guidance function receives same blocked context", () {
      final inner = FakeSearchSource();
      final blockedContexts = <SearchQueryContext>[];
      final source = inner.gated(
        (context) => false,
        closedGuidance: (context) {
          blockedContexts.add(context);
          return null;
        },
      );
      addTearDown(source.dispose);
      final context = queryContext("alpha");

      source.search(context);

      expect(blockedContexts, [context]);
    });

    test("closed gate ignores later inner ready snapshot", () {
      final inner = FakeSearchSource();
      final source = inner.gated((context) => false);
      addTearDown(source.dispose);
      final snapshots = <SearchSourceSnapshot>[];
      final subscription = source.snapshots.listen(snapshots.add);
      addTearDown(subscription.cancel);
      final ready = readySnapshot(nodes: [resultNode("alpha")]);

      source.search(queryContext("alpha"));
      inner.emitSnapshot(ready);

      expect(snapshots, hasLength(1));
      expect(snapshots.single.nodes, isEmpty);
    });

    test("closed gate ignores later inner loading snapshot", () {
      final inner = FakeSearchSource();
      final source = inner.gated((context) => false);
      addTearDown(source.dispose);
      final snapshots = <SearchSourceSnapshot>[];
      final subscription = source.snapshots.listen(snapshots.add);
      addTearDown(subscription.cancel);

      source.search(queryContext("alpha"));
      inner.emitSnapshot(SearchSourceSnapshot.loading());

      expect(snapshots, hasLength(1));
      expect(snapshots.single.status, SearchSourceStatus.idle);
    });

    test("closed gate ignores later inner error snapshot", () {
      final inner = FakeSearchSource();
      final source = inner.gated((context) => false);
      addTearDown(source.dispose);
      final snapshots = <SearchSourceSnapshot>[];
      final subscription = source.snapshots.listen(snapshots.add);
      addTearDown(subscription.cancel);

      source.search(queryContext("alpha"));
      inner.emitSnapshot(errorSnapshot("Network failed"));

      expect(snapshots, hasLength(1));
      expect(snapshots.single.errorSummaries, isEmpty);
    });

    test("closed then open forwards next search", () {
      final inner = FakeSearchSource();
      var open = false;
      final source = inner.gated((context) => open);
      addTearDown(source.dispose);
      final blocked = queryContext("alpha");
      final allowed = queryContext("beta");

      source.search(blocked);
      open = true;
      source.search(allowed);

      expect(inner.searches, [allowed]);
    });

    test("closed then open forwards new inner snapshots", () {
      final inner = FakeSearchSource();
      var open = false;
      final source = inner.gated((context) => open);
      addTearDown(source.dispose);
      final snapshots = <SearchSourceSnapshot>[];
      final subscription = source.snapshots.listen(snapshots.add);
      addTearDown(subscription.cancel);
      final ready = readySnapshot(nodes: [resultNode("alpha")]);

      source.search(queryContext("alpha"));
      open = true;
      source.search(queryContext("alpha"));
      inner.emitSnapshot(ready);

      expect(snapshots, hasLength(2));
      expect(snapshots.first.status, SearchSourceStatus.idle);
      expect(snapshots.last, ready);
    });

    test("open then closed clears previous visible results", () {
      final inner = FakeSearchSource();
      var open = true;
      final source = inner.gated((context) => open);
      addTearDown(source.dispose);
      final snapshots = <SearchSourceSnapshot>[];
      final subscription = source.snapshots.listen(snapshots.add);
      addTearDown(subscription.cancel);
      final ready = readySnapshot(nodes: [resultNode("alpha")]);

      source.search(queryContext("alpha"));
      inner.emitSnapshot(ready);
      open = false;
      source.search(queryContext("beta"));

      expect(snapshots, hasLength(2));
      expect(snapshots.first, ready);
      expect(snapshots.last.status, SearchSourceStatus.idle);
      expect(snapshots.last.nodes, isEmpty);
    });

    test("predicate can depend on normalized query", () {
      final inner = FakeSearchSource();
      final source = inner.gated(
        (context) => context.normalizedQuery.length >= 3,
      );
      addTearDown(source.dispose);
      final short = queryContext("ab");
      final long = queryContext("abc");

      source.search(short);
      source.search(long);

      expect(inner.searches, [long]);
    });

    test("predicate can depend on parsed selectors", () {
      final inner = FakeSearchSource();
      final source = inner.gated(
        (context) => context.selectors.any((s) => s.selectorId == "realm"),
      );
      addTearDown(source.dispose);
      final withoutRealm = queryContext("alpha");
      final withRealm = queryContext(
        "alpha",
        selectors: const [
          SearchParsedSelector(
            selectorId: "realm",
            key: "realm:",
            value: "main",
          ),
        ],
      );

      source.search(withoutRealm);
      source.search(withRealm);

      expect(inner.searches, [withRealm]);
    });

    test("guidance can depend on parsed selectors", () {
      final inner = FakeSearchSource();
      final source = inner.gated(
        (context) => false,
        closedGuidance: (context) {
          final hasRealm = context.selectors.any(
            (s) => s.selectorId == "realm",
          );
          return SearchGuidance(
            id: hasRealm ? "disabled" : "missing-realm",
            title: hasRealm ? "Search disabled" : "Choose realm first",
          );
        },
      );
      addTearDown(source.dispose);
      final snapshots = <SearchSourceSnapshot>[];
      final subscription = source.snapshots.listen(snapshots.add);
      addTearDown(subscription.cancel);

      source.search(queryContext("alpha"));

      expect(snapshots.single.guidance.single.id, "missing-realm");
      expect(snapshots.single.guidance.single.title, "Choose realm first");
    });
  });
}

SearchQueryContext queryContext(
  String query, {
  List<SearchParsedSelector> selectors = const [],
}) {
  return SearchQueryContext(normalizedQuery: query, selectors: selectors);
}

SearchSourceSnapshot errorSnapshot(String message) {
  return SearchSourceSnapshot.error(
    errorSummaries: [
      SearchErrorSummary(
        id: "error",
        message: message,
        severity: SearchErrorSeverity.error,
      ),
    ],
  );
}
