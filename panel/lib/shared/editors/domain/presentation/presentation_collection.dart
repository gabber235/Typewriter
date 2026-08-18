import "package:freezed_annotation/freezed_annotation.dart";
import "package:typewriter_panel/typewriter_panel.dart";

part "presentation_collection.freezed.dart";

enum CollectionGraphDirection { forward, reverse }

@Freezed(toStringOverride: false)
abstract class PresentationCollectionSourceId
    with _$PresentationCollectionSourceId {
  @Assert("value != \"\"", "Collection source ID must not be empty.")
  const factory PresentationCollectionSourceId(String value) =
      _PresentationCollectionSourceId;

  const PresentationCollectionSourceId._();

  @override
  String toString() => value;
}

@Freezed(toStringOverride: false)
abstract class PresentationCollectionRelationId
    with _$PresentationCollectionRelationId {
  @Assert("value != \"\"", "Collection relation ID must not be empty.")
  const factory PresentationCollectionRelationId(String value) =
      _PresentationCollectionRelationId;

  const PresentationCollectionRelationId._();

  @override
  String toString() => value;
}

@freezed
abstract class PresentationCollectionSchema
    with _$PresentationCollectionSchema {
  const factory PresentationCollectionSchema({
    required TypeExpression rowType,
    required TypeExpression keyType,
    required BindingId rowBindingId,
    required TypedExpression key,
    @Default(<PresentationCollectionRelation>[])
    List<PresentationCollectionRelation> relations,
  }) = _PresentationCollectionSchema;
}

@freezed
abstract class PresentationCollectionRelation
    with _$PresentationCollectionRelation {
  const factory PresentationCollectionRelation({
    required PresentationCollectionRelationId id,
    required TypedExpression targets,
  }) = _PresentationCollectionRelation;
}

@freezed
sealed class PresentationCollectionQuery with _$PresentationCollectionQuery {
  const factory PresentationCollectionQuery.all() = PresentationCollectionAll;

  const factory PresentationCollectionQuery.keys(List<DataValue> keys) =
      PresentationCollectionKeys;

  const factory PresentationCollectionQuery.search(SearchQueryContext query) =
      PresentationCollectionSearch;

  @Assert(
    "maximumDepth == null || maximumDepth > 0",
    "Maximum depth must be positive.",
  )
  const factory PresentationCollectionQuery.graph({
    required List<DataValue> roots,
    required PresentationCollectionRelationId relation,
    required CollectionGraphDirection direction,
    int? maximumDepth,
  }) = PresentationCollectionGraph;
}

abstract interface class PresentationCollectionSource {
  PresentationCollectionSourceId get id;

  PresentationCollectionSchema get schema;

  Stream<PresentationCollectionSnapshot> watch(
    PresentationCollectionQuery query,
  );
}

@freezed
abstract class PresentationCollectionRow with _$PresentationCollectionRow {
  const factory PresentationCollectionRow({
    required DataValue key,
    required DataValue value,
  }) = _PresentationCollectionRow;
}

@freezed
abstract class PresentationCollectionPath with _$PresentationCollectionPath {
  const factory PresentationCollectionPath(List<DataValue> keys) =
      _PresentationCollectionPath;
}

@freezed
abstract class PresentationCollectionSnapshot
    with _$PresentationCollectionSnapshot {
  const factory PresentationCollectionSnapshot({
    @Default(<PresentationCollectionRow>[])
    List<PresentationCollectionRow> rootRows,
    @Default(<PresentationCollectionRow>[])
    List<PresentationCollectionRow> rows,
    @Default(<PresentationCollectionPath>[])
    List<PresentationCollectionPath> paths,
    @Default(<TypeDiagnostic>[]) List<TypeDiagnostic> diagnostics,
    @Default(false) bool loading,
  }) = _PresentationCollectionSnapshot;

  const PresentationCollectionSnapshot._();

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
