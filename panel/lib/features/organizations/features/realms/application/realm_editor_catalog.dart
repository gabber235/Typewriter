// The realm editor catalog is the versioned capability boundary between the
// panel and a running realm. It carries the authoritative type catalog plus
// the presentations, conversions, capabilities, discovered elements, and page
// editors needed to construct local editors. Fetches are paired with an
// invalidation watch so consumers can replace stale definitions after a realm
// reload without owning transport details.
import "package:freezed_annotation/freezed_annotation.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

part "realm_editor_catalog.freezed.dart";

/// Identifies one realm catalog endpoint and derives its request subjects.
///
/// Keeping subject derivation here prevents providers and transports from
/// constructing operation names independently. Organization and realm
/// identifiers stay typed until this transport boundary. Fetch and
/// invalidation subjects are separate because fetch is request and response
/// traffic, while invalidation is a long lived watch. The route owns no
/// connection or subscription.
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

  String get initializationSubject =>
      address.request("editor.typed.value.initialize");

  String get invalidationRequestSubject =>
      address.request("editor.catalog.invalidate");

  String get invalidationSubject => address.event("editor.catalog.invalidate");
}

/// One internally consistent catalog generation used by editor construction.
///
/// The realm service is authoritative. Consumers may use this snapshot until
/// an invalidation changes [generation]. That generation is sent with later
/// capability calls. Diagnostics describe rejected or undecodable entries and
/// are retained so valid definitions can still be rendered.
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
    @Default(RealmPageCatalog()) RealmPageCatalog pageCatalog,
    @Default({})
    Map<skir.ResourceKind, RealmResourceKindDefinition> resourceKinds,
    @Default({}) Map<String, RealmRelationDefinition> relations,
    @Default({})
    Map<PresentationCollectionSourceId, RealmCollectionProjectionDefinition>
    collectionProjections,
  }) = _RealmEditorCatalogSnapshot;
}

final class RealmCollectionProjectionDefinition {
  const RealmCollectionProjectionDefinition({
    required this.sourceId,
    required this.kinds,
    required this.assignableTo,
    required this.rowType,
    required this.fields,
  });

  final PresentationCollectionSourceId sourceId;
  final Set<skir.ResourceKind> kinds;
  final TypeExpression? assignableTo;
  final ResolvedTypeRef rowType;
  final List<RealmCollectionProjectionField> fields;
}

final class RealmCollectionProjectionField {
  const RealmCollectionProjectionField({
    required this.target,
    required this.source,
  });

  final DataPath target;
  final RealmCollectionProjectionSource source;
}

sealed class RealmCollectionProjectionSource {
  const RealmCollectionProjectionSource();
}

final class RealmCollectionResourceId extends RealmCollectionProjectionSource {
  const RealmCollectionResourceId();
}

final class RealmCollectionContentPath extends RealmCollectionProjectionSource {
  const RealmCollectionContentPath(this.path);

  final DataPath path;
}

final class RealmCollectionLiteral extends RealmCollectionProjectionSource {
  const RealmCollectionLiteral(this.value);

  final DataValue value;
}

final class RealmResourceKindDefinition {
  const RealmResourceKindDefinition({
    required this.kind,
    required this.acceptedRoot,
    required this.defaultRoot,
  });

  final skir.ResourceKind kind;
  final TypeExpression acceptedRoot;
  final ResolvedTypeRef? defaultRoot;
}

enum RealmRelationDeletePolicy { restrict, cascade, clear }

enum RealmRelationCardinality { one, many }

enum RealmRelationEndpointSide { source, target }

final class RealmRelationEndpointDefinition {
  const RealmRelationEndpointDefinition({
    required this.owner,
    required this.path,
    required this.side,
    required this.cardinality,
  });

  final ResolvedTypeRef owner;
  final DataPath path;
  final RealmRelationEndpointSide side;
  final RealmRelationCardinality cardinality;
}

final class RealmRelationDefinition {
  const RealmRelationDefinition({
    required this.id,
    required this.source,
    required this.target,
    required this.onSourceDelete,
    required this.onTargetDelete,
    required this.sourceEndpoint,
    required this.targetEndpoint,
  });

  final String id;
  final ResolvedTypeRef source;
  final ResolvedTypeRef target;
  final RealmRelationDeletePolicy onSourceDelete;
  final RealmRelationDeletePolicy onTargetDelete;
  final RealmRelationEndpointDefinition? sourceEndpoint;
  final RealmRelationEndpointDefinition? targetEndpoint;
}

/// Outcome of fetching the catalog requested by a consumer.
///
/// A generation mismatch is a coordination result, not transport failure. The
/// cache retries against [currentGeneration]. Unavailable diagnostics are
/// terminal for that fetch and preserve any previous snapshot at the cache.
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

sealed class RealmTypedValueInitializationResult {
  const RealmTypedValueInitializationResult();
}

final class RealmTypedValueInitialized
    extends RealmTypedValueInitializationResult {
  const RealmTypedValueInitialized(this.value);

  final TypedValueEnvelope value;
}

final class RealmTypedValueInitializationRejected
    extends RealmTypedValueInitializationResult {
  const RealmTypedValueInitializationRejected(this.diagnostics);

  final List<TypeDiagnostic> diagnostics;
}

final class RealmTypedValueInitializationGenerationMismatch
    extends RealmTypedValueInitializationResult {
  const RealmTypedValueInitializationGenerationMismatch(this.generation);

  final CatalogGeneration generation;
}

/// Notification from the realm that the catalog generation changed or watching
/// became impossible. An invalidation carries the generation to request next;
/// unavailability ends the useful watch state and requires a later provider
/// refresh. The cache surfaces the failure without discarding its prior
/// snapshot.
@freezed
sealed class RealmEditorCatalogWatchEvent with _$RealmEditorCatalogWatchEvent {
  const factory RealmEditorCatalogWatchEvent.invalidated(
    CatalogGeneration generation,
  ) = RealmEditorCatalogInvalidated;
  const factory RealmEditorCatalogWatchEvent.unavailable(
    List<TypeDiagnostic> diagnostics,
  ) = RealmEditorCatalogWatchUnavailable;
}

/// Boundary for fetching catalog projections and receiving invalidations.
///
/// Implementations own protocol encoding and decoding. The cache owns merged
/// consumer demand, state publication, generation retry, stale response
/// suppression, and subscription lifetime. Callers should use
/// [RealmEditorCatalogCache] unless they need another source implementation.
abstract interface class RealmEditorCatalogSource {
  Future<RealmEditorCatalogFetchResult> fetch(
    RealmEditorCatalogRoute route,
    RealmEditorCatalogRequest request, {
    CatalogGeneration? expectedGeneration,
  });

  Stream<RealmEditorCatalogWatchEvent> watchInvalidations(
    RealmEditorCatalogRoute route,
  );

  Future<RealmTypedValueInitializationResult> initialize(
    RealmEditorCatalogRoute route, {
    required CatalogGeneration generation,
    required TypedValueEnvelope partial,
    required TypeRegistry registry,
  });
}

/// Catalog source used when the realm transport cannot be constructed.
///
/// It returns a diagnostic fetch result and a diagnostic invalidation event so
/// consumers render an unavailable catalog instead of treating missing transport
/// as an empty, valid catalog.
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

  @override
  Future<RealmTypedValueInitializationResult> initialize(
    RealmEditorCatalogRoute route, {
    required CatalogGeneration generation,
    required TypedValueEnvelope partial,
    required TypeRegistry registry,
  }) async => RealmTypedValueInitializationRejected([_unavailableDiagnostic()]);
}

/// Converts source and decoding failures into diagnostics understood by editor
/// consumers without exposing transport exceptions across the catalog boundary.
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
