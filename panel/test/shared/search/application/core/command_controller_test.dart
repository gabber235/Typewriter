import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  group("CommandController", () {
    test("rejects an inapplicable command", () {
      final controller = CommandController(
        effectCallback: (_) {},
        prompts: const UnsupportedSearchPromptHost(),
      );
      addTearDown(controller.dispose);
      final command = searchCommand(
        evaluate: (_, _) => const SearchCommandState.disabled("Unavailable"),
      );

      expect(
        controller.execute(command, commandTarget(searchResult("a"))),
        SearchCommandSubmitResult.notApplicable,
      );
      expect(controller.state, isA<SearchCommandIdle>());
    });

    test("running command blocks another execution", () {
      final completer = Completer<SearchCommandResult>();
      final command = searchCommand(
        execute: (context, value, target) => completer.future,
      );
      final controller = CommandController(
        effectCallback: (_) {},
        prompts: const UnsupportedSearchPromptHost(),
      );
      addTearDown(controller.dispose);
      final target = commandTarget(searchResult("a"));

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
        searchCommand(
          execute: (context, value, target) async =>
              const SearchCommandResult.cancelled(),
        ),
        commandTarget(searchResult("a")),
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
          SearchHostEffectExecutor<NamedHostEffect>(
            (effect) => events.add("host:${effect.name}"),
          ),
        ],
      );
      addTearDown(controller.dispose);

      controller.execute(
        searchCommand(
          execute: (context, value, target) async =>
              const SearchCommandResult.completed(
                hostEffects: [NamedHostEffect("organization")],
              ),
        ),
        commandTarget(searchResult("a")),
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
        searchCommand(
          execute: (context, value, target) => Future.error(StateError("boom")),
        ),
        commandTarget(searchResult("a")),
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
