import "package:flutter/foundation.dart";
import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/logic/search/search.dart";

import "search_core_test_harness.dart";

void main() {
  group("ActionController", () {
    test("rejects empty, missing, and absent selections", () {
      final effects = <SearchActionEffect>[];
      final action = TestSingleAction(
        result: const SearchActionResult.completed(),
      );
      final controller = ActionController(effectCallback: effects.add);
      addTearDown(controller.dispose);
      final snapshot = readySnapshot(
        nodes: [
          resultNode("a", actions: [TestSingleAction]),
        ],
        actions: {TestSingleAction: action},
      );

      expect(
        controller.execute(TestSingleAction, {}, snapshot),
        SearchActionSubmitResult.invalidSelection,
      );
      expect(
        controller.execute(TestBatchAction, {"a"}, snapshot),
        SearchActionSubmitResult.actionNotFound,
      );
      expect(
        controller.execute(TestSingleAction, {"missing"}, snapshot),
        SearchActionSubmitResult.invalidSelection,
      );
      expect(effects, isEmpty);
    });

    test("finds nested results and passes them to a batch action", () async {
      final effects = <SearchActionEffect>[];
      final action = TestBatchAction();
      final controller = ActionController(effectCallback: effects.add);
      addTearDown(controller.dispose);
      final snapshot = readySnapshot(
        nodes: [
          sectionNode("section", [
            resultNode("a", actions: [TestBatchAction]),
            sectionNode("nested", [
              resultNode("b", actions: [TestBatchAction]),
            ]),
          ]),
        ],
        actions: {TestBatchAction: action},
      );

      expect(
        controller.execute(TestBatchAction, {"a", "b"}, snapshot),
        SearchActionSubmitResult.submitted,
      );
      await Future<void>.delayed(Duration.zero);

      expect(action.batches.single.map((r) => r.id), ["a", "b"]);
      expect(controller.state, isA<SearchActionCompleted>());
      expect(effects.single, const SearchActionEffect.close());
    });

    test(
      "single, repeated, and batch actions receive the expected results",
      () async {
        final effects = <SearchActionEffect>[];
        final single = TestSingleAction(
          result: const SearchActionResult.completed(),
        );
        final repeated = TestRepeatedAction();
        final batch = TestBatchAction();
        final snapshot = readySnapshot(
          nodes: [
            resultNode(
              "a",
              actions: [TestSingleAction, TestRepeatedAction, TestBatchAction],
            ),
            resultNode("b", actions: [TestRepeatedAction, TestBatchAction]),
          ],
          actions: {
            TestSingleAction: single,
            TestRepeatedAction: repeated,
            TestBatchAction: batch,
          },
        );

        final singleController = ActionController(effectCallback: effects.add);
        addTearDown(singleController.dispose);
        expect(
          singleController.execute(TestSingleAction, {"a"}, snapshot),
          SearchActionSubmitResult.submitted,
        );
        await Future<void>.delayed(Duration.zero);
        expect(single.executedResults.map((r) => r.id), ["a"]);

        final repeatedController = ActionController(
          effectCallback: effects.add,
        );
        addTearDown(repeatedController.dispose);
        expect(
          repeatedController.execute(TestRepeatedAction, {"a", "b"}, snapshot),
          SearchActionSubmitResult.submitted,
        );
        await Future<void>.delayed(Duration.zero);
        expect(repeated.executedResults.map((r) => r.id), ["a", "b"]);

        final batchController = ActionController(effectCallback: effects.add);
        addTearDown(batchController.dispose);
        expect(
          batchController.execute(TestBatchAction, {"a", "b"}, snapshot),
          SearchActionSubmitResult.submitted,
        );
        await Future<void>.delayed(Duration.zero);
        expect(batch.batches.single.map((r) => r.id), ["a", "b"]);
      },
    );

    test("running action blocks another execute call with busy", () {
      final action = TestSingleAction();
      final controller = ActionController(effectCallback: (_) {});
      addTearDown(controller.dispose);
      final snapshot = readySnapshot(
        nodes: [
          resultNode("a", actions: [TestSingleAction]),
        ],
        actions: {TestSingleAction: action},
      );

      expect(
        controller.execute(TestSingleAction, {"a"}, snapshot),
        SearchActionSubmitResult.submitted,
      );
      expect(controller.state, isA<SearchActionRunning>());
      expect(
        controller.execute(TestSingleAction, {"a"}, snapshot),
        SearchActionSubmitResult.busy,
      );

      action.completer.complete(const SearchActionResult.completed());
    });

    test(
      "completed and failed states include action, ids, and message",
      () async {
        final failedAction = TestSingleAction(
          result: const SearchActionResult.failed(message: "nope"),
        );
        final controller = ActionController(effectCallback: (_) {});
        addTearDown(controller.dispose);
        final snapshot = readySnapshot(
          nodes: [
            resultNode("a", actions: [TestSingleAction]),
          ],
          actions: {TestSingleAction: failedAction},
        );

        controller.execute(TestSingleAction, {"a"}, snapshot);
        await Future<void>.delayed(Duration.zero);

        final state = controller.state as SearchActionFailed;
        expect(state.action, TestSingleAction);
        expect(state.resultIds, {"a"});
        expect(state.message, "nope");
      },
    );

    test(
      "repeated action result merge prioritizes effects and aggregates messages",
      () async {
        final effects = <SearchActionEffect>[];
        final action = TestRepeatedAction(
          onExecute: (result) async {
            if (result.id == "a") {
              return const SearchActionResult.failed(
                message: "first",
                effect: SearchActionEffect.refresh(),
              );
            }
            return const SearchActionResult.failed(
              message: "second",
              effect: SearchActionEffect.updateQuery(updateQuery: "next"),
            );
          },
        );
        final controller = ActionController(effectCallback: effects.add);
        addTearDown(controller.dispose);
        final snapshot = readySnapshot(
          nodes: [
            resultNode("a", actions: [TestRepeatedAction]),
            resultNode("b", actions: [TestRepeatedAction]),
          ],
          actions: {TestRepeatedAction: action},
        );

        controller.execute(TestRepeatedAction, {"a", "b"}, snapshot);
        await Future<void>.delayed(Duration.zero);

        final state = controller.state as SearchActionFailed;
        expect(state.message, "Search failed: first, second");
        expect(
          effects.single,
          const SearchActionEffect.updateQuery(updateQuery: "next"),
        );
      },
    );

    test(
      "action errors become failed state without invoking an effect",
      () async {
        final previousDebugPrint = debugPrint;
        debugPrint = (_, {wrapWidth}) {};
        addTearDown(() => debugPrint = previousDebugPrint);

        final effects = <SearchActionEffect>[];
        final action = TestSingleAction(throwError: true);
        final controller = ActionController(effectCallback: effects.add);
        addTearDown(controller.dispose);
        final snapshot = readySnapshot(
          nodes: [
            resultNode("a", actions: [TestSingleAction]),
          ],
          actions: {TestSingleAction: action},
        );

        controller.execute(TestSingleAction, {"a"}, snapshot);
        await Future<void>.delayed(Duration.zero);

        expect(controller.state, isA<SearchActionFailed>());
        expect(effects, isEmpty);
      },
    );
  });
}
