import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";

/// The result type of every result [searchResult] builds.
const testResultType = SearchResultType(
  id: "test-result",
  rowRendererId: "test-row",
  label: "Test result",
);

/// A [testResultType] result [id], titled [title] (else [id]) and carrying
/// [payload] (else [id]).
SearchResult searchResult(
  String id, {
  String? title,
  String? subtitle,
  Object? payload,
}) => SearchResult(
  id: id,
  type: testResultType,
  payload: payload ?? id,
  title: title ?? id,
  subtitle: subtitle,
);

/// A tree node showing [searchResult] [id].
SearchNode resultNode(String id, {String? title, String? subtitle}) =>
    SearchNode.result(
      result: searchResult(id, title: title, subtitle: subtitle),
    );

/// A section [id], titled [title] or else [id], holding [children].
SearchNode sectionNode(String id, List<SearchNode> children, {String? title}) =>
    SearchNode.section(id: id, title: title ?? id, children: children);

/// A tree of section "root" holding only section "nested", which holds
/// [results].
List<SearchNode> nestedSectionTree(List<SearchNode> results) => [
  sectionNode("root", [
    sectionNode("nested", results, title: "Nested"),
  ], title: "Root"),
];

/// The context of a search for [query] with the parsed [selectors].
SearchQueryContext queryContext(
  String query, {
  List<SearchParsedSelector> selectors = const [],
}) => SearchQueryContext(normalizedQuery: query, selectors: selectors);

/// A selector [id] typed as `id:` whose values the search source completes
/// and validates.
KeyValueSelectorDefinition sourceBackedSelector(String id) =>
    KeyValueSelectorDefinition(
      id: id,
      key: "$id:",
      value: const QuerySelectorValue.sourceBacked(),
    );

/// The selector `id:value` as the query parser reports it.
SearchParsedSelector parsedSelector(String id, String value) =>
    SearchParsedSelector(selectorId: id, key: "$id:", value: value);

/// The context of a search whose whole query is the selector `id:value`.
SearchQueryContext selectorContext(String id, String value) {
  final selector = parsedSelector(id, value);
  return SearchQueryContext(
    normalizedQuery: "$id:$value",
    selectors: [selector],
    selectorExpression: SearchSelectorExpression.leaf(selector),
  );
}

/// The row context of [searchResult] `resource`, selected, focused and busy
/// while [loading], with the shortcut Control 1, running [onTap] when
/// activated.
SearchResultRowContext searchRowContext({
  VoidCallback? onTap,
  bool loading = false,
}) => SearchResultRowContext(
  result: searchResult("resource"),
  selected: true,
  focused: true,
  loading: loading,
  onTap: onTap ?? () {},
  shortcutActivator: AdaptiveSingleActivator(
    LogicalKeyboardKey.digit1,
    control: true,
  ),
);

/// The results [snapshot] shows, sections walked in order.
List<SearchResult> resultsOf(SearchSourceSnapshot snapshot) => snapshot.nodes
    .walk()
    .whereType<SearchResultNode>()
    .map((node) => node.result)
    .toList();

/// The ids of the results [snapshot] shows, sections walked in order.
List<String> resultIds(SearchSourceSnapshot snapshot) =>
    resultsOf(snapshot).map((result) => result.id).toList();

/// A ready snapshot showing [nodes].
SearchSourceSnapshot readySnapshot({required List<SearchNode> nodes}) =>
    SearchSourceSnapshot.ready(nodes: nodes);

/// A failed snapshot reporting [message] as error summary [id], still
/// showing [nodes] and [guidance].
SearchSourceSnapshot errorSnapshot(
  String message, {
  String id = "error",
  List<SearchNode> nodes = const [],
  List<SearchGuidance> guidance = const [],
}) => SearchSourceSnapshot.error(
  nodes: nodes,
  guidance: guidance,
  errorSummaries: [
    SearchErrorSummary(
      id: id,
      message: message,
      severity: SearchErrorSeverity.error,
    ),
  ],
);

/// A session over [source] filtered by [scope], selecting by
/// [selectionMode] and offering [commands]. Activating a result runs the
/// first command; without commands it records the result id in [activated]
/// and keeps the search open, or offers no activation when [activated] is
/// absent.
SearchSession<void> searchSession(
  SearchSource source, {
  SearchSelectionMode selectionMode = SearchSelectionMode.multiple,
  SearchScope scope = const AllSearchScope(),
  List<SearchCommand> commands = const [],
  List<String>? activated,
}) => SearchSession(
  source: source,
  scope: scope,
  interaction: SearchInteraction(
    activation: commands.isEmpty
        ? SearchActivation.custom(
            dependencies: const [],
            evaluate: (context, result) => activated == null
                ? const SearchActivationState.hidden()
                : const SearchActivationState.enabled(),
            activate: (context, result) async {
              activated?.add(result.id);
              return const SearchActivationResult.keepOpen();
            },
          )
        : SearchActivation.command(
            resolve: (_) => commands.first.id,
            dependencies: const [],
          ),
    selectionMode: selectionMode,
    commands: commands,
  ),
);

/// A command [id] labeled [label] that acts on one [testResultType] result
/// at a time; it is enabled unless [evaluate] says otherwise and completes
/// unless [execute] does something else.
SearchCommand searchCommand({
  String id = "test.single",
  String label = "Single",
  SearchCommandEvaluator<String>? evaluate,
  SearchCommandExecutor<String>? execute,
}) => SearchCommand.single<String>(
  id: SearchCommandId(id),
  presentation: SearchCommandPresentation(label: label),
  matcher: const SearchResultMatcher(testResultType),
  evaluate: evaluate,
  execute:
      execute ??
      (context, value, target) async => const SearchCommandResult.completed(),
);

/// A command target on [result], outside any query.
SearchCommandTarget commandTarget(SearchResult result) =>
    SearchCommandTarget(result: result, query: SearchQueryContext.empty);

/// A host effect a command asks for, told apart by [name].
final class NamedHostEffect implements SearchHostEffect {
  const NamedHostEffect(this.name);

  final String name;
}

/// The context a search source receives for the typed [input] over
/// [selectors], which decides the results.
SearchQueryContext sourceQueryContext(
  String input,
  List<QuerySelectorDefinition> selectors,
) {
  final controller = SourceController(
    source: FakeSearchSource(),
    baseSelectors: selectors,
    initialQuery: input,
  );
  final context = controller.queryContext;
  controller.dispose();
  return context;
}

/// A search source a test or story drives: it remembers every search,
/// preview and selector completion, emits the snapshots the test gives it or
/// its [answer] makes, and answers previews and completions with what the
/// test sets.
final class FakeSearchSource
    implements SearchSource, SearchSelectorCompletionSource {
  /// A source offering [selectors] that emits [initialSnapshot], when given,
  /// as it initializes, and the [answer] to each query, when given.
  FakeSearchSource({
    this.selectors = const [],
    this.initialSnapshot,
    this.answer,
    this.answerDelay = Duration.zero,
  });

  final SearchSourceSnapshot? initialSnapshot;

  /// The snapshot each query answers with: emitted as the source
  /// initializes, unless [initialSnapshot] is given, and for every search.
  final SearchSourceSnapshot Function(SearchQueryContext context)? answer;

  /// How long a search takes to answer; meanwhile the last snapshot shows
  /// as loading.
  final Duration answerDelay;

  SearchSourceSnapshot? _last;
  Timer? _answerTimer;

  final _snapshots = StreamController<SearchSourceSnapshot>.broadcast(
    sync: true,
  );
  @override
  final List<QuerySelectorDefinition> selectors;

  int initializeCount = 0;
  int disposeCount = 0;
  final searches = <SearchQueryContext>[];
  final previewRequests = <SearchPreviewRequest>[];
  final completionRequests = <SearchSelectorCompletionRequest>[];

  /// What every preview answers; null keeps previews loading forever.
  SearchPreviewRequestResult? previewResult =
      const SearchPreviewRequestResult.data(data: "preview");
  SearchSelectorCompletionResult completionResult =
      const SearchSelectorCompletionResult();
  Object? completionError;

  @override
  Stream<SearchSourceSnapshot> get snapshots => _snapshots.stream;

  @override
  void initialize(SearchQueryContext context) {
    initializeCount++;
    if (initialSnapshot ?? answer?.call(context) case final snapshot?) {
      emitSnapshot(snapshot);
    }
  }

  @override
  void search(SearchQueryContext context) {
    searches.add(context);
    final answer = this.answer;
    if (answer == null) return;
    _answerTimer?.cancel();
    if (answerDelay == Duration.zero) {
      emitSnapshot(answer(context));
      return;
    }
    emitSnapshot(
      (_last ?? SearchSourceSnapshot.loading()).copyWith(
        status: SearchSourceStatus.loading,
      ),
    );
    _answerTimer = Timer(answerDelay, () => emitSnapshot(answer(context)));
  }

  @override
  Future<SearchPreviewRequestResult> preview(
    SearchPreviewRequest request,
  ) async {
    previewRequests.add(request);
    return previewResult ?? Completer<SearchPreviewRequestResult>().future;
  }

  @override
  Future<SearchSelectorCompletionResult> completeSelector(
    SearchSelectorCompletionRequest request,
  ) async {
    completionRequests.add(request);
    final error = completionError;
    if (error != null) Error.throwWithStackTrace(error, StackTrace.current);
    return completionResult;
  }

  /// Emits [snapshot] to every listener.
  void emitSnapshot(SearchSourceSnapshot snapshot) {
    if (_snapshots.isClosed) return;
    _last = snapshot;
    _snapshots.add(snapshot);
  }

  /// The context of the latest search; fails when nothing was searched.
  SearchQueryContext get lastSearchContext {
    expect(searches, isNotEmpty);
    return searches.last;
  }

  /// Checks the latest search asked for [normalizedQuery] with [selectors].
  void expectLastSearchContext({
    required String normalizedQuery,
    List<SearchParsedSelector> selectors = const [],
  }) {
    final context = lastSearchContext;
    expect(context.normalizedQuery, normalizedQuery);
    expect(context.selectors, selectors);
  }

  @override
  void dispose() {
    disposeCount++;
    _answerTimer?.cancel();
    unawaited(_snapshots.close());
  }
}

/// A card result row "Resource" of kind book, as wide as a dropdown, whose
/// body is the button "Inner action". [onRow] runs when the row activates
/// and [onInner] when the button does.
Widget innerActionRow({
  required VoidCallback onRow,
  required VoidCallback onInner,
}) => SizedBox(
  width: 360,
  child: SearchResultRow(
    row: searchRowContext(onTap: onRow),
    density: SearchResultDensity.card,
    title: "Resource",
    leading: const Icon(Icons.book),
    kindLabel: "book",
    body: TextButton(onPressed: onInner, child: const Text("Inner action")),
  ),
);

/// A live list a test drives through the transitions a provider makes: it
/// loads, holds values, loads again when its scope changes, and fails. The
/// states come from a real provider, so a value the list held stays in its
/// loading and failed states as it does in the panel.
final class DrivenList<T> {
  DrivenList() {
    addTearDown(_container.dispose);
    _container.listen(
      _provider,
      (_, next) => _states.value = next,
      fireImmediately: true,
    );
  }

  final _container = ProviderContainer();
  final _scope = NotifierProvider<_ListScope, int>(_ListScope.new);
  late final _provider = StreamProvider<T>((ref) {
    ref.watch(_scope);
    final controller = StreamController<T>();
    ref.onDispose(controller.close);
    _controller = controller;
    return controller.stream;
  });
  late StreamController<T> _controller;
  final _states = ValueNotifier<AsyncValue<T>>(const AsyncLoading());

  /// The list's state, as a search source reads it.
  ValueListenable<AsyncValue<T>> get states => _states;

  /// The list holds [value].
  Future<void> emit(T value) async {
    _controller.add(value);
    await _settle();
  }

  /// The list fails with [error], keeping any value it held.
  Future<void> fail(Object error) async {
    _controller.addError(error);
    await _settle();
  }

  /// The list's scope changes, such as the organization it belongs to, so
  /// it loads again while still holding its last value.
  Future<void> changeScope() async {
    _container.read(_scope.notifier).next();
    await _settle();
  }

  Future<void> _settle() async {
    await _container.pump();
    await Future<void>.delayed(Duration.zero);
  }
}

final class _ListScope extends Notifier<int> {
  @override
  int build() {
    return 0;
  }

  void next() => state++;
}

/// The first snapshot the source [create] builds over [list] answers
/// [query] with; the source is disposed after the test.
Future<SearchSourceSnapshot> firstSnapshot<T>(
  SearchSource Function(ValueListenable<AsyncValue<T>> list) create,
  DrivenList<T> list, {
  String query = "",
}) async {
  final source = create(list.states);
  addTearDown(source.dispose);
  source.initialize(
    query.isEmpty
        ? SearchQueryContext.empty
        : SearchQueryContext(normalizedQuery: query, selectors: const []),
  );
  return source.snapshots.first;
}
