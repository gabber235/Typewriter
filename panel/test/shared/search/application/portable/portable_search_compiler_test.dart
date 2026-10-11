import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

void main() {
  test(
    "selection uses the exact row invocation captured by its environment",
    () async {
      final fixture = _fixture(rowValue: "row a");
      final binding = fixture.bind();
      final otherFixture = _fixture(rowValue: "row b");
      final otherBinding = otherFixture.bind();
      final result = await _firstResult(binding.source);
      final otherResult = await _firstResult(otherBinding.source);
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
        fixture.host.writtenContext?.bindings[_rowContextBinding]?.value,
        skir.DataValue.wrapStringValue("row a"),
      );
      binding.source.dispose();
      binding.dispose();
      otherBinding.source.dispose();
      otherBinding.dispose();
    },
  );

  test("rejected host admission preserves its reason", () async {
    final fixture = _fixture(
      rejection: "The selected value is no longer admissible",
    );
    final binding = fixture.bind();
    final result = await _firstResult(binding.source);

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
      final storage = _MemoryHistoryStorage();
      final fixture = _fixture(multiple: true, historyStorage: storage);
      final binding = fixture.bind();
      final result = await _firstResult(binding.source);

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
    final fixture = _fixture(selected: selected);
    final binding = fixture.bind();
    final result = await _firstResult(binding.source);

    await binding.choose(result);

    expect(identical(fixture.host.written, selected), isTrue);
    binding.source.dispose();
    binding.dispose();
  });

  test("distinct merged sources collapse only equal authored keys", () async {
    final fixture = _fixture(
      provider: skir.SearchProvider.createDistinct(
        child: skir.SearchProvider.createMerge(
          children: [
            _staticProvider(["same", "first"]),
            _staticProvider(["same", "second"]),
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
        (node) =>
            (node.result.payload as PortableMappedSearchPayload).distinctKey,
      ),
      [
        canonicalAuthoredValue(skir.DataValue.wrapStringValue("same")),
        canonicalAuthoredValue(skir.DataValue.wrapStringValue("first")),
        canonicalAuthoredValue(skir.DataValue.wrapStringValue("second")),
      ],
    );
    binding.source.dispose();
    binding.dispose();
  });

  test("merged equal keys retain independent occurrence identity", () async {
    final fixture = _fixture(
      provider: skir.SearchProvider.createMerge(
        children: [
          _staticProvider(["same"]),
          _staticProvider(["same"]),
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
    final storage = _MemoryHistoryStorage();
    final first = skir.SearchProvider.createHistory(
      historyKey: "first",
      label: _literal("First"),
      capacity: 5,
      child: _staticProvider(["same"]),
    );
    final second = skir.SearchProvider.createHistory(
      historyKey: "second",
      label: _literal("Second"),
      capacity: 5,
      child: _staticProvider(["same"]),
    );
    final fixture = _fixture(
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
    final storage = _MemoryHistoryStorage();
    final fixture = _fixture(
      writeCompletion: completion,
      historyStorage: storage,
    );
    final binding = fixture.bind();
    final result = await _firstResult(binding.source);
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
    final fixture = _fixture(writeCompletion: completion);
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
    final storage = _MemoryHistoryStorage();
    final first = _fixture(
      historyStorage: storage,
      historyNamespace: "user:one:organization:first",
    );
    final second = _fixture(
      historyStorage: storage,
      historyNamespace: "user:one:organization:second",
    );
    final firstBinding = first.bind();
    final secondBinding = second.bind();

    await firstBinding.choose(await _firstResult(firstBinding.source));
    await secondBinding.choose(await _firstResult(secondBinding.source));
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

final _targetBinding = skir.ExpressionBindingId(value: "target");
final _rowBinding = skir.ExpressionBindingId(value: "row");
final _rowContextBinding = skir.ExpressionBindingId(value: "row_context");

final class _SearchFixture {
  _SearchFixture({
    required this.catalog,
    required this.host,
    required this.invocation,
    required this.control,
    required this.storage,
    required this.historyNamespace,
  });

  final CheckedEditorCatalog catalog;
  final _FakeHost host;
  final PortableInvocationContext invocation;
  final skir.SearchControl control;
  final SearchHistoryStorage storage;
  final String historyNamespace;

  PortableSearchBinding bind() => const PortableSearchCompiler().bindControl(
    control: control,
    environment: PortableSearchEnvironment(
      catalog: catalog,
      budget: skir.EvaluationBudget(maxSteps: 100, maxCollectionItems: 100),
      context: invocation,
      http: Client(),
      historyStorage: storage,
      historyNamespace: historyNamespace,
    ),
    host: host,
  );
}

_SearchFixture _fixture({
  String rowValue = "row",
  String? rejection,
  bool multiple = false,
  skir.DataValue? selected,
  SearchHistoryStorage? historyStorage,
  skir.SearchProvider? provider,
  Completer<PortablePresentationWriteResult>? writeCompletion,
  String historyNamespace = "user:test:organization:test",
}) {
  final generation = skir.CatalogGeneration(value: "catalog:test");
  final catalog = CheckedEditorCatalog(_catalog(generation));
  final chosen = selected ?? skir.DataValue.wrapStringValue("chosen");
  final rowRead = skir.ExpressionNode.createRead(
    binding: _rowBinding,
    path: skir.ValuePath(segments: const []),
  );
  final mapping = skir.SearchResultMapping(
    bindingId: _rowBinding,
    key: rowRead,
    selectedValue: selected == null
        ? skir.ExpressionNode.createRead(
            binding: _rowContextBinding,
            path: skir.ValuePath(segments: const []),
          )
        : skir.ExpressionNode.wrapLiteral(chosen),
    presentation: skir.PresentationNode.defaultInstance,
    label: rowRead,
  );
  final leaf = _staticProvider(["Result"], mapping: mapping);
  final selectedProvider =
      provider ??
      (historyStorage == null
          ? leaf
          : skir.SearchProvider.createHistory(
              historyKey: "recent",
              label: skir.ExpressionNode.wrapLiteral(
                skir.DataValue.wrapStringValue("Recent"),
              ),
              capacity: 5,
              child: leaf,
            ));
  final initial = multiple
      ? skir.DataValue.createListValue(items: const [])
      : skir.DataValue.unfilled;
  final host = _FakeHost(
    catalog: catalog,
    initial: initial,
    rejection: rejection,
    writeCompletion: writeCompletion,
  );
  return _SearchFixture(
    catalog: catalog,
    host: host,
    invocation: PortableInvocationContext(
      bindings: {
        _rowContextBinding: PortableExpressionBinding(
          value: skir.DataValue.wrapStringValue(rowValue),
        ),
      },
      catalogGeneration: generation,
    ),
    control: skir.SearchControl(
      control: skir.BoundControl(
        binding: skir.BindingRef(
          bindingId: _targetBinding,
          path: skir.ValuePath(segments: const []),
        ),
        label: null,
        description: null,
        prefix: null,
        semanticLabel: null,
      ),
      selectionMode: multiple
          ? skir.SearchSelectionMode.multiple
          : skir.SearchSelectionMode.single,
      queryBindingId: skir.ExpressionBindingId(value: "query"),
      summaryBindingId: skir.ExpressionBindingId(value: "summary"),
      maximumExtent: skir.ExpressionNode.wrapLiteral(
        skir.DataValue.wrapInteger("320"),
      ),
      provider: selectedProvider,
      summary: null,
      placeholder: null,
      customValue: null,
      initialQuery: null,
    ),
    storage: historyStorage ?? _MemoryHistoryStorage(),
    historyNamespace: historyNamespace,
  );
}

skir.SearchProvider _staticProvider(
  List<String> values, {
  skir.SearchResultMapping? mapping,
}) {
  final rowRead = skir.ExpressionNode.createRead(
    binding: _rowBinding,
    path: skir.ValuePath(segments: const []),
  );
  return skir.SearchProvider.createStaticValues(
    values: skir.ExpressionNode.wrapLiteral(
      skir.DataValue.createListValue(
        items: [
          for (final (index, value) in values.indexed)
            skir.ListItem(
              id: skir.ItemId(value: "result_$index"),
              value: skir.DataValue.wrapStringValue(value),
            ),
        ],
      ),
    ),
    result:
        mapping ??
        skir.SearchResultMapping(
          bindingId: _rowBinding,
          key: rowRead,
          selectedValue: rowRead,
          presentation: skir.PresentationNode.defaultInstance,
          label: rowRead,
        ),
    selectors: const [],
  );
}

skir.ExpressionNode _literal(String value) =>
    skir.ExpressionNode.wrapLiteral(skir.DataValue.wrapStringValue(value));

skir.EditorCatalogWireSnapshot _catalog(skir.CatalogGeneration generation) =>
    skir.EditorCatalogWireSnapshot(
      generation: generation,
      types: const [],
      relations: const [],
      resourceDefinitions: const [],
      presentations: const [],
      presentationMaterials: const [],
      configuration: const [],
      diagnostics: const [],
      initialization: const [],
      endpointBindings: const [],
      capabilities: const [],
      recommendations: const [],
      roleFallbacks: const [],
    );

Future<SearchResult> _firstResult(SearchSource source) async {
  final ready = source.snapshots.firstWhere(
    (snapshot) => snapshot.nodes.firstResult != null,
  );
  source.initialize(SearchQueryContext.empty);
  return (await ready).nodes.firstResult!;
}

final class _FakeHost extends ChangeNotifier
    implements PortablePresentationHost {
  _FakeHost({
    required CheckedEditorCatalog catalog,
    required skir.DataValue initial,
    required this.rejection,
    this.writeCompletion,
  }) : _value = initial,
       _document = PortablePresentationDocument(
         catalog: catalog,
         root: skir.PresentationNode.defaultInstance,
         bindings: const {},
         budget: skir.EvaluationBudget(maxSteps: 100, maxCollectionItems: 100),
       );

  final String? rejection;
  final Completer<PortablePresentationWriteResult>? writeCompletion;
  skir.DataValue _value;
  final PortablePresentationDocument _document;
  skir.DataValue? written;
  PortableInvocationContext? writtenContext;

  @override
  PortablePresentationCapabilities get capabilities =>
      const PortablePresentationCapabilities();
  @override
  PortablePresentationDocument get document => _document;
  @override
  bool get enabled => true;
  @override
  bool get readOnly => false;

  @override
  skir.TypeUse? expectedType(
    skir.BindingRef reference, {
    required PortableInvocationContext context,
  }) => skir.TypeUse.wrapScalar(skir.ScalarKind.text);

  @override
  skir.ValueLocation? location(
    skir.BindingRef reference, {
    required PortableInvocationContext context,
  }) => null;

  @override
  skir.DataValue? read(
    skir.BindingRef reference, {
    required PortableInvocationContext context,
  }) => _value;

  @override
  Future<PortablePresentationWriteResult> write(
    skir.BindingRef reference,
    skir.DataValue value, {
    required PortableInvocationContext context,
  }) async {
    writtenContext = context;
    if (writeCompletion case final completion?) {
      return completion.future;
    }
    if (rejection case final message?) {
      return PortablePresentationWriteResult.rejected(message);
    }
    written = value;
    _value = value;
    return const PortablePresentationWriteResult.applied();
  }

  @override
  Future<PortablePresentationWriteResult> execute(
    skir.EditorAction editorAction, {
    required PortableInvocationContext context,
  }) async {
    writtenContext = context;
    if (rejection case final message?) {
      return PortablePresentationWriteResult.rejected(message);
    }
    final items = _value.authoredItems?.toList() ?? <skir.ListItem>[];
    switch (editorAction) {
      case skir.EditorAction_localWrapper(
        value: skir.LocalEditorAction_insertListItemWrapper(:final value),
      ):
        final selected = value.value as skir.ExpressionNode_literalWrapper;
        items.add(
          skir.ListItem(
            id: skir.ItemId(value: "selected"),
            value: selected.value,
          ),
        );
      case skir.EditorAction_localWrapper(
        value: skir.LocalEditorAction_removeListItemWrapper(:final value),
      ):
        items.removeWhere((item) => item.id == value.item);
      case _:
        return const PortablePresentationWriteResult.rejected(
          "Unsupported action",
        );
    }
    _value = skir.DataValue.createListValue(items: items);
    return const PortablePresentationWriteResult.applied();
  }
}

final class _MemoryHistoryStorage implements SearchHistoryStorage {
  int writes = 0;
  List<SearchResult> results = const [];
  final Map<String, List<SearchResult>> resultsByKey = {};

  @override
  Future<List<SearchResult>> loadValidResults({
    required String key,
    required int capacity,
  }) async => results;

  @override
  Future<void> replaceResults({
    required String key,
    required List<SearchResult> results,
  }) async {
    writes++;
    this.results = results;
    resultsByKey[key] = results;
  }
}
