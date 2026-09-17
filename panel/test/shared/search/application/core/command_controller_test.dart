import "dart:async";

import "package:flutter/foundation.dart";
import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";

import "support/search_core_test_harness.dart";

void main() {
  group("CommandController", () {
    test("rejects an inapplicable command", () {
      final controller = CommandController(
        effectCallback: (_) {},
        prompts: const UnsupportedSearchPromptHost(),
      );
      addTearDown(controller.dispose);
      final command = _singleCommand(
        evaluate: (_, _) => const SearchCommandState.disabled("Unavailable"),
      );

      expect(
        controller.execute(command, _target([searchResult("a")])),
        SearchCommandSubmitResult.notApplicable,
      );
      expect(controller.state, isA<SearchCommandIdle>());
    });

    test("batch command receives the complete selection", () async {
      final batches = <List<String>>[];
      final effects = <SearchSurfaceEffect>[];
      final command = SearchCommand.batch<String>(
        id: const SearchCommandId("test.batch"),
        presentation: const SearchCommandPresentation(label: "Batch"),
        matcher: const SearchResultMatcher(testResultType),
        execute: (context, values, target) async {
          batches.add(values);
          return const SearchCommandResult.completed();
        },
      );
      final controller = CommandController(
        effectCallback: effects.add,
        prompts: const UnsupportedSearchPromptHost(),
      );
      addTearDown(controller.dispose);

      expect(
        controller.execute(
          command,
          _target([searchResult("a"), searchResult("b")]),
        ),
        SearchCommandSubmitResult.submitted,
      );
      await Future<void>.delayed(Duration.zero);

      expect(batches, [
        ["a", "b"],
      ]);
      expect(controller.state, isA<SearchCommandCompleted>());
      expect(effects, [const SearchSurfaceEffect.close()]);
    });

    test("running command blocks another execution", () {
      final completer = Completer<SearchCommandResult>();
      final command = _singleCommand(
        execute: (context, value, target) => completer.future,
      );
      final controller = CommandController(
        effectCallback: (_) {},
        prompts: const UnsupportedSearchPromptHost(),
      );
      addTearDown(controller.dispose);
      final target = _target([searchResult("a")]);

      expect(
        controller.execute(command, target),
        SearchCommandSubmitResult.submitted,
      );
      expect(controller.state, isA<SearchCommandRunning>());
      expect(
        controller.execute(command, target),
        SearchCommandSubmitResult.busy,
      );
      completer.complete(const SearchCommandResult.cancelled());
    });

    test("cancellation returns to idle without effects", () async {
      final effects = <SearchSurfaceEffect>[];
      final controller = CommandController(
        effectCallback: effects.add,
        prompts: const UnsupportedSearchPromptHost(),
      );
      addTearDown(controller.dispose);

      controller.execute(
        _singleCommand(
          execute: (context, value, target) async =>
              const SearchCommandResult.cancelled(),
        ),
        _target([searchResult("a")]),
      );
      await Future<void>.delayed(Duration.zero);

      expect(controller.state, isA<SearchCommandIdle>());
      expect(effects, isEmpty);
    });

    test("applies the surface effect before host effects", () async {
      final events = <String>[];
      final controller = CommandController(
        effectCallback: (_) => events.add("surface"),
        prompts: const UnsupportedSearchPromptHost(),
        hostEffectExecutors: [
          SearchHostEffectExecutor<_TestHostEffect>(
            (effect) => events.add("host:${effect.value}"),
          ),
        ],
      );
      addTearDown(controller.dispose);

      controller.execute(
        _singleCommand(
          execute: (context, value, target) async =>
              const SearchCommandResult.completed(
                hostEffects: [_TestHostEffect("organization")],
              ),
        ),
        _target([searchResult("a")]),
      );
      await Future<void>.delayed(Duration.zero);

      expect(events, ["surface", "host:organization"]);
    });

    test("execution errors become failed state", () async {
      final previousDebugPrint = debugPrint;
      debugPrint = (_, {wrapWidth}) {};
      addTearDown(() => debugPrint = previousDebugPrint);
      final controller = CommandController(
        effectCallback: (_) {},
        prompts: const UnsupportedSearchPromptHost(),
      );
      addTearDown(controller.dispose);

      controller.execute(
        _singleCommand(
          execute: (context, value, target) => Future.error(StateError("boom")),
        ),
        _target([searchResult("a")]),
      );
      await Future<void>.delayed(Duration.zero);

      expect(controller.state, isA<SearchCommandFailed>());
      expect(
        (controller.state as SearchCommandFailed).message,
        contains("boom"),
      );
    });
  });
}

SearchCommand _singleCommand({
  SearchCommandEvaluator<String>? evaluate,
  SearchCommandExecutor<String>? execute,
}) => SearchCommand.single<String>(
  id: const SearchCommandId("test.single"),
  presentation: const SearchCommandPresentation(label: "Single"),
  matcher: const SearchResultMatcher(testResultType),
  evaluate: evaluate,
  execute:
      execute ??
      (context, value, target) async => const SearchCommandResult.completed(),
);

SearchCommandTarget _target(List<SearchResult> results) => SearchCommandTarget(
  primary: results.first,
  selection: results,
  query: SearchQueryContext.empty,
);

final class _TestHostEffect implements SearchHostEffect {
  const _TestHostEffect(this.value);

  final String value;
}
