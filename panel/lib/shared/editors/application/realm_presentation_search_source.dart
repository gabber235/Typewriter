import "dart:async";

import "package:typewriter_panel/typewriter_panel.dart";

typedef RealmPresentationSearchSourceBuilder =
    SearchSource Function({
      required RealmCallbackSearchProvider provider,
      required BindingId queryBindingId,
      required ExpressionContext expressions,
      required TypeRegistry registry,
      required ExpressionBudget budget,
      required String providerKey,
    });

final class RealmPresentationSearchSource implements SearchSource {
  RealmPresentationSearchSource({
    required this.provider,
    required this.generation,
    required this.payloadType,
    required this.resultType,
    required this.transport,
    required this.queryBindingId,
    required this.expressions,
    required this.registry,
    required this.budget,
    required this.providerKey,
  }) : _sourceId = _nextSourceId++;

  static var _nextSourceId = 0;

  final RealmCallbackSearchProvider provider;
  final CatalogGeneration generation;
  final TypeExpression payloadType;
  final TypeExpression resultType;
  final RealmPresentationSearchTransport transport;
  final BindingId queryBindingId;
  final ExpressionContext expressions;
  final TypeRegistry registry;
  final ExpressionBudget budget;
  final String providerKey;
  final int _sourceId;

  final _snapshots = StreamController<SearchSourceSnapshot>.broadcast(
    sync: true,
  );
  StreamSubscription<RealmPresentationSearchUpdate>? _subscription;
  var _revision = 0;
  var _disposed = false;

  @override
  Stream<SearchSourceSnapshot> get snapshots => _snapshots.stream;

  @override
  Stream<List<QuerySelectorDefinition>> get selectors =>
      Stream.value(presentationQuerySelectors(provider.selectors));

  @override
  void initialize() {
    scheduleMicrotask(() {
      if (!_disposed) {
        _snapshots.add(SearchSourceSnapshot.idle());
      }
    });
  }

  @override
  void search(SearchQueryContext query) {
    if (_disposed) {
      return;
    }
    final revision = ++_revision;
    unawaited(_subscription?.cancel());
    _subscription = null;
    final context = presentationSearchContext(
      base: expressions,
      queryBindingId: queryBindingId,
      query: query,
      selectors: provider.selectors,
    );
    final payload = provider.payload.evaluate(
      context,
      registry: registry,
      budget: budget,
    );
    final diagnostics = [
      ...payload.diagnostics,
      if (payload.valueOrNull case final value?)
        ...value.validateAgainst(payloadType, registry: registry),
    ];
    if (diagnostics.isNotEmpty) {
      _snapshots.add(_error(diagnostics));
      return;
    }
    final subscriptionId = "$providerKey:$_sourceId:$revision";
    _snapshots.add(SearchSourceSnapshot.loading());
    _subscription =
        transport(
          RealmPresentationSearchRequest(
            subscriptionId: subscriptionId,
            generation: generation,
            capabilityId: provider.capabilityId,
            payload: payload.valueOrNull!,
            resultType: resultType,
            query: query,
          ),
        ).listen(
          (update) => _onUpdate(
            update,
            context: context,
            subscriptionId: subscriptionId,
            revision: revision,
          ),
          onError: (Object error, StackTrace stackTrace) {
            if (_disposed || revision != _revision) {
              return;
            }
            _snapshots.add(
              _error([
                TypeDiagnostic(
                  code: TypeDiagnosticCode.invalidPresentation,
                  message: "Realm search transport failed: $error",
                ),
              ]),
            );
          },
        );
  }

  void _onUpdate(
    RealmPresentationSearchUpdate update, {
    required ExpressionContext context,
    required String subscriptionId,
    required int revision,
  }) {
    if (_disposed || revision != _revision) {
      return;
    }
    if (update.subscriptionId != subscriptionId) {
      return;
    }
    switch (update) {
      case RealmPresentationSearchUnavailableUpdate(:final diagnostics):
        _snapshots.add(_error(diagnostics));
      case RealmPresentationSearchSnapshotUpdate():
        _snapshots.add(_mapSnapshot(update, context));
    }
  }

  SearchSourceSnapshot _mapSnapshot(
    RealmPresentationSearchSnapshotUpdate update,
    ExpressionContext context,
  ) {
    final mapper = PresentationSearchMapper(
      mapping: provider.result,
      registry: registry,
      budget: budget,
      providerKey: providerKey,
    );
    final nodes = <SearchNode>[];
    final diagnostics = [...update.diagnostics];
    for (final value in update.values) {
      final validation = value.validateAgainst(resultType, registry: registry);
      if (validation.isNotEmpty) {
        diagnostics.addAll(validation);
        continue;
      }
      final result = mapper.map(
        value: value,
        type: resultType,
        expressions: context,
      );
      diagnostics.addAll(result.diagnostics);
      if (result.valueOrNull case final mapped?) {
        nodes.add(SearchNode.result(result: mapped));
      }
    }
    final errors = _summaries(diagnostics);
    return SearchSourceSnapshot(
      status: update.status,
      nodes: nodes,
      guidance: [
        for (final entry in update.guidance.indexed)
          SearchGuidance(id: "realm.$providerKey.${entry.$1}", title: entry.$2),
      ],
      errorSummaries: errors,
    );
  }

  SearchSourceSnapshot _error(List<TypeDiagnostic> diagnostics) =>
      SearchSourceSnapshot.error(errorSummaries: _summaries(diagnostics));

  List<SearchErrorSummary> _summaries(List<TypeDiagnostic> diagnostics) =>
      diagnostics.indexed
          .map(
            (entry) => SearchErrorSummary(
              id: "realm.$providerKey.${entry.$1}",
              message: entry.$2.message,
              severity: entry.$2.severity == TypeDiagnosticSeverity.error
                  ? SearchErrorSeverity.error
                  : SearchErrorSeverity.warning,
              sourceLabel: "Realm",
            ),
          )
          .toList(growable: false);

  @override
  Future<SearchPreviewRequestResult> preview(
    SearchPreviewRequest request,
  ) async => const SearchPreviewRequestResult.error(
    message: "Realm presentation results render directly",
  );

  @override
  void dispose() {
    if (_disposed) {
      return;
    }
    _disposed = true;
    _revision++;
    unawaited(_subscription?.cancel());
    _subscription = null;
    unawaited(_snapshots.close());
  }
}

final class UnavailableRealmPresentationSearchSource implements SearchSource {
  UnavailableRealmPresentationSearchSource({required this.provider});

  final RealmCallbackSearchProvider provider;
  final _snapshots = StreamController<SearchSourceSnapshot>.broadcast(
    sync: true,
  );
  var _disposed = false;

  @override
  Stream<SearchSourceSnapshot> get snapshots => _snapshots.stream;

  @override
  Stream<List<QuerySelectorDefinition>> get selectors =>
      Stream.value(presentationQuerySelectors(provider.selectors));

  @override
  void initialize() {
    scheduleMicrotask(() {
      if (!_disposed) {
        _snapshots.add(SearchSourceSnapshot.idle());
      }
    });
  }

  @override
  void search(SearchQueryContext context) {
    if (_disposed) {
      return;
    }
    _snapshots.add(
      SearchSourceSnapshot.error(
        errorSummaries: const [
          SearchErrorSummary(
            id: "realmSearchUnavailable",
            message: "Realm search is unavailable in this environment",
            severity: SearchErrorSeverity.error,
            sourceLabel: "Realm",
          ),
        ],
      ),
    );
  }

  @override
  Future<SearchPreviewRequestResult> preview(
    SearchPreviewRequest request,
  ) async => const SearchPreviewRequestResult.error(
    message: "Realm search is unavailable in this environment",
  );

  @override
  void dispose() {
    _disposed = true;
    unawaited(_snapshots.close());
  }
}
