// ignore_for_file: cascade_invocations

import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/logic/search/search.dart";

import "search_core_test_harness.dart";

void main() {
  const baseSelectors = [KeyValueSelectorDefinition(id: "tag", key: "#")];

  group("SourceController", () {
    test(
      "initializes source and exposes initial idle snapshot and base selectors",
      () {
        final source = FakeSearchSource();
        final controller = SourceController(
          source: source,
          baseSelectors: baseSelectors,
        );
        addTearDown(controller.dispose);

        expect(source.initializeCount, 1);
        expect(controller.snapshot.status, SearchSourceStatus.idle);
        expect(controller.selectors, baseSelectors);
      },
    );

    test("snapshot stream updates snapshot and notifies listeners", () {
      final source = FakeSearchSource();
      final controller = SourceController(
        source: source,
        baseSelectors: baseSelectors,
      );
      addTearDown(controller.dispose);
      final notifications = recordNotifications(controller);
      addTearDown(notifications.dispose);

      final snapshot = readySnapshot(nodes: [resultNode("a")]);
      source.emitSnapshot(snapshot);

      expect(controller.snapshot, snapshot);
      expect(notifications.count, 1);
    });

    test("updateQuery parses text and selectors into the searched context", () {
      final source = FakeSearchSource();
      final controller = SourceController(
        source: source,
        baseSelectors: baseSelectors,
      );
      addTearDown(controller.dispose);

      controller.updateQuery("hello #dart");

      source.expectLastSearchContext(
        normalizedQuery: "hello",
        selectors: const [
          SearchParsedSelector(selectorId: "tag", key: "#", value: "dart"),
        ],
      );
    });

    test("equivalent parsed query does not trigger duplicate searches", () {
      final source = FakeSearchSource();
      final controller = SourceController(
        source: source,
        baseSelectors: baseSelectors,
      );
      addTearDown(controller.dispose);

      controller.updateQuery("hello #dart");
      controller.updateQuery("hello #dart");

      expect(source.searches, hasLength(1));
    });

    test(
      "dynamic selectors merge with base selectors and re-run last raw query",
      () {
        final source = FakeSearchSource();
        final controller = SourceController(
          source: source,
          baseSelectors: baseSelectors,
        );
        addTearDown(controller.dispose);

        controller.updateQuery("status:open");
        expect(source.searches.single.normalizedQuery, "status:open");

        source.emitSelectors(const [
          KeyValueSelectorDefinition(
            id: "status",
            key: "status:",
            value: QuerySelectorValue.enumValue(["open"]),
          ),
        ]);

        expect(controller.selectors.map((s) => s.id), ["tag", "status"]);
        source.expectLastSearchContext(
          normalizedQuery: "",
          selectors: const [
            SearchParsedSelector(
              selectorId: "status",
              key: "status:",
              value: "open",
            ),
          ],
        );
      },
    );

    test("triggerQuery repeats the last searched context", () {
      final source = FakeSearchSource();
      final controller = SourceController(
        source: source,
        baseSelectors: baseSelectors,
      );
      addTearDown(controller.dispose);

      controller.updateQuery("hello #dart");
      controller.triggerQuery();

      expect(source.searches, hasLength(2));
      expect(source.searches.last, source.searches.first);
    });

    test("dispose disposes the source", () {
      final source = FakeSearchSource();
      final controller = SourceController(
        source: source,
        baseSelectors: baseSelectors,
      );

      controller.dispose();

      expect(source.disposeCount, 1);
    });
  });
}
