import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

part "portable_presentation_host.freezed.dart";

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
/// Writes pass through [PortablePresentationHost] rather than mutating this value.
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
    Set<skir.PresentationId> activePresentations = const {},
    Map<String, skir.PresentationNode> slots = const {},
  }) {
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
    Iterable<PortableExpressionRead> expressionReads = const [],
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
    required List<PortableExpressionRead> expressionReads,
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
    Iterable<PortableExpressionRead> reads,
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

/// Owns one portable presentation document and its mutation boundary.
///
/// Implementations notify listeners after their document changes. Reads stay
/// synchronous so one render observes one coherent document. Writes and
/// actions may suspend while their owning persistence boundary prepares work.
abstract interface class PortablePresentationHost implements Listenable {
  PortablePresentationDocument get document;

  bool get enabled;

  bool get readOnly;

  PortablePresentationCapabilities get capabilities;

  EditControl? commitControl(
    skir.BindingRef reference, {
    required PortableInvocationContext context,
  });

  skir.DataValue? read(
    skir.BindingRef reference, {
    required PortableInvocationContext context,
  });

  skir.ValueLocation? location(
    skir.BindingRef reference, {
    required PortableInvocationContext context,
  });

  skir.TypeUse? expectedType(
    skir.BindingRef reference, {
    required PortableInvocationContext context,
  });

  Future<PortablePresentationWriteResult> write(
    skir.BindingRef reference,
    skir.DataValue value, {
    required PortableInvocationContext context,
  });

  Future<PortablePresentationWriteResult> execute(
    skir.EditorAction editorAction, {
    required PortableInvocationContext context,
  });

  void dispose();
}

abstract interface class PortableCollectionMutationHost {
  Future<PortablePresentationWriteResult> addCollectionItem(
    skir.BindingRef reference, {
    required PortableInvocationContext context,
  });

  Future<PortablePresentationWriteResult> addMapRow(
    skir.BindingRef reference, {
    required PortableInvocationContext context,
  });
}

@freezed
abstract class PortableCollectionRowProjection
    with _$PortableCollectionRowProjection {
  const factory PortableCollectionRowProjection({
    required skir.ResourceId resource,
    required skir.TypeSelection configuration,
    required String label,
    required skir.DataValue row,
    required skir.DataValue key,
    required String canonicalKey,
    required bool selectable,
    PortablePresentationBindingSchema? schema,
  }) = _PortableCollectionRowProjection;
}

@Freezed(map: FreezedMapOptions.none, when: FreezedWhenOptions.none)
abstract class PortableCollectionProjection
    with _$PortableCollectionProjection {
  factory PortableCollectionProjection({
    required skir.PresentationCollectionDefinition? definition,
    required List<PortableCollectionRowProjection> rows,
    String? problem,
  }) => PortableCollectionProjection._value(
    definition: definition,
    rows: List.unmodifiable(rows),
    problem: problem,
  );

  const factory PortableCollectionProjection._value({
    required skir.PresentationCollectionDefinition? definition,
    required List<PortableCollectionRowProjection> rows,
    required String? problem,
  }) = _PortableCollectionProjection;
}

/// One resource as presentations see it: its configured value, its evaluated
/// display, and the diagnostics that belong to it.
@freezed
abstract class PortableResourceProjection with _$PortableResourceProjection {
  const factory PortableResourceProjection({
    required skir.ResourceId resource,
    required skir.TypeSelection configuration,
    required ResourceAppearance appearance,
    required skir.DataValue value,
    @Default([]) List<PortablePresentationDiagnostic> diagnostics,
    @Default(PortableDiagnosticFallback.presentation)
    PortableDiagnosticFallback diagnosticFallback,
  }) = _PortableResourceProjection;
}

abstract interface class PortableCollectionProjectionHost {
  PortableCollectionProjection projectCollection(
    String sourceId, {
    required skir.PresentationMaterial material,
    required PortableInvocationContext context,
  });

  PortableResourceProjection? projectResource(
    skir.ResourceId resource, {
    required PortableInvocationContext context,
  });
}

@freezed
sealed class PortableLinkCounterpartRequest
    with _$PortableLinkCounterpartRequest {
  const factory PortableLinkCounterpartRequest.automatic() =
      PortableAutomaticCounterpart;
  const factory PortableLinkCounterpartRequest.existing(
    skir.LinkOccurrence occurrence,
  ) = PortableExistingCounterpart;
  const factory PortableLinkCounterpartRequest.created(
    PortableNewCounterpartChoice slot,
  ) = PortableCreatedCounterpart;
  const factory PortableLinkCounterpartRequest.collection(
    skir.ValueLocation containing,
  ) = PortableCollectionCounterpart;
}

abstract interface class PortableLinkHost {
  bool get canPrepareCounterpart;

  PortableLinkPlanResult planLink(
    skir.ValueLocation source, {
    required PortableInvocationContext context,
  });

  Future<PortablePresentationWriteResult> connectLink({
    required PortableLinkPlan plan,
    required PortableLinkTargetChoice target,
    required PortableLinkCounterpartRequest counterpart,
    required PortableInvocationContext context,
  });

  PortablePresentationWriteResult disconnectLink(
    skir.LinkOccurrence occurrence, {
    required PortableInvocationContext context,
  });
}

@freezed
abstract class PortableGraphPlacement with _$PortableGraphPlacement {
  const factory PortableGraphPlacement({
    required int x,
    required int y,
    required int width,
    required int height,
  }) = _PortableGraphPlacement;
}

/// One resource laid out by a resources element: the target of one link of the
/// bound field, with the link value the layout binds while ordering members.
@freezed
abstract class PortableResourceMember with _$PortableResourceMember {
  const factory PortableResourceMember({
    required skir.ResourceId resource,
    required skir.LinkOccurrence occurrence,
    required skir.DataValue link,
    required PortableResourceProjection resourceProjection,
    PortableGraphPlacement? graph,
  }) = _PortableResourceMember;

  const PortableResourceMember._();

  ResourceAppearance get appearance => resourceProjection.appearance;
}

@freezed
abstract class PortableResourceEdge with _$PortableResourceEdge {
  const factory PortableResourceEdge({
    required String id,
    required skir.ResourceId source,
    required skir.ResourceId target,
  }) = _PortableResourceEdge;
}

@freezed
sealed class PortableTimelinePlacement with _$PortableTimelinePlacement {
  const factory PortableTimelinePlacement.keyframe(int frame) =
      PortableTimelineKeyframe;
  const factory PortableTimelinePlacement.segment(
    int startFrame,
    int endFrame,
  ) = PortableTimelineSegment;
}

@Freezed(map: FreezedMapOptions.none, when: FreezedWhenOptions.none)
abstract class PortableTimelineCueProjection
    with _$PortableTimelineCueProjection {
  factory PortableTimelineCueProjection({
    required skir.ResourceId resource,
    required String label,
    required PortableTimelinePlacement placement,
    required List<PortableTimelineCueProjection> children,
  }) => PortableTimelineCueProjection._value(
    resource: resource,
    label: label,
    placement: placement,
    children: List.unmodifiable(children),
  );

  const factory PortableTimelineCueProjection._value({
    required skir.ResourceId resource,
    required String label,
    required PortableTimelinePlacement placement,
    required List<PortableTimelineCueProjection> children,
  }) = _PortableTimelineCueProjection;
}

/// The members of a resources binding in link order, the edges among them,
/// and for each member the owned resources it places on a timeline.
@Freezed(map: FreezedMapOptions.none, when: FreezedWhenOptions.none)
abstract class PortableResourcesProjection with _$PortableResourcesProjection {
  factory PortableResourcesProjection({
    required List<PortableResourceMember> members,
    required List<PortableResourceEdge> edges,
    required Map<skir.ResourceId, List<PortableTimelineCueProjection>> timeline,
    String? problem,
  }) => PortableResourcesProjection._value(
    members: List.unmodifiable(members),
    edges: List.unmodifiable(edges),
    timeline: {
      for (final entry in timeline.entries)
        entry.key: List.unmodifiable(entry.value),
    },
    problem: problem,
  );

  const factory PortableResourcesProjection._value({
    required List<PortableResourceMember> members,
    required List<PortableResourceEdge> edges,
    required Map<skir.ResourceId, List<PortableTimelineCueProjection>> timeline,
    required String? problem,
  }) = _PortableResourcesProjection;
}

final class PortableGraphPositionChange {
  const PortableGraphPositionChange(this.resource, this.x, this.y);

  final skir.ResourceId resource;
  final int x;
  final int y;
}

final class PortableGraphSizeChange {
  const PortableGraphSizeChange(this.resource, this.width, this.height);

  final skir.ResourceId resource;
  final int width;
  final int height;
}

final class PortableTimelineChange {
  const PortableTimelineChange(this.resource, this.startFrame, this.endFrame);

  final skir.ResourceId resource;
  final int startFrame;
  final int endFrame;
}

/// Lays out the resources of a bound link field for every resources layout.
/// Members are the link targets of the bound field; geometry writes go to each
/// member's published placement field.
abstract interface class PortableResourcesHost {
  PortableResourcesProjection projectResources(
    skir.BindingRef source, {
    required PortableInvocationContext context,
  });

  PortablePresentationWriteResult moveGraphNodes(
    List<PortableGraphPositionChange> changes, {
    required PortableInvocationContext context,
  });

  PortablePresentationWriteResult resizeGraphNodes(
    List<PortableGraphSizeChange> changes, {
    required PortableInvocationContext context,
  });

  PortablePresentationWriteResult moveTimelineElements(
    List<PortableTimelineChange> changes, {
    required PortableInvocationContext context,
  });

  /// Unlinks [member] from the bound field, or deletes it when [delete].
  PortablePresentationWriteResult removeMember(
    PortableResourceMember member, {
    required bool delete,
    required PortableInvocationContext context,
  });
}

extension PortablePresentationRootInvocation on PortablePresentationHost {
  PortableInvocationContext get rootInvocation {
    final observation = document;
    return PortableInvocationContext(
      bindings: {
        for (final entry in observation.bindings.entries)
          entry.key: PortableExpressionBinding(
            value: entry.value.value,
            location: entry.value.location,
            schema: entry.value.schema,
          ),
      },
      catalogGeneration: observation.catalog.snapshot.generation,
      queries: observation.queries,
      resourceDiagnostics: observation.resourceDiagnostics,
    );
  }
}
