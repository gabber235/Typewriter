import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

part "portable_presentation_document.freezed.dart";

/// Resolves resource findings from the same observation used for display.
typedef ResourceDiagnosticReader =
    List<PortablePresentationDiagnostic> Function(skir.ResourceId);

List<PortablePresentationDiagnostic> noResourceDiagnostics(
  skir.ResourceId id,
) => const [];

/// Interpretation contract for a portable binding. Complete bindings expose
/// a type use; partial bindings preserve an unfinished type selection.
@freezed
sealed class PortablePresentationBindingSchema
    with _$PortablePresentationBindingSchema {
  const factory PortablePresentationBindingSchema.complete(skir.TypeUse use) =
      CompletePortablePresentationBinding;

  const factory PortablePresentationBindingSchema.partial(
    skir.TypeSelection selection,
  ) = PartialPortablePresentationBinding;
}

/// One observed value and its schema, editability and optional resource origin.
/// Writes pass through `PortablePresentationHost` rather than mutating this value.
@freezed
abstract class PortablePresentationBinding with _$PortablePresentationBinding {
  const factory PortablePresentationBinding({
    required PortablePresentationBindingSchema schema,
    required skir.DataValue value,
    @Default(false) bool editable,
    skir.ValueLocation? location,
  }) = _PortablePresentationBinding;
}

/// An immutable presentation observation interpreted by one checked catalog.
///
/// Local service documents and Realm documents use the same generated values,
/// expressions, and presentation tree. Persistence and optional capabilities
/// remain on the host that produced this observation.
@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
abstract class PortablePresentationDocument
    with _$PortablePresentationDocument {
  factory PortablePresentationDocument({
    required CheckedEditorCatalog catalog,
    required skir.PresentationNode root,
    required Map<skir.ExpressionBindingId, PortablePresentationBinding>
    bindings,
    required skir.EvaluationBudget budget,
    PortableExpressionQueries? queries,
    ResourceDiagnosticReader resourceDiagnostics = noResourceDiagnostics,
    List<PortablePresentationDiagnostic> diagnostics = const [],
    PortableDiagnosticFallback diagnosticFallback =
        PortableDiagnosticFallback.presentation,
    skir.PresentationRole? role,
    skir.PresentationMaterial? material,
    List<skir.PresentationContextInput>? contextInputs,
    Set<skir.PresentationId> activePresentations = const {},
    Map<String, skir.PresentationNode> slots = const {},
  }) {
    if (material != null && contextInputs != null) {
      throw ArgumentError(
        "Material declares its own context inputs",
        "contextInputs",
      );
    }
    if (queries != null && !identical(queries.catalog, catalog)) {
      throw ArgumentError(
        "Presentation and query catalogs must have the same owner",
      );
    }
    for (final value in bindings.values) {
      if (value.schema case PartialPortablePresentationBinding(:final selection)
          when selection is! skir.TypeSelection_pendingWrapper) {
        throw ArgumentError.value(
          selection,
          "bindings",
          "Partial bindings require an unfinished type selection",
        );
      }
    }
    return PortablePresentationDocument._value(
      catalog: catalog,
      root: root,
      bindings: Map.unmodifiable(bindings),
      budget: budget,
      queries: queries,
      resourceDiagnostics: resourceDiagnostics,
      diagnostics: List.unmodifiable(diagnostics),
      diagnosticFallback: diagnosticFallback,
      role: role,
      material: material,
      contextInputs: List.unmodifiable(
        material?.dependencies.contextInputs ?? contextInputs ?? const [],
      ),
      activePresentations: Set.unmodifiable(activePresentations),
      slots: Map.unmodifiable(slots),
    );
  }

  const PortablePresentationDocument._();

  const factory PortablePresentationDocument._value({
    required CheckedEditorCatalog catalog,
    required skir.PresentationNode root,
    required Map<skir.ExpressionBindingId, PortablePresentationBinding>
    bindings,
    required skir.EvaluationBudget budget,
    required PortableExpressionQueries? queries,
    required ResourceDiagnosticReader resourceDiagnostics,
    required List<PortablePresentationDiagnostic> diagnostics,
    required PortableDiagnosticFallback diagnosticFallback,
    required skir.PresentationRole? role,
    required skir.PresentationMaterial? material,

    /// Values the presentation reads from its surroundings: the material's
    /// declarations, or those of a presentation built without material.
    required List<skir.PresentationContextInput> contextInputs,
    required Set<skir.PresentationId> activePresentations,
    required Map<String, skir.PresentationNode> slots,
  }) = _PortablePresentationDocument;
}

/// Immutable lexical bindings and read evidence captured for one interaction.
///
/// Catalog generation gates lookup, while resource locations connect bindings
/// to authored values. Async writes use this captured observation to reject
/// stale interaction intent rather than silently reading a new target.
@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
abstract class PortableInvocationContext with _$PortableInvocationContext {
  factory PortableInvocationContext({
    required Map<skir.ExpressionBindingId, PortableExpressionBinding> bindings,
    required skir.CatalogGeneration catalogGeneration,
    PortableExpressionQueries? queries,
    ResourceDiagnosticReader resourceDiagnostics = noResourceDiagnostics,
    Iterable<skir.ValueLocation> expressionReads = const [],
  }) {
    if (queries != null &&
        queries.catalog.snapshot.generation != catalogGeneration) {
      throw StateError("Invocation and query catalog generations differ");
    }
    return PortableInvocationContext._value(
      bindings: Map.unmodifiable(bindings),
      catalogGeneration: catalogGeneration,
      queries: queries,
      resourceDiagnostics: resourceDiagnostics,
      expressionReads: List.unmodifiable(expressionReads),
    );
  }

  const PortableInvocationContext._();

  const factory PortableInvocationContext._value({
    required Map<skir.ExpressionBindingId, PortableExpressionBinding> bindings,
    required skir.CatalogGeneration catalogGeneration,
    required PortableExpressionQueries? queries,
    required ResourceDiagnosticReader resourceDiagnostics,
    required List<skir.ValueLocation> expressionReads,
  }) = _PortableInvocationContext;

  skir.DataValue? read(
    skir.BindingRef reference,
    skir.CatalogGeneration generation,
  ) {
    if (catalogGeneration != generation) return null;
    final value = bindings[reference.bindingId]?.value;
    return value?.editorValueAt(reference.path);
  }

  skir.ValueLocation? location(
    skir.BindingRef reference,
    skir.CatalogGeneration generation,
  ) {
    if (catalogGeneration != generation) return null;
    final base = bindings[reference.bindingId]?.location;
    return base == null
        ? null
        : skir.ValueLocation(
            resource: base.resource,
            path: skir.ValuePath(
              segments: [...base.path.segments, ...reference.path.segments],
            ),
          );
  }

  bool isCurrent(
    skir.BindingRef reference,
    skir.CatalogGeneration generation,
    skir.DataValue? current,
  ) =>
      catalogGeneration == generation &&
      current != null &&
      read(reference, generation) == current;

  PortableInvocationContext withExpressionReads(
    Iterable<skir.ValueLocation> reads,
  ) => PortableInvocationContext(
    bindings: bindings,
    catalogGeneration: catalogGeneration,
    queries: queries,
    resourceDiagnostics: resourceDiagnostics,
    expressionReads: [...expressionReads, ...reads],
  );

  PortableInvocationContext withBinding(
    skir.ExpressionBindingId id,
    PortableExpressionBinding binding,
  ) => PortableInvocationContext(
    bindings: {...bindings, id: binding},
    catalogGeneration: catalogGeneration,
    queries: queries,
    resourceDiagnostics: resourceDiagnostics,
    expressionReads: expressionReads,
  );

  PortableInvocationContext withBindings(
    Map<skir.ExpressionBindingId, PortableExpressionBinding> values,
  ) => PortableInvocationContext(
    bindings: {...bindings, ...values},
    catalogGeneration: catalogGeneration,
    queries: queries,
    resourceDiagnostics: resourceDiagnostics,
    expressionReads: expressionReads,
  );
}

/// Optional operations supplied by hosts that support more than local writes.
///
/// A service or topology editor normally leaves these callbacks absent. A
/// Realm host can attach its existing search, initialization, navigation, and
/// command operations without changing the portable document.
@freezed
abstract class PortablePresentationCapabilities
    with _$PortablePresentationCapabilities {
  const factory PortablePresentationCapabilities({
    Future<void> Function(
      skir.CapabilityId capabilityId,
      skir.DataValue payload,
    )?
    invokeCommand,
    Stream<skir.RealmPresentationSearchUpdate> Function(
      skir.RealmPresentationSearchRequest request,
    )?
    watchSearch,
    Future<void> Function()? reload,
    ValueChanged<skir.ResourceId>? openResource,
    Future<PortablePresentationWriteResult> Function(
      skir.EditorAction action,
      PortableInvocationContext context,
    )?
    resourceAction,
    Future<skir.PreparedValue> Function(skir.ValuePreparationRequest request)?
    prepareValue,
  }) = _PortablePresentationCapabilities;
}

@freezed
sealed class PortablePresentationWriteResult
    with _$PortablePresentationWriteResult {
  const factory PortablePresentationWriteResult.applied() =
      PortablePresentationWriteApplied;

  const factory PortablePresentationWriteResult.rejected(
    List<PortablePresentationDiagnostic> diagnostics,
  ) = PortablePresentationWriteRejected;
}
