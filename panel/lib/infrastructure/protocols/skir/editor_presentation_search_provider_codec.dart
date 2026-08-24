part of "editor_presentation_codec.dart";

extension SkirPresentationSearchProviderDecoder on SkirPresentationDecoder {
  TypeResult<SearchProvider> _searchProvider(wire.SearchProvider value) =>
      switch (value) {
        wire.SearchProvider_collectionWrapper(:final value) =>
          _collectionSearchProvider(value),
        wire.SearchProvider_staticValuesWrapper(:final value) =>
          _staticSearchProvider(value),
        wire.SearchProvider_httpJsonWrapper(:final value) =>
          _httpSearchProvider(value),
        wire.SearchProvider_realmCallbackWrapper(:final value) =>
          _realmSearchProvider(value),
        wire.SearchProvider_gateWrapper(:final value) => combineThreeResults(
          expressions.decode(value.condition),
          _optionalExpression(value.guidance),
          _searchProvider(value.child),
          (condition, guidance, child) => SearchProvider.gate(
            condition: condition,
            guidance: guidance,
            child: child,
          ),
        ),
        wire.SearchProvider_debounceWrapper(:final value) =>
          value.durationMilliseconds < 0
              ? invalidWire("Debounce duration must not be negative")
              : _searchProvider(value.child).mapValue(
                  (child) => SearchProvider.debounce(
                    duration: Duration(
                      milliseconds: value.durationMilliseconds,
                    ),
                    child: child,
                  ),
                ),
        wire.SearchProvider_cacheWrapper(:final value) =>
          value.capacity <= 0
              ? invalidWire("Cache capacity must be positive")
              : _searchProvider(value.child).mapValue(
                  (child) => SearchProvider.cache(
                    capacity: value.capacity,
                    retainStaleResults: value.retainStaleResults,
                    child: child,
                  ),
                ),
        wire.SearchProvider_rankWrapper(:final value) => _rankedSearchProvider(
          value,
        ),
        wire.SearchProvider_limitWrapper(:final value) => combineResults(
          expressions.decode(value.maximum),
          _searchProvider(value.child),
          (maximum, child) =>
              SearchProvider.limit(maximum: maximum, child: child),
        ),
        wire.SearchProvider_distinctWrapper(:final value) => _searchProvider(
          value.child,
        ).mapValue((child) => SearchProvider.distinct(child: child)),
        wire.SearchProvider_historyWrapper(:final value) =>
          _historicalSearchProvider(value),
        wire.SearchProvider_sectionWrapper(:final value) =>
          _sectionSearchProvider(value),
        wire.SearchProvider_mergeWrapper(:final value) => _mergedSearchProvider(
          value,
        ),
        wire.SearchProvider_unknown() => invalidWire("Unknown search provider"),
      };

  TypeResult<SearchProvider> _collectionSearchProvider(
    wire.CollectionSearchProvider value,
  ) {
    if (value.sourceId.isEmpty) {
      return invalidWire("Collection source ID is empty");
    }
    final result = _searchResultMapping(value.result);
    final where = _optionalExpression(value.where);
    final selectors = _decodeSearchList(value.selectors, _searchSelector);
    return combineThreeResults(
      result,
      where,
      selectors,
      (result, where, selectors) => SearchProvider.collection(
        sourceId: PresentationCollectionSourceId(value.sourceId),
        result: result,
        where: where,
        selectors: selectors,
      ),
    );
  }

  TypeResult<SearchProvider> _staticSearchProvider(
    wire.StaticSearchProvider value,
  ) {
    final selectors = _decodeSearchList(value.selectors, _searchSelector);
    return combineThreeResults(
      expressions.decode(value.values),
      _searchResultMapping(value.result),
      selectors,
      (values, result, selectors) => SearchProvider.staticValues(
        values: values,
        result: result,
        selectors: selectors,
      ),
    );
  }

  TypeResult<SearchProvider> _httpSearchProvider(
    wire.HttpJsonSearchProvider value,
  ) {
    final uri = expressions.decode(value.uri);
    final parameters = _decodeSearchList(value.parameters, _httpQueryParameter);
    final resultType = types.decodeExpression(value.resultType);
    final result = _searchResultMapping(value.result);
    final context = _decodeSearchList(
      value.contextBindings,
      _httpContextBinding,
    );
    final selectors = _decodeSearchList(value.selectors, _searchSelector);
    final diagnostics = [
      ...uri.diagnostics,
      ...parameters.diagnostics,
      ...resultType.diagnostics,
      ...result.diagnostics,
      ...context.diagnostics,
      ...selectors.diagnostics,
    ];
    if (value.resultPath.isEmpty) {
      diagnostics.add(wireDiagnostic("HTTP result path is empty"));
    }
    if (value.timeoutMilliseconds < 0) {
      diagnostics.add(wireDiagnostic("HTTP timeout must not be negative"));
    }
    return diagnostics.isEmpty
        ? TypeResult.success(
            SearchProvider.httpJson(
              uri: uri.valueOrNull!,
              parameters: parameters.valueOrNull!,
              resultPath: value.resultPath,
              resultType: resultType.valueOrNull!,
              result: result.valueOrNull!,
              contextBindings: context.valueOrNull!,
              selectors: selectors.valueOrNull!,
              timeout: Duration(milliseconds: value.timeoutMilliseconds),
            ),
          )
        : TypeResult.failure(diagnostics);
  }

  TypeResult<SearchProvider> _realmSearchProvider(
    wire.RealmCallbackSearchProvider value,
  ) {
    final capabilityId = value.capabilityId.value.isEmpty
        ? invalidWire<CapabilityId>("Realm search capability ID is empty")
        : TypeResult.success(CapabilityId(value.capabilityId.value));
    final selectors = _decodeSearchList(value.selectors, _searchSelector);
    final payload = expressions.decode(value.payload);
    final result = _searchResultMapping(value.result);
    final diagnostics = [
      ...capabilityId.diagnostics,
      ...payload.diagnostics,
      ...result.diagnostics,
      ...selectors.diagnostics,
    ];
    return diagnostics.isEmpty
        ? TypeResult.success(
            SearchProvider.realmCallback(
              capabilityId: capabilityId.valueOrNull!,
              payload: payload.valueOrNull!,
              result: result.valueOrNull!,
              selectors: selectors.valueOrNull!,
            ),
          )
        : TypeResult.failure(diagnostics);
  }

  TypeResult<SearchProvider> _rankedSearchProvider(
    wire.RankedSearchProvider value,
  ) {
    if (value.fields.isEmpty) return invalidWire("Ranking fields are empty");
    return combineResults(
      _decodeSearchList(value.fields, _searchRankingField),
      _searchProvider(value.child),
      (fields, child) => SearchProvider.rank(fields: fields, child: child),
    );
  }

  TypeResult<SearchProvider> _historicalSearchProvider(
    wire.HistoricalSearchProvider value,
  ) {
    if (value.historyKey.isEmpty) return invalidWire("History key is empty");
    if (value.capacity <= 0) return invalidWire("History capacity is invalid");
    return combineResults(
      expressions.decode(value.label),
      _searchProvider(value.child),
      (label, child) => SearchProvider.history(
        key: value.historyKey,
        label: label,
        capacity: value.capacity,
        child: child,
      ),
    );
  }

  TypeResult<SearchProvider> _sectionSearchProvider(
    wire.SectionSearchProvider value,
  ) {
    if (value.sectionId.isEmpty) return invalidWire("Section ID is empty");
    return combineResults(
      expressions.decode(value.label),
      _searchProvider(value.child),
      (label, child) => SearchProvider.section(
        id: value.sectionId,
        label: label,
        child: child,
      ),
    );
  }

  TypeResult<SearchProvider> _mergedSearchProvider(
    wire.MergedSearchProvider value,
  ) {
    if (value.children.isEmpty) {
      return invalidWire("Merged providers are empty");
    }
    return _decodeSearchList(
      value.children,
      _searchProvider,
    ).mapValue((children) => SearchProvider.merge(children: children));
  }
}
