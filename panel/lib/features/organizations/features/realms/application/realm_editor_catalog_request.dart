import "package:freezed_annotation/freezed_annotation.dart";
import "package:typewriter_panel/typewriter_panel.dart";

part "realm_editor_catalog_request.freezed.dart";

/// Names one subtype lookup within a merged catalog request.
@freezed
abstract class RealmEditorSubtypeQuery with _$RealmEditorSubtypeQuery {
  @Assert("id != \"\"", "Query ID must not be empty.")
  const factory RealmEditorSubtypeQuery({
    required String id,
    required ResolvedTypeRef target,
  }) = _RealmEditorSubtypeQuery;
}

/// Demand declared by one catalog consumer.
///
/// The cache merges requests from active leases, so these sets describe what
/// must be present in the next snapshot rather than an exclusive fetch scope.
/// Empty sets are valid and represent no additional demand.
@freezed
abstract class RealmEditorCatalogRequest with _$RealmEditorCatalogRequest {
  const factory RealmEditorCatalogRequest({
    @Default({}) Set<ResolvedTypeRef> types,
    @Default({}) Set<PresentationId> presentations,
    @Default({}) Set<RealmEditorSubtypeQuery> subtypeQueries,
  }) = _RealmEditorCatalogRequest;

  const RealmEditorCatalogRequest._();

  bool get isEmpty =>
      types.isEmpty && presentations.isEmpty && subtypeQueries.isEmpty;

  RealmEditorCatalogRequest merge(RealmEditorCatalogRequest other) =>
      RealmEditorCatalogRequest(
        types: {...types, ...other.types},
        presentations: {...presentations, ...other.presentations},
        subtypeQueries: {...subtypeQueries, ...other.subtypeQueries},
      );

  /// Whether this request includes every projection required by [other].
  bool covers(RealmEditorCatalogRequest other) =>
      types.containsAll(other.types) &&
      presentations.containsAll(other.presentations) &&
      subtypeQueries.containsAll(other.subtypeQueries);
}

/// Decoded matches for one [RealmEditorSubtypeQuery].
@freezed
abstract class RealmEditorSubtypeResult with _$RealmEditorSubtypeResult {
  @Assert("queryId != \"\"", "Query ID must not be empty.")
  const factory RealmEditorSubtypeResult({
    required String queryId,
    required List<ResolvedTypeRef> matches,
  }) = _RealmEditorSubtypeResult;
}
