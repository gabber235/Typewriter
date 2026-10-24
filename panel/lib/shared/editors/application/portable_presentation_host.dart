import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

part "portable_presentation_host.freezed.dart";

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
    required skir.ResourceAppearance appearance,
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

  skir.ResourceAppearance get appearance => resourceProjection.appearance;
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
