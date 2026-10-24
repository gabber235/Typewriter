import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

part "portable_http_search_source.dart";
part "portable_realm_search_source.dart";
part "portable_search_sources.dart";

const portableSearchResultType = SearchResultType(
  id: "typewriter.portable.value",
  rowRendererId: "typewriter.portable.presentation",
);

/// Interprets catalog supplied search providers for the shared search surface.
///
/// Provider leaves read static values, projected collections, HTTP JSON or Realm
/// callbacks. Wrappers reuse the shared source decorators, preserving declared
/// composition order. Expression evaluation uses the checked catalog and
/// invocation budget captured in [PortableSearchEnvironment].
///
/// [bindControl] connects result selection to a portable editor host. Search
/// results retain source and selected values separately so presentation can
/// bind the source row while activation writes the selected value.
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
      queryBinding: control.queryBinding,
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
      _compile(
        value.child,
        evaluation,
        committedSelections,
        "$path.limit",
      ).limited(
        (query) =>
            _integer(
              evaluation.evaluate(
                value.maximum,
                query: query,
                selectors: value.child.selectorDefinitions,
              ),
            )?.clamp(0, 100000) ??
            0,
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
    skir.SearchProvider_sectionWrapper(:final value) => SectionSearchSource(
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

/// Connects one compiled search session to its portable editor binding.
///
/// Selection writes through [host] and records successful additions for history.
/// Catalog generation mismatch rejects selection before writing. This object
/// owns feedback and the committed selection stream. The session controller
/// owns source disposal; disposing this binding does not dispose [source].
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
      case PortablePresentationWriteRejected(:final diagnostics):
        final message = diagnostics
            .map((diagnostic) => diagnostic.message)
            .join("\n");
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
        outcome: PortablePresentationWriteResult.rejected([
          PortablePresentationDiagnostic(
            code: "invalid_collection",
            message: "The selected binding is not a collection",
            severity: skir.DiagnosticSeverity.error,
            targets: [
              PortableDiagnosticTarget.binding(control.control.binding),
            ],
          ),
        ]),
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
      PortableMappedSearchPayload(
        :final mapping,
        :final sourceValue,
        :final contextBindings,
      ) =>
        base
            .copyWith(bindings: {...base.bindings, ...contextBindings})
            .declare(mapping.binding, sourceValue),
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
    required this.queryBinding,
  });

  final PortableSearchEnvironment environment;
  final skir.BindingDeclaration queryBinding;
  PortableExpressionResult evaluate(
    skir.ExpressionNode expression, {
    required SearchQueryContext query,
    required Iterable<skir.SearchSelectorDefinition> selectors,
    (skir.BindingDeclaration, skir.DataValue)? row,
  }) => environment.evaluate(
    expression,
    query: query,
    queryBinding: queryBinding,
    selectors: selectors,
    row: row,
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
        :final contextBindings,
      ) =>
        _text(
          environment.evaluateWith({
            ...environment.expressionBindings(
              query: query,
              queryBinding: queryBinding,
              selectors: selectors,
            ),
            ...contextBindings,
            mapping.binding.id: environment.declared(
              mapping.binding,
              sourceValue,
            ),
          }, expression),
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
      row: (mapping.binding, source),
    );
    final selected = evaluate(
      mapping.selectedValue,
      query: query,
      selectors: selectors,
      row: (mapping.binding, source),
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
              row: (mapping.binding, source),
            ),
          );
    final distinctKey = canonicalAuthoredValue(key.value);
    final result = SearchResult(
      id: "$providerPath:$distinctKey",
      type: portableSearchResultType,
      payload: PortableSearchPayload.mapped(
        sourceValue: source,
        contextBindings: environment.expressionBindings(
          query: query,
          queryBinding: queryBinding,
          selectors: selectors,
        ),
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
