import "dart:async";

import "package:collection/collection.dart";
import "package:typewriter_panel/typewriter_panel.dart";

/// Combines independent sources into one snapshot and selector stream.
///
/// Results, guidance, and errors are concatenated with first source ownership
/// winning for duplicate result IDs. The merged status stays
/// loading until every child has reported and becomes error only when every
/// child errors without results. Preview requests route by result ID.
final class MergedSearchSource
    implements SearchSource, SearchSelectorCompletionSource {
  MergedSearchSource({required this.sources}) : assert(sources.isNotEmpty) {
    _latestSnapshots = List.filled(sources.length, null);
    final definitions = <QuerySelectorDefinition>[];
    final owners = <String, List<int>>{};
    for (final entry in sources.indexed) {
      for (final selector in entry.$2.selectors) {
        owners.putIfAbsent(selector.id, () => []).add(entry.$1);
        final existing = definitions.indexWhere(
          (item) => item.id == selector.id,
        );
        if (existing == -1) {
          definitions.add(selector);
        } else {
          definitions[existing] = definitions[existing].merge(selector);
        }
      }
    }
    selectors = List.unmodifiable(definitions);
    _selectorOwners = Map.unmodifiable(owners);
  }

  final List<SearchSource> sources;

  final _snapshots = StreamController<SearchSourceSnapshot>.broadcast(
    sync: true,
  );
  late final List<SearchSourceSnapshot?> _latestSnapshots;
  late final Map<String, List<int>> _selectorOwners;
  @override
  late final List<QuerySelectorDefinition> selectors;
  final List<StreamSubscription<Object?>> _subscriptions = [];
  final Map<String, SearchSource> _resultSources = {};
  final Set<int> _activeSourceIndexes = {};
  SearchQueryContext _activeContext = SearchQueryContext.empty;
  bool _initialized = false;
  bool _disposed = false;

  @override
  Stream<SearchSourceSnapshot> get snapshots => _snapshots.stream;

  @override
  void initialize(SearchQueryContext context) {
    if (_initialized) return;
    _initialized = true;

    _activeContext = context;
    for (var index = 0; index < sources.length; index++) {
      final source = sources[index];
      _subscriptions.add(
        source.snapshots.listen((snapshot) => _onSnapshot(index, snapshot)),
      );
      final selectorIds = source.selectors.map((item) => item.id).toSet();
      final projected = context.projectFor(selectorIds);
      if (projected == null) {
        _latestSnapshots[index] = SearchSourceSnapshot.ready(nodes: const []);
        source.initialize(SearchQueryContext.empty);
      } else {
        _activeSourceIndexes.add(index);
        source.initialize(projected);
      }
    }
  }

  @override
  void search(SearchQueryContext context) {
    _activeContext = context;
    _latestSnapshots.fillRange(0, _latestSnapshots.length, null);
    _resultSources.clear();
    _activeSourceIndexes.clear();
    for (final entry in sources.indexed) {
      final source = entry.$2;
      final selectorIds = source.selectors.map((item) => item.id).toSet();
      final projected = context.projectFor(selectorIds);
      if (projected == null) {
        _latestSnapshots[entry.$1] = SearchSourceSnapshot.ready(
          nodes: const [],
        );
        continue;
      }
      _activeSourceIndexes.add(entry.$1);
      source.search(projected);
    }
    _snapshots.add(_mergeSnapshots());
  }

  @override
  Future<SearchSelectorCompletionResult> completeSelector(
    SearchSelectorCompletionRequest request,
  ) async {
    final ownerIndexes = _selectorOwners[request.selectorId] ?? const [];
    final requests = <Future<SearchSelectorCompletionResult>>[];
    for (final index in ownerIndexes) {
      final source = sources[index];
      if (source is! SearchSelectorCompletionSource) continue;
      final selectorIds = source.selectors.map((item) => item.id).toSet();
      final projected = request.projectFor(selectorIds);
      if (projected == null) continue;
      requests.add(
        (source as SearchSelectorCompletionSource).completeSelector(projected),
      );
    }
    if (requests.isEmpty) return const SearchSelectorCompletionResult();

    final settled = await Future.wait([
      for (final request in requests)
        request.then<(SearchSelectorCompletionResult?, Object?)>(
          (value) => (value, null),
          onError: (Object error) => (null, error),
        ),
    ]);
    final successful = settled.map((item) => item.$1).nonNulls.toList();
    if (successful.isEmpty) {
      return const SearchSelectorCompletionResult(
        warning: "Selector suggestions are temporarily unavailable",
      );
    }

    final definition = selectors
        .whereType<KeyValueSelectorDefinition>()
        .firstWhere((item) => item.id == request.selectorId);
    final values = <String>[];
    final seen = <String>{};
    for (final result in successful) {
      for (final value in result.values) {
        final key = definition.caseSensitive ? value : value.toLowerCase();
        if (seen.add(key)) values.add(value);
      }
    }
    final partiallyUnavailable =
        settled.any((item) => item.$2 != null) ||
        successful.any((item) => item.warning != null);
    return SearchSelectorCompletionResult(
      values: List.unmodifiable(values),
      exhaustive:
          !partiallyUnavailable && successful.every((item) => item.exhaustive),
      warning: partiallyUnavailable
          ? "Some selector suggestions are temporarily unavailable"
          : null,
    );
  }

  @override
  Future<SearchPreviewRequestResult> preview(SearchPreviewRequest request) {
    final source = _resultSources[request.resultId];
    if (source == null) {
      return Future.value(
        const SearchPreviewRequestResult.error(
          message: "Preview source is unavailable",
        ),
      );
    }
    return source.preview(request);
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }
    _subscriptions.clear();
    for (final source in sources) {
      source.dispose();
    }

    unawaited(_snapshots.close());
  }

  void _onSnapshot(int index, SearchSourceSnapshot snapshot) {
    if (_disposed || !_activeSourceIndexes.contains(index)) return;
    _latestSnapshots[index] = snapshot;
    _snapshots.add(_mergeSnapshots());
  }

  SearchSourceSnapshot _mergeSnapshots() {
    final available = _latestSnapshots.whereType<SearchSourceSnapshot>();

    final nodes = <SearchNode>[];
    final guidance = <SearchGuidance>[];
    final guidanceIds = <String>{};

    final errors = <SearchErrorSummary>[];

    final errorIds = <String>{};
    _resultSources.clear();

    for (var index = 0; index < _latestSnapshots.length; index++) {
      final snapshot = _latestSnapshots[index];
      if (snapshot == null) continue;

      nodes.addAll(snapshot.nodes);
      guidance.addAll(
        snapshot.guidance.where((item) {
          return guidanceIds.add(item.id);
        }),
      );
      errors.addAll(
        snapshot.errorSummaries.where((item) {
          return errorIds.add(item.id);
        }),
      );
      for (final result
          in snapshot.nodes.walk().whereType<SearchResultNode>()) {
        _resultSources.putIfAbsent(result.result.id, () => sources[index]);
      }
    }

    final statuses = available.map((snapshot) => snapshot.status).toList();
    final validations = _mergeValidations();

    if (statuses.isEmpty || statuses.every((status) => status == .idle)) {
      return SearchSourceSnapshot.idle(nodes: nodes, guidance: guidance);
    }

    final allChildrenReported = statuses.length == sources.length;
    final allErrors =
        allChildrenReported && statuses.every((status) => status == .error);
    if (allErrors && nodes.isEmpty) {
      return SearchSourceSnapshot.error(
        nodes: nodes,
        guidance: guidance,
        errorSummaries: errors,
        selectorValidations: validations,
      );
    }

    final isLoading =
        !allChildrenReported ||
        statuses.any((status) {
          return status == .loading;
        });
    if (isLoading) {
      return SearchSourceSnapshot.loading(
        nodes: nodes,
        guidance: guidance,
        errorSummaries: errors,
        selectorValidations: validations,
      );
    }

    if (statuses.any((status) => status == .ready)) {
      return SearchSourceSnapshot.ready(
        nodes: nodes,
        guidance: guidance,
        errorSummaries: errors,
        selectorValidations: validations,
      );
    }

    return SearchSourceSnapshot(
      status: SearchSourceStatus.idle,
      nodes: nodes,
      guidance: guidance,
      errorSummaries: errors,
      selectorValidations: validations,
    );
  }

  List<SearchSelectorValidation> _mergeValidations() {
    final validations = <SearchSelectorValidation>[];
    final seen = <String>{};
    for (final selector in _activeContext.selectors) {
      final value = selector.value;
      if (value == null) continue;
      final definition = selectors
          .whereType<KeyValueSelectorDefinition>()
          .firstWhereOrNull((item) => item.id == selector.selectorId);
      if (definition == null ||
          definition.value is! SourceBackedSelectorValue) {
        continue;
      }
      final normalized = definition.caseSensitive ? value : value.toLowerCase();
      final key = "${selector.selectorId}\u0000$normalized";
      if (!seen.add(key)) continue;

      final owners = (_selectorOwners[selector.selectorId] ?? const [])
          .where(_activeSourceIndexes.contains)
          .toList();
      final claims = <SearchSelectorValidation>[];
      bool matchesClaim(SearchSelectorValidation claim) {
        final claimValue = definition.caseSensitive
            ? claim.value
            : claim.value.toLowerCase();
        return claim.selectorId == selector.selectorId &&
            claimValue == normalized;
      }

      for (final index in owners) {
        final snapshot = _latestSnapshots[index];
        if (snapshot == null) continue;
        claims.addAll(snapshot.selectorValidations.where(matchesClaim));
      }

      final status =
          claims.any(
            (claim) => claim.status == SearchSelectorValidationStatus.accepted,
          )
          ? SearchSelectorValidationStatus.accepted
          : owners.isNotEmpty &&
                owners.every((index) {
                  final snapshot = _latestSnapshots[index];
                  return snapshot != null &&
                      snapshot.status != SearchSourceStatus.error &&
                      snapshot.selectorValidations.any(
                        (claim) =>
                            matchesClaim(claim) &&
                            claim.status ==
                                SearchSelectorValidationStatus.rejected,
                      );
                })
          ? SearchSelectorValidationStatus.rejected
          : SearchSelectorValidationStatus.unresolved;
      validations.add(
        SearchSelectorValidation(
          selectorId: selector.selectorId,
          value: value,
          status: status,
        ),
      );
    }
    return validations;
  }
}

/// Merges sources in iterable order, which also defines conflict precedence.
extension MergedSearchSourcesX on Iterable<SearchSource> {
  SearchSource merged() {
    return MergedSearchSource(sources: toList(growable: false));
  }
}
