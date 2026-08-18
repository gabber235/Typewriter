import "package:typewriter_panel/typewriter_panel.dart";

final class LocalPresentationCollectionSource
    implements PresentationCollectionSource {
  const LocalPresentationCollectionSource({
    required this.id,
    required this.schema,
    required this.rows,
    required this.registry,
    this.searchPredicate,
    this.expressionBudget = const ExpressionBudget(),
    this.graphNodeBudget = 4096,
  }) : assert(graphNodeBudget > 0, "Graph node budget must be positive.");

  @override
  final PresentationCollectionSourceId id;

  @override
  final PresentationCollectionSchema schema;

  final Iterable<DataValue> rows;
  final TypeRegistry registry;
  final PresentationCollectionSearchPredicate? searchPredicate;
  final ExpressionBudget expressionBudget;
  final int graphNodeBudget;

  @override
  Stream<PresentationCollectionSnapshot> watch(
    PresentationCollectionQuery query,
  ) => Stream.value(_snapshot(query));

  PresentationCollectionSnapshot _snapshot(PresentationCollectionQuery query) {
    final indexed = _indexRows();
    if (indexed.$2.isNotEmpty) {
      return PresentationCollectionSnapshot(diagnostics: indexed.$2);
    }
    final byKey = indexed.$1;
    return switch (query) {
      PresentationCollectionAll() => PresentationCollectionSnapshot(
        rows: byKey.values.toList(growable: false),
      ),
      PresentationCollectionKeys(:final keys) => PresentationCollectionSnapshot(
        rows: keys.map((key) => byKey[key]).nonNulls.toList(growable: false),
      ),
      PresentationCollectionSearch(:final query) =>
        PresentationCollectionSnapshot(
          rows: byKey.values
              .where((row) => searchPredicate?.call(row.value, query) ?? true)
              .toList(growable: false),
        ),
      PresentationCollectionGraph() => _graph(query, byKey),
    };
  }

  (Map<DataValue, PresentationCollectionRow>, List<TypeDiagnostic>)
  _indexRows() {
    final indexed = <DataValue, PresentationCollectionRow>{};
    final diagnostics = <TypeDiagnostic>[];
    for (final row in rows) {
      final key = _evaluate(schema.key, row);
      if (key case TypeFailure(:final diagnostics)) {
        return ({}, diagnostics);
      }
      final value = key.valueOrNull!;
      if (indexed.containsKey(value)) {
        diagnostics.add(
          _diagnostic("Collection contains duplicate keys", value),
        );
        continue;
      }
      indexed[value] = PresentationCollectionRow(key: value, value: row);
    }
    return (indexed, diagnostics);
  }

  PresentationCollectionSnapshot _graph(
    PresentationCollectionGraph query,
    Map<DataValue, PresentationCollectionRow> byKey,
  ) {
    final relation = schema.relations
        .where((candidate) => candidate.id == query.relation)
        .firstOrNull;
    if (relation == null) {
      return PresentationCollectionSnapshot(
        diagnostics: [_diagnostic("Collection relation is unavailable")],
      );
    }
    final targets = <DataValue, List<DataValue>>{};
    for (final row in byKey.values) {
      final evaluated = _evaluate(relation.targets, row.value);
      if (evaluated case TypeFailure(:final diagnostics)) {
        return PresentationCollectionSnapshot(diagnostics: diagnostics);
      }
      final value = evaluated.valueOrNull!;
      targets[row.key] = switch (value) {
        ListValue(:final values) => values,
        UnitValue() => const [],
        _ => [value],
      };
    }
    final edges = query.direction == CollectionGraphDirection.forward
        ? targets
        : _reverse(targets);
    return _traverse(query, byKey, edges);
  }

  PresentationCollectionSnapshot _traverse(
    PresentationCollectionGraph query,
    Map<DataValue, PresentationCollectionRow> byKey,
    Map<DataValue, List<DataValue>> edges,
  ) {
    final reached = <DataValue, PresentationCollectionRow>{};
    final paths = <PresentationCollectionPath>[];
    final pathKeys = <_GraphPathKey>{};
    final diagnostics = <TypeDiagnostic>[];
    final rootKeys = query.roots.toSet();
    var visitedNodes = 0;

    void visit(DataValue key, List<DataValue> path) {
      if (++visitedNodes > graphNodeBudget) {
        if (diagnostics.isEmpty) {
          diagnostics.add(_diagnostic("Collection graph budget exhausted"));
        }
        return;
      }
      if (query.maximumDepth != null && path.length > query.maximumDepth!) {
        return;
      }
      if (path.contains(key)) {
        diagnostics.add(_diagnostic("Collection graph contains a cycle", key));
        return;
      }
      final row = byKey[key];
      if (row == null) {
        diagnostics.add(_diagnostic("Collection graph target is missing", key));
        return;
      }
      final nextPath = [...path, key];
      if (!rootKeys.contains(key)) reached.putIfAbsent(key, () => row);
      if (pathKeys.add(_GraphPathKey(nextPath))) {
        paths.add(PresentationCollectionPath(nextPath));
      }
      for (final target in edges[key] ?? const []) {
        visit(target, nextPath);
      }
    }

    for (final root in query.roots) {
      for (final target in edges[root] ?? const []) {
        visit(target, [root]);
      }
    }
    return PresentationCollectionSnapshot(
      rootRows: query.roots
          .map((key) => byKey[key])
          .nonNulls
          .toList(growable: false),
      rows: reached.values.toList(growable: false),
      paths: paths,
      diagnostics: diagnostics,
    );
  }

  Map<DataValue, List<DataValue>> _reverse(
    Map<DataValue, List<DataValue>> targets,
  ) {
    final reversed = <DataValue, List<DataValue>>{};
    for (final entry in targets.entries) {
      for (final target in entry.value) {
        reversed.putIfAbsent(target, () => []).add(entry.key);
      }
    }
    return reversed;
  }

  TypeResult<DataValue> _evaluate(TypedExpression expression, DataValue row) =>
      expression.evaluate(
        ExpressionContext(
          bindings: BindingEnvironment({
            schema.rowBindingId: BindingSnapshot(
              type: schema.rowType,
              value: row,
              revision: 0,
              writable: false,
            ),
          }),
        ),
        registry: registry,
        budget: expressionBudget,
      );
}

final class _GraphPathKey {
  const _GraphPathKey(this.keys);

  final List<DataValue> keys;

  @override
  bool operator ==(Object other) {
    if (other is! _GraphPathKey || other.keys.length != keys.length) {
      return false;
    }
    for (var index = 0; index < keys.length; index++) {
      if (other.keys[index] != keys[index]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hashAll(keys);
}

TypeDiagnostic _diagnostic(String message, [DataValue? key]) => TypeDiagnostic(
  code: TypeDiagnosticCode.invalidValue,
  message: message,
  details: [if (key != null) TypeDiagnosticDetail(key: "key", value: "$key")],
);
