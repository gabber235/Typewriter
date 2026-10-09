import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

const portableSearchResultType = SearchResultType(
  id: "typewriter.portable.value",
  rowRendererId: "typewriter.portable.presentation",
);

/// Compiles portable declarations into the shared search source model.
final class PortableSearchCompiler {
  const PortableSearchCompiler();

  PortableSearchBinding bindControl({
    required skir.SearchControl control,
    required PortableSearchEnvironment environment,
    required PortablePresentationHost host,
  }) {
    final committed = StreamController<SearchResult>.broadcast(sync: true);
    final evaluation = _PortableSearchEvaluation(
      environment: environment,
      queryBindingId: control.queryBindingId,
    );
    final declaredSource = _compile(
      control.provider,
      evaluation,
      committed.stream,
      "root",
    );
    final source = switch (control.customValue) {
      final custom? => [
        declaredSource,
        _PortableCustomSearchSource(
          expression: custom,
          evaluation: evaluation,
          selectors: control.provider.selectorDefinitions,
        ),
      ].merged(),
      null => declaredSource,
    };
    late final PortableSearchBinding binding;
    final activation = SearchActivation<void>.custom(
      dependencies: [host],
      evaluate: (_, result) =>
          result.payload is PortableSearchPayload &&
              host.enabled &&
              !host.readOnly
          ? const SearchActivationState.enabled()
          : const SearchActivationState.disabled(
              "This search result cannot be selected",
            ),
      activate: (_, result) async {
        final selected = await binding.choose(result);
        if (selected is PortableSearchSelectionRejected) {
          return const SearchActivationResult<void>.keepOpen();
        }
        return control.selectionMode == skir.SearchSelectionMode.single
            ? const SearchActivationResult<void>.complete(null)
            : const SearchActivationResult<void>.keepOpen();
      },
    );
    return binding = PortableSearchBinding._(
      control: control,
      environment: environment,
      host: host,
      context: environment.context,
      source: source,
      interaction: SearchInteraction(
        activation: activation,
        selectionMode:
            control.selectionMode == skir.SearchSelectionMode.multiple
            ? SearchSelectionMode.multiple
            : SearchSelectionMode.single,
      ),
      committedSelections: committed,
    );
  }

  SearchSource _compile(
    skir.SearchProvider provider,
    _PortableSearchEvaluation evaluation,
    Stream<SearchResult> committedSelections,
    String path,
  ) => switch (provider) {
    skir.SearchProvider_staticValuesWrapper(:final value) =>
      _PortableStaticSearchSource(
        provider: value,
        evaluation: evaluation,
        providerPath: "$path.static",
      ),
    skir.SearchProvider_httpJsonWrapper(:final value) =>
      _PortableHttpSearchSource(
        provider: value,
        evaluation: evaluation,
        providerPath: "$path.http",
      ),
    skir.SearchProvider_realmCallbackWrapper(:final value) =>
      _PortableRealmSearchSource(
        provider: value,
        evaluation: evaluation,
        providerPath: "$path.realm",
      ),
    skir.SearchProvider_collectionWrapper(:final value) =>
      _PortableCollectionSearchSource(
        provider: value,
        evaluation: evaluation,
        providerPath: "$path.collection",
      ),
    skir.SearchProvider_gateWrapper(:final value) =>
      _compile(
        value.child,
        evaluation,
        committedSelections,
        "$path.gate",
      ).gated(
        (query) => _boolean(
          evaluation.evaluate(
            value.condition,
            query: query,
            selectors: value.child.selectorDefinitions,
          ),
        ),
        closedGuidance: (query) {
          final guidance = value.guidance;
          return SearchGuidance(
            id: "$path.gate.closed",
            title: guidance == null
                ? "Search is unavailable for the current value"
                : _text(
                        evaluation.evaluate(
                          guidance,
                          query: query,
                          selectors: value.child.selectorDefinitions,
                        ),
                      ) ??
                      "Search is unavailable for the current value",
          );
        },
      ),
    skir.SearchProvider_debounceWrapper(:final value) =>
      _compile(
        value.child,
        evaluation,
        committedSelections,
        "$path.debounce",
      ).debounced(
        Duration(milliseconds: value.durationMilliseconds.clamp(0, 60000)),
      ),
    skir.SearchProvider_cacheWrapper(:final value) =>
      _compile(
        value.child,
        evaluation,
        committedSelections,
        "$path.cache",
      ).cached(
        capacity: value.capacity.clamp(1, 100000),
        retainStaleResults: value.retainStaleResults,
      ),
    skir.SearchProvider_rankWrapper(:final value) =>
      _compile(
        value.child,
        evaluation,
        committedSelections,
        "$path.rank",
      ).ranked([
        for (final field in value.fields)
          SearchRankField(
            weight: field.weight.clamp(1, 100000),
            text: (result) => evaluation.resultText(
              result,
              field.expression,
              value.child.selectorDefinitions,
            ),
          ),
      ]),
    skir.SearchProvider_limitWrapper(:final value) =>
      _PortableLimitedSearchSource(
        source: _compile(
          value.child,
          evaluation,
          committedSelections,
          "$path.limit",
        ),
        maximum: (query) => _integer(
          evaluation.evaluate(
            value.maximum,
            query: query,
            selectors: value.child.selectorDefinitions,
          ),
        ),
      ),
    skir.SearchProvider_distinctWrapper(:final value) => _compile(
      value.child,
      evaluation,
      committedSelections,
      "$path.distinct",
    ).distinct(by: (result) => result.portableDistinctKey),
    skir.SearchProvider_historyWrapper(:final value) =>
      _compile(
        value.child,
        evaluation,
        committedSelections,
        "$path.history",
      ).withHistory(
        key:
            "${evaluation.environment.historyNamespace}:${evaluation.environment.context.catalogGeneration.value}:${value.historyKey}:$path",
        label:
            _text(
              evaluation.evaluate(
                value.label,
                query: SearchQueryContext.empty,
                selectors: value.child.selectorDefinitions,
              ),
            ) ??
            "Recent",
        capacity: value.capacity.clamp(1, 100000),
        storage: evaluation.environment.historyStorage,
        committedSelections: committedSelections.where(
          (selection) => selection.belongsToProviderSubtree("$path.history"),
        ),
      ),
    skir.SearchProvider_sectionWrapper(:final value) =>
      _PortableSectionSearchSource(
        source: _compile(
          value.child,
          evaluation,
          committedSelections,
          "$path.section",
        ),
        id: value.sectionId,
        title: (query) =>
            _text(
              evaluation.evaluate(
                value.label,
                query: query,
                selectors: value.child.selectorDefinitions,
              ),
            ) ??
            value.sectionId,
      ),
    skir.SearchProvider_mergeWrapper(:final value) =>
      value.children.isEmpty
          ? _PortableUnavailableSearchSource(
              message: "The search provider has no sources",
            )
          : value.children.indexed
                .map(
                  (entry) => _compile(
                    entry.$2,
                    evaluation,
                    committedSelections,
                    "$path.merge.${entry.$1}",
                  ),
                )
                .merged(),
    skir.SearchProvider_unknown() => _PortableUnavailableSearchSource(
      message: "The search provider is unknown",
    ),
  };
}

extension on SearchResult {
  Object get portableDistinctKey => switch (payload) {
    PortableMappedSearchPayload(:final distinctKey) => distinctKey,
    PortableCustomSearchPayload(:final selectedValue) => canonicalAuthoredValue(
      selectedValue,
    ),
    _ => id,
  };

  bool belongsToProviderSubtree(String root) {
    final providerPath = switch (payload) {
      PortableSearchPayload(:final providerPath) => providerPath,
      _ => null,
    };
    return providerPath == root || providerPath?.startsWith("$root.") == true;
  }
}

/// Owns one compiled source graph and its committed selection stream.
final class PortableSearchBinding {
  PortableSearchBinding._({
    required this.control,
    required this.environment,
    required this.host,
    required this.context,
    required this.source,
    required this.interaction,
    required this._committedSelections,
  });

  final skir.SearchControl control;
  final PortableSearchEnvironment environment;
  final PortablePresentationHost host;
  final PortableInvocationContext context;
  final SearchSource source;
  final SearchInteraction<void> interaction;
  final StreamController<SearchResult> _committedSelections;
  final ValueNotifier<String?> feedback = ValueNotifier(null);
  bool _disposed = false;

  SearchSession<void> session({String initialQuery = ""}) => SearchSession(
    source: source,
    interaction: interaction,
    initialQuery: initialQuery,
  );

  Future<PortableSearchSelectionResult> choose(SearchResult result) async {
    if (_disposed || result.payload is! PortableSearchPayload) {
      return const PortableSearchSelectionResult.rejected(
        "This search result is unavailable",
      );
    }
    if (context.catalogGeneration !=
        host.document.catalog.snapshot.generation) {
      const rejected = PortableSearchSelectionResult.rejected(
        "The editor catalog changed",
      );
      feedback.value = "The editor catalog changed";
      return rejected;
    }
    final payload = result.payload as PortableSearchPayload;
    final selectedValue = switch (payload) {
      PortableMappedSearchPayload(:final selectedValue) => selectedValue,
      PortableCustomSearchPayload(:final selectedValue) => selectedValue,
    };
    final selection = control.selectionMode == skir.SearchSelectionMode.multiple
        ? await _toggle(selectedValue)
        : (outcome: await _write(selectedValue), added: true);
    switch (selection.outcome) {
      case PortablePresentationWriteApplied():
        if (!_disposed) {
          feedback.value = null;
          if (selection.added) _committedSelections.add(result);
        }
        return PortableSearchSelectionResult.applied(added: selection.added);
      case PortablePresentationWriteRejected(:final message):
        if (!_disposed) feedback.value = message;
        return PortableSearchSelectionResult.rejected(message);
    }
  }

  Future<PortablePresentationWriteResult> _write(skir.DataValue selected) =>
      host.write(control.control.binding, selected, context: context);

  Future<({PortablePresentationWriteResult outcome, bool added})> _toggle(
    skir.DataValue selected,
  ) async {
    final current = host.read(control.control.binding, context: context);
    final items = current?.authoredItems?.toList();
    if (items == null) {
      return (
        outcome: const PortablePresentationWriteRejected(
          "The selected binding is not a collection",
        ),
        added: false,
      );
    }
    final key = canonicalAuthoredValue(selected);
    final existing = items
        .where((item) => canonicalAuthoredValue(item.value) == key)
        .firstOrNull;
    final action = existing == null
        ? skir.LocalEditorAction.createInsertListItem(
            target: control.control.binding,
            after: items.lastOrNull?.id,
            value: skir.ExpressionNode.wrapLiteral(selected),
          )
        : skir.LocalEditorAction.createRemoveListItem(
            target: control.control.binding,
            item: existing.id,
          );
    return (
      outcome: await host.execute(
        skir.EditorAction.wrapLocal(action),
        context: context,
      ),
      added: existing == null,
    );
  }

  PortablePresentationScope resultScope(
    SearchResult result,
    PortablePresentationScope base,
  ) {
    return switch (result.payload as PortableSearchPayload) {
      PortableMappedSearchPayload(:final mapping, :final sourceValue) =>
        base.withValues({mapping.bindingId: sourceValue}),
      PortableCustomSearchPayload() => base,
    };
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    unawaited(_committedSelections.close());
    feedback.dispose();
  }
}

final class _PortableSearchEvaluation {
  const _PortableSearchEvaluation({
    required this.environment,
    required this.queryBindingId,
  });

  final PortableSearchEnvironment environment;
  final skir.ExpressionBindingId queryBindingId;
  PortableExpressionResult evaluate(
    skir.ExpressionNode expression, {
    required SearchQueryContext query,
    required Iterable<skir.SearchSelectorDefinition> selectors,
    skir.ExpressionBindingId? rowBinding,
    skir.DataValue? rowValue,
  }) => environment.evaluate(
    expression,
    query: query,
    queryBindingId: queryBindingId,
    selectors: selectors,
    rowBinding: rowBinding,
    rowValue: rowValue,
  );

  String? resultText(
    SearchResult result,
    skir.ExpressionNode expression,
    Iterable<skir.SearchSelectorDefinition> selectors,
  ) {
    final payload = result.payload;
    if (payload is! PortableSearchPayload) return null;
    return switch (payload) {
      PortableMappedSearchPayload(
        :final query,
        :final mapping,
        :final sourceValue,
      ) =>
        _text(
          evaluate(
            expression,
            query: query,
            selectors: selectors,
            rowBinding: mapping.bindingId,
            rowValue: sourceValue,
          ),
        ),
      PortableCustomSearchPayload() => result.title,
    };
  }

  SearchResult? mapResult(
    skir.DataValue source,
    skir.SearchResultMapping mapping,
    SearchQueryContext query,
    Iterable<skir.SearchSelectorDefinition> selectors,
    String providerPath,
  ) {
    final key = evaluate(
      mapping.key,
      query: query,
      selectors: selectors,
      rowBinding: mapping.bindingId,
      rowValue: source,
    );
    final selected = evaluate(
      mapping.selectedValue,
      query: query,
      selectors: selectors,
      rowBinding: mapping.bindingId,
      rowValue: source,
    );
    if (key is! PortableExpressionAvailable ||
        selected is! PortableExpressionAvailable) {
      return null;
    }
    final label = mapping.label == null
        ? _dataText(selected.value)
        : _text(
            evaluate(
              mapping.label!,
              query: query,
              selectors: selectors,
              rowBinding: mapping.bindingId,
              rowValue: source,
            ),
          );
    final distinctKey = canonicalAuthoredValue(key.value);
    final result = SearchResult(
      id: "$providerPath:$distinctKey",
      type: portableSearchResultType,
      payload: PortableSearchPayload.mapped(
        sourceValue: source,
        selectedValue: selected.value,
        mapping: mapping,
        providerPath: providerPath,
        distinctKey: distinctKey,
        query: query,
      ),
      title: label ?? "Result",
    );
    return result;
  }
}

final class _PortableCustomSearchSource implements SearchSource {
  _PortableCustomSearchSource({
    required this.expression,
    required this.evaluation,
    required Iterable<skir.SearchSelectorDefinition> selectors,
  }) : selectorDefinitions = List.unmodifiable(selectors),
       selectors = List.unmodifiable(selectors.map(_querySelector));

  final skir.ExpressionNode expression;
  final _PortableSearchEvaluation evaluation;
  final List<skir.SearchSelectorDefinition> selectorDefinitions;
  @override
  final List<QuerySelectorDefinition> selectors;
  final StreamController<SearchSourceSnapshot> _snapshots =
      StreamController.broadcast(sync: true);

  @override
  Stream<SearchSourceSnapshot> get snapshots => _snapshots.stream;

  @override
  void initialize(SearchQueryContext context) => search(context);

  @override
  void search(SearchQueryContext context) {
    if (context.normalizedQuery.isEmpty) {
      _snapshots.add(SearchSourceSnapshot.ready(nodes: const []));
      return;
    }
    final evaluated = evaluation.evaluate(
      expression,
      query: context,
      selectors: selectorDefinitions,
    );
    if (evaluated is! PortableExpressionAvailable) {
      _snapshots.add(SearchSourceSnapshot.ready(nodes: const []));
      return;
    }
    _snapshots.add(
      SearchSourceSnapshot.ready(
        nodes: [
          SearchNode.result(
            result: SearchResult(
              id: "custom:${canonicalAuthoredValue(evaluated.value)}",
              type: portableSearchResultType,
              payload: PortableSearchPayload.custom(
                selectedValue: evaluated.value,
                providerPath: "custom",
                query: context,
              ),
              title: context.normalizedQuery,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Future<SearchPreviewRequestResult> preview(SearchPreviewRequest request) =>
      Future.value(
        const SearchPreviewRequestResult.error(
          message: "Custom values have no separate preview",
        ),
      );

  @override
  void dispose() => unawaited(_snapshots.close());
}

abstract base class _PortableLeafSearchSource implements SearchSource {
  _PortableLeafSearchSource({
    required this.evaluation,
    required this.providerPath,
    required Iterable<skir.SearchSelectorDefinition> selectorDefinitions,
  }) : selectorDefinitions = List.unmodifiable(selectorDefinitions),
       selectors = List.unmodifiable(selectorDefinitions.map(_querySelector));

  final _PortableSearchEvaluation evaluation;
  final String providerPath;
  final List<skir.SearchSelectorDefinition> selectorDefinitions;
  @override
  final List<QuerySelectorDefinition> selectors;
  final StreamController<SearchSourceSnapshot> _snapshots =
      StreamController.broadcast(sync: true);
  bool disposed = false;

  @override
  Stream<SearchSourceSnapshot> get snapshots => _snapshots.stream;

  @override
  void initialize(SearchQueryContext context) => search(context);

  @override
  Future<SearchPreviewRequestResult> preview(SearchPreviewRequest request) =>
      Future.value(
        const SearchPreviewRequestResult.error(
          message: "Portable search results have no separate preview",
        ),
      );

  void emit(SearchSourceSnapshot snapshot) {
    if (!disposed) _snapshots.add(snapshot);
  }

  List<SearchNode> mapValues(
    Iterable<skir.DataValue> values,
    skir.SearchResultMapping mapping,
    SearchQueryContext query,
  ) => values
      .map(
        (value) => evaluation.mapResult(
          value,
          mapping,
          query,
          selectorDefinitions,
          providerPath,
        ),
      )
      .nonNulls
      .map((result) => SearchNode.result(result: result))
      .toList(growable: false);

  @override
  void dispose() {
    if (disposed) return;
    disposed = true;
    unawaited(_snapshots.close());
  }
}

final class _PortableStaticSearchSource extends _PortableLeafSearchSource {
  _PortableStaticSearchSource({
    required this.provider,
    required super.evaluation,
    required super.providerPath,
  }) : super(selectorDefinitions: provider.selectors);

  final skir.StaticSearchProvider provider;

  @override
  void search(SearchQueryContext context) {
    final result = evaluation.evaluate(
      provider.values,
      query: context,
      selectors: selectorDefinitions,
    );
    if (result case PortableExpressionAvailable(:final value)) {
      final items = value.authoredItems;
      if (items != null) {
        emit(
          SearchSourceSnapshot.ready(
            nodes: mapValues(
              items.map((item) => item.value),
              provider.result,
              context,
            ),
          ),
        );
        return;
      }
    }
    emit(_searchError(providerPath, "Static search values are unavailable"));
  }
}

final class _PortableCollectionSearchSource extends _PortableLeafSearchSource {
  _PortableCollectionSearchSource({
    required this.provider,
    required super.evaluation,
    required super.providerPath,
  }) : super(selectorDefinitions: provider.selectors);

  final skir.CollectionSearchProvider provider;

  @override
  void search(SearchQueryContext context) {
    final environment = evaluation.environment;
    final host = environment.collectionHost;
    final material = environment.material;
    if (host == null || material == null) {
      emit(_searchError(providerPath, "Collection search is unavailable"));
      return;
    }
    final projection = host.projectCollection(
      provider.sourceId,
      material: material,
      context: environment.context,
    );
    if (projection.problem case final problem?) {
      emit(_searchError(providerPath, problem));
      return;
    }
    final rows = provider.where == null
        ? projection.rows
        : projection.rows.where((row) {
            return _boolean(
              evaluation.evaluate(
                provider.where!,
                query: context,
                selectors: selectorDefinitions,
                rowBinding: provider.result.bindingId,
                rowValue: row.row,
              ),
            );
          });
    emit(
      SearchSourceSnapshot.ready(
        nodes: mapValues(rows.map((row) => row.row), provider.result, context),
      ),
    );
  }
}

final class _PortableHttpSearchSource extends _PortableLeafSearchSource {
  _PortableHttpSearchSource({
    required this.provider,
    required super.evaluation,
    required super.providerPath,
  }) : super(selectorDefinitions: provider.selectors);

  final skir.HttpJsonSearchProvider provider;
  var _generation = 0;

  @override
  void search(SearchQueryContext context) {
    final generation = ++_generation;
    emit(SearchSourceSnapshot.loading());
    unawaited(_load(context, generation));
  }

  Future<void> _load(SearchQueryContext context, int generation) async {
    try {
      final uriText = _text(
        evaluation.evaluate(
          provider.uri,
          query: context,
          selectors: selectorDefinitions,
        ),
      );
      if (uriText == null) {
        throw const FormatException("Search URI must evaluate to text");
      }
      final original = Uri.parse(uriText);
      if (original.scheme != "https" || original.host.isEmpty) {
        throw const FormatException("Search URI must use HTTPS");
      }
      final parameters = Map<String, String>.of(original.queryParameters);
      for (final parameter in provider.parameters) {
        final value = evaluation.evaluate(
          parameter.value,
          query: context,
          selectors: selectorDefinitions,
        );
        if (value is! PortableExpressionAvailable) {
          throw FormatException(
            "Search parameter ${parameter.name} is unavailable",
          );
        }
        final text = _dataText(value.value) ?? "";
        if (!parameter.omitIfEmpty || text.isNotEmpty) {
          parameters[parameter.name] = text;
        }
      }
      final uri = parameters.isEmpty
          ? original
          : original.replace(queryParameters: parameters);
      final response = await evaluation.environment.http
          .get(uri, headers: const {"Accept": "application/json"})
          .timeout(
            Duration(
              milliseconds: provider.timeoutMilliseconds.clamp(1, 60000),
            ),
          );
      if (disposed || generation != _generation) return;
      final responseUri = response.request?.url ?? uri;
      if (responseUri.scheme != "https") {
        throw const FormatException("Search redirects must remain on HTTPS");
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw FormatException(
          "Search request returned status ${response.statusCode}",
        );
      }
      final document = jsonDecode(utf8.decode(response.bodyBytes));
      final catalog = evaluation.environment.catalog;
      final extraBindings =
          <skir.ExpressionBindingId, PortableExpressionBinding>{};
      for (final binding in provider.contextBindings) {
        final values = JsonPath(binding.path).readValues(document).toList();
        final expected = catalog.concreteType(binding.valueType);
        if (expected == null) {
          throw FormatException(
            "Search context ${binding.bindingId.value} has an incomplete type",
          );
        }
        extraBindings[binding.bindingId] = PortableExpressionBinding(
          value: _decodePortableJson(
            values.length == 1 ? values.single : values,
            expected,
            catalog,
            r"$",
          ),
        );
      }
      final expected = catalog.concreteType(provider.resultType);
      if (expected == null) {
        throw const FormatException("Search result type is incomplete");
      }
      final values = <skir.DataValue>[];
      final guidance = <SearchGuidance>[];
      for (final (index, source) in JsonPath(
        provider.resultPath,
      ).readValues(document).indexed) {
        try {
          values.add(
            _decodePortableJson(
              source,
              expected,
              catalog,
              r"$.results"
              "[$index]",
            ),
          );
        } on FormatException catch (error) {
          guidance.add(
            SearchGuidance(
              id: "$providerPath.invalid.$index",
              title: error.message,
            ),
          );
        }
      }
      if (disposed || generation != _generation) return;
      emit(
        SearchSourceSnapshot.ready(
          nodes: _mapHttpValues(values, context, extraBindings),
          guidance: guidance,
        ),
      );
    } on TimeoutException {
      if (!disposed && generation == _generation) {
        emit(_searchError(providerPath, "Search request timed out"));
      }
    } on FormatException catch (error) {
      if (!disposed && generation == _generation) {
        emit(_searchError(providerPath, error.message));
      }
    } on Object catch (error) {
      if (!disposed && generation == _generation) {
        emit(_searchError(providerPath, "Search provider failed: $error"));
      }
    }
  }

  List<SearchNode> _mapHttpValues(
    Iterable<skir.DataValue> values,
    SearchQueryContext query,
    Map<skir.ExpressionBindingId, PortableExpressionBinding> extraBindings,
  ) {
    if (extraBindings.isEmpty) return mapValues(values, provider.result, query);
    final environment = evaluation.environment;
    final scoped = PortableSearchEnvironment(
      catalog: environment.catalog,
      budget: environment.budget,
      context: environment.context.withBindings(extraBindings),
      http: environment.http,
      historyStorage: environment.historyStorage,
      historyNamespace: environment.historyNamespace,
      watchRealm: environment.watchRealm,
      collectionHost: environment.collectionHost,
      material: environment.material,
    );
    final mapper = _PortableSearchEvaluation(
      environment: scoped,
      queryBindingId: evaluation.queryBindingId,
    );
    return values
        .map(
          (value) => mapper.mapResult(
            value,
            provider.result,
            query,
            selectorDefinitions,
            providerPath,
          ),
        )
        .nonNulls
        .map((result) => SearchNode.result(result: result))
        .toList(growable: false);
  }

  @override
  void dispose() {
    _generation++;
    super.dispose();
  }
}

skir.DataValue _decodePortableJson(
  Object? source,
  skir.TypeUse expected,
  CheckedEditorCatalog catalog,
  String path,
) {
  if (expected case skir.TypeUse_nullableWrapper(:final value)) {
    if (source == null) return skir.DataValue.null_;
    return _decodePortableJson(source, value.value, catalog, path);
  }
  return switch (expected) {
    skir.TypeUse_scalarWrapper(:final value) => _decodePortableJsonScalar(
      source,
      value,
      path,
    ),
    skir.TypeUse_namedWrapper(:final value) => _decodePortableJsonNamed(
      source,
      value,
      catalog,
      path,
    ),
    _ => throw FormatException("Expected a complete authored type at $path"),
  };
}

skir.DataValue _decodePortableJsonNamed(
  Object? source,
  skir.NamedTypeUse expected,
  CheckedEditorCatalog catalog,
  String path,
) {
  final published = catalog.published(expected.definition);
  if (published == null || published.status != skir.DeclarationStatus.ready) {
    throw FormatException("Expected an available named type at $path");
  }
  final containing = skir.TypeSelection.wrapComplete(expected);
  final payload = switch (published.definition.representation) {
    skir.RepresentationTemplate_scalarWrapper(:final value) =>
      _decodePortableJsonScalar(source, value.kind, path),
    skir.RepresentationTemplate_recordWrapper() => _decodePortableJsonRecord(
      source,
      containing,
      catalog,
      path,
    ),
    skir.RepresentationTemplate_sequenceWrapper(:final value) =>
      _decodePortableJsonSequence(source, value, containing, catalog, path),
    skir.RepresentationTemplate_mappingWrapper(:final value) =>
      _decodePortableJsonMapping(source, value, containing, catalog, path),
    skir.RepresentationTemplate_enumerationWrapper(:final value) =>
      _decodePortableJsonEnumeration(source, value, path),
    skir.RepresentationTemplate_linkWrapper(:final value) =>
      _decodePortableJsonLink(source, value, path),
    _ => throw FormatException("Expected a supported named type at $path"),
  };
  return skir.DataValue.createNamed(actualType: expected, payload: payload);
}

skir.DataValue _decodePortableJsonScalar(
  Object? source,
  skir.ScalarKind kind,
  String path,
) {
  if (kind == skir.ScalarKind.unit && source == null) {
    return skir.DataValue.unit;
  }
  if (kind == skir.ScalarKind.boolean && source is bool) {
    return skir.DataValue.wrapBoolean(source);
  }
  if (kind == skir.ScalarKind.text && source is String) {
    return skir.DataValue.wrapStringValue(source);
  }
  if (kind == skir.ScalarKind.bytes && source is String) {
    try {
      return skir.DataValue.wrapBytes(
        skir.ByteString.copy(base64Decode(source)),
      );
    } on FormatException {
      throw _invalidPortableJson(path, "a valid base64 string", source);
    }
  }
  if (kind case skir.ScalarKind_integerWrapper()) {
    if (source is int || source is String) {
      final value = admitPortableNumericInput(
        current: null,
        expected: skir.TypeUse.wrapScalar(kind),
        text: source.toString(),
      );
      if (value != null) return value;
    }
    throw _invalidPortableJson(path, "an integer in range", source);
  }
  if (kind case skir.ScalarKind_floatWrapper()) {
    if (source is num) {
      final value = admitPortableNumericInput(
        current: null,
        expected: skir.TypeUse.wrapScalar(kind),
        text: source.toString(),
      );
      if (value != null) return value;
    }
    throw _invalidPortableJson(path, "a finite number in range", source);
  }
  if (kind == skir.ScalarKind.decimal && (source is num || source is String)) {
    final value = admitPortableNumericInput(
      current: null,
      expected: skir.TypeUse.wrapScalar(kind),
      text: source.toString(),
    );
    if (value != null) return value;
  }
  if (kind == skir.ScalarKind.timestamp && source is String) {
    final value = DateTime.tryParse(source);
    if (value != null) return skir.DataValue.wrapTimestamp(value);
  }
  if (kind == skir.ScalarKind.duration && source is int) {
    return skir.DataValue.createDuration(
      value: skir.Duration(milliseconds: source),
    );
  }
  throw _invalidPortableJson(path, "a ${kind.runtimeType} value", source);
}

skir.DataValue _decodePortableJsonRecord(
  Object? source,
  skir.TypeSelection containing,
  CheckedEditorCatalog catalog,
  String path,
) {
  if (source is! Map<String, Object?>) {
    throw _invalidPortableJson(path, "an object", source);
  }
  final fields = catalog.fields(containing);
  final declared = fields.map((field) => field.template.key).toSet();
  final unknown = source.keys
      .where((key) => !declared.contains(key))
      .firstOrNull;
  if (unknown != null) {
    throw FormatException("Expected a declared field at $path.$unknown");
  }
  return skir.DataValue.createRecord(
    fields: [
      for (final field in fields)
        skir.FieldValue(
          name: field.template.key,
          value: _decodePortableJsonField(
            source,
            field,
            catalog,
            "$path.${field.template.key}",
          ),
        ),
    ],
  );
}

skir.DataValue _decodePortableJsonField(
  Map<String, Object?> source,
  AppliedEditorField field,
  CheckedEditorCatalog catalog,
  String path,
) {
  final type = field.type;
  if (type == null) {
    throw FormatException("Expected an available field type at $path");
  }
  if (!source.containsKey(field.template.key)) {
    if (type is skir.TypeUse_nullableWrapper) return skir.DataValue.null_;
    throw FormatException("Expected a required field at $path");
  }
  return _decodePortableJson(source[field.template.key], type, catalog, path);
}

skir.DataValue _decodePortableJsonSequence(
  Object? source,
  skir.SequenceRepresentationTemplate representation,
  skir.TypeSelection containing,
  CheckedEditorCatalog catalog,
  String path,
) {
  if (source is! List<Object?>) {
    throw _invalidPortableJson(path, "a list", source);
  }
  final itemType = catalog.applyTemplate(representation.item, containing);
  if (itemType == null) {
    throw FormatException("Expected a complete item type at $path");
  }
  final items = [
    for (final (index, item) in source.indexed)
      skir.ListItem(
        id: skir.ItemId(value: "http:$path:item:$index"),
        value: _decodePortableJson(item, itemType, catalog, "$path[$index]"),
      ),
  ];
  return representation.kind == skir.CollectionKind.list
      ? skir.DataValue.createListValue(items: items)
      : skir.DataValue.createSetValue(items: items);
}

skir.DataValue _decodePortableJsonMapping(
  Object? source,
  skir.MappingRepresentationTemplate representation,
  skir.TypeSelection containing,
  CheckedEditorCatalog catalog,
  String path,
) {
  if (source is! Map<String, Object?>) {
    throw _invalidPortableJson(path, "an object", source);
  }
  final keyType = catalog.applyTemplate(representation.key, containing);
  final valueType = catalog.applyTemplate(representation.value, containing);
  if (keyType == null || valueType == null) {
    throw FormatException("Expected complete map types at $path");
  }
  return skir.DataValue.createMapValue(
    rows: [
      for (final (index, entry) in source.entries.indexed)
        skir.MapRow(
          id: skir.ItemId(value: "http:$path:row:$index"),
          key: _decodePortableJson(
            entry.key,
            keyType,
            catalog,
            "$path.keys[$index]",
          ),
          value: _decodePortableJson(
            entry.value,
            valueType,
            catalog,
            "$path.${entry.key}",
          ),
        ),
    ],
  );
}

skir.DataValue _decodePortableJsonEnumeration(
  Object? source,
  skir.EnumerationRepresentationTemplate representation,
  String path,
) {
  if (source is String &&
      representation.cases.any((candidate) => candidate.key == source)) {
    return skir.DataValue.wrapEnumCase(source);
  }
  throw _invalidPortableJson(path, "a declared enum case", source);
}

skir.DataValue _decodePortableJsonLink(
  Object? source,
  skir.LinkRepresentationTemplate representation,
  String path,
) {
  if (source is! String || source.isEmpty) {
    throw _invalidPortableJson(path, "a resource id string", source);
  }
  return skir.DataValue.createLink(
    endpoint: representation.endpoint,
    target: skir.LinkTarget(
      resource: skir.ResourceId(value: source),
      opposite: null,
    ),
  );
}

FormatException _invalidPortableJson(
  String path,
  String expected,
  Object? actual,
) => FormatException(
  "Expected $expected at $path, got ${actual == null ? "null" : actual.runtimeType}",
);

final class _PortableUnavailableSearchSource implements SearchSource {
  _PortableUnavailableSearchSource({required this.message});

  final String message;
  final StreamController<SearchSourceSnapshot> _snapshots =
      StreamController.broadcast(sync: true);

  @override
  Stream<SearchSourceSnapshot> get snapshots => _snapshots.stream;

  @override
  List<QuerySelectorDefinition> get selectors => const [];

  @override
  void initialize(SearchQueryContext context) => search(context);

  @override
  void search(SearchQueryContext context) =>
      _snapshots.add(_searchError("unavailable", message));

  @override
  Future<SearchPreviewRequestResult> preview(SearchPreviewRequest request) =>
      Future.value(SearchPreviewRequestResult.error(message: message));

  @override
  void dispose() => unawaited(_snapshots.close());
}

final class _PortableLimitedSearchSource extends DelegatingSearchSource {
  _PortableLimitedSearchSource({required super.source, required this.maximum});

  final int? Function(SearchQueryContext query) maximum;
  int _activeMaximum = 0;

  @override
  void initialize(SearchQueryContext context) {
    _activeMaximum = maximum(context)?.clamp(0, 100000) ?? 0;
    super.initialize(context);
  }

  @override
  void search(SearchQueryContext context) {
    _activeMaximum = maximum(context)?.clamp(0, 100000) ?? 0;
    super.search(context);
  }

  @override
  void onSnapshot(SearchSourceSnapshot snapshot) => emit(
    snapshot.copyWith(nodes: _limitNodes(snapshot.nodes, _activeMaximum)),
  );
}

List<SearchNode> _limitNodes(List<SearchNode> nodes, int available) {
  if (available == 0) return const [];
  final limited = <SearchNode>[];
  var remaining = available;
  for (final node in nodes) {
    if (remaining == 0) break;
    switch (node) {
      case SearchResultNode():
        limited.add(node);
        remaining--;
      case SearchSectionNode():
        final children = _limitNodes(node.children, remaining);
        if (children.isEmpty) continue;
        limited.add(node.copyWith(children: children));
        remaining -= children.walk().whereType<SearchResultNode>().length;
    }
  }
  return limited;
}

final class _PortableSectionSearchSource extends DelegatingSearchSource {
  _PortableSectionSearchSource({
    required super.source,
    required this.id,
    required this.title,
  });

  final String id;
  final String Function(SearchQueryContext query) title;
  String _activeTitle = "";

  @override
  void initialize(SearchQueryContext context) {
    _activeTitle = title(context);
    super.initialize(context);
  }

  @override
  void search(SearchQueryContext context) {
    _activeTitle = title(context);
    super.search(context);
  }

  @override
  void onSnapshot(SearchSourceSnapshot snapshot) {
    if (snapshot.nodes.isEmpty) {
      emit(snapshot);
      return;
    }
    emit(
      snapshot.copyWith(
        nodes: [
          SearchNode.section(
            id: id,
            title: _activeTitle,
            children: snapshot.nodes,
          ),
        ],
      ),
    );
  }
}

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
          case skir.RealmPresentationSearchUpdate_unavailableWrapper(
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

extension PortableRealmSearchQuery on SearchQueryContext {
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

extension PortableRealmSelectorExpression on SearchSelectorExpression {
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

extension PortableTypeUseTemplate on skir.TypeUse {
  skir.TypeTemplate get portableTemplate => switch (this) {
    skir.TypeUse_scalarWrapper(:final value) => skir.TypeTemplate.wrapScalar(
      value,
    ),
    skir.TypeUse_nullableWrapper(:final value) =>
      skir.TypeTemplate.createNullable(value: value.value.portableTemplate),
    skir.TypeUse_namedWrapper(:final value) => skir.TypeTemplate.createNamed(
      definition: value.definition,
      arguments: value.arguments.map((argument) => argument.portableTemplate),
    ),
    skir.TypeUse_unknown() => skir.TypeTemplate.unknown,
  };
}

SearchSourceSnapshot _searchError(String id, String message) =>
    SearchSourceSnapshot.error(
      errorSummaries: [
        SearchErrorSummary(
          id: "$id.error",
          message: message,
          severity: SearchErrorSeverity.error,
        ),
      ],
    );

bool _boolean(PortableExpressionResult result) => switch (result) {
  PortableExpressionAvailable(
    value: skir.DataValue_booleanWrapper(:final value),
  ) =>
    value,
  _ => false,
};

String? _text(PortableExpressionResult result) => switch (result) {
  PortableExpressionAvailable(:final value) => _dataText(value),
  _ => null,
};

String? _dataText(skir.DataValue value) => switch (value.authoredPayload) {
  skir.DataValue_stringValueWrapper(:final value) => value,
  skir.DataValue_integerWrapper(:final value) => value,
  skir.DataValue_decimalWrapper(:final value) => value,
  skir.DataValue_floatWrapper(:final value) => value.toString(),
  skir.DataValue_booleanWrapper(:final value) => value.toString(),
  skir.DataValue_enumCaseWrapper(:final value) => value,
  _ => null,
};

int? _integer(PortableExpressionResult result) => switch (result) {
  PortableExpressionAvailable(
    value: skir.DataValue_integerWrapper(:final value),
  ) =>
    int.tryParse(value),
  _ => null,
};

QuerySelectorDefinition _querySelector(
  skir.SearchSelectorDefinition definition,
) => KeyValueSelectorDefinition(
  id: definition.selectorId,
  key: definition.key,
  caseSensitive: definition.caseSensitive,
  multiplicity:
      definition.multiplicity == skir.SearchSelectorMultiplicity.single
      ? QueryMultiplicity.single
      : QueryMultiplicity.multiple,
  color: definition.color == null ? null : Color(definition.color!),
  value: switch (definition.values) {
    skir.SearchSelectorValues_enumerationWrapper(:final value) =>
      QuerySelectorValue.enumValue(value.values.toList()),
    _ => const QuerySelectorValue.freeText(),
  },
);

extension PortableSearchProviderSelectors on skir.SearchProvider {
  List<skir.SearchSelectorDefinition> get selectorDefinitions => switch (this) {
    skir.SearchProvider_staticValuesWrapper(:final value) =>
      value.selectors.toList(),
    skir.SearchProvider_httpJsonWrapper(:final value) =>
      value.selectors.toList(),
    skir.SearchProvider_realmCallbackWrapper(:final value) =>
      value.selectors.toList(),
    skir.SearchProvider_collectionWrapper(:final value) =>
      value.selectors.toList(),
    skir.SearchProvider_gateWrapper(:final value) =>
      value.child.selectorDefinitions,
    skir.SearchProvider_debounceWrapper(:final value) =>
      value.child.selectorDefinitions,
    skir.SearchProvider_cacheWrapper(:final value) =>
      value.child.selectorDefinitions,
    skir.SearchProvider_rankWrapper(:final value) =>
      value.child.selectorDefinitions,
    skir.SearchProvider_limitWrapper(:final value) =>
      value.child.selectorDefinitions,
    skir.SearchProvider_distinctWrapper(:final value) =>
      value.child.selectorDefinitions,
    skir.SearchProvider_historyWrapper(:final value) =>
      value.child.selectorDefinitions,
    skir.SearchProvider_sectionWrapper(:final value) =>
      value.child.selectorDefinitions,
    skir.SearchProvider_mergeWrapper(:final value) => _mergeSelectors(
      value.children,
    ),
    skir.SearchProvider_unknown() => const [],
  };
}

List<skir.SearchSelectorDefinition> _mergeSelectors(
  Iterable<skir.SearchProvider> providers,
) {
  final merged = <String, skir.SearchSelectorDefinition>{};
  for (final provider in providers) {
    for (final selector in provider.selectorDefinitions) {
      merged.putIfAbsent(selector.selectorId, () => selector);
    }
  }
  return merged.values.toList(growable: false);
}
