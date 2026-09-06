part of "editor_presentation_encoder.dart";

extension SkirPresentationSearchProviderEncoder on SkirPresentationEncoder {
  TypeResult<wire.SearchProvider> _searchProvider(SearchProvider value) =>
      switch (value) {
        CollectionSearchProvider() => combineThreeResults(
          _searchResultMapping(value.result),
          _optional(value.where),
          TypeResult.success(value.selectors.map(_searchSelector)),
          (result, where, selectors) => wire.SearchProvider.createCollection(
            sourceId: value.sourceId.value,
            result: result,
            where: where,
            selectors: selectors,
          ),
        ),
        StaticSearchProvider() => combineResults(
          expressions.encode(value.values),
          _searchResultMapping(value.result),
          (values, result) => wire.SearchProvider.createStaticValues(
            values: values,
            result: result,
            selectors: value.selectors.map(_searchSelector),
          ),
        ),
        HttpJsonSearchProvider() => _httpSearchProvider(value),
        RealmCallbackSearchProvider() => _realmSearchProvider(value),
        GatedSearchProvider() => combineThreeResults(
          expressions.encode(value.condition),
          _optional(value.guidance),
          _searchProvider(value.child),
          (condition, guidance, child) => wire.SearchProvider.createGate(
            condition: condition,
            guidance: guidance,
            child: child,
          ),
        ),
        DebouncedSearchProvider() => _searchProvider(value.child).mapValue(
          (child) => wire.SearchProvider.createDebounce(
            durationMilliseconds: value.duration.inMilliseconds,
            child: child,
          ),
        ),
        CachedSearchProvider() => _searchProvider(value.child).mapValue(
          (child) => wire.SearchProvider.createCache(
            capacity: value.capacity,
            retainStaleResults: value.retainStaleResults,
            child: child,
          ),
        ),
        RankedSearchProvider() => combineResults(
          _encodeSearchList(value.fields, _searchRankingField),
          _searchProvider(value.child),
          (fields, child) =>
              wire.SearchProvider.createRank(fields: fields, child: child),
        ),
        LimitedSearchProvider() => combineResults(
          expressions.encode(value.maximum),
          _searchProvider(value.child),
          (maximum, child) =>
              wire.SearchProvider.createLimit(maximum: maximum, child: child),
        ),
        DistinctSearchProvider() => _searchProvider(
          value.child,
        ).mapValue((child) => wire.SearchProvider.createDistinct(child: child)),
        HistoricalSearchProvider() => combineResults(
          expressions.encode(value.label),
          _searchProvider(value.child),
          (label, child) => wire.SearchProvider.createHistory(
            historyKey: value.key,
            label: label,
            capacity: value.capacity,
            child: child,
          ),
        ),
        SectionSearchProvider() => combineResults(
          expressions.encode(value.label),
          _searchProvider(value.child),
          (label, child) => wire.SearchProvider.createSection(
            sectionId: value.id,
            label: label,
            child: child,
          ),
        ),
        MergedSearchProvider() =>
          _encodeSearchList(value.children, _searchProvider).mapValue(
            (children) => wire.SearchProvider.createMerge(children: children),
          ),
      };

  TypeResult<wire.SearchProvider> _httpSearchProvider(
    HttpJsonSearchProvider value,
  ) {
    final uri = expressions.encode(value.uri);
    final parameters = _encodeSearchList(value.parameters, _httpQueryParameter);
    final resultType = types.encodeExpression(value.resultType);
    final result = _searchResultMapping(value.result);
    final context = _encodeSearchList(
      value.contextBindings,
      _httpContextBinding,
    );
    final diagnostics = [
      ...uri.diagnostics,
      ...parameters.diagnostics,
      ...resultType.diagnostics,
      ...result.diagnostics,
      ...context.diagnostics,
    ];
    return diagnostics.isEmpty
        ? TypeResult.success(
            wire.SearchProvider.createHttpJson(
              uri: uri.valueOrNull!,
              parameters: parameters.valueOrNull!,
              resultPath: value.resultPath,
              resultType: resultType.valueOrNull!,
              result: result.valueOrNull!,
              contextBindings: context.valueOrNull!,
              selectors: value.selectors.map(_searchSelector),
              timeoutMilliseconds: value.timeout.inMilliseconds,
            ),
          )
        : TypeResult.failure(diagnostics);
  }

  TypeResult<wire.SearchProvider> _realmSearchProvider(
    RealmCallbackSearchProvider value,
  ) {
    final payload = expressions.encode(value.payload);
    final result = _searchResultMapping(value.result);
    return combineResults(
      payload,
      result,
      (payload, result) => wire.SearchProvider.createRealmCallback(
        capabilityId: wire_type.CapabilityId(value: value.capabilityId.value),
        payload: payload,
        result: result,
        selectors: value.selectors.map(_searchSelector),
      ),
    );
  }
}
