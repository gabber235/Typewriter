import "dart:async";
import "dart:convert";

import "package:http/http.dart" as http;
import "package:json_path/json_path.dart";
import "package:typewriter_panel/typewriter_panel.dart";

final class HttpJsonPresentationSearchSource implements SearchSource {
  HttpJsonPresentationSearchSource({
    required this.provider,
    required this.client,
    required this.expressions,
    required this.registry,
    required this.budget,
    required this.queryBindingId,
    required this.providerKey,
  });

  final HttpJsonSearchProvider provider;
  final http.Client client;
  final ExpressionContext expressions;
  final TypeRegistry registry;
  final ExpressionBudget budget;
  final BindingId queryBindingId;
  final String providerKey;

  final _snapshots = StreamController<SearchSourceSnapshot>.broadcast(
    sync: true,
  );
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
      if (!_disposed) _snapshots.add(SearchSourceSnapshot.idle());
    });
  }

  @override
  void search(SearchQueryContext query) {
    if (_disposed) return;
    final revision = ++_revision;
    _snapshots.add(SearchSourceSnapshot.loading());
    unawaited(_search(query, revision));
  }

  Future<void> _search(SearchQueryContext query, int revision) async {
    try {
      final context = presentationSearchContext(
        base: expressions,
        queryBindingId: queryBindingId,
        query: query,
        selectors: provider.selectors,
      );
      final uri = _uri(context);
      final response = await client
          .get(uri, headers: const {"Accept": "application/json"})
          .timeout(provider.timeout);
      final responseUri = response.request?.url ?? uri;
      if (responseUri.scheme != "https") {
        throw const FormatException("Search redirects must remain on HTTPS");
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw FormatException(
          "Search request returned status ${response.statusCode}",
        );
      }
      final document = jsonDecode(response.body);
      final withBindings = _contextBindings(document, context);
      final snapshot = _snapshot(document, withBindings);
      if (_disposed || revision != _revision) return;
      _snapshots.add(snapshot);
    } on TimeoutException {
      _emitError(revision, "Search request timed out");
    } on Object catch (error) {
      _emitError(revision, _errorMessage(error));
    }
  }

  Uri _uri(ExpressionContext context) {
    final evaluated = provider.uri.evaluate(
      context,
      registry: registry,
      budget: budget,
    );
    final value = evaluated.valueOrNull;
    if (value is! StringValue) {
      throw const FormatException("Search URI must evaluate to a string");
    }
    final uri = Uri.parse(value.value);
    if (uri.scheme != "https" || uri.host.isEmpty) {
      throw const FormatException("Search URI must use HTTPS");
    }
    final parameters = Map<String, String>.of(uri.queryParameters);
    for (final parameter in provider.parameters) {
      final result = parameter.value.evaluate(
        context,
        registry: registry,
        budget: budget,
      );
      if (result case TypeFailure(:final diagnostics)) {
        throw FormatException(diagnostics.first.message);
      }
      final text = result.valueOrNull!.expressionDisplayText;
      if (parameter.omitIfEmpty && text.isEmpty) continue;
      parameters[parameter.name] = text;
    }
    return uri.replace(queryParameters: parameters);
  }

  ExpressionContext _contextBindings(
    Object? document,
    ExpressionContext context,
  ) {
    var bound = context;
    for (final binding in provider.contextBindings) {
      final matches = JsonPath(binding.path).readValues(document).toList();
      final source = matches.length == 1 ? matches.single : matches;
      final decoded = decodeJsonDataValue(
        source,
        binding.type,
        registry: registry,
      );
      if (decoded case TypeFailure(:final diagnostics)) {
        throw FormatException(diagnostics.first.message);
      }
      bound = bound.withBinding(
        binding.bindingId,
        BindingSnapshot(
          type: binding.type,
          value: decoded.valueOrNull!,
          revision: 0,
          writable: false,
        ),
      );
    }
    return bound;
  }

  SearchSourceSnapshot _snapshot(Object? document, ExpressionContext context) {
    final candidates = JsonPath(provider.resultPath).readValues(document);
    final mapper = PresentationSearchMapper(
      mapping: provider.result,
      registry: registry,
      budget: budget,
      providerKey: providerKey,
    );
    final nodes = <SearchNode>[];
    final errors = <SearchErrorSummary>[];
    for (final candidate in candidates) {
      final decoded = decodeJsonDataValue(
        candidate,
        provider.resultType,
        registry: registry,
      );
      if (decoded case TypeFailure(:final diagnostics)) {
        errors.add(_warning(diagnostics.first.message, errors.length));
        continue;
      }
      final mapped = mapper.map(
        value: decoded.valueOrNull!,
        type: provider.resultType,
        expressions: context,
      );
      if (mapped case TypeFailure(:final diagnostics)) {
        errors.add(_warning(diagnostics.first.message, errors.length));
        continue;
      }
      nodes.add(SearchNode.result(result: mapped.valueOrNull!));
    }
    return SearchSourceSnapshot.ready(nodes: nodes, errorSummaries: errors);
  }

  SearchErrorSummary _warning(String message, int index) => SearchErrorSummary(
    id: "httpJsonCandidate.$index",
    message: message,
    severity: SearchErrorSeverity.warning,
    sourceLabel: providerKey,
  );

  void _emitError(int revision, String message) {
    if (_disposed || revision != _revision) return;
    _snapshots.add(
      SearchSourceSnapshot.error(
        errorSummaries: [
          SearchErrorSummary(
            id: "httpJsonUnavailable",
            message: message,
            severity: SearchErrorSeverity.error,
            sourceLabel: providerKey,
          ),
        ],
      ),
    );
  }

  String _errorMessage(Object error) => switch (error) {
    FormatException(:final message) => message,
    _ => "Search provider is unavailable",
  };

  @override
  Future<SearchPreviewRequestResult> preview(
    SearchPreviewRequest request,
  ) async => const SearchPreviewRequestResult.error(
    message: "Presentation results render their preview directly",
  );

  @override
  void dispose() {
    _disposed = true;
    _revision++;
    unawaited(_snapshots.close());
  }
}
