// ignore_for_file: cascade_invocations

import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/logic/search/search.dart";

import "../search_core_test_harness.dart";

void main() {
  group("DebouncedSearchSource", () {
    test("initializes the inner source once", () {
      final inner = FakeSearchSource();
      final source = inner.debounced(const Duration(milliseconds: 100));
      addTearDown(source.dispose);

      source.initialize();

      expect(inner.initializeCount, 1);
    });

    test("disposes the inner source once", () {
      final inner = FakeSearchSource();
      final source = inner.debounced(const Duration(milliseconds: 100));

      source.dispose();

      expect(inner.disposeCount, 1);
    });

    testWidgets("cancels pending search on dispose", (tester) async {
      final inner = FakeSearchSource();
      final source = inner.debounced(const Duration(milliseconds: 100));

      source.search(queryContext("alpha"));
      source.dispose();
      await tester.pump(const Duration(milliseconds: 100));

      expect(inner.searches, isEmpty);
    });

    test("does not forward search immediately", () {
      final inner = FakeSearchSource();
      final source = inner.debounced(const Duration(milliseconds: 100));
      addTearDown(source.dispose);

      source.search(queryContext("alpha"));

      expect(inner.searches, isEmpty);
    });

    testWidgets("forwards search after duration", (tester) async {
      final inner = FakeSearchSource();
      final source = inner.debounced(const Duration(milliseconds: 100));
      addTearDown(source.dispose);
      final context = queryContext("alpha");

      source.search(context);
      await tester.pump(const Duration(milliseconds: 99));
      expect(inner.searches, isEmpty);
      await tester.pump(const Duration(milliseconds: 1));

      expect(inner.searches, [context]);
    });

    testWidgets("coalesces multiple searches into the latest context", (
      tester,
    ) async {
      final inner = FakeSearchSource();
      final source = inner.debounced(const Duration(milliseconds: 100));
      addTearDown(source.dispose);
      final first = queryContext("alpha");
      final second = queryContext("beta");
      final third = queryContext("gamma");

      source.search(first);
      await tester.pump(const Duration(milliseconds: 40));
      source.search(second);
      await tester.pump(const Duration(milliseconds: 40));
      source.search(third);
      await tester.pump(const Duration(milliseconds: 100));

      expect(inner.searches, [third]);
    });

    testWidgets("starts a new debounce window after previous search fired", (
      tester,
    ) async {
      final inner = FakeSearchSource();
      final source = inner.debounced(const Duration(milliseconds: 100));
      addTearDown(source.dispose);
      final first = queryContext("alpha");
      final second = queryContext("beta");

      source.search(first);
      await tester.pump(const Duration(milliseconds: 100));
      source.search(second);
      await tester.pump(const Duration(milliseconds: 99));
      expect(inner.searches, [first]);
      await tester.pump(const Duration(milliseconds: 1));

      expect(inner.searches, [first, second]);
    });

    testWidgets("allows the same context after debounce window", (
      tester,
    ) async {
      final inner = FakeSearchSource();
      final source = inner.debounced(const Duration(milliseconds: 100));
      addTearDown(source.dispose);
      final context = queryContext("alpha");

      source.search(context);
      await tester.pump(const Duration(milliseconds: 100));
      source.search(context);
      await tester.pump(const Duration(milliseconds: 100));

      expect(inner.searches, [context, context]);
    });

    test("forwards snapshots from the inner source", () {
      final inner = FakeSearchSource();
      final source = inner.debounced(const Duration(milliseconds: 100));
      addTearDown(source.dispose);
      final snapshots = <SearchSourceSnapshot>[];
      final subscription = source.snapshots.listen(snapshots.add);
      addTearDown(subscription.cancel);
      final snapshot = readySnapshot(nodes: [resultNode("alpha")]);

      inner.emitSnapshot(snapshot);

      expect(snapshots, [snapshot]);
    });

    test("forwards selectors from the inner source", () {
      final inner = FakeSearchSource();
      final source = inner.debounced(const Duration(milliseconds: 100));
      addTearDown(source.dispose);
      final selectors = <List<QuerySelectorDefinition>>[];
      final subscription = source.selectors.listen(selectors.add);
      addTearDown(subscription.cancel);
      const emitted = [KeyValueSelectorDefinition(id: "tag", key: "#")];

      inner.emitSelectors(emitted);

      expect(selectors, [emitted]);
    });

    test("forwards preview requests", () async {
      final inner = FakeSearchSource();
      final source = inner.debounced(const Duration(milliseconds: 100));
      addTearDown(source.dispose);
      const request = SearchPreviewRequest(resultId: "alpha");

      final result = await source.preview(request);

      expect(result, inner.previewResult);
      expect(inner.previewRequests, [request]);
    });
  });
}

SearchQueryContext queryContext(String query) {
  return SearchQueryContext(normalizedQuery: query, selectors: const []);
}
