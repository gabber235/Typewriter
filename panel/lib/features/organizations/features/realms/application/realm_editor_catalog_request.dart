import "package:freezed_annotation/freezed_annotation.dart";
import "package:typewriter_panel/typewriter_panel.dart";

part "realm_editor_catalog_request.freezed.dart";

@freezed
abstract class RealmEditorSubtypeQuery with _$RealmEditorSubtypeQuery {
  @Assert("id != \"\"", "Query ID must not be empty.")
  const factory RealmEditorSubtypeQuery({
    required String id,
    required ResolvedTypeRef target,
  }) = _RealmEditorSubtypeQuery;
}

@freezed
abstract class RealmEditorCatalogRequest with _$RealmEditorCatalogRequest {
  const factory RealmEditorCatalogRequest({
    @Default({}) Set<ResolvedTypeRef> types,
    @Default({}) Set<PresentationId> presentations,
    @Default({}) Set<ConversionId> conversions,
    @Default({}) Set<RealmActionId> realmActions,
    @Default({}) Set<RealmEditorSubtypeQuery> subtypeQueries,
  }) = _RealmEditorCatalogRequest;

  const RealmEditorCatalogRequest._();

  bool get isEmpty =>
      types.isEmpty &&
      presentations.isEmpty &&
      conversions.isEmpty &&
      realmActions.isEmpty &&
      subtypeQueries.isEmpty;

  RealmEditorCatalogRequest merge(RealmEditorCatalogRequest other) =>
      RealmEditorCatalogRequest(
        types: {...types, ...other.types},
        presentations: {...presentations, ...other.presentations},
        conversions: {...conversions, ...other.conversions},
        realmActions: {...realmActions, ...other.realmActions},
        subtypeQueries: {...subtypeQueries, ...other.subtypeQueries},
      );
}

@freezed
abstract class RealmEditorSubtypeResult with _$RealmEditorSubtypeResult {
  @Assert("queryId != \"\"", "Query ID must not be empty.")
  const factory RealmEditorSubtypeResult({
    required String queryId,
    required List<ResolvedTypeRef> matches,
  }) = _RealmEditorSubtypeResult;
}
