import "package:typewriter_panel/typewriter_panel.dart";

const authoringTagCollectionSourceId = PresentationCollectionSourceId(
  "realm.tags",
);

/// Projects canonical graph resources through Realm supplied collection plans.
///
/// The session generation and catalog generation must match. Every required
/// source must have one coherent schema and one Realm owned projection. Invalid
/// rows remain visible through diagnostics.
typedef AuthoringCollectionProjection = ({
  Map<PresentationCollectionSourceId, PresentationCollectionSource> sources,
  List<TypeDiagnostic> diagnostics,
});

AuthoringCollectionProjection decodeAuthoringCollections({
  required AuthoringSessionState session,
  required RealmEditorCatalogSnapshot catalog,
  required Iterable<PresentationDefinition> presentations,
}) {
  if (session.generation?.value != catalog.generation.value) {
    return (
      sources: const {},
      diagnostics: [
        _collectionDiagnostic(
          "Authoring collections and the editor catalog use different generations",
        ),
      ],
    );
  }
  final schemas =
      <PresentationCollectionSourceId, PresentationCollectionSchema>{};
  final diagnostics = <TypeDiagnostic>[];
  for (final presentation in presentations) {
    for (final entry in presentation.collections.entries) {
      final existing = schemas[entry.key];
      if (existing != null && existing != entry.value) {
        diagnostics.add(
          _collectionDiagnostic(
            "Collection '${entry.key.value}' has conflicting schemas",
          ),
        );
      } else {
        schemas[entry.key] = entry.value;
      }
    }
  }
  final codec = TypedAuthoringCodec(catalog);
  final sources =
      <PresentationCollectionSourceId, PresentationCollectionSource>{};
  for (final entry in schemas.entries) {
    final projection = catalog.collectionProjections[entry.key];
    if (projection == null) {
      diagnostics.add(
        _collectionDiagnostic(
          "Collection '${entry.key.value}' has no Realm projection",
        ),
      );
      continue;
    }
    final schemaRowType = switch (entry.value.rowType) {
      NamedType(:final reference) => reference,
      _ => null,
    };
    if (projection.rowType != schemaRowType) {
      diagnostics.add(
        _collectionDiagnostic(
          "Collection '${entry.key.value}' projection has an incompatible row type",
        ),
      );
      continue;
    }
    final rows = <DataValue>[];
    for (final wire in session.resources.values) {
      if (projection.kinds.isNotEmpty &&
          !projection.kinds.contains(wire.kind)) {
        continue;
      }
      final decoded = codec.decodeResource(wire);
      diagnostics.addAll(decoded.diagnostics);
      final resource = decoded.valueOrNull;
      if (resource == null) continue;
      if (projection.assignableTo != null &&
          !NamedType(resource.content.rootType).isStructurallyAssignableTo(
            projection.assignableTo!,
            codec.registry,
          )) {
        continue;
      }
      final fields = <String, DataValue>{};
      var valid = true;
      for (final field in projection.fields) {
        if (field.target.segments case [FieldPathSegment(:final name)]) {
          final value = switch (field.source) {
            RealmCollectionResourceId() => ReferenceValue(resource.id),
            RealmCollectionContentPath(:final path) =>
              path.read(resource.content.rootValue).valueOrNull,
            RealmCollectionLiteral(:final value) => value,
          };
          if (value == null || fields.containsKey(name)) {
            valid = false;
            break;
          }
          fields[name] = value;
        } else {
          valid = false;
          break;
        }
      }
      if (!valid) {
        diagnostics.add(
          _collectionDiagnostic(
            "Collection '${entry.key.value}' could not project resource '${resource.id.value}'",
          ),
        );
        continue;
      }
      final row = RecordValue(fields);
      final rowDiagnostics = row.validateAgainst(
        entry.value.rowType,
        registry: codec.registry,
      );
      if (rowDiagnostics.isNotEmpty) {
        diagnostics.addAll(rowDiagnostics);
        continue;
      }
      rows.add(row);
    }
    sources[entry.key] = LocalPresentationCollectionSource(
      id: entry.key,
      schema: entry.value,
      rows: List.unmodifiable(rows),
      registry: codec.registry,
    );
  }
  return (
    sources: Map.unmodifiable(sources),
    diagnostics: List.unmodifiable(diagnostics),
  );
}

TypeDiagnostic _collectionDiagnostic(String message) => TypeDiagnostic(
  code: TypeDiagnosticCode.invalidValue,
  message: message,
  pathPresent: false,
);

/// Merges generation pinned local collection snapshots for one multi editor.
///
/// Source identity, schema, row keys, and every value outside the declared
/// selectability binding must match. Selectability is intersected so a row is
/// enabled only when every selected owner permits it.
TypeResult<PresentationCollectionSource> mergeAuthoringCollectionSources(
  Iterable<PresentationCollectionSource> candidates,
) {
  final sources = candidates.toList(growable: false);
  if (sources.isEmpty ||
      sources.any((source) => source is! LocalPresentationCollectionSource)) {
    return _collectionMergeFailure();
  }
  final local = sources.cast<LocalPresentationCollectionSource>();
  final first = local.first;
  if (local.any(
    (source) =>
        source.id != first.id ||
        source.schema != first.schema ||
        source.registry.catalog != first.registry.catalog,
  )) {
    return _collectionMergeFailure();
  }
  final selectability = first.schema.selectability.expression;
  if (selectability is! BindingExpression ||
      selectability.binding.bindingId != first.schema.rowBindingId) {
    return _collectionMergeFailure();
  }
  final indexed = <Map<DataValue, DataValue>>[];
  for (final source in local) {
    final rows = <DataValue, DataValue>{};
    for (final row in source.rows) {
      final key = _evaluateCollectionExpression(source, source.schema.key, row);
      if (key == null || rows.containsKey(key)) {
        return _collectionMergeFailure();
      }
      rows[key] = row;
    }
    indexed.add(rows);
  }
  final keys = indexed.first.keys.toSet();
  if (indexed.skip(1).any((rows) => !_sameValues(keys, rows.keys.toSet()))) {
    return _collectionMergeFailure();
  }
  final rows = <DataValue>[];
  for (final key in indexed.first.keys) {
    final values = indexed
        .map((source) => source[key]!)
        .toList(growable: false);
    final normalized = <DataValue>[];
    var selectable = true;
    for (var index = 0; index < values.length; index++) {
      final source = local[index];
      final selected = _evaluateCollectionExpression(
        source,
        source.schema.selectability,
        values[index],
      );
      if (selected is! BooleanValue) return _collectionMergeFailure();
      selectable = selectable && selected.value;
      final stable = selectability.binding.path.replace(
        values[index],
        const BooleanValue(true),
      );
      final stableValue = stable.valueOrNull;
      if (stableValue == null) return _collectionMergeFailure();
      normalized.add(stableValue);
    }
    if (normalized.skip(1).any((value) => value != normalized.first)) {
      return _collectionMergeFailure();
    }
    final combined = selectability.binding.path
        .replace(normalized.first, BooleanValue(selectable))
        .valueOrNull;
    if (combined == null) return _collectionMergeFailure();
    rows.add(combined);
  }
  return TypeResult.success(
    LocalPresentationCollectionSource(
      id: first.id,
      schema: first.schema,
      rows: List.unmodifiable(rows),
      registry: first.registry,
      searchPredicate: first.searchPredicate,
      expressionBudget: first.expressionBudget,
      graphNodeBudget: first.graphNodeBudget,
    ),
  );
}

DataValue? _evaluateCollectionExpression(
  LocalPresentationCollectionSource source,
  TypedExpression expression,
  DataValue row,
) => expression
    .evaluate(
      ExpressionContext(
        bindings: BindingEnvironment({
          source.schema.rowBindingId: BindingSnapshot(
            type: source.schema.rowType,
            value: row,
            revision: 0,
            writable: false,
          ),
        }),
      ),
      registry: source.registry,
      budget: source.expressionBudget,
    )
    .valueOrNull;

bool _sameValues(Set<DataValue> left, Set<DataValue> right) =>
    left.length == right.length && left.every(right.contains);

TypeResult<PresentationCollectionSource> _collectionMergeFailure() =>
    TypeResult<PresentationCollectionSource>.failure([
      const TypeDiagnostic(
        code: TypeDiagnosticCode.invalidValue,
        message: "Selected resources have inconsistent collection snapshots",
        pathPresent: false,
      ),
    ]);
