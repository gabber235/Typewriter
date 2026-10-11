import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

part "portable_presentation_host.freezed.dart";

/// One value exposed to a portable presentation.
///
/// The binding carries its exact checked type and current value. An editable
/// binding delegates every mutation to [PortablePresentationHost], which keeps
/// the persistence owner outside the presentation document.
@freezed
sealed class PortablePresentationBindingSchema
    with _$PortablePresentationBindingSchema {
  const factory PortablePresentationBindingSchema.complete(skir.TypeUse use) =
      CompletePortablePresentationBinding;

  const factory PortablePresentationBindingSchema.partial(
    skir.TypeSelection selection,
  ) = PartialPortablePresentationBinding;
}

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
    skir.PresentationRole? role,
    skir.PresentationMaterial? material,
    Set<skir.PresentationId> activePresentations = const {},
    Map<String, skir.PresentationNode> slots = const {},
  }) {
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
    required skir.PresentationRole? role,
    required skir.PresentationMaterial? material,
    required Set<skir.PresentationId> activePresentations,
    required Map<String, skir.PresentationNode> slots,
  }) = _PortablePresentationDocument;
}

final class PortableInvocationContext {
  PortableInvocationContext({
    required Map<skir.ExpressionBindingId, PortableExpressionBinding> bindings,
    required this.catalogGeneration,
  }) : bindings = Map.unmodifiable(bindings);

  final Map<skir.ExpressionBindingId, PortableExpressionBinding> bindings;
  final skir.CatalogGeneration catalogGeneration;

  PortableInvocationContext withBinding(
    skir.ExpressionBindingId id,
    PortableExpressionBinding binding,
  ) => PortableInvocationContext(
    bindings: {...bindings, id: binding},
    catalogGeneration: catalogGeneration,
  );

  PortableInvocationContext withBindings(
    Map<skir.ExpressionBindingId, PortableExpressionBinding> values,
  ) => PortableInvocationContext(
    bindings: {...bindings, ...values},
    catalogGeneration: catalogGeneration,
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
    Future<void> Function()? commit,
    ValueChanged<skir.ResourceId>? openResource,
    Future<skir.PreparedValue> Function(skir.ValuePreparationRequest request)?
    prepareValue,
  }) = _PortablePresentationCapabilities;
}

@freezed
sealed class PortablePresentationWriteResult
    with _$PortablePresentationWriteResult {
  const factory PortablePresentationWriteResult.applied() =
      PortablePresentationWriteApplied;

  const factory PortablePresentationWriteResult.rejected(String message) =
      PortablePresentationWriteRejected;
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

  PortablePresentationWriteResult addMapRow(
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

@freezed
abstract class PortableResourceProjection with _$PortableResourceProjection {
  const factory PortableResourceProjection({
    required skir.ResourceId resource,
    required skir.TypeSelection configuration,
    required String label,
    required skir.DataValue value,
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

sealed class PortableLinkCounterpartRequest {
  const PortableLinkCounterpartRequest();
}

final class PortableAutomaticCounterpart
    extends PortableLinkCounterpartRequest {
  const PortableAutomaticCounterpart();
}

final class PortableExistingCounterpart extends PortableLinkCounterpartRequest {
  const PortableExistingCounterpart(this.occurrence);

  final skir.LinkOccurrence occurrence;
}

final class PortableCreatedCounterpart extends PortableLinkCounterpartRequest {
  const PortableCreatedCounterpart(this.slot);

  final PortableNewCounterpartChoice slot;
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
abstract class PortablePageGraphPlacement with _$PortablePageGraphPlacement {
  const factory PortablePageGraphPlacement({
    required int x,
    required int y,
    required int width,
    required int height,
  }) = _PortablePageGraphPlacement;
}

@freezed
abstract class PortablePageEntryProjection with _$PortablePageEntryProjection {
  const factory PortablePageEntryProjection({
    required skir.ResourceId resource,
    required skir.LinkOccurrence occurrence,
    required PortableResourceProjection resourceProjection,
    PortablePageGraphPlacement? graph,
  }) = _PortablePageEntryProjection;
}

@freezed
abstract class PortablePageEdgeProjection with _$PortablePageEdgeProjection {
  const factory PortablePageEdgeProjection({
    required String id,
    required skir.ResourceId source,
    required skir.ResourceId target,
  }) = _PortablePageEdgeProjection;
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

@Freezed(map: FreezedMapOptions.none, when: FreezedWhenOptions.none)
abstract class PortablePageProjection with _$PortablePageProjection {
  factory PortablePageProjection({
    required List<PortablePageEntryProjection> entries,
    required List<PortablePageEdgeProjection> edges,
    required Map<skir.ResourceId, List<PortableTimelineCueProjection>> timeline,
    String? problem,
  }) => PortablePageProjection._value(
    entries: List.unmodifiable(entries),
    edges: List.unmodifiable(edges),
    timeline: {
      for (final entry in timeline.entries)
        entry.key: List.unmodifiable(entry.value),
    },
    problem: problem,
  );

  const factory PortablePageProjection._value({
    required List<PortablePageEntryProjection> entries,
    required List<PortablePageEdgeProjection> edges,
    required Map<skir.ResourceId, List<PortableTimelineCueProjection>> timeline,
    required String? problem,
  }) = _PortablePageProjection;
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

abstract interface class PortablePageHost {
  PortablePageProjection projectPage(
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

  PortablePresentationWriteResult removePageResource(
    PortablePageEntryProjection entry, {
    required bool delete,
    required PortableInvocationContext context,
  });
}

extension PortablePresentationRootInvocation on PortablePresentationHost {
  PortableInvocationContext get rootInvocation => PortableInvocationContext(
    bindings: {
      for (final entry in document.bindings.entries)
        entry.key: PortableExpressionBinding(
          value: entry.value.value,
          location: entry.value.location,
          schema: entry.value.schema,
        ),
    },
    catalogGeneration: document.catalog.snapshot.generation,
  );
}

/// Supplies the portable presentation used to review one retained draft.
///
/// The target owns the feature specific schema and binding codecs. The local
/// work session owns the live [EditorSource], so constructing this host keeps
/// presentation metadata separate from draft persistence and conflict policy.
abstract interface class PortablePresentationTarget {
  PortablePresentationHost? buildPortablePresentationHost(EditorSource source);
}

typedef PortablePresentationHostBuilder = PortablePresentationHost Function(
  EditorSource source,
);
