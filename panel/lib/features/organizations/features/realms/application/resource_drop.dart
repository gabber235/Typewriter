import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

part "resource_drop.freezed.dart";
part "resource_drop.g.dart";

/// The one drag payload every resource item produces: the resource the
/// gesture started on and every resource it carries.
@freezed
abstract class ResourceDrag with _$ResourceDrag implements GraphDragData {
  const factory ResourceDrag({
    required AuthoringScope scope,
    required AuthoringResourceIdentifier primary,
    required List<skir.ResourceId> subjects,

    /// Set when a tree group header is dragged: its members keep their path
    /// below the group when they move into another group.
    DraggedGroup? group,
  }) = _ResourceDrag;

  const ResourceDrag._();

  /// Carries the selection only when the gesture starts on a selected
  /// resource of the same scope; otherwise only [primary].
  factory ResourceDrag.forSelection({
    required AuthoringResourceIdentifier primary,
    required Iterable<SelectableIdentifier> selection,
  }) {
    final selected = selection
        .whereType<AuthoringResourceIdentifier>()
        .where((id) => id.scope == primary.scope)
        .toList(growable: false);
    return ResourceDrag(
      scope: primary.scope,
      primary: primary,
      subjects: selected.contains(primary)
          ? [
              primary.resourceId,
              for (final id in selected)
                if (id != primary) id.resourceId,
            ]
          : [primary.resourceId],
    );
  }

  @override
  GraphIdentifier get graphId => switch (group) {
    final group? => GraphIdentifier("group:${group.path}"),
    null => primary.graphId,
  };
}

/// A dragged tree group: the hierarchy path field its members are grouped by
/// and the group's path.
@freezed
abstract class DraggedGroup with _$DraggedGroup {
  const factory DraggedGroup({
    required skir.ValuePath field,
    required String path,
  }) = _DraggedGroup;
}

/// Where a dragged resource is released.
@freezed
sealed class DropDestination with _$DropDestination {
  /// A resource item, breadcrumb or inspector heading. A graph canvas also
  /// offers its own resource, with the pointer as [anchor] for operations
  /// that place graph members.
  const factory DropDestination.resource(skir.ResourceId id, {Offset? anchor}) =
      ResourceDestination;

  /// An inspector link control or a graph canvas: writes the link directly,
  /// validated by the planner. A canvas places linked graph members at
  /// [anchor], in grid units.
  const factory DropDestination.linkField(
    skir.ValueLocation location, {
    Offset? anchor,
  }) = LinkFieldDestination;

  /// A tree group header: rewrites the grouped path field of every dragged
  /// resource.
  const factory DropDestination.regroup(skir.ValuePath field, String value) =
      RegroupDestination;
}

/// Candidates for one drag, indexed by operation.
@freezed
abstract class DropCandidateIndex with _$DropCandidateIndex {
  const factory DropCandidateIndex({
    required ResourceDrag drag,
    required Map<skir.ResourceOperationId, skir.DropCandidates> byOperation,
  }) = _DropCandidateIndex;

  const DropCandidateIndex._();

  List<skir.ResourceId> get subjects => drag.subjects;

  Iterable<skir.ResourceOperationId> operationsAccepting(skir.ResourceId id) =>
      byOperation.entries
          .where((entry) => entry.value.destinations.contains(id))
          .map((entry) => entry.key);
}

/// Fetched once when a drag starts, so hovering is a local lookup. Retries a
/// stale observation once, as [resourceOperations] does.
@riverpod
Future<DropCandidateIndex> dropCandidates(Ref ref, ResourceDrag drag) async {
  final workspace = ref.read(realmEditingProvider(drag.scope));
  final commands = ref.watch(authoredResourceCommandsProvider(drag.scope));
  for (var attempt = 0; attempt < 2; attempt++) {
    final result = await commands.resolveDropCandidates(
      skir.ResolveDropCandidatesRequest(
        invocation: captureResourceOperationInvocation(
          document: workspace.document,
          targets: drag.subjects,
          invocationId: skir.InvocationId(value: "drop-candidates"),
        ),
        context: workspace.captureOperationContext().context,
      ),
    );
    if (!ref.mounted) throw StateError("The drag ended");
    switch (result) {
      case skir.ResolveDropCandidatesResult_resolvedWrapper(:final value):
        return DropCandidateIndex(
          drag: drag,
          byOperation: {
            for (final candidates in value) candidates.operation: candidates,
          },
        );
      case skir.ResolveDropCandidatesResult_staleObservationWrapper():
        await workspace.refreshConfirmed();
      default:
        throw StateError("Drop targets are unavailable. Refresh the Realm");
    }
  }
  throw StateError("Saved resources changed again. Refresh the Realm");
}

/// One thing a drop can do. Offers at one destination sort by [rank].
@freezed
sealed class DropOffer with _$DropOffer {
  const DropOffer._();

  /// Runs a catalog operation whose drop field takes [destination].
  const factory DropOffer.operation({
    required skir.ResourceOperationDefinition operation,
    required skir.ResourceId destination,
    Offset? anchor,
  }) = OperationDropOffer;

  /// Writes a link to every dragged resource at [location].
  const factory DropOffer.link({
    required skir.ValueLocation location,
    Offset? anchor,
  }) = LinkDropOffer;

  /// Moves every dragged resource into the group [value] of [field].
  const factory DropOffer.regroup({
    required skir.ValuePath field,
    required String value,
  }) = RegroupDropOffer;

  String get label => switch (this) {
    OperationDropOffer(:final operation) => operation.presentation.label,
    LinkDropOffer() => "Link",
    RegroupDropOffer(:final value) =>
      value.isEmpty ? "Move out of groups" : "Move to $value",
  };

  /// What the hover chip says.
  String get hint => switch (this) {
    OperationDropOffer(:final operation) =>
      operation.drop?.hint ?? operation.presentation.label,
    LinkDropOffer() => "Link here",
    RegroupDropOffer() => label,
  };

  String get icon => switch (this) {
    OperationDropOffer(:final operation) => operation.presentation.icon,
    LinkDropOffer() => "mdi:link-variant",
    RegroupDropOffer() => "mdi:folder-move-outline",
  };

  /// Menu order: group, then order, then label.
  (int, int, String) get rank => switch (this) {
    OperationDropOffer(:final operation) => (
      operationGroupRank(operation.presentation.group),
      operation.presentation.order,
      label,
    ),
    _ => (operationGroupRank(skir.OperationGroup.organize), 0, label),
  };
}

/// The display position of an operation group in menus.
int operationGroupRank(skir.OperationGroup group) => switch (group) {
  skir.OperationGroup.edit => 0,
  skir.OperationGroup.organize => 1,
  skir.OperationGroup.destructive => 2,
  _ => 3,
};

extension DropOffers on DropCandidateIndex {
  /// Offers for the most specific destination that has any, sorted by group
  /// then order.
  List<DropOffer> offersFor(
    List<DropDestination> destinations,
    AuthoringDocument document,
  ) {
    for (final destination in destinations) {
      final offers = switch (destination) {
        ResourceDestination(:final id, :final anchor) =>
          subjects.contains(id)
              ? const <DropOffer>[]
              : [
                  for (final operation in operationsAccepting(id))
                    if (document.catalog.snapshot.resourceOperations
                            .firstWhereOrNull(
                              (definition) => definition.id == operation,
                            )
                        case final definition? when definition.drop != null)
                      DropOffer.operation(
                        operation: definition,
                        destination: id,
                        anchor: anchor,
                      ),
                ],
        LinkFieldDestination() ||
        RegroupDestination() => drag.localOffers(destination, document),
      };
      if (offers.isNotEmpty) return offers.sortedByCompare(_rank, _compareRank);
    }
    return const [];
  }
}

/// Offers a drag can decide without its candidates.
extension LocalDropOffers on ResourceDrag {
  /// Offers for [destinations] before the drag's candidates arrive: the
  /// offers of the most specific destination that has any, or null when a
  /// resource destination before it might still offer an operation. An empty
  /// list means no destination can offer anything.
  List<DropOffer>? pendingOffersFor(
    List<DropDestination> destinations,
    AuthoringDocument document,
  ) {
    final droppable = document.catalog.snapshot.resourceOperations.any(
      (operation) => operation.drop != null,
    );
    for (final destination in destinations) {
      switch (destination) {
        case ResourceDestination(:final id):
          if (droppable && !subjects.contains(id)) return null;
        case LinkFieldDestination() || RegroupDestination():
          final offers = localOffers(destination, document);
          if (offers.isNotEmpty) {
            return offers.sortedByCompare(_rank, _compareRank);
          }
      }
    }
    return const [];
  }

  /// The link or regroup offers at [destination], which need no round trip.
  List<DropOffer> localOffers(
    DropDestination destination,
    AuthoringDocument document,
  ) => switch (destination) {
    ResourceDestination() => const [],
    LinkFieldDestination(:final location, :final anchor) => [
      if (document.canLinkAll(location, subjects))
        DropOffer.link(location: location, anchor: anchor),
    ],
    RegroupDestination(:final field, :final value) => [
      if (document.regroupedValues(this, field, value) case final values?
          when values.entries.any(
            (entry) => document.textAt(entry.key, field) != entry.value,
          ))
        DropOffer.regroup(field: field, value: value),
    ],
  };
}

(int, int, String) _rank(DropOffer offer) => offer.rank;

int _compareRank((int, int, String) left, (int, int, String) right) =>
    switch (left.$1.compareTo(right.$1)) {
      0 => switch (left.$2.compareTo(right.$2)) {
        0 => left.$3.compareTo(right.$3),
        final order => order,
      },
      final group => group,
    };

/// Link field and group facts the panel can decide locally, without a round
/// trip.
extension ResourceDropFacts on AuthoringDocument {
  /// The text at [field] of [resource], or null when it has none.
  String? textAt(skir.ResourceId resource, skir.ValuePath field) =>
      switch (this.resource(resource)?.readAt(field)) {
        PortablePathValue(:final value) => value.authoredPayload.authoredString,
        _ => null,
      };

  /// Whether [location] holds a collection of links rather than one link.
  bool isLinkCollection(skir.ValueLocation location) {
    final record = resource(location.resource);
    if (record == null) return false;
    return catalog.collectionItemType(
          catalog.valueTypeAt(
            record.configuration,
            location.path,
            value: skir.DataValue.createRecord(fields: record.fields),
          ),
        ) !=
        null;
  }

  /// The resources linked at or below [location].
  Set<skir.ResourceId> linkedAt(skir.ValueLocation location) => {
    for (final link in links)
      if (link.first == location.resource &&
          (link.firstLocation?.isAtOrBelow(location.path) ?? false))
        link.second
      else if (link.second == location.resource &&
          (link.secondLocation?.isAtOrBelow(location.path) ?? false))
        link.first,
  };

  /// Whether every one of [subjects] can be linked at [location] with its
  /// declared counterpart. A single value field takes one resource; an
  /// already linked resource and a resource owned elsewhere are not linked
  /// again (moving between owners is an operation).
  bool canLinkAll(skir.ValueLocation location, List<skir.ResourceId> subjects) {
    if (subjects.isEmpty || subjects.contains(location.resource)) return false;
    final collection = isLinkCollection(location);
    if (!collection && subjects.length != 1) return false;
    final linked = linkedAt(location);
    final source = collection
        ? location.item(skir.ItemId(value: "panel:drop:probe"))
        : location;
    for (final subject in subjects) {
      if (linked.contains(subject)) return false;
      final choice = automaticLink(this, catalog, source, subject);
      if (choice == null) return false;
      if (_ownsTarget(choice.plan) &&
          (relations.parents[subject]?.isNotEmpty ?? false)) {
        return false;
      }
    }
    return true;
  }

  /// The value [field] takes for each dragged resource in group [value], or
  /// null when a dragged resource has no such field or a dragged group would
  /// move into itself.
  Map<skir.ResourceId, String>? regroupedValues(
    ResourceDrag drag,
    skir.ValuePath field,
    String value,
  ) {
    final group = drag.group;
    if (group != null &&
        (group.field != field ||
            value == group.path ||
            value.startsWith("${group.path}."))) {
      return null;
    }
    final values = <skir.ResourceId, String>{};
    for (final subject in drag.subjects) {
      final current = textAt(subject, field);
      if (current == null &&
          resource(subject)?.readAt(field)
              is! PortablePathValue<skir.DataValue>) {
        return null;
      }
      values[subject] = switch (group) {
        null => value,
        final group => _joinPath([
          value,
          group.path.split(".").last,
          if ((current ?? "").startsWith("${group.path}."))
            (current ?? "").substring(group.path.length + 1),
        ]),
      };
    }
    return values;
  }
}

/// Whether linking through [plan] makes its source the owner of the target.
bool _ownsTarget(PortableLinkPlan plan) {
  final relation = plan.relation;
  if (!relation.ownsResources) return false;
  final firstOwns = relation.first.cardinality == skir.EndpointCardinality.one;
  return (plan.source.id.endpoint == relation.first.id) == firstOwns;
}

String _joinPath(List<String> segments) =>
    segments.where((segment) => segment.isNotEmpty).join(".");

/// A link plan and target that link [target] at [source] with its declared
/// counterpart, or null when the link needs an explicit choice.
({PortableLinkPlan plan, PortableLinkTargetChoice target})? automaticLink(
  PortableAuthoringView view,
  CheckedEditorCatalog catalog,
  skir.ValueLocation source,
  skir.ResourceId target,
) {
  final plans = view.linkPlans(catalog: catalog, source: source);
  if (plans is! PortableLinkPlanReady) return null;
  final matches = [
    for (final plan in plans.plans)
      for (final choice in plan.targets)
        if (choice.resource == target &&
            choice.automaticCounterpart &&
            choice.disabledReason == null)
          (plan: plan, target: choice),
  ];
  return matches.length == 1 ? matches.single : null;
}

extension on skir.ValueLocation {
  skir.ValueLocation item(skir.ItemId id) => skir.ValueLocation(
    resource: resource,
    path: skir.ValuePath(
      segments: [
        ...path.segments,
        skir.PathSegment.createItem(id: id),
      ],
    ),
  );
}

/// Runs drop offers for one drag. Operation offers go through the same path
/// as menus; link and group writes are direct edits the planner validates.
extension DropOfferRuns on DropOffer {
  Future<void> run(
    WidgetRef ref,
    ResourceDrag drag, {
    required bool Function() canMutate,
  }) async {
    final workspace = ref.read(realmEditingProvider(drag.scope));
    final document = workspace.document;
    switch (this) {
      case OperationDropOffer(
        :final operation,
        :final destination,
        :final anchor,
      ):
        await ResourceSelectionOperation(
          scope: drag.scope,
          invocation: captureResourceOperationInvocation(
            document: document,
            targets: drag.subjects,
          ),
          operation: skir.ResolvedResourceOperation(
            definition: operation,
            availability: skir.OperationAvailability.enabled,
          ),
          canMutate: canMutate,
        ).executeOn(
          ref,
          initialInput: seedDropInput(
            document,
            operation,
            destination: destination,
            anchor: anchor,
          ),
        );
      case LinkDropOffer(:final location, :final anchor):
        if (!canMutate()) return;
        _report(
          ref,
          workspace.edit(
            label: "Link resources",
            apply: (edit) =>
                edit.linkDropped(location, drag.subjects, anchor: anchor),
          ),
        );
      case RegroupDropOffer(:final field, :final value):
        if (!canMutate()) return;
        final values = document.regroupedValues(drag, field, value);
        if (values == null) return;
        _report(
          ref,
          workspace.edit(
            label: "Move to group",
            apply: (edit) {
              for (final entry in values.entries) {
                final result = edit.setPayload(
                  skir.ValueLocation(resource: entry.key, path: field),
                  skir.DataValue.wrapStringValue(entry.value),
                );
                if (result case PortablePathUnavailable(:final message)) {
                  throw StateError(message);
                }
              }
            },
          ),
        );
    }
  }

  void _report(WidgetRef ref, EditStageResult result) {
    if (ref.context.mounted) result.report(ref.context);
  }
}

/// The operation input a drop starts from: the drop field holds
/// [destination], a placement anchor field holds [anchor], every other field
/// its default. The Realm prepares it before the operation runs.
skir.DataValue? seedDropInput(
  AuthoringDocument document,
  skir.ResourceOperationDefinition operation, {
  required skir.ResourceId destination,
  Offset? anchor,
}) {
  final drop = operation.drop;
  final input = document.catalog.snapshot.capabilities
      .whereType<skir.CapabilityDefinition_authoringWrapper>()
      .map((item) => item.value)
      .firstWhereOrNull((item) => item.capabilityId == operation.capability)
      ?.input;
  final actual = input == null ? null : document.catalog.namedUse(input.type);
  if (drop == null || actual == null) return null;
  final fields = document.catalog.fields(
    skir.TypeSelection.wrapComplete(actual),
  );
  final record = skir.DataValue.createRecord(
    fields: [
      for (final field in fields)
        skir.FieldValue(
          name: field.template.key,
          value: switch (_withoutNullable(field.type)) {
            skir.TypeUse_namedWrapper(:final value)
                when anchor != null &&
                    value.definition == placementAnchorTypeRef =>
              skir.DataValue.createNamed(
                actualType: value,
                payload: skir.DataValue.createRecord(
                  fields: [
                    skir.FieldValue(
                      name: "x",
                      value: skir.DataValue.wrapFloat(anchor.dx),
                    ),
                    skir.FieldValue(
                      name: "y",
                      value: skir.DataValue.wrapFloat(anchor.dy),
                    ),
                  ],
                ),
              ),
            _ => document.defaultValue(field.type),
          },
        ),
    ],
  );
  final target = switch (record.readAt(drop.input)) {
    PortablePathValue(:final value) => value,
    PortablePathUnavailable() => null,
  };
  if (target == null) return null;
  return switch (record.replaceAt(
    drop.input,
    target.withAuthoredPayload(
      skir.DataValue.wrapStringValue(destination.value),
    ),
  )) {
    PortablePathValue(:final value) => skir.DataValue.createNamed(
      actualType: actual,
      payload: value,
    ),
    PortablePathUnavailable() => null,
  };
}

skir.TypeUse? _withoutNullable(skir.TypeUse? type) => switch (type) {
  skir.TypeUse_nullableWrapper(:final value) => _withoutNullable(value.value),
  _ => type,
};

extension ResourceDropEdits on AuthoringEdit {
  /// Links every one of [subjects] at [location] with its declared
  /// counterpart, then places graph members around [anchor], in grid units.
  void linkDropped(
    skir.ValueLocation location,
    List<skir.ResourceId> subjects, {
    Offset? anchor,
  }) {
    final checked =
        catalog ?? (throw StateError("The editor catalog is unavailable"));
    final document = toDocument();
    final collection = document.isLinkCollection(location);
    if (!collection && subjects.length != 1) {
      throw StateError("This field links one resource");
    }
    final occupants = document.linkedAt(location);
    for (final subject in subjects) {
      final source = collection
          ? location.item(skir.ItemId(value: "panel:link:${const Uuid().v4()}"))
          : location;
      final link =
          automaticLink(this, checked, source, subject) ??
          (throw StateError("The resource cannot be linked here"));
      applyResolvedReference(
        resolveReference(
          catalog: checked,
          plan: link.plan,
          target: link.target,
        ),
      );
    }
    if (anchor == null) return;
    final moving = [
      for (final subject in subjects)
        if (resource(subject)?.graphRect(checked) case final rect?)
          (subject, rect),
    ];
    if (moving.isEmpty) return;
    final placed = const GraphIncrementalPlacer().placeGroup(
      obstacles: [
        for (final occupant in occupants)
          if (!subjects.contains(occupant))
            ?resource(occupant)?.graphRect(checked),
      ],
      group: [for (final (_, rect) in moving) rect],
      anchor: anchor,
    );
    for (var index = 0; index < moving.length; index++) {
      moveGraphPlacement(moving[index].$1, placed[index].x, placed[index].y);
    }
  }
}
