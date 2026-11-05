// ignore_for_file: cascade_invocations

import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  group("HistoricalSearchSource", () {
    test("shows persisted results for an empty query", () async {
      final inner = FakeSearchSource();
      final selections = StreamController<SearchResult>.broadcast(sync: true);
      final storage = MemorySearchHistory(
        results: [searchResult("recent"), searchResult("older")],
      );
      final source = inner.withHistory(
        key: "icons",
        label: "Recent",
        capacity: 10,
        storage: storage,
        committedSelections: selections.stream,
      );
      addTearDown(source.dispose);
      addTearDown(selections.close);

      final snapshots = <SearchSourceSnapshot>[];
      final subscription = source.snapshots.listen(snapshots.add);
      addTearDown(subscription.cancel);

      source.initialize(SearchQueryContext.empty);
      await pumpEventQueue();
      source.search(queryContext(""));
      inner.emitSnapshot(SearchSourceSnapshot.idle());

      expect(resultIds(snapshots.last), ["recent", "older"]);
      final section = snapshots.last.nodes.single as SearchSectionNode;
      expect(section.id, "history:icons");
      expect(section.title, "Recent");
      expect(snapshots.last.status, SearchSourceStatus.ready);
      expect(storage.loadKeys, ["icons"]);
    });

    test("records committed child results with newest first", () async {
      final inner = FakeSearchSource();
      final selections = StreamController<SearchResult>.broadcast(sync: true);
      final storage = MemorySearchHistory();
      final source = inner.withHistory(
        key: "test",
        label: "Recent",
        capacity: 2,
        storage: storage,
        committedSelections: selections.stream,
      );
      addTearDown(source.dispose);
      addTearDown(selections.close);
      source.initialize(SearchQueryContext.empty);
      await pumpEventQueue();
      source.search(queryContext("query"));
      final one = searchResult("one");

      final two = searchResult("two");
      final three = searchResult("three");
      inner.emitSnapshot(
        readySnapshot(
          nodes: [
            SearchNode.result(result: one),
            SearchNode.result(result: two),
            SearchNode.result(result: three),
          ],
        ),
      );

      selections.add(one);
      selections.add(two);
      selections.add(three);
      selections.add(two);
      await pumpEventQueue();

      expect(storage.resultIds, ["two", "three"]);
    });

    test("ignores committed results that do not belong to its child", () async {
      final inner = FakeSearchSource();
      final selections = StreamController<SearchResult>.broadcast(sync: true);
      final storage = MemorySearchHistory();
      final source = inner.withHistory(
        key: "test",
        label: "Recent",
        capacity: 5,
        storage: storage,
        committedSelections: selections.stream,
      );
      addTearDown(source.dispose);
      addTearDown(selections.close);
      source.initialize(SearchQueryContext.empty);
      await pumpEventQueue();
      source.search(queryContext("query"));
      inner.emitSnapshot(readySnapshot(nodes: [resultNode("owned")]));

      selections.add(searchResult("foreign"));
      await pumpEventQueue();

      expect(storage.writes, 0);
    });

    test("merges selections committed while storage is loading", () async {
      final load = Completer<List<SearchResult>>();
      final storage = MemorySearchHistory(pendingLoad: load.future);
      final inner = FakeSearchSource();
      final selections = StreamController<SearchResult>.broadcast(sync: true);
      final source = inner.withHistory(
        key: "players",
        label: "Recent players",
        capacity: 3,
        storage: storage,
        committedSelections: selections.stream,
      );
      addTearDown(source.dispose);

      addTearDown(selections.close);
      source.initialize(SearchQueryContext.empty);
      source.search(queryContext("query"));
      final selected = searchResult("selected");
      inner.emitSnapshot(
        readySnapshot(nodes: [SearchNode.result(result: selected)]),
      );
      selections.add(selected);

      load.complete([searchResult("stored")]);
      await pumpEventQueue();

      expect(storage.resultIds, ["selected", "stored"]);
    });

    test("shows history outside a closed gate", () async {
      final inner = FakeSearchSource();
      final gated = inner.gated((context) => false);
      final selections = StreamController<SearchResult>.broadcast(sync: true);
      final storage = MemorySearchHistory(results: [searchResult("recent")]);
      final source = gated.withHistory(
        key: "icons",
        label: "Recent",
        capacity: 5,
        storage: storage,
        committedSelections: selections.stream,
      );
      addTearDown(source.dispose);

      addTearDown(selections.close);
      final snapshots = <SearchSourceSnapshot>[];
      final subscription = source.snapshots.listen(snapshots.add);
      addTearDown(subscription.cancel);
      source.initialize(SearchQueryContext.empty);
      await pumpEventQueue();

      source.search(queryContext(""));

      expect(resultIds(snapshots.last), ["recent"]);
      expect(snapshots.last.status, SearchSourceStatus.ready);
      expect(inner.searches, isEmpty);
    });

    test("disposal cancels loading and selection events", () async {
      final load = Completer<List<SearchResult>>();
      final storage = MemorySearchHistory(pendingLoad: load.future);
      final inner = FakeSearchSource();
      final selections = StreamController<SearchResult>.broadcast(sync: true);
      final source = inner.withHistory(
        key: "effects",
        label: "Recent",
        capacity: 5,
        storage: storage,
        committedSelections: selections.stream,
      );
      final snapshots = <SearchSourceSnapshot>[];

      final subscription = source.snapshots.listen(snapshots.add);
      addTearDown(subscription.cancel);
      addTearDown(selections.close);
      source.initialize(SearchQueryContext.empty);

      source.dispose();
      source.dispose();
      load.complete([searchResult("late")]);
      selections.add(searchResult("late"));
      await pumpEventQueue();

      expect(snapshots, isEmpty);
      expect(storage.writes, 0);
      expect(inner.disposeCount, 1);
    });
  });
}
