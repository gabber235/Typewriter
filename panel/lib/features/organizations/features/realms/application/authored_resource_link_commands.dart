import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

part "authored_resource_link_commands.freezed.dart";

@freezed
abstract class AuthoredResourceLinkPlan with _$AuthoredResourceLinkPlan {
  const factory AuthoredResourceLinkPlan({
    @Default([]) List<AuthoredResourceLinkSlot> slots,
    String? problem,
  }) = _AuthoredResourceLinkPlan;
}

@freezed
abstract class AuthoredResourceLinkSlot with _$AuthoredResourceLinkSlot {
  const factory AuthoredResourceLinkSlot({
    required String key,
    required String label,
    required AuthoringDocument document,
    required List<AuthoredResourceLinkMember> members,
  }) = _AuthoredResourceLinkSlot;
}

@freezed
abstract class AuthoredResourceLinkMember with _$AuthoredResourceLinkMember {
  const factory AuthoredResourceLinkMember({
    required skir.ResourceId resource,
    required List<AuthoredResourceLinkChoice> choices,
  }) = _AuthoredResourceLinkMember;
}

@freezed
abstract class AuthoredResourceLinkChoice with _$AuthoredResourceLinkChoice {
  const factory AuthoredResourceLinkChoice({
    required String key,
    required String label,
    required PortableLinkPlan plan,
    required PortableLinkTargetChoice target,
    required PortableLinkCounterpartRequest counterpart,
    skir.LinkOccurrence? disconnect,
  }) = _AuthoredResourceLinkChoice;
}

/// Plans node drops from the dragged resources and stages a whole group once.
///
/// Choices retain their working observation. Preparation records exact source
/// and membership reads so a dialog cannot overwrite intervening local edits.
final class AuthoredResourceLinkCommands {
  const AuthoredResourceLinkCommands({
    required this.workspace,
    required this.scope,
    required this.canMutate,
    this.prepareValue,
  });

  final RealmEditing workspace;
  final AuthoringScope scope;
  final bool Function() canMutate;
  final Future<skir.PreparedValue> Function(skir.ValuePreparationRequest)?
  prepareValue;

  AuthoredResourceLinkPlan plan(
    AuthoringResourceDragGroup group,
    skir.ResourceId target,
  ) {
    if (!canMutate()) {
      return const AuthoredResourceLinkPlan(problem: "This page is read only");
    }
    return workspace.document.planResourceLinks(
      group: group,
      target: target,
      scope: scope,
      canPrepareCounterpart: prepareValue != null,
    );
  }

  Future<EditStageResult> apply(
    AuthoringResourceDragGroup group,
    AuthoredResourceLinkSlot slot,
    Map<skir.ResourceId, AuthoredResourceLinkChoice> choices, {
    bool confirmedMixed = false,
    bool Function()? isCurrent,
  }) async {
    bool available() =>
        canMutate() &&
        (group.sourceCanMutate?.call() ?? true) &&
        (isCurrent?.call() ?? true);
    if (!available()) return _linkRejected("This interaction is unavailable");
    if (slot.document.generation != workspace.document.generation) {
      return _linkRejected("The editor catalog changed");
    }
    if (choices.length != slot.members.length ||
        slot.members.length != group.memberships.length ||
        slot.members.any(
          (member) => !group.memberships.keys.any(
            (identifier) => identifier.resourceId == member.resource,
          ),
        ) ||
        slot.members.any(
          (member) => !member.choices.contains(choices[member.resource]),
        )) {
      return _linkRejected("Choose a reference for every dragged resource");
    }
    final removals = choices.values.where(
      (choice) => choice.disconnect != null,
    );
    if (removals.isNotEmpty &&
        removals.length != choices.length &&
        !confirmedMixed) {
      return _linkRejected("Confirm the combined link and unlink changes");
    }
    return workspace.prepare(
      label: removals.length == choices.length
          ? "Unlink entries"
          : "Link entries",
      from: slot.document,
      apply: (edit) async {
        verifyResourceDragMemberships(edit, group, scope);
        final reservations = <skir.ValueLocation>{};
        for (final member in slot.members) {
          final choice = choices[member.resource]!;
          if (group.memberships.keys.any(
            (identifier) => identifier.resourceId == choice.target.resource,
          )) {
            throw StateError("A resource cannot be dropped onto itself");
          }
          edit.expect(choice.plan.source.id.location);
          if (choice.disconnect case final occurrence?) {
            edit.disconnect(occurrence);
            continue;
          }
          final counterpart = await preparePortableLinkCounterpart(
            generation: edit.generation,
            counterpart: choice.counterpart,
            prepareValue: prepareValue,
          );
          if (!available()) {
            throw StateError("This interaction is unavailable");
          }
          final reference = edit.resolveReference(
            catalog: slot.document.catalog,
            plan: choice.plan,
            target: choice.target,
            counterpart: counterpart,
            collection: switch (choice.counterpart) {
              PortableCollectionCounterpart(:final containing) => containing,
              _ => null,
            },
          );
          reserveResourceLinkCounterpart(reference, reservations);
          edit.applyResolvedReference(reference);
        }
        if (!available()) throw StateError("This interaction is unavailable");
      },
    );
  }
}

extension AuthoredResourceLinkPlanning on AuthoringDocument {
  /// Intersects semantic source slots, retaining exact occurrence choices.
  AuthoredResourceLinkPlan planResourceLinks({
    required AuthoringResourceDragGroup group,
    required skir.ResourceId target,
    required AuthoringScope scope,
    bool canPrepareCounterpart = false,
  }) {
    try {
      verifyResourceDragMemberships(this, group, scope);
      if (resource(target) == null) {
        throw StateError("The target is unavailable");
      }
      if (group.memberships.keys.any((id) => id.resourceId == target)) {
        throw StateError("A resource cannot be dropped onto itself");
      }
      final perMember =
          <skir.ResourceId, Map<String, List<AuthoredResourceLinkChoice>>>{};
      final labels = <String, String>{};
      for (final identifier in group.memberships.keys) {
        final source = identifier.resourceId;
        final record = resource(source)!;
        final slots = <String, List<AuthoredResourceLinkChoice>>{};
        final collections = catalog.referenceCollections(record).toList();
        void add(
          skir.ValuePath path,
          skir.EndpointId endpoint, {
          bool collection = false,
        }) {
          final key =
              "${endpoint.value}:${resourceLinkPathLabel(path, semantic: true)}";
          labels[key] = resourceLinkPathLabel(path, semantic: true);
          final matching = collection
              ? catalog
                    .referenceLocations(record)
                    .where(
                      (location) =>
                          location.endpoint == endpoint &&
                          location.path.segments.length ==
                              path.segments.length + 1 &&
                          location.path.isAtOrBelow(path) &&
                          switch (record.readAt(location.path)) {
                            PortablePathValue(value: final value) =>
                              value.authoredLink?.target.resource == target,
                            _ => false,
                          },
                    )
              : const Iterable<
                  ({
                    skir.ValuePath path,
                    skir.EndpointId endpoint,
                    skir.TypeUse target,
                  })
                >.empty();
          final locations = collection && matching.isNotEmpty
              ? matching.map((value) => value.path).toList()
              : [
                  if (collection)
                    skir.ValuePath(
                      segments: [
                        ...path.segments,
                        skir.PathSegment.createItem(
                          id: skir.ItemId(
                            value: "panel:node-link:${const Uuid().v4()}",
                          ),
                        ),
                      ],
                    )
                  else
                    path,
                ];
          for (final location in locations) {
            final planned = linkPlans(
              catalog: catalog,
              source: skir.ValueLocation(resource: source, path: location),
            );
            if (planned is! PortableLinkPlanReady) continue;
            for (final plan in planned.plans) {
              for (final candidate in plan.targets.where(
                (choice) =>
                    choice.resource == target && choice.disabledReason == null,
              )) {
                final removal = collection && matching.isNotEmpty
                    ? plan.source
                    : null;
                slots
                    .putIfAbsent(key, () => [])
                    .addAll(
                      resourceLinkChoices(
                        plan,
                        candidate,
                        document: this,
                        disconnect: removal,
                        canPrepareCounterpart: canPrepareCounterpart,
                      ),
                    );
              }
            }
          }
        }

        for (final location in catalog.referenceLocations(record)) {
          if (collections.any(
            (collection) =>
                location.path.segments.length ==
                    collection.path.segments.length + 1 &&
                location.path.isAtOrBelow(collection.path),
          )) {
            continue;
          }
          add(location.path, location.endpoint);
        }
        for (final collection in collections) {
          add(collection.path, collection.endpoint, collection: true);
        }
        slots.removeWhere((_, choices) => choices.isEmpty);
        perMember[source] = slots;
      }
      final keys = perMember.values.first.keys.where(
        (key) => perMember.values.every((slots) => slots.containsKey(key)),
      );
      final common = [
        for (final key in keys)
          AuthoredResourceLinkSlot(
            key: key,
            label: labels[key]!,
            document: this,
            members: [
              for (final member in perMember.entries)
                AuthoredResourceLinkMember(
                  resource: member.key,
                  choices: member.value[key]!,
                ),
            ],
          ),
      ]..removeWhere((slot) => !hasResourceLinkAssignment(this, slot.members));
      return AuthoredResourceLinkPlan(
        slots: common,
        problem: common.isEmpty
            ? "The dragged resources have no common compatible reference"
            : null,
      );
    } on Object catch (error) {
      return AuthoredResourceLinkPlan(problem: error.toString());
    }
  }
}

/// Validates identity and exact reciprocal page membership without mutating it.
void verifyResourceDragMemberships(
  PortableAuthoringView document,
  AuthoringResourceDragGroup group,
  AuthoringScope scope,
) {
  if (!(group.sourceCanMutate?.call() ?? true)) {
    throw StateError("The source page is no longer editable");
  }
  if (group.memberships.isEmpty ||
      !group.memberships.containsKey(group.primary)) {
    throw StateError("The dragged resources are unavailable");
  }
  final catalog = switch (document) {
    AuthoringDocument(:final catalog) => catalog,
    AuthoringEdit(:final catalog) => catalog,
    _ => null,
  };
  for (final member in group.memberships.entries) {
    final identifier = member.key;
    final occurrence = member.value;
    if (catalog == null ||
        !catalog.snapshot.relations.any(
          (relation) =>
              (relation.first.id == occurrence.id.endpoint ||
                  relation.second.id == occurrence.id.endpoint) &&
              relation.families.any(
                (family) => family.value == "resource.ownership",
              ),
        )) {
      throw StateError("The dragged resource has no page ownership relation");
    }
    if (occurrence.source != group.memberships[group.primary]!.source) {
      throw StateError("Dragged resources belong to different pages");
    }
    if (identifier.scope != scope) {
      throw StateError("Resources belong to another Realm");
    }
    if (document.resource(identifier.resourceId) == null ||
        occurrence.target.resource != identifier.resourceId ||
        occurrence.id.location.resource != occurrence.source) {
      throw StateError("The dragged resource membership is unavailable");
    }
    final current = document is PortableAuthoringEdit
        ? document.expect(occurrence.id.location)
        : document.read(occurrence.id.location);
    final actual = switch (current) {
      PortablePathValue(value: final value) => value.authoredLink,
      _ => null,
    };
    if (actual == null ||
        actual.endpoint != occurrence.id.endpoint ||
        actual.target != occurrence.target) {
      throw StateError("A dragged resource changed pages");
    }
    final inverse = occurrence.target.opposite;
    if (inverse == null) {
      throw StateError("The page membership has no exact inverse");
    }
    final at = skir.ValueLocation(
      resource: identifier.resourceId,
      path: inverse,
    );
    final back = document is PortableAuthoringEdit
        ? document.expect(at)
        : document.read(at);
    final linked = switch (back) {
      PortablePathValue(value: final value) => value.authoredLink,
      _ => null,
    };
    if (linked?.target.resource != occurrence.source ||
        linked?.target.opposite != occurrence.id.location.path) {
      throw StateError("A dragged resource changed pages");
    }
  }
}

List<AuthoredResourceLinkChoice> resourceLinkChoices(
  PortableLinkPlan plan,
  PortableLinkTargetChoice target, {
  required PortableAuthoringView document,
  skir.LinkOccurrence? disconnect,
  bool canPrepareCounterpart = false,
}) {
  final prefix = _resourceLinkLocationLabel(document, plan.source.id.location);
  final sourceKey = resourceLinkPathLabel(plan.source.id.location.path);
  AuthoredResourceLinkChoice choice(
    String key,
    String label,
    PortableLinkCounterpartRequest counterpart,
  ) => AuthoredResourceLinkChoice(
    key: "$sourceKey:$key",
    label: label,
    plan: plan,
    target: target,
    counterpart: counterpart,
    disconnect: disconnect,
  );
  if (disconnect != null) {
    return [
      choice(
        "unlink",
        "Unlink $prefix",
        const PortableLinkCounterpartRequest.automatic(),
      ),
    ];
  }
  bool available(skir.LinkOccurrence occurrence) {
    final current = switch (document.read(occurrence.id.location)) {
      PortablePathValue(value: final value) => value.authoredLink?.target,
      _ => null,
    };
    return current == null ||
        (current.resource == plan.source.source &&
            (current.opposite == null ||
                current.opposite == plan.source.id.location.path));
  }

  if (target.automaticCounterpart &&
      (target.collections.isNotEmpty ||
          target.existing.isEmpty ||
          target.existing.any(available))) {
    return [
      choice(
        "automatic",
        "Link $prefix",
        const PortableLinkCounterpartRequest.automatic(),
      ),
    ];
  }
  return [
    for (final occurrence in target.existing.where(available))
      choice(
        "existing:${resourceLinkPathLabel(occurrence.id.location.path)}",
        "Link $prefix to ${_resourceLinkLocationLabel(document, occurrence.id.location)}",
        PortableLinkCounterpartRequest.existing(occurrence),
      ),
    for (final containing in target.collections)
      choice(
        "collection:${resourceLinkPathLabel(containing.path)}",
        "Link $prefix into ${_resourceLinkLocationLabel(document, containing)}",
        PortableLinkCounterpartRequest.collection(containing),
      ),
    if (canPrepareCounterpart)
      for (final slot in target.creatable)
        choice(
          "created:${resourceLinkPathLabel(slot.containing.path)}:${slot.selection}",
          "Link $prefix with a new counterpart in ${_resourceLinkLocationLabel(document, slot.containing)}",
          PortableLinkCounterpartRequest.created(slot),
        ),
  ];
}

String resourceLinkPathLabel(skir.ValuePath path, {bool semantic = false}) =>
    path.segments
        .map(
          (segment) => switch (segment) {
            skir.PathSegment_fieldWrapper(:final value) => value.name,
            skir.PathSegment_itemWrapper(:final value) =>
              semantic ? "item" : value.id.value,
            _ => segment.toString(),
          },
        )
        .join(" / ");

String _resourceLinkLocationLabel(
  PortableAuthoringView document,
  skir.ValueLocation location,
) {
  final labels = <String>[];
  final segments = <skir.PathSegment>[];
  for (final segment in location.path.segments) {
    switch (segment) {
      case skir.PathSegment_fieldWrapper(:final value):
        labels.add(value.name);
      case skir.PathSegment_itemWrapper(:final value):
        final parent = document.read(
          skir.ValueLocation(
            resource: location.resource,
            path: skir.ValuePath(segments: segments),
          ),
        );
        final items = switch (parent) {
          PortablePathValue(value: final value) =>
            value.authoredItems?.toList(),
          _ => null,
        };
        final index = items?.indexWhere((item) => item.id == value.id) ?? -1;
        if (index >= 0) labels.add("item ${index + 1}");
      case skir.PathSegment.mapKey:
        labels.add("key");
      case skir.PathSegment.mapValue:
        labels.add("value");
      case _:
        labels.add("unavailable field");
    }
    segments.add(segment);
  }
  return labels.join(" / ");
}

/// Checks whether every member can reserve a distinct exact counterpart.
/// Collection append choices allocate fresh occurrences and need no reservation.
bool hasResourceLinkAssignment(
  PortableAuthoringView document,
  List<AuthoredResourceLinkMember> members,
) {
  skir.ValueLocation? reservation(AuthoredResourceLinkChoice choice) {
    if (choice.disconnect != null) return null;
    return switch (choice.counterpart) {
      PortableExistingCounterpart(:final occurrence) => occurrence.id.location,
      PortableCreatedCounterpart(:final slot) => switch (document.read(
        slot.containing,
      )) {
        PortablePathValue(value: final value)
            when value.authoredItems != null =>
          null,
        _ => slot.containing,
      },
      PortableCollectionCounterpart() => null,
      PortableAutomaticCounterpart() =>
        choice.target.collections.isEmpty && choice.target.existing.length == 1
            ? choice.target.existing.single.id.location
            : null,
    };
  }

  final occupied = <skir.ValueLocation, int>{};
  bool assign(int index, Set<int> visited) {
    if (!visited.add(index)) return false;
    for (final choice in members[index].choices) {
      final at = reservation(choice);
      if (at == null) return true;
      final previous = occupied[at];
      if (previous == null || assign(previous, visited)) {
        occupied[at] = index;
        return true;
      }
    }
    return false;
  }

  for (var index = 0; index < members.length; index++) {
    if (!assign(index, {})) return false;
  }
  return true;
}

/// Rejects group choices that would overwrite a previously resolved inverse.
void reserveResourceLinkCounterpart(
  ResolvedReference reference,
  Set<skir.ValueLocation> reservations,
) {
  final locations = <skir.ValueLocation>[
    if (reference.connection.counterpart
        case skir.CounterpartChoice_existingWrapper(:final value))
      value.id.location,
    for (final materialization in reference.materializations)
      if (materialization case PreparedReferenceRecord(:final at)) at,
  ];
  for (final at in locations) {
    if (reservations.any(
      (previous) =>
          previous.resource == at.resource &&
          (previous.path.isAtOrBelow(at.path) ||
              at.path.isAtOrBelow(previous.path)),
    )) {
      throw StateError(
        "Choose different counterpart locations for the dragged resources",
      );
    }
  }
  reservations.addAll(locations);
}

EditStageResult _linkRejected(String message) =>
    EditStageResult.rejected(message, null);
