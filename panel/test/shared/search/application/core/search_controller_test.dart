// ignore_for_file: cascade_invocations

import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";

import "support/search_core_test_harness.dart";

void main() {
  const selectors = [KeyValueSelectorDefinition(id: "tag", key: "#")];

  group("SearchController", () {
    test(
      "selection and section collapse toggles notify and expose immutable lists",
      () {
        final source = FakeSearchSource();
        final controller = SearchController(
          source: source,
          baseSelectors: selectors,
        );
        addTearDown(controller.dispose);
        final notifications = recordNotifications(controller);
        addTearDown(notifications.dispose);

        controller.toggleSelected("a", isMultiSelect: false);
        controller.toggleSection("section");

        expect(controller.isSelected("a"), isTrue);
        expect(controller.selectedIds, ["a"]);
        expect(() => controller.selectedIds.add("b"), throwsUnsupportedError);
        expect(controller.isCollapsed("section"), isTrue);
        expect(controller.collapsedSectionIds, ["section"]);
        expect(
          () => controller.collapsedSectionIds.add("other"),
          throwsUnsupportedError,
        );
        expect(notifications.count, 2);
      },
    );

    test(
      "cleans selected ids when snapshots remove results, including nested sections",
      () {
        final source = FakeSearchSource();
        final controller = SearchController(
          source: source,
          baseSelectors: selectors,
        );
        addTearDown(controller.dispose);

        source.emitSnapshot(
          readySnapshot(
            nodes: [
              sectionNode("section", [
                resultNode("a"),
                sectionNode("nested", [resultNode("b")]),
              ]),
            ],
          ),
        );
        controller.toggleSelected("a", isMultiSelect: false);
        controller.toggleSelected("b", isMultiSelect: false);

        source.emitSnapshot(
          readySnapshot(
            nodes: [
              sectionNode("section", [
                sectionNode("nested", [resultNode("b")]),
              ]),
            ],
          ),
        );

        expect(controller.selectedIds, ["b"]);
      },
    );

    test("queues query updates while an action is running", () async {
      final source = FakeSearchSource();
      final action = TestSingleAction();
      final controller = SearchController(
        source: source,
        baseSelectors: selectors,
      );
      addTearDown(controller.dispose);
      source.emitSnapshot(
        readySnapshot(
          nodes: [
            resultNode("a", actions: [TestSingleAction]),
          ],
          actions: {TestSingleAction: action},
        ),
      );
      controller.toggleSelected("a", isMultiSelect: false);

      expect(
        controller.executeAction(TestSingleAction),
        SearchActionSubmitResult.submitted,
      );
      controller.updateQuery("queued #tag");
      expect(source.searches, isEmpty);

      action.completer.complete(
        const SearchActionResult.completed(
          effect: SearchActionEffect.refresh(),
        ),
      );
      await Future<void>.delayed(Duration.zero);

      source.expectLastSearchContext(
        normalizedQuery: "queued",
        selectors: const [
          SearchParsedSelector(selectorId: "tag", key: "#", value: "tag"),
        ],
      );
    });

    test("action update query effect searches immediately", () async {
      final source = FakeSearchSource();
      final action = TestSingleAction(
        result: const SearchActionResult.completed(
          effect: SearchActionEffect.updateQuery(updateQuery: "effect #tag"),
        ),
      );
      final controller = SearchController(
        source: source,
        baseSelectors: selectors,
      );
      addTearDown(controller.dispose);
      source.emitSnapshot(
        readySnapshot(
          nodes: [
            resultNode("a", actions: [TestSingleAction]),
          ],
          actions: {TestSingleAction: action},
        ),
      );
      controller.toggleSelected("a", isMultiSelect: false);

      controller.executeAction(TestSingleAction);
      await Future<void>.delayed(Duration.zero);

      source.expectLastSearchContext(
        normalizedQuery: "effect",
        selectors: const [
          SearchParsedSelector(selectorId: "tag", key: "#", value: "tag"),
        ],
      );
    });

    test(
      "refresh effect repeats the current search and close effect invokes callback",
      () async {
        var closeCount = 0;
        final source = FakeSearchSource();
        final refreshAction = TestSingleAction(
          result: const SearchActionResult.completed(
            effect: SearchActionEffect.refresh(),
          ),
        );
        final closeAction = TestBatchAction(
          result: const SearchActionResult.completed(
            effect: SearchActionEffect.close(),
          ),
        );
        final controller = SearchController(
          source: source,
          baseSelectors: selectors,
          onCloseRequested: () => closeCount++,
        );
        addTearDown(controller.dispose);
        source.emitSnapshot(
          readySnapshot(
            nodes: [
              resultNode("a", actions: [TestSingleAction, TestBatchAction]),
            ],
            actions: {
              TestSingleAction: refreshAction,
              TestBatchAction: closeAction,
            },
          ),
        );
        controller.updateQuery("current #tag");
        final firstContext = source.lastSearchContext;
        controller.toggleSelected("a", isMultiSelect: false);

        controller.executeAction(TestSingleAction);
        await Future<void>.delayed(Duration.zero);
        expect(source.searches.last, firstContext);

        controller.executeAction(TestBatchAction);
        await Future<void>.delayed(Duration.zero);
        expect(closeCount, 1);
      },
    );

    test("user-pending query wins over an action updateQuery effect", () async {
      final source = FakeSearchSource();
      final action = TestSingleAction();
      final controller = SearchController(
        source: source,
        baseSelectors: selectors,
      );
      addTearDown(controller.dispose);
      source.emitSnapshot(
        readySnapshot(
          nodes: [
            resultNode("a", actions: [TestSingleAction]),
          ],
          actions: {TestSingleAction: action},
        ),
      );
      controller.toggleSelected("a", isMultiSelect: false);

      controller.executeAction(TestSingleAction);
      controller.updateQuery("user #wins");
      action.completer.complete(
        const SearchActionResult.completed(
          effect: SearchActionEffect.updateQuery(
            updateQuery: "effect #ignored",
          ),
        ),
      );
      await Future<void>.delayed(Duration.zero);

      source.expectLastSearchContext(
        normalizedQuery: "user",
        selectors: const [
          SearchParsedSelector(selectorId: "tag", key: "#", value: "wins"),
        ],
      );
    });
  });
}
