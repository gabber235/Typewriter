import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/src/doubles/search_history.dart";
import "package:typewriter_testkit/src/shared/editors/catalog_fixture.dart";
import "package:typewriter_testkit/src/shared/editors/presentation_builders.dart";

/// One search control bound through the portable search compiler over a
/// [FakeSearchHost], offering the static result "Result".
final class SearchControlScenario {
  SearchControlScenario._({
    required this.catalog,
    required this.host,
    required this.invocation,
    required this.control,
    required this.storage,
    required this.historyNamespace,
  });

  final CheckedEditorCatalog catalog;
  final FakeSearchHost host;
  final PortableInvocationContext invocation;
  final skir.SearchControl control;
  final SearchHistoryStorage storage;
  final String historyNamespace;

  /// The value the search writes, the row a result maps and the context row
  /// the invocation carries.
  static final targetBinding = skir.ExpressionBindingId(value: "target");
  static final rowBinding = skir.ExpressionBindingId(value: "row");
  static final rowContextBinding = skir.ExpressionBindingId(
    value: "row_context",
  );

  /// A scenario whose results map row "Result" with the context row
  /// [rowValue], selecting [selected] or the context row; [multiple] collects
  /// choices into a list. [historyStorage] adds a recent history around the
  /// static provider unless [provider] replaces it; [rejection] refuses every
  /// write and action with that message and [writeCompletion] answers writes.
  factory SearchControlScenario({
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
    final catalog = CheckedEditorCatalog(
      testCatalogSnapshot(generation: generation),
    );
    final chosen = selected ?? skir.DataValue.wrapStringValue("chosen");
    final rowRead = skir.ExpressionNode.createInput(
      binding: rowBinding,
      path: skir.ValuePath(segments: const []),
    );
    final mapping = skir.SearchResultMapping(
      binding: declareBinding(rowBinding, textTemplate),
      key: rowRead,
      selectedValue: selected == null
          ? skir.ExpressionNode.createInput(
              binding: rowContextBinding,
              path: skir.ValuePath(segments: const []),
            )
          : skir.ExpressionNode.wrapLiteral(chosen),
      presentation: skir.PresentationNode.defaultInstance,
      label: rowRead,
    );
    final leaf = staticSearchProvider(["Result"], mapping: mapping);
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
    final host = FakeSearchHost(
      catalog: catalog,
      initial: initial,
      rejection: rejection,
      writeCompletion: writeCompletion,
    );
    return SearchControlScenario._(
      catalog: catalog,
      host: host,
      invocation: PortableInvocationContext(
        bindings: {
          rowContextBinding: PortableExpressionBinding(
            schema: CompletePortablePresentationBinding(
              skir.TypeUse.wrapScalar(skir.ScalarKind.text),
            ),
            value: skir.DataValue.wrapStringValue(rowValue),
          ),
        },
        catalogGeneration: generation,
      ),
      control: skir.SearchControl(
        control: skir.BoundControl(
          binding: skir.BindingRef(
            bindingId: targetBinding,
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
        queryBinding: declareNamedBinding("query", textTemplate),
        summaryBinding: declareNamedBinding("summary", textTemplate),
        maximumExtent: skir.ExpressionNode.wrapLiteral(
          skir.DataValue.wrapInteger("320"),
        ),
        provider: selectedProvider,
        summary: null,
        placeholder: null,
        customValue: null,
        initialQuery: null,
        appearance: null,
        content: null,
        popup: null,
        popupSide: null,
        emptyText: null,
        loadingText: null,
        empty: null,
        loading: null,
      ),
      storage: historyStorage ?? MemorySearchHistory(),
      historyNamespace: historyNamespace,
    );
  }

  /// Binds the control, fetching over [http] or a fresh client.
  PortableSearchBinding bind({Client? http}) =>
      const PortableSearchCompiler().bindControl(
        control: control,
        environment: PortableSearchEnvironment(
          catalog: catalog,
          budget: skir.EvaluationBudget(maxSteps: 100, maxCollectionItems: 100),
          context: invocation,
          http: http ?? Client(),
          historyStorage: storage,
          historyNamespace: historyNamespace,
        ),
        host: host,
      );
}

/// A provider of the static text [values], with item ids `result_<index>`,
/// mapped by [mapping] or as plain text rows.
skir.SearchProvider staticSearchProvider(
  List<String> values, {
  skir.SearchResultMapping? mapping,
}) {
  final rowRead = skir.ExpressionNode.createInput(
    binding: SearchControlScenario.rowBinding,
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
          binding: declareBinding(
            SearchControlScenario.rowBinding,
            textTemplate,
          ),
          key: rowRead,
          selectedValue: rowRead,
          presentation: skir.PresentationNode.defaultInstance,
          label: rowRead,
        ),
    selectors: const [],
  );
}

/// The first result [source] offers once it initializes for [query].
Future<SearchResult> firstSearchResult(
  SearchSource source, {
  SearchQueryContext query = SearchQueryContext.empty,
}) async {
  final ready = source.snapshots.firstWhere(
    (snapshot) => snapshot.nodes.firstResult != null,
  );
  source.initialize(query);
  return (await ready).nodes.firstResult!;
}

/// A presentation host over one value that a search edits: writes replace
/// it and list item inserts and removals change it, unless [rejection]
/// refuses them with that message. [writeCompletion] answers writes instead.
final class FakeSearchHost extends ChangeNotifier
    implements PortablePresentationHost {
  FakeSearchHost({
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

  /// The value the last applied write gave.
  skir.DataValue? written;

  /// The invocation context of the last write or action.
  PortableInvocationContext? writtenContext;

  @override
  EditControl? commitControl(
    skir.BindingRef reference, {
    required PortableInvocationContext context,
  }) => null;

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
      return PortablePresentationWriteResult.rejected([
        PortablePresentationDiagnostic(
          code: "search_rejected",
          message: message,
          severity: skir.DiagnosticSeverity.error,
        ),
      ]);
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
      return PortablePresentationWriteResult.rejected([
        PortablePresentationDiagnostic(
          code: "search_rejected",
          message: message,
          severity: skir.DiagnosticSeverity.error,
        ),
      ]);
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
        return PortablePresentationWriteResult.rejected([
          PortablePresentationDiagnostic(
            code: "unsupported_action",
            message: "Unsupported action",
            severity: skir.DiagnosticSeverity.error,
          ),
        ]);
    }
    _value = skir.DataValue.createListValue(items: items);
    return const PortablePresentationWriteResult.applied();
  }
}

/// A search result [id] a static provider mapped from [value], selecting
/// [value] itself.
SearchResult mappedSearchResult(String id, skir.DataValue value) {
  final read = inputExpression(SearchControlScenario.rowBinding);
  return SearchResult(
    id: id,
    type: portableSearchResultType,
    title: id,
    payload: PortableSearchPayload.mapped(
      sourceValue: value,
      selectedValue: value,
      mapping: skir.SearchResultMapping(
        binding: declareBinding(SearchControlScenario.rowBinding, textTemplate),
        key: read,
        selectedValue: read,
        presentation: skir.PresentationNode.defaultInstance,
        label: read,
      ),
      providerPath: "root",
      distinctKey: id,
      query: SearchQueryContext.empty,
    ),
  );
}

/// A search result [id] for the custom [value] the user typed.
SearchResult customSearchResult(String id, skir.DataValue value) =>
    SearchResult(
      id: id,
      type: portableSearchResultType,
      title: id,
      payload: PortableSearchPayload.custom(
        selectedValue: value,
        providerPath: "root",
        query: SearchQueryContext.empty,
      ),
    );
