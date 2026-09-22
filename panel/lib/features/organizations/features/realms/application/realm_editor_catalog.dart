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
    Map<ResourceDefinitionId, RealmResourceDefinition> resourceDefinitions,
    @Default({})
    Map<AuthoringCreationSlotId, RealmAuthoringCreationSlot> creationSlots,
    @Default({}) Map<String, RealmRelationDefinition> relations,
    @Default({})
    Map<PresentationCollectionSourceId, RealmCollectionProjectionDefinition>
    collectionProjections,
    @Default([])
    List<RealmAuthoringCompilationProjection> compilationProjections,
    RealmAuthoringSearchDefinition? authoringSearch,
  }) = _RealmEditorCatalogSnapshot;
}

/// Describes which resource roots a registered compilation projection accepts.
final class RealmAuthoringCompilationProjection {
  const RealmAuthoringCompilationProjection({
    required this.id,
    required this.root,
  });

  final String id;
  final TypeExpression root;
}

final class RealmCollectionProjectionDefinition {
  const RealmCollectionProjectionDefinition({
    required this.sourceId,
    required this.definitions,
    required this.assignableTo,
    required this.rowType,
    required this.fields,
  });

  final PresentationCollectionSourceId sourceId;
  final Set<ResourceDefinitionId> definitions;
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

extension type const ResourceDefinitionId(String value) {}

extension type const AuthoringCreationSlotId(String value) {}

extension type const CoreResourceDefinitionIds._(Object _) {
  static const book = ResourceDefinitionId("typewriter.book");
  static const tag = ResourceDefinitionId("typewriter.tag");
  static const page = ResourceDefinitionId("typewriter.page");
  static const element = ResourceDefinitionId("typewriter.element");
}

extension type const CoreAuthoringCreationSlotIds._(Object _) {
  static const book = AuthoringCreationSlotId("typewriter:book");
  static const tag = AuthoringCreationSlotId("typewriter:tag");
  static const page = AuthoringCreationSlotId("typewriter:page");

  static AuthoringCreationSlotId pageElements(
    PageKindRef kind,
    String placement,
  ) => AuthoringCreationSlotId(
    "typewriter:page/${kind.id}/${kind.revision}/$placement",
  );
}

final class RealmResourceDefinition {
  const RealmResourceDefinition({required this.id, required this.acceptedRoot});

  final ResourceDefinitionId id;
  final TypeExpression acceptedRoot;
}

@freezed
abstract class RealmAuthoringSearchDefinition
    with _$RealmAuthoringSearchDefinition {
  const factory RealmAuthoringSearchDefinition({
    @Default({}) Set<ResourceDefinitionId> definitions,
    @Default([]) List<SearchSelectorDefinition> selectors,
    @Default([]) List<RealmAuthoringSearchFacetDefinition> facets,
  }) = _RealmAuthoringSearchDefinition;
}

@freezed
abstract class RealmAuthoringSearchFacetDefinition
    with _$RealmAuthoringSearchFacetDefinition {
  const factory RealmAuthoringSearchFacetDefinition({
    required String id,
    required String label,
    required String selectorId,
  }) = _RealmAuthoringSearchFacetDefinition;
}

enum RealmCreationHostCardinality { exactlyOne, oneOrMore }

enum RealmCreationRelationDirection { outgoing, incoming, both }

@freezed
sealed class RealmAuthoringCreationContext
    with _$RealmAuthoringCreationContext {
  const factory RealmAuthoringCreationContext.standalone() =
      RealmStandaloneCreationContext;

  const factory RealmAuthoringCreationContext.declaredRelation({
    required RealmCreationHostFilter hosts,
    required RealmCreationHostCardinality cardinality,
    required String relation,
    required RealmCreationRelationDirection direction,
  }) = RealmDeclaredRelationCreationContext;

  const factory RealmAuthoringCreationContext.referencePath({
    required RealmCreationHostFilter hosts,
    required RealmCreationHostCardinality cardinality,
    required DataPath path,
  }) = RealmReferencePathCreationContext;
}

@freezed
abstract class RealmCreationHostFilter with _$RealmCreationHostFilter {
  const factory RealmCreationHostFilter({
    @Default({}) Set<ResourceDefinitionId> definitions,
    TypeExpression? assignableTo,
  }) = _RealmCreationHostFilter;
}

@freezed
abstract class RealmAuthoringCreationSlot with _$RealmAuthoringCreationSlot {
  const factory RealmAuthoringCreationSlot({
    required AuthoringCreationSlotId id,
    required String label,
    required ResourceDefinitionId creates,
    required RealmAuthoringCreationContext context,
    required List<ResolvedTypeRef> concreteRoots,
  }) = _RealmAuthoringCreationSlot;

  const RealmAuthoringCreationSlot._();

  bool acceptsRoot(ResolvedTypeRef root) => concreteRoots.contains(root);
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

enum TypeInitializationRequirementReason { missingValue, concreteTypeRequired }

@freezed
abstract class TypeInitializationRequirement
    with _$TypeInitializationRequirement {
  const factory TypeInitializationRequirement({
    required DataPath path,
    required TypeExpression expected,
    required TypeInitializationRequirementReason reason,
  }) = _TypeInitializationRequirement;
}

@freezed
abstract class TypeInitializationDraft with _$TypeInitializationDraft {
  const factory TypeInitializationDraft({
    required ResolvedTypeRef rootType,
    required DataValue? suppliedValue,
    required List<TypeInitializationRequirement> requirements,
  }) = _TypeInitializationDraft;
}

@freezed
sealed class RealmTypedValueInitializationResult
    with _$RealmTypedValueInitializationResult {
  const factory RealmTypedValueInitializationResult.initialized(
    TypedValueEnvelope value,
  ) = RealmTypedValueInitialized;
  const factory RealmTypedValueInitializationResult.needsInput(
    TypeInitializationDraft draft,
  ) = RealmTypedValueInitializationNeedsInput;
  const factory RealmTypedValueInitializationResult.rejected(
    List<TypeDiagnostic> diagnostics,
  ) = RealmTypedValueInitializationRejected;
  const factory RealmTypedValueInitializationResult.generationMismatch(
    CatalogGeneration generation,
  ) = RealmTypedValueInitializationGenerationMismatch;
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
    required ResolvedTypeRef root,
    required DataValue? supplied,
    required TypeRegistry registry,
  });
}

extension RealmEditorCatalogConcreteTypeInitialization
    on RealmEditorCatalogSource {
  ConcreteTypeInitializer concreteTypeInitializer({
    required RealmEditorCatalogRoute route,
    required CatalogGeneration generation,
    required TypeRegistry registry,
  }) => ({required type, required supplied}) async {
    final result = await initialize(
      route,
      generation: generation,
      root: type,
      supplied: supplied,
      registry: registry,
    );
    return result.toConcreteTypeInitialization();
  };
}

extension RealmTypedValueInitializationConversion
    on RealmTypedValueInitializationResult {
  ConcreteTypeInitializationResult
  toConcreteTypeInitialization() => switch (this) {
    RealmTypedValueInitialized(:final value) => ConcreteTypeInitialized(value),
    RealmTypedValueInitializationNeedsInput(:final draft) =>
      ConcreteTypeNeedsInput(suppliedValue: draft.suppliedValue),
    RealmTypedValueInitializationRejected(:final diagnostics) =>
      ConcreteTypeInitializationRejected(diagnostics),
    RealmTypedValueInitializationGenerationMismatch(:final generation) =>
      ConcreteTypeInitializationRejected([
        TypeDiagnostic(
          code: TypeDiagnosticCode.invalidRevision,
          message:
              "The editor catalog changed to generation ${generation.value}",
          pathPresent: false,
        ),
      ]),
  };
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
    required ResolvedTypeRef root,
    required DataValue? supplied,
    required TypeRegistry registry,
  }) async =>
      RealmTypedValueInitializationResult.rejected([_unavailableDiagnostic()]);
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
