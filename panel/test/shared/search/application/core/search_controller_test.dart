import "dart:async";

import "package:collection/collection.dart";
import "package:flutter/foundation.dart";
import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";

import "support/search_core_test_harness.dart";

void main() {
  const selectors = [KeyValueSelectorDefinition(id: "tag", key: "#")];

  group("SearchController", () {
    test("projects scope changes without rerunning the source", () {
      final source = FakeSearchSource();
      final visible = ValueNotifier(false);
      final controller = _controller(
        source,
        scope: PredicateSearchScope(
          dependencies: [visible],
          evaluate: (result, query) => visible.value
              ? const SearchResultVisibility.visible()
              : const SearchResultVisibility.hidden(),
        ),
      );
      addTearDown(controller.dispose);
      addTearDown(visible.dispose);
      source.emitSnapshot(readySnapshot(nodes: [resultNode("a")]));

      expect(controller.snapshot.nodes, isEmpty);
      visible.value = true;

      expect(controller.snapshot.nodes.findResults({"a"}), hasLength(1));
      expect(source.searches, isEmpty);
    });

    test("command applicability reacts without recreating source", () {
      final source = FakeSearchSource();
      final enabled = ValueNotifier(false);
      final command = SearchCommand.single<String>(
        id: const SearchCommandId("test.open"),
        presentation: const SearchCommandPresentation(label: "Open"),
        matcher: const SearchResultMatcher(testResultType),
        dependencies: [enabled],
        evaluate: (value, target) => enabled.value
            ? const SearchCommandState.enabled()
            : const SearchCommandState.hidden(),
        execute: (context, value, target) async =>
            const SearchCommandResult.completed(),
      );
      final controller = _controller(source, commands: [command]);
      addTearDown(controller.dispose);
      addTearDown(enabled.dispose);
      source.emitSnapshot(readySnapshot(nodes: [resultNode("a")]));
      final result = controller.snapshot.nodes.firstResult!;

      expect(controller.commandsFor(result), isEmpty);
      enabled.value = true;

      expect(controller.commandsFor(result).single.command.id, command.id);
      expect(source.searches, isEmpty);
    });

    test("queues query updates while a command runs", () async {
      final source = FakeSearchSource();
      final completer = Completer<SearchCommandResult>();
      final command = _command(
        execute: (context, value, target) => completer.future,
      );
      final controller = _controller(
        source,
        commands: [command],
        baseSelectors: selectors,
      );
      addTearDown(controller.dispose);
      source.emitSnapshot(readySnapshot(nodes: [resultNode("a")]));

      expect(
        controller.executeCommand(command.id, resultId: "a"),
        SearchCommandSubmitResult.submitted,
      );
      controller.updateQuery("queued #tag");
      expect(source.searches, isEmpty);

      completer.complete(
        const SearchCommandResult.completed(
          surfaceEffect: SearchSurfaceEffect.refresh(),
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

    test("activation completes with a typed value", () async {
      final source = FakeSearchSource();
      String? completed;
      final controller = SearchController<String>(
        session: SearchSession(
          source: source,
          interaction: SearchInteraction(
            activation: SearchActivation.custom(
              dependencies: const [],
              evaluate: (context, result) =>
                  const SearchActivationState.enabled(),
              activate: (context, result) async =>
                  SearchActivationResult.complete(result.id),
            ),
            selectionMode: SearchSelectionMode.single,
          ),
        ),
        baseSelectors: const [],
        onCompleted: (value) => completed = value,
      );
      addTearDown(controller.dispose);
      source.emitSnapshot(readySnapshot(nodes: [resultNode("a")]));

      await controller.activate(controller.snapshot.nodes.firstResult!);

      expect(completed, "a");
    });

    test("selection cleanup follows projected snapshots", () {
      final source = FakeSearchSource();
      final controller = _controller(source);
      addTearDown(controller.dispose);
      source.emitSnapshot(
        readySnapshot(nodes: [resultNode("a"), resultNode("b")]),
      );
      controller
        ..toggleSelected("a", isMultiSelect: true)
        ..toggleSelected("b", isMultiSelect: true);

      source.emitSnapshot(readySnapshot(nodes: [resultNode("b")]));

      expect(controller.selectedIds, ["b"]);
    });
  });
}

SearchController<void> _controller(
  FakeSearchSource source, {
  SearchScope scope = const AllSearchScope(),
  List<SearchCommand> commands = const [],
  List<QuerySelectorDefinition> baseSelectors = const [],
}) => SearchController(
  session: SearchSession(
    source: source,
    scope: scope,
    interaction: SearchInteraction(
      activation: SearchActivation.command(
        resolve: (_) => commands.firstOrNull?.id,
        dependencies: const [],
      ),
      selectionMode: SearchSelectionMode.multiple,
      commands: commands,
    ),
  ),
  baseSelectors: baseSelectors,
);

SearchCommand _command({required SearchCommandExecutor<String> execute}) =>
    SearchCommand.single<String>(
      id: const SearchCommandId("test.command"),
      presentation: const SearchCommandPresentation(label: "Command"),
      matcher: const SearchResultMatcher(testResultType),
      execute: execute,
    );
