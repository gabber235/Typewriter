import "package:freezed_annotation/freezed_annotation.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

part "realm_editor_catalog.freezed.dart";

@freezed
abstract class RealmEditorCatalogRoute with _$RealmEditorCatalogRoute {
  const factory RealmEditorCatalogRoute({
    required skir.RecordId organizationId,
    required skir.RecordId realmId,
  }) = _RealmEditorCatalogRoute;

  const RealmEditorCatalogRoute._();

  String get fetchSubject =>
      "service.to.${this.realmId.id}.organization.${this.organizationId.id}.realm.editor.catalog.fetch";

  String get invalidationRequestSubject =>
      "service.to.${this.realmId.id}.organization.${this.organizationId.id}.realm.editor.catalog.invalidate";

  String get invalidationSubject =>
      "service.from.${this.realmId.id}.organization.${this.organizationId.id}.realm.editor.catalog.invalidate";
}

@freezed
abstract class RealmEditorCatalogSnapshot with _$RealmEditorCatalogSnapshot {
  const factory RealmEditorCatalogSnapshot({
    required TypeCatalog catalog,
    required CatalogGeneration generation,
    @Default({}) Map<PresentationId, PresentationDefinition> presentations,
    @Default({}) Map<ConversionId, ConversionDefinition> conversions,
    @Default({}) Map<RealmActionId, RealmActionDefinition> realmActions,
    @Default({}) Map<String, RealmEditorSubtypeResult> subtypeResults,
    @Default([]) List<TypeDiagnostic> diagnostics,
  }) = _RealmEditorCatalogSnapshot;

  const RealmEditorCatalogSnapshot._();

  RealmEditorCatalogSnapshot merge(RealmEditorCatalogSnapshot other) {
    if (generation != other.generation) return other;
    final definitions = <ResolvedTypeRef, TypeDefinition>{
      for (final definition in catalog.definitions) definition.id: definition,
      for (final definition in other.catalog.definitions)
        definition.id: definition,
    };
    return RealmEditorCatalogSnapshot(
      catalog: TypeCatalog(definitions.values.toList()),
      generation: generation,
      presentations: {...presentations, ...other.presentations},
      conversions: {...conversions, ...other.conversions},
      realmActions: {...realmActions, ...other.realmActions},
      subtypeResults: {...subtypeResults, ...other.subtypeResults},
      diagnostics: [...diagnostics, ...other.diagnostics],
    );
  }
}

@freezed
sealed class RealmEditorCatalogFetchResult
    with _$RealmEditorCatalogFetchResult {
  const factory RealmEditorCatalogFetchResult.fetched(
    RealmEditorCatalogSnapshot snapshot,
  ) = RealmEditorCatalogFetched;
  const factory RealmEditorCatalogFetchResult.generationMismatch(
    CatalogGeneration currentGeneration,
  ) = RealmEditorCatalogGenerationMismatch;
  const factory RealmEditorCatalogFetchResult.unavailable(
    List<TypeDiagnostic> diagnostics,
  ) = RealmEditorCatalogFetchUnavailable;
}

@freezed
sealed class RealmEditorCatalogWatchEvent with _$RealmEditorCatalogWatchEvent {
  const factory RealmEditorCatalogWatchEvent.invalidated(
    CatalogGeneration generation,
  ) = RealmEditorCatalogInvalidated;
  const factory RealmEditorCatalogWatchEvent.unavailable(
    List<TypeDiagnostic> diagnostics,
  ) = RealmEditorCatalogWatchUnavailable;
}

abstract interface class RealmEditorCatalogSource {
  Future<RealmEditorCatalogFetchResult> fetch(
    RealmEditorCatalogRoute route,
    RealmEditorCatalogRequest request, {
    CatalogGeneration? expectedGeneration,
  });

  Stream<RealmEditorCatalogWatchEvent> watchInvalidations(
    RealmEditorCatalogRoute route,
  );
}

final class UnavailableRealmEditorCatalogSource
    implements RealmEditorCatalogSource {
  const UnavailableRealmEditorCatalogSource();

  @override
  Future<RealmEditorCatalogFetchResult> fetch(
    RealmEditorCatalogRoute route,
    RealmEditorCatalogRequest request, {
    CatalogGeneration? expectedGeneration,
  }) async =>
      RealmEditorCatalogFetchResult.unavailable([_unavailableDiagnostic()]);

  @override
  Stream<RealmEditorCatalogWatchEvent> watchInvalidations(
    RealmEditorCatalogRoute route,
  ) => Stream.value(
    RealmEditorCatalogWatchEvent.unavailable([_unavailableDiagnostic()]),
  );
}

TypeDiagnostic realmEditorCatalogUnavailableDiagnostic(String message) =>
    TypeDiagnostic(
      code: TypeDiagnosticCode.invalidPresentation,
      message: message,
      pathPresent: false,
    );

TypeDiagnostic _unavailableDiagnostic() =>
    realmEditorCatalogUnavailableDiagnostic(
      "Realm editor catalog transport is unavailable",
    );
