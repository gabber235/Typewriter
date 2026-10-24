part of "portable_search_compiler.dart";

final class _PortableRealmSearchSource extends _PortableLeafSearchSource {
  _PortableRealmSearchSource({
    required this.provider,
    required super.evaluation,
    required super.providerPath,
  }) : super(selectorDefinitions: provider.selectors);

  final skir.RealmCallbackSearchProvider provider;
  StreamSubscription<skir.RealmPresentationSearchUpdate>? _subscription;
  var _generation = 0;

  @override
  void search(SearchQueryContext context) {
    final generation = ++_generation;
    unawaited(_replace(context, generation));
  }

  Future<void> _replace(SearchQueryContext context, int generation) async {
    final previous = _subscription;
    _subscription = null;
    await previous?.cancel();
    if (disposed || generation != _generation) return;
    final environment = evaluation.environment;
    final watch = environment.watchRealm;
    if (watch == null) {
      emit(_searchError(providerPath, "Realm search is unavailable"));
      return;
    }
    final definition = environment.catalog.snapshot.capabilities
        .whereType<skir.CapabilityDefinition_searchWrapper>()
        .map((entry) => entry.value)
        .where((entry) => entry.capabilityId == provider.capabilityId)
        .firstOrNull;
    if (definition == null) {
      emit(_searchError(providerPath, "The Realm search is not published"));
      return;
    }
    final payload = evaluation.evaluate(
      provider.payload,
      query: context,
      selectors: selectorDefinitions,
    );
    if (payload is! PortableExpressionAvailable) {
      emit(
        _searchError(providerPath, "The Realm search payload is unavailable"),
      );
      return;
    }
    final subscriptionId = "panel:search:${const Uuid().v4()}";
    final request = skir.RealmPresentationSearchRequest(
      subscriptionId: subscriptionId,
      generation: environment.context.catalogGeneration,
      capabilityId: provider.capabilityId,
      payload: payload.value,
      resultType: definition.resultType.portableTemplate,
      query: context.realmQuery,
      operationContext: null,
    );
    emit(SearchSourceSnapshot.loading());
    late final StreamSubscription<skir.RealmPresentationSearchUpdate> owned;
    owned = watch(request).listen(
      (update) {
        if (disposed || generation != _generation) return;
        switch (update) {
          case skir.RealmPresentationSearchUpdate_snapshotWrapper(:final value):
            if (value.subscriptionId != subscriptionId) return;
            final nodes = mapValues(value.values, provider.result, context);
            final guidance = [
              for (final (index, message) in value.guidance.indexed)
                SearchGuidance(
                  id: "$providerPath.guidance.$index",
                  title: message,
                ),
            ];
            emit(
              value.status == skir.RealmPresentationSearchStatus.loading
                  ? SearchSourceSnapshot.loading(
                      nodes: nodes,
                      guidance: guidance,
                    )
                  : SearchSourceSnapshot.ready(
                      nodes: nodes,
                      guidance: guidance,
                    ),
            );
          case skir.RealmPresentationSearchUpdate_unavailableErrorWrapper(
            :final value,
          ):
            if (value.subscriptionId != subscriptionId) return;
            emit(
              _searchError(
                providerPath,
                value.diagnostics.firstOrNull?.message ??
                    "Realm search is unavailable",
              ),
            );
          case skir.RealmPresentationSearchUpdate_staleObservationErrorWrapper():
            emit(
              _searchError(
                providerPath,
                "Saved resources changed. Review the operation input",
              ),
            );
          case skir.RealmPresentationSearchUpdate_internalErrorWrapper():
            emit(_searchError(providerPath, "Realm search is unavailable"));
          case skir.RealmPresentationSearchUpdate_unknown():
            emit(
              _searchError(
                providerPath,
                "Realm search returned an unknown update",
              ),
            );
        }
      },
      onError: (Object error) {
        if (!disposed && generation == _generation) {
          emit(_searchError(providerPath, "Realm search failed: $error"));
        }
      },
    );
    if (disposed || generation != _generation) {
      await owned.cancel();
      return;
    }
    _subscription = owned;
  }

  @override
  void dispose() {
    _generation++;
    final subscription = _subscription;
    _subscription = null;
    unawaited(subscription?.cancel());
    super.dispose();
  }
}

extension _PortableRealmSearchQuery on SearchQueryContext {
  skir.RealmSearchQuery get realmQuery => skir.RealmSearchQuery(
    normalizedQuery: normalizedQuery,
    selectors: [
      for (final selector in selectors)
        skir.RealmSearchSelector(
          selectorId: selector.selectorId,
          key: selector.key,
          value: selector.value,
        ),
    ],
    selectorExpression: selectorExpression?.realmExpression,
    terms: terms,
  );
}

extension _PortableRealmSelectorExpression on SearchSelectorExpression {
  skir.RealmSearchSelectorExpression get realmExpression => switch (this) {
    SearchSelectorLeafExpression(:final selector) =>
      skir.RealmSearchSelectorExpression.createSelector(
        selectorId: selector.selectorId,
        key: selector.key,
        value: selector.value,
      ),
    SearchSelectorBinaryExpression(
      :final operator,
      :final left,
      :final right,
    ) =>
      skir.RealmSearchSelectorExpression.createBinary(
        operator_: operator == SearchSelectorOperator.and
            ? skir.RealmSearchSelectorOperator.and
            : skir.RealmSearchSelectorOperator.or,
        left: left.realmExpression,
        right: right.realmExpression,
      ),
    SearchSelectorNotExpression(:final expression) =>
      skir.RealmSearchSelectorExpression.createNot(
        expression: expression.realmExpression,
      ),
  };
}
