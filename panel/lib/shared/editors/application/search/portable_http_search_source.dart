part of "portable_search_compiler.dart";

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
      for (final context in provider.contextBindings) {
        final values = JsonPath(context.path).readValues(document).toList();
        final expected = evaluation.environment.declaredType(
          context.binding.type,
        );
        if (expected == null) {
          throw FormatException(
            "Search context ${context.binding.id.value} has an incomplete type",
          );
        }
        extraBindings[context.binding.id] = PortableExpressionBinding(
          schema: CompletePortablePresentationBinding(expected),
          value: decodePortableJson(
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
            decodePortableJson(
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
    if (extraBindings.isEmpty) {
      return mapValues(values, provider.result, query);
    }
    final mapper = _PortableSearchEvaluation(
      environment: evaluation.environment.withBindings(extraBindings),
      queryBinding: evaluation.queryBinding,
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
