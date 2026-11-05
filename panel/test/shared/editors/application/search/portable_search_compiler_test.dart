import "package:flutter_test/flutter_test.dart";
import "package:http/testing.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  test(
    "HTTP context survives mapping into the typed row presentation",
    () async {
      final origin = skir.ExpressionBindingId(value: "response.origin");
      final row = skir.ExpressionNode.createInput(
        binding: SearchControlScenario.rowBinding,
        path: editorRootPath,
      );
      final fixture = SearchControlScenario(
        provider: skir.SearchProvider.createHttpJson(
          uri: textLiteral("https://example.test/choices"),
          parameters: const [],
          resultPath: r"$.results[*]",
          resultType: skir.TypeTemplate.wrapScalar(skir.ScalarKind.text),
          result: skir.SearchResultMapping(
            binding: declareBinding(
              SearchControlScenario.rowBinding,
              textTemplate,
            ),
            key: row,
            selectedValue: row,
            label: row,
            presentation: skir.PresentationNode.defaultInstance,
          ),
          contextBindings: [
            skir.HttpJsonContextBinding(
              binding: declareBinding(origin, textTemplate),
              path: r"$.origin",
            ),
          ],
          selectors: const [],
          timeoutMilliseconds: 1000,
        ),
      );
      final client = MockClient(
        (_) async => Response(
          '{"origin":"Marketplace","results":["Remote choice"]}',
          200,
        ),
      );
      addTearDown(client.close);
      final binding = fixture.bind(http: client);
      final result = await firstSearchResult(binding.source);
      final payload = result.payload as PortableMappedSearchPayload;
      final text = CompletePortablePresentationBinding(
        skir.TypeUse.wrapScalar(skir.ScalarKind.text),
      );
      expect(payload.contextBindings[origin]?.schema, text);
      final operations = PortableOperationResults();
      final scope = binding.resultScope(
        result,
        PortablePresentationScope(
          bindings: const {},
          budget: skir.EvaluationBudget(maxSteps: 100, maxCollectionItems: 100),
          operations: operations,
          catalog: fixture.catalog,
        ),
      );
      expect(scope.bindings[origin]?.value.authoredString, "Marketplace");
      expect(scope.bindings[SearchControlScenario.rowBinding]?.schema, text);
      expect(
        scope.bindings[SearchControlScenario.rowBinding]?.value.authoredString,
        "Remote choice",
      );
      await Future<void>.delayed(Duration.zero);
      operations.dispose();
      binding.source.dispose();
      binding.dispose();
    },
  );

  test(
    "a row presentation reads its row, the query and the captured context",
    () async {
      final fixture = SearchControlScenario();
      final binding = fixture.bind();
      final result = await firstSearchResult(
        binding.source,
        query: const SearchQueryContext(
          normalizedQuery: "res",
          terms: ["res"],
          selectors: [],
        ),
      );
      final operations = PortableOperationResults();
      final scope = binding.resultScope(
        result,
        PortablePresentationScope(
          bindings: const {},
          budget: skir.EvaluationBudget(maxSteps: 100, maxCollectionItems: 100),
          operations: operations,
          catalog: fixture.catalog,
        ),
      );
      String? shown(skir.ExpressionBindingId binding) => switch (scope.evaluate(
        portableCall("text.upper", [inputExpression(binding)]),
      )) {
        PortableExpressionAvailable(:final value) => value.authoredString,
        _ => null,
      };

      expect(shown(SearchControlScenario.rowBinding), "RESULT");
      expect(shown(fixture.control.queryBinding.id), "RES");
      expect(shown(SearchControlScenario.rowContextBinding), "ROW");
      operations.dispose();
      binding.source.dispose();
      binding.dispose();
    },
  );

  test(
    "selection uses the exact row invocation captured by its environment",
    () async {
      final fixture = SearchControlScenario(rowValue: "row a");
      final binding = fixture.bind();
      final otherFixture = SearchControlScenario(rowValue: "row b");
      final otherBinding = otherFixture.bind();
      final result = await firstSearchResult(binding.source);
      final otherResult = await firstSearchResult(otherBinding.source);
      final selected = await binding.choose(result);

      expect(
        (result.payload as PortableSearchPayload).selectedValue,
        skir.DataValue.wrapStringValue("row a"),
      );
      expect(
        (otherResult.payload as PortableSearchPayload).selectedValue,
        skir.DataValue.wrapStringValue("row b"),
      );
      expect(
        selected,
        const PortableSearchSelectionResult.applied(added: true),
      );
      expect(fixture.host.written, skir.DataValue.wrapStringValue("row a"));
      expect(
        fixture
            .host
            .writtenContext
            ?.bindings[SearchControlScenario.rowContextBinding]
            ?.value,
        skir.DataValue.wrapStringValue("row a"),
      );
      binding.source.dispose();
      binding.dispose();
      otherBinding.source.dispose();
      otherBinding.dispose();
    },
  );

  test("rejected host admission preserves its reason", () async {
    final fixture = SearchControlScenario(
      rejection: "The selected value is no longer admissible",
    );
    final binding = fixture.bind();
    final result = await firstSearchResult(binding.source);

    expect(
      await binding.choose(result),
      const PortableSearchSelectionResult.rejected(
        "The selected value is no longer admissible",
      ),
    );
    expect(
      binding.feedback.value,
      "The selected value is no longer admissible",
    );
    binding.source.dispose();
    binding.dispose();
  });

  test(
    "multiple selection history records additions and ignores removals",
    () async {
      final storage = MemorySearchHistory();
      final fixture = SearchControlScenario(
        multiple: true,
        historyStorage: storage,
      );
      final binding = fixture.bind();
      final result = await firstSearchResult(binding.source);

      expect(
        await binding.choose(result),
        const PortableSearchSelectionResult.applied(added: true),
      );
      await Future<void>.delayed(Duration.zero);
      expect(storage.writes, 1);

      expect(
        await binding.choose(result),
        const PortableSearchSelectionResult.applied(added: false),
      );
      await Future<void>.delayed(Duration.zero);
      expect(storage.writes, 1);
      binding.source.dispose();
      binding.dispose();
    },
  );

  test("named selected values reach host admission unchanged", () async {
    final definition = skir.TypeDefinitionId(
      typeId: skir.TypeId.createQualified(namespace: "test", name: "choice"),
      revision: 1,
    );
    final selected = skir.DataValue.createNamed(
      actualType: skir.NamedTypeUse(
        definition: definition,
        arguments: const [],
      ),
      payload: skir.DataValue.wrapStringValue("chosen"),
    );
    final fixture = SearchControlScenario(selected: selected);
    final binding = fixture.bind();
    final result = await firstSearchResult(binding.source);

    await binding.choose(result);

    expect(fixture.host.written, selected);
    binding.source.dispose();
    binding.dispose();
  });

  test("distinct merged sources collapse only equal authored keys", () async {
    final fixture = SearchControlScenario(
      provider: skir.SearchProvider.createDistinct(
        child: skir.SearchProvider.createMerge(
          children: [
            staticSearchProvider(["same", "first"]),
            staticSearchProvider(["same", "second"]),
          ],
        ),
      ),
    );
    final binding = fixture.bind();
    final snapshot = binding.source.snapshots.firstWhere(
      (value) => value.nodes.walk().whereType<SearchResultNode>().length == 3,
    );

    binding.source.initialize(SearchQueryContext.empty);

    expect(
      (await snapshot).nodes.walk().whereType<SearchResultNode>().map(
        (node) => node.result.title,
      ),
      ["same", "first", "second"],
    );
    binding.source.dispose();
    binding.dispose();
  });

  test("merged equal keys retain independent occurrence identity", () async {
    final fixture = SearchControlScenario(
      provider: skir.SearchProvider.createMerge(
        children: [
          staticSearchProvider(["same"]),
          staticSearchProvider(["same"]),
        ],
      ),
    );
    final binding = fixture.bind();
    final controller = SearchController<void>(
      session: binding.session(),
      baseSelectors: const [],
    );
    final results = controller.snapshot.nodes
        .walk()
        .whereType<SearchResultNode>()
        .map((node) => node.result)
        .toList();

    expect(results, hasLength(2));
    expect(results.map((result) => result.id).toSet(), hasLength(2));
    expect(
      results
          .map(
            (result) =>
                (result.payload as PortableMappedSearchPayload).distinctKey,
          )
          .toSet(),
      hasLength(1),
    );
    controller.preview(results.first);
    expect(controller.currentPreview?.id, results.first.id);
    controller.preview(results.last);
    expect(controller.currentPreview?.id, results.last.id);
    await controller.activate(results.last);
    expect(fixture.host.written, skir.DataValue.wrapStringValue("same"));
    controller.dispose();
    binding.dispose();
  });

  test("sibling history providers retain only their own selections", () async {
    final storage = MemorySearchHistory();
    final first = skir.SearchProvider.createHistory(
      historyKey: "first",
      label: textLiteral("First"),
      capacity: 5,
      child: staticSearchProvider(["same"]),
    );
    final second = skir.SearchProvider.createHistory(
      historyKey: "second",
      label: textLiteral("Second"),
      capacity: 5,
      child: staticSearchProvider(["same"]),
    );
    final fixture = SearchControlScenario(
      historyStorage: storage,
      provider: skir.SearchProvider.createMerge(children: [first, second]),
    );
    final binding = fixture.bind();
    final ready = binding.source.snapshots.firstWhere(
      (snapshot) =>
          snapshot.nodes.walk().whereType<SearchResultNode>().length == 2,
    );
    binding.source.initialize(SearchQueryContext.empty);
    final selected = (await ready).nodes
        .walk()
        .whereType<SearchResultNode>()
        .first
        .result;

    await binding.choose(selected);
    await Future<void>.delayed(Duration.zero);

    expect(storage.resultsByKey.length, 1);
    expect(storage.resultsByKey.values.single.single.payload, selected.payload);
    binding.source.dispose();
    binding.dispose();
  });

  test("late host completion has no effects after binding disposal", () async {
    final completion = Completer<PortablePresentationWriteResult>();
    final storage = MemorySearchHistory();
    final fixture = SearchControlScenario(
      writeCompletion: completion,
      historyStorage: storage,
    );
    final binding = fixture.bind();
    final result = await firstSearchResult(binding.source);
    final choosing = binding.choose(result);

    binding.dispose();
    completion.complete(const PortablePresentationWriteResult.applied());

    expect(
      await choosing,
      const PortableSearchSelectionResult.applied(added: true),
    );
    expect(storage.writes, 0);
    binding.source.dispose();
  });

  test("disposed controller ignores late activation completion", () async {
    final completion = Completer<PortablePresentationWriteResult>();
    final fixture = SearchControlScenario(writeCompletion: completion);
    final binding = fixture.bind();
    var completed = 0;
    final controller = SearchController<void>(
      session: binding.session(),
      baseSelectors: const [],
      onCompleted: (_) => completed++,
    );
    final result = controller.snapshot.nodes.firstResult!;
    final activating = controller.activate(result);

    controller.dispose();
    binding.dispose();
    completion.complete(const PortablePresentationWriteResult.applied());
    await activating;

    expect(completed, 0);
  });

  test("history storage is isolated by authenticated organization", () async {
    final storage = MemorySearchHistory();
    final first = SearchControlScenario(
      historyStorage: storage,
      historyNamespace: "user:one:organization:first",
    );
    final second = SearchControlScenario(
      historyStorage: storage,
      historyNamespace: "user:one:organization:second",
    );
    final firstBinding = first.bind();
    final secondBinding = second.bind();

    await firstBinding.choose(await firstSearchResult(firstBinding.source));
    await secondBinding.choose(await firstSearchResult(secondBinding.source));
    await Future<void>.delayed(Duration.zero);

    expect(storage.resultsByKey.keys, hasLength(2));
    expect(
      storage.resultsByKey.keys.any(
        (key) => key.startsWith("user:one:organization:first:"),
      ),
      isTrue,
    );
    expect(
      storage.resultsByKey.keys.any(
        (key) => key.startsWith("user:one:organization:second:"),
      ),
      isTrue,
    );
    firstBinding.source.dispose();
    firstBinding.dispose();
    secondBinding.source.dispose();
    secondBinding.dispose();
  });
}
