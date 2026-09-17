// ignore_for_file: cascade_invocations

import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";

import "support/search_core_test_harness.dart";

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

    test("parses the initial query before initializing the source", () {
      final source = FakeSearchSource();
      final controller = SourceController(
        source: source,
        baseSelectors: baseSelectors,
        initialQuery: "hello #dart",
      );
      addTearDown(controller.dispose);

      expect(
        controller.queryContext,
        const SearchQueryContext(
          normalizedQuery: "hello",
          terms: ["hello"],
          selectors: [
            SearchParsedSelector(selectorId: "tag", key: "#", value: "dart"),
          ],
          selectorExpression: SearchSelectorExpression.leaf(
            SearchParsedSelector(selectorId: "tag", key: "#", value: "dart"),
          ),
        ),
      );
    });

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
      expect(source.searches.last.terms, ["hello"]);
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

    test("source selectors merge with base selectors", () {
      final source = FakeSearchSource(
        selectors: const [
          KeyValueSelectorDefinition(
            id: "status",
            key: "status:",
            value: QuerySelectorValue.enumValue(["open"]),
          ),
        ],
      );
      final controller = SourceController(
        source: source,
        baseSelectors: baseSelectors,
      );
      addTearDown(controller.dispose);

      expect(controller.selectors.map((s) => s.id), ["tag", "status"]);
      controller.updateQuery("status:open");
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
    });

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

    test("maps rejected source validation to the selector value", () {
      final source = FakeSearchSource(
        selectors: const [
          KeyValueSelectorDefinition(
            id: "book",
            key: "book:",
            value: QuerySelectorValue.sourceBacked(),
          ),
        ],
      );
      final controller = SourceController(
        source: source,
        baseSelectors: baseSelectors,
      );
      addTearDown(controller.dispose);
      controller.updateQuery("book:Missing");

      source.emitSnapshot(
        SearchSourceSnapshot.ready(
          nodes: const [],
          selectorValidations: const [
            SearchSelectorValidation(
              selectorId: "book",
              value: "missing",
              status: SearchSelectorValidationStatus.rejected,
            ),
          ],
        ),
      );

      expect(controller.validationIssues, hasLength(1));
      expect(
        controller.validationIssues.single.code,
        QueryIssueCode.invalidSelectorValue,
      );
      expect(controller.validationIssues.single.range, const QueryRange(5, 12));
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
