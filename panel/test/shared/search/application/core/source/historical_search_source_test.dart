// ignore_for_file: cascade_invocations

import "dart:async";

import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";

import "../support/search_core_test_harness.dart";

void main() {
  group("HistoricalSearchSource", () {
    test("shows validated persisted results for an empty query", () async {
      final inner = FakeSearchSource();
      final selections = StreamController<SearchResult>.broadcast(sync: true);
      final storage = FakeHistoryStorage([
        searchResult("recent"),
        "invalid",
        searchResult("older"),
      ]);
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

      source.initialize();
      await flushEvents();
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
      final harness = HistoryHarness(capacity: 2);
      addTearDown(harness.dispose);
      harness.source.initialize();
      await flushEvents();
      harness.source.search(queryContext("query"));
      final one = searchResult("one");
      final two = searchResult("two");
      final three = searchResult("three");
      harness.inner.emitSnapshot(
        readySnapshot(
          nodes: [
            SearchNode.result(result: one),
            SearchNode.result(result: two),
            SearchNode.result(result: three),
          ],
        ),
      );

      harness.selections.add(one);
      harness.selections.add(two);
      harness.selections.add(three);
      harness.selections.add(two);
      await flushEvents();

      expect(harness.storage.storedIds, ["two", "three"]);
      expect(harness.storage.replaceCount, 4);
    });

    test("ignores committed results that do not belong to its child", () async {
      final harness = HistoryHarness();
      addTearDown(harness.dispose);
      harness.source.initialize();
      await flushEvents();
      harness.source.search(queryContext("query"));
      harness.inner.emitSnapshot(readySnapshot(nodes: [resultNode("owned")]));

      harness.selections.add(searchResult("foreign"));
      await flushEvents();

      expect(harness.storage.replaceCount, 0);
    });

    test("merges selections committed while storage is loading", () async {
      final load = Completer<List<SearchResult>>();
      final storage = ControlledHistoryStorage(load.future);
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
      source.initialize();
      source.search(queryContext("query"));
      final selected = searchResult("selected");
      inner.emitSnapshot(
        readySnapshot(nodes: [SearchNode.result(result: selected)]),
      );
      selections.add(selected);

      load.complete([searchResult("stored")]);
      await flushEvents();

      expect(storage.storedIds, ["selected", "stored"]);
    });

    test("shows history outside a closed gate", () async {
      final inner = FakeSearchSource();
      final gated = inner.gated((context) => false);
      final selections = StreamController<SearchResult>.broadcast(sync: true);
      final storage = FakeHistoryStorage([searchResult("recent")]);
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
      source.initialize();
      await flushEvents();

      source.search(queryContext(""));

      expect(resultIds(snapshots.last), ["recent"]);
      expect(snapshots.last.status, SearchSourceStatus.ready);
      expect(inner.searches, isEmpty);
    });

    test("disposal cancels loading and selection events", () async {
      final load = Completer<List<SearchResult>>();
      final storage = ControlledHistoryStorage(load.future);
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
      source.initialize();

      source.dispose();
      source.dispose();
      load.complete([searchResult("late")]);
      selections.add(searchResult("late"));
      await flushEvents();

      expect(snapshots, isEmpty);
      expect(storage.replaceCount, 0);
      expect(inner.disposeCount, 1);
    });
  });
}

final class HistoryHarness {
  HistoryHarness({this.capacity = 5}) : storage = FakeHistoryStorage(const []) {
    source = inner.withHistory(
      key: "test",
      label: "Recent",
      capacity: capacity,
      storage: storage,
      committedSelections: selections.stream,
    );
  }

  final int capacity;
  final inner = FakeSearchSource();
  final selections = StreamController<SearchResult>.broadcast(sync: true);
  final FakeHistoryStorage storage;
  late final SearchSource source;

  void dispose() {
    source.dispose();
    unawaited(selections.close());
  }
}

class FakeHistoryStorage implements SearchHistoryStorage {
  FakeHistoryStorage(this.rawResults);

  final List<Object> rawResults;
  final loadKeys = <String>[];
  List<SearchResult> stored = const [];
  int replaceCount = 0;

  List<String> get storedIds => stored.map((result) => result.id).toList();

  @override
  Future<List<SearchResult>> loadValidResults({
    required String key,
    required int capacity,
  }) async {
    loadKeys.add(key);
    return rawResults.whereType<SearchResult>().take(capacity).toList();
  }

  @override
  Future<void> replaceResults({
    required String key,
    required List<SearchResult> results,
  }) async {
    replaceCount++;
    stored = results;
  }
}

final class ControlledHistoryStorage extends FakeHistoryStorage {
  ControlledHistoryStorage(this.load) : super(const []);

  final Future<List<SearchResult>> load;

  @override
  Future<List<SearchResult>> loadValidResults({
    required String key,
    required int capacity,
  }) => load;
}

SearchQueryContext queryContext(String query) {
  return SearchQueryContext(normalizedQuery: query, selectors: const []);
}

List<String> resultIds(SearchSourceSnapshot snapshot) {
  return snapshot.nodes
      .walk()
      .whereType<SearchResultNode>()
      .map((node) => node.result.id)
      .toList();
}

Future<void> flushEvents() => Future<void>.delayed(Duration.zero);
