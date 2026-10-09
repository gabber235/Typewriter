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

final class PortableCollectionRowProjection {
  const PortableCollectionRowProjection({
    required this.resource,
    required this.configuration,
    required this.label,
    required this.row,
    required this.key,
    required this.canonicalKey,
    required this.selectable,
  });

  final skir.ResourceId resource;
  final skir.TypeSelection configuration;
  final String label;
  final skir.DataValue row;
  final skir.DataValue key;
  final String canonicalKey;
  final bool selectable;
}

final class PortableCollectionProjection {
  const PortableCollectionProjection({
    required this.definition,
    required this.rows,
    this.problem,
  });

  final skir.PresentationCollectionDefinition? definition;
  final List<PortableCollectionRowProjection> rows;
  final String? problem;
}

final class PortableResourceProjection {
  const PortableResourceProjection({
    required this.resource,
    required this.configuration,
    required this.label,
    required this.value,
  });

  final skir.ResourceId resource;
  final skir.TypeSelection configuration;
  final String label;
  final skir.DataValue value;
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

final class PortablePageGraphPlacement {
  const PortablePageGraphPlacement({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  final int x;
  final int y;
  final int width;
  final int height;
}

final class PortablePageEntryProjection {
  const PortablePageEntryProjection({
    required this.resource,
    required this.occurrence,
    required this.resourceProjection,
    this.graph,
  });

  final skir.ResourceId resource;
  final skir.LinkOccurrence occurrence;
  final PortableResourceProjection resourceProjection;
  final PortablePageGraphPlacement? graph;
}

final class PortablePageEdgeProjection {
  const PortablePageEdgeProjection({
    required this.id,
    required this.source,
    required this.target,
  });

  final String id;
  final skir.ResourceId source;
  final skir.ResourceId target;
}

sealed class PortableTimelinePlacement {
  const PortableTimelinePlacement();
}

final class PortableTimelineKeyframe extends PortableTimelinePlacement {
  const PortableTimelineKeyframe(this.frame);

  final int frame;
}

final class PortableTimelineSegment extends PortableTimelinePlacement {
  const PortableTimelineSegment(this.startFrame, this.endFrame);

  final int startFrame;
  final int endFrame;
}

final class PortableTimelineCueProjection {
  const PortableTimelineCueProjection({
    required this.resource,
    required this.label,
    required this.placement,
    required this.children,
  });

  final skir.ResourceId resource;
  final String label;
  final PortableTimelinePlacement placement;
  final List<PortableTimelineCueProjection> children;
}

final class PortablePageProjection {
  const PortablePageProjection({
    required this.entries,
    required this.edges,
    required this.timeline,
    this.problem,
  });

  final List<PortablePageEntryProjection> entries;
  final List<PortablePageEdgeProjection> edges;
  final Map<skir.ResourceId, List<PortableTimelineCueProjection>> timeline;
  final String? problem;
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
