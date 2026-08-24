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

  RealmServiceAddress get address => RealmServiceAddress(
    organizationId: this.organizationId,
    realmId: this.realmId,
  );

  String get fetchSubject => address.request("editor.catalog.fetch");

  String get invalidationRequestSubject =>
      address.request("editor.catalog.invalidate");

  String get invalidationSubject => address.event("editor.catalog.invalidate");

  String get elementsFetchSubject => address.request("editor.elements.fetch");
}

@freezed
abstract class RealmEditorCatalogSnapshot with _$RealmEditorCatalogSnapshot {
  const factory RealmEditorCatalogSnapshot({
    required TypeCatalog catalog,
    required CatalogGeneration generation,
    @Default({}) Map<PresentationId, PresentationDefinition> presentations,
    @Default({}) Map<ConversionId, ConversionDefinition> conversions,
    @Default({}) Map<CapabilityId, CapabilityDefinition> capabilities,
    @Default({}) Map<String, RealmEditorSubtypeResult> subtypeResults,
    @Default([]) List<TypeDiagnostic> diagnostics,
    @Default({}) Map<String, RealmElementCatalogEntry> elements,
  }) = _RealmEditorCatalogSnapshot;

  const RealmEditorCatalogSnapshot._();

  RealmEditorCatalogSnapshot merge(RealmEditorCatalogSnapshot other) {
    if (generation != other.generation) return other;
    return RealmEditorCatalogSnapshot(
      catalog: other.catalog,
      generation: generation,
      presentations: {...presentations, ...other.presentations},
      conversions: {...conversions, ...other.conversions},
      capabilities: {...capabilities, ...other.capabilities},
      subtypeResults: {...subtypeResults, ...other.subtypeResults},
      diagnostics: [...diagnostics, ...other.diagnostics],
      elements: {...elements, ...other.elements},
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
