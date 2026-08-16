import "package:typewriter_panel/typewriter_panel.dart";

enum CollectionGraphDirection { forward, reverse }

final class PresentationCollectionSourceId {
  const PresentationCollectionSourceId(this.value)
    : assert(value != "", "Collection source ID must not be empty.");

  final String value;

  @override
  bool operator ==(Object other) =>
      other is PresentationCollectionSourceId && value == other.value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value;
}

final class PresentationCollectionRelationId {
  const PresentationCollectionRelationId(this.value)
    : assert(value != "", "Collection relation ID must not be empty.");

  final String value;

  @override
  bool operator ==(Object other) =>
      other is PresentationCollectionRelationId && value == other.value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value;
}

final class PresentationCollectionSchema {
  const PresentationCollectionSchema({
    required this.rowType,
    required this.keyType,
    required this.rowBindingId,
    required this.key,
    this.relations = const [],
  });

  final TypeExpression rowType;
  final TypeExpression keyType;
  final BindingId rowBindingId;
  final TypedExpression key;
  final List<PresentationCollectionRelation> relations;
}

final class PresentationCollectionRelation {
  const PresentationCollectionRelation({
    required this.id,
    required this.targets,
  });

  final PresentationCollectionRelationId id;
  final TypedExpression targets;
}

sealed class PresentationCollectionQuery {
  const PresentationCollectionQuery();

  const factory PresentationCollectionQuery.all() = PresentationCollectionAll;

  const factory PresentationCollectionQuery.keys(List<DataValue> keys) =
      PresentationCollectionKeys;

  const factory PresentationCollectionQuery.search(SearchQueryContext query) =
      PresentationCollectionSearch;

  const factory PresentationCollectionQuery.graph({
    required List<DataValue> roots,
    required PresentationCollectionRelationId relation,
    required CollectionGraphDirection direction,
    int? maximumDepth,
  }) = PresentationCollectionGraph;
}

final class PresentationCollectionAll extends PresentationCollectionQuery {
  const PresentationCollectionAll();
}

final class PresentationCollectionKeys extends PresentationCollectionQuery {
  const PresentationCollectionKeys(this.keys);

  final List<DataValue> keys;
}

final class PresentationCollectionSearch extends PresentationCollectionQuery {
  const PresentationCollectionSearch(this.query);

  final SearchQueryContext query;
}

final class PresentationCollectionGraph extends PresentationCollectionQuery {
  const PresentationCollectionGraph({
    required this.roots,
    required this.relation,
    required this.direction,
    this.maximumDepth,
  }) : assert(
         maximumDepth == null || maximumDepth > 0,
         "Maximum depth must be positive.",
       );

  final List<DataValue> roots;
  final PresentationCollectionRelationId relation;
  final CollectionGraphDirection direction;
  final int? maximumDepth;
}

abstract interface class PresentationCollectionSource {
  PresentationCollectionSourceId get id;

  PresentationCollectionSchema get schema;

  Stream<PresentationCollectionSnapshot> watch(
    PresentationCollectionQuery query,
  );
}

final class PresentationCollectionRow {
  const PresentationCollectionRow({required this.key, required this.value});

  final DataValue key;
  final DataValue value;
}

final class PresentationCollectionPath {
  const PresentationCollectionPath(this.keys);

  final List<DataValue> keys;
}

final class PresentationCollectionSnapshot {
  const PresentationCollectionSnapshot({
    this.rootRows = const [],
    this.rows = const [],
    this.paths = const [],
    this.diagnostics = const [],
    this.loading = false,
  });

  final List<PresentationCollectionRow> rootRows;
  final List<PresentationCollectionRow> rows;
  final List<PresentationCollectionPath> paths;
  final List<TypeDiagnostic> diagnostics;
  final bool loading;

  PresentationCollectionRow? row(DataValue key) {
    for (final row in rootRows) {
      if (row.key == key) return row;
    }
    for (final row in rows) {
      if (row.key == key) return row;
    }
    return null;
  }
}

typedef PresentationCollectionSearchPredicate =
    bool Function(DataValue row, SearchQueryContext query);
