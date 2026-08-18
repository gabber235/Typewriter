// ignore_for_file: cascade_invocations

import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";

import "../support/search_core_test_harness.dart";

void main() {
  group("ranked", () {
    test("scores each fuzzy match category in priority order", () {
      final scores = [
        scoreFuzzySearchMatch("home", "home"),
        scoreFuzzySearchMatch("home", "homepage"),
        scoreFuzzySearchMatch("home", "large home icon"),
        scoreFuzzySearchMatch("home", "myhomeicon"),
        scoreFuzzySearchMatch("mhi", "my home icon"),
        scoreFuzzySearchMatch("hme", "home"),
        scoreFuzzySearchMatch("homr", "home"),
      ];

      for (var index = 1; index < scores.length; index++) {
        expect(scores[index - 1], greaterThan(scores[index]));
      }
    });

    test("orders fuzzy matches by quality and preserves ties", () {
      final inner = FakeSearchSource();
      final source = inner.ranked([
        SearchRankField(text: (result) => result.title, weight: 100),
      ]);
      addTearDown(source.dispose);
      final snapshots = <SearchSourceSnapshot>[];
      final subscription = source.snapshots.listen(snapshots.add);
      addTearDown(subscription.cancel);

      source.search(queryContext("home"));
      inner.emitSnapshot(
        readySnapshot(
          nodes: [
            resultNode("substring", title: "my home icon"),
            resultNode("prefix", title: "homepage"),
            resultNode("exact", title: "home"),
            resultNode("tie one", title: "home"),
            resultNode("tie two", title: "home"),
            resultNode("missing", title: "unrelated"),
          ],
        ),
      );

      expect(resultIds(snapshots.single), [
        "exact",
        "tie one",
        "tie two",
        "prefix",
        "substring",
      ]);
    });

    test("weights can make a secondary exact match win", () {
      final inner = FakeSearchSource();
      final source = inner.ranked([
        SearchRankField(text: (result) => result.title, weight: 1),
        SearchRankField(text: (result) => result.subtitle, weight: 10),
      ]);
      addTearDown(source.dispose);
      final snapshots = <SearchSourceSnapshot>[];
      final subscription = source.snapshots.listen(snapshots.add);
      addTearDown(subscription.cancel);

      source.search(queryContext("sword"));
      inner.emitSnapshot(
        readySnapshot(
          nodes: [
            resultNodeWithSubtitle("title", "sword", "equipment"),
            resultNodeWithSubtitle("subtitle", "equipment", "sword"),
          ],
        ),
      );

      expect(resultIds(snapshots.single), ["subtitle", "title"]);
    });

    test("recursively removes empty sections", () {
      final inner = FakeSearchSource();
      final source = inner.ranked([
        SearchRankField(text: (result) => result.title, weight: 1),
      ]);
      addTearDown(source.dispose);
      final snapshots = <SearchSourceSnapshot>[];
      final subscription = source.snapshots.listen(snapshots.add);
      addTearDown(subscription.cancel);

      source.search(queryContext("home"));
      inner.emitSnapshot(
        readySnapshot(
          nodes: [
            sectionNode("empty", [resultNode("sword")]),
            sectionNode("matching", [resultNode("home")]),
          ],
        ),
      );

      expect(snapshots.single.nodes, hasLength(1));
      expect(
        (snapshots.single.nodes.single as SearchSectionNode).id,
        "matching",
      );
    });

    test("extracts every configured field once per result", () {
      final inner = FakeSearchSource();
      var extractionCount = 0;
      final source = inner.ranked([
        SearchRankField(
          text: (result) {
            extractionCount++;
            return result.title;
          },
          weight: 1,
        ),
      ]);
      addTearDown(source.dispose);
      final subscription = source.snapshots.listen((snapshot) {});
      addTearDown(subscription.cancel);

      source.search(queryContext("home"));
      inner.emitSnapshot(
        readySnapshot(
          nodes: [
            sectionNode("nested", [resultNode("home")]),
            resultNode("homepage"),
          ],
        ),
      );

      expect(extractionCount, 2);
    });
  });

  group("limited", () {
    test("limits depth first and removes empty sections", () {
      final inner = FakeSearchSource();
      final source = inner.limited(2);
      addTearDown(source.dispose);
      final snapshots = <SearchSourceSnapshot>[];
      final subscription = source.snapshots.listen(snapshots.add);
      addTearDown(subscription.cancel);

      inner.emitSnapshot(
        readySnapshot(
          nodes: [
            sectionNode("first", [resultNode("one"), resultNode("two")]),
            sectionNode("second", [resultNode("three")]),
          ],
        ),
      );

      expect(resultIds(snapshots.single), ["one", "two"]);
      expect(snapshots.single.nodes, hasLength(1));
    });
  });

  group("distinct", () {
    test("keeps first duplicate across sections", () {
      final inner = FakeSearchSource();
      final source = inner.distinct();
      addTearDown(source.dispose);
      final snapshots = <SearchSourceSnapshot>[];
      final subscription = source.snapshots.listen(snapshots.add);
      addTearDown(subscription.cancel);

      inner.emitSnapshot(
        readySnapshot(
          nodes: [
            sectionNode("first", [resultNode("same")]),
            sectionNode("second", [resultNode("same"), resultNode("unique")]),
          ],
        ),
      );

      expect(resultIds(snapshots.single), ["same", "unique"]);
      final second = snapshots.single.nodes.last as SearchSectionNode;
      expect(second.children, hasLength(1));
    });
  });

  group("section", () {
    test("wraps nonempty snapshots and preserves empty snapshots", () {
      final inner = FakeSearchSource();
      final source = inner.inSection(id: "icons", title: "Icons");
      addTearDown(source.dispose);
      final snapshots = <SearchSourceSnapshot>[];
      final subscription = source.snapshots.listen(snapshots.add);
      addTearDown(subscription.cancel);

      inner.emitSnapshot(readySnapshot(nodes: [resultNode("home")]));
      inner.emitSnapshot(readySnapshot(nodes: const []));

      final section = snapshots.first.nodes.single as SearchSectionNode;
      expect(section.id, "icons");
      expect(section.title, "Icons");
      expect(resultIds(snapshots.first), ["home"]);
      expect(snapshots.last.nodes, isEmpty);
    });
  });

  test("rank before limit differs from limit before rank", () {
    final firstInner = FakeSearchSource();
    final secondInner = FakeSearchSource();
    final fields = [SearchRankField(text: (result) => result.title, weight: 1)];
    final rankThenLimit = firstInner.ranked(fields).limited(1);
    final limitThenRank = secondInner.limited(1).ranked(fields);
    addTearDown(rankThenLimit.dispose);
    addTearDown(limitThenRank.dispose);
    final rankedSnapshots = <SearchSourceSnapshot>[];
    final limitedSnapshots = <SearchSourceSnapshot>[];
    final firstSubscription = rankThenLimit.snapshots.listen(
      rankedSnapshots.add,
    );
    final secondSubscription = limitThenRank.snapshots.listen(
      limitedSnapshots.add,
    );
    addTearDown(firstSubscription.cancel);
    addTearDown(secondSubscription.cancel);

    rankThenLimit.search(queryContext("home"));
    limitThenRank.search(queryContext("home"));
    final snapshot = readySnapshot(
      nodes: [
        resultNode("weak", title: "my home icon"),
        resultNode("exact", title: "home"),
      ],
    );
    firstInner.emitSnapshot(snapshot);
    secondInner.emitSnapshot(snapshot);

    expect(resultIds(rankedSnapshots.single), ["exact"]);
    expect(resultIds(limitedSnapshots.single), ["weak"]);
  });
}

SearchQueryContext queryContext(String query) {
  return SearchQueryContext(normalizedQuery: query, selectors: const []);
}

SearchNode resultNodeWithSubtitle(String id, String title, String subtitle) {
  return SearchNode.result(
    result: searchResult(id, title: title).copyWith(subtitle: subtitle),
  );
}

List<String> resultIds(SearchSourceSnapshot snapshot) {
  return snapshot.nodes
      .walk()
      .whereType<SearchResultNode>()
      .map((node) => node.result.id)
      .toList();
}
