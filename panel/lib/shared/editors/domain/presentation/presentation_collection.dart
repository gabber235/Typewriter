import "package:freezed_annotation/freezed_annotation.dart";
import "package:typewriter_panel/typewriter_panel.dart";

part "presentation_collection.freezed.dart";

/// Direction used when following a relation during graph expansion.
enum CollectionGraphDirection { forward, reverse }

@Freezed(toStringOverride: false)
/// Stable identity used to connect a presentation collection reference to its
/// runtime source.
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
/// Stable identity of a relation that a collection graph can traverse.
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
/// Describes how a collection source exposes rows to presentation elements.
///
/// [rowBindingId] is the binding installed while a row presentation is
/// rendered. [key] derives the unique lookup key and its type for that row.
/// [selectability] decides whether the row may be selected for the current
/// owner. Relations derive zero, one, or many target keys from the same row and
/// are selected by their [PresentationCollectionRelationId].
abstract class PresentationCollectionSchema
    with _$PresentationCollectionSchema {
  const factory PresentationCollectionSchema({
    required TypeExpression rowType,
    required BindingId rowBindingId,
    required TypedExpression key,
    required TypedExpression selectability,
    @Default(<PresentationCollectionRelation>[])
    List<PresentationCollectionRelation> relations,
  }) = _PresentationCollectionSchema;

  const PresentationCollectionSchema._();

  TypeExpression get keyType => key.resultType;
}

@freezed
/// Defines the expression that resolves relation targets for a row.
abstract class PresentationCollectionRelation
    with _$PresentationCollectionRelation {
  const factory PresentationCollectionRelation({
    required PresentationCollectionRelationId id,
    required TypedExpression targets,
  }) = _PresentationCollectionRelation;
}

@freezed
/// Selects the projection a collection source must produce.
///
/// Sources return a stream because remote implementations may load or refresh;
/// local sources commonly emit one snapshot synchronously. Graph queries keep
/// root rows separate from reached rows and preserve paths so renderers can
/// represent repeated occurrences without duplicating row data.
sealed class PresentationCollectionQuery with _$PresentationCollectionQuery {
  /// Requests every indexed row.
  const factory PresentationCollectionQuery.all() = PresentationCollectionAll;

  /// Requests rows whose canonical keys occur in [keys].
  const factory PresentationCollectionQuery.keys(List<DataValue> keys) =
      PresentationCollectionKeys;

  /// Requests rows selected by the source's search policy.
  const factory PresentationCollectionQuery.search(SearchQueryContext query) =
      PresentationCollectionSearch;

  @Assert(
    "maximumDepth == null || maximumDepth > 0",
    "Maximum depth must be positive.",
  )
  /// Traverses [relation] from [roots], optionally limiting path depth.
  ///
  /// [direction] chooses whether relation targets or reverse dependants are
  /// followed. A positive [maximumDepth] limits the number of edges in each
  /// path. Implementations report malformed relations, cycles, missing targets,
  /// and resource limits through the snapshot diagnostics.
  const factory PresentationCollectionQuery.graph({
    required List<DataValue> roots,
    required PresentationCollectionRelationId relation,
    required CollectionGraphDirection direction,
    int? maximumDepth,
  }) = PresentationCollectionGraph;
}

/// Supplies typed collection data to lookup, search, and graph elements.
///
/// The source owns access to its rows and schema. Presentation renderers own
/// neither the rows nor the stream lifecycle: they subscribe for a query and
/// render each [PresentationCollectionSnapshot]. Implementations must keep the
/// schema binding IDs and expression contracts consistent with the rows they
/// expose.
abstract interface class PresentationCollectionSource {
  PresentationCollectionSourceId get id;

  PresentationCollectionSchema get schema;

  Stream<PresentationCollectionSnapshot> watch(
    PresentationCollectionQuery query,
  );
}

@freezed
/// One source row paired with the key derived by its schema.
abstract class PresentationCollectionRow with _$PresentationCollectionRow {
  const factory PresentationCollectionRow({
    required DataValue key,
    required DataValue value,
  }) = _PresentationCollectionRow;
}

@freezed
/// One ordered root to descendant occurrence in a graph result.
///
/// Paths retain relationship occurrences even when [PresentationCollectionRow]
/// values are deduplicated in the snapshot's row list.
abstract class PresentationCollectionPath with _$PresentationCollectionPath {
  const factory PresentationCollectionPath(List<DataValue> keys) =
      _PresentationCollectionPath;
}

@freezed
/// Immutable result delivered by a collection source.
///
/// [rootRows] are the requested graph roots. [rows] contains reached rows and
/// may omit roots because roots are rendered separately. [paths] preserves
/// every distinct occurrence path. Diagnostics describe unusable data or
/// partial graph expansion, while [loading] lets a renderer keep its loading
/// state instead of treating an incomplete result as final.
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

  /// Finds a row in the root projection first, then the reached projection.
  ///
  /// Root precedence matters when a graph renderer resolves a child key that
  /// is also one of the requested roots.
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

/// Optional local filtering policy for [PresentationCollectionSource] search.
/// Returning false excludes the row from the search snapshot.
typedef PresentationCollectionSearchPredicate = bool Function(
  DataValue row,
  SearchQueryContext query,
);
