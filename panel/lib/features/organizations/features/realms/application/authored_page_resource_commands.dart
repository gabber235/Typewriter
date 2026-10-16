import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

/// Transfers existing resources through their scalar page reference.
///
/// Membership and graph geometry stage together. Resource identity and unrelated
/// references remain owned by the original resources.
final class AuthoredPageResourceCommands {
  const AuthoredPageResourceCommands({
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

  String? plan(AuthoringResourceDragGroup group, skir.ResourceId destination) =>
      planChoices(group, destination).problem;

  AuthoredResourceLinkPlan planChoices(
    AuthoringResourceDragGroup group,
    skir.ResourceId destination,
  ) {
    try {
      if (!canMutate()) throw StateError("This page is read only");
      final document = workspace.document;
      verifyResourceDragMemberships(document, group, scope);
      if (document.resource(destination) == null) {
        throw StateError("The destination page is unavailable");
      }
      final members = <AuthoredResourceLinkMember>[];
      for (final member in group.memberships.entries) {
        if (document.resource(member.key.resourceId)?.graphGridRect == null) {
          throw StateError("The dragged resource has no graph placement");
        }
        members.add(
          AuthoredResourceLinkMember(
            resource: member.key.resourceId,
            choices: _pageMoveChoices(
              document,
              document.catalog,
              member.value,
              destination,
              canPrepareCounterpart: prepareValue != null,
            ),
          ),
        );
      }
      if (!hasResourceLinkAssignment(document, members)) {
        throw StateError(
          "The destination has no compatible counterpart for the whole group",
        );
      }
      return AuthoredResourceLinkPlan(
        slots: [
          AuthoredResourceLinkSlot(
            key: "page",
            label: "Page",
            document: document,
            members: members,
          ),
        ],
      );
    } on Object catch (error) {
      return AuthoredResourceLinkPlan(problem: error.toString());
    }
  }

  Future<EditStageResult> move(
    AuthoringResourceDragGroup group,
    skir.ResourceId destination, {
    bool Function()? isCurrent,
    Offset? anchor,
    Map<skir.ResourceId, AuthoredResourceLinkChoice>? choices,
    AuthoredResourceLinkSlot? plannedSlot,
  }) async {
    bool available() =>
        canMutate() &&
        (group.sourceCanMutate?.call() ?? true) &&
        (isCurrent?.call() ?? true);
    if (!available()) return _pageRejected("This interaction is unavailable");
    final planned = planChoices(group, destination);
    if (planned.problem case final problem?) return _pageRejected(problem);
    if (plannedSlot != null &&
        plannedSlot.document.generation != workspace.document.generation) {
      return _pageRejected("The editor catalog changed");
    }
    if (group.memberships.values.every(
      (member) => member.source == destination,
    )) {
      return const EditStageResult.unchanged();
    }
    final slot = plannedSlot ?? planned.slots.single;
    if (slot.members.length != group.memberships.length ||
        choices != null && choices.length != slot.members.length ||
        slot.members.any(
          (member) => !group.memberships.keys.any(
            (identifier) => identifier.resourceId == member.resource,
          ),
        ) ||
        slot.members.any(
          (member) => member.choices.any(
            (choice) => choice.target.resource != destination,
          ),
        )) {
      return _pageRejected(
        "The page move choices do not match the dragged resources",
      );
    }
    final selected = <skir.ResourceId, AuthoredResourceLinkChoice>{};
    for (final member in slot.members) {
      final requested = choices?[member.resource];
      final matching = requested == null
          ? member.choices
          : member.choices.where((choice) => choice == requested).toList();
      if (matching.length != 1) {
        return _pageRejected(
          "Choose the exact destination counterpart for every resource",
        );
      }
      selected[member.resource] = matching.single;
    }
    final captured = slot.document;
    return workspace.prepare(
      label: "Move entries to page",
      from: captured,
      apply: (edit) async {
        verifyResourceDragMemberships(edit, group, scope);
        final ids = group.memberships.keys
            .map((member) => member.resourceId)
            .toList();
        final moved = <GraphGridRect>[];
        for (final id in ids) {
          edit.expect(
            skir.ValueLocation(resource: id, path: elementPlacementPath),
          );
          final rect = edit.resource(id)?.graphGridRect;
          if (rect == null) {
            throw StateError("The dragged resource placement changed");
          }
          moved.add(rect);
        }
        final obstacles = <GraphGridRect>[];
        for (final id
            in captured.relations.children[destination] ??
                const <skir.ResourceId>[]) {
          if (ids.contains(id)) continue;
          final rect = edit.resource(id)?.graphGridRect;
          if (rect != null) {
            edit.expect(
              skir.ValueLocation(resource: id, path: elementPlacementPath),
            );
            obstacles.add(rect);
          }
        }
        final placed = const GraphIncrementalPlacer().placeGroup(
          obstacles: obstacles,
          group: moved,
          anchor: anchor ?? obstacles.graphBounds?.center ?? Offset.zero,
        );
        final reservations = <skir.ValueLocation>{};
        for (final choice in selected.values) {
          edit.expect(choice.plan.source.id.location);
          final counterpart = await preparePortableLinkCounterpart(
            generation: edit.generation,
            counterpart: choice.counterpart,
            prepareValue: prepareValue,
          );
          if (!available()) throw StateError("This interaction is unavailable");
          final reference = edit.resolveReference(
            catalog: captured.catalog,
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
        for (var index = 0; index < ids.length; index++) {
          for (final coordinate in [
            ("x", placed[index].x),
            ("y", placed[index].y),
          ]) {
            final at = skir.ValueLocation(
              resource: ids[index],
              path: elementPlacementPath.field(coordinate.$1),
            );
            final previous = edit.expect(at);
            if (previous is! PortablePathValue<skir.DataValue>) {
              throw StateError("The dragged resource placement is unavailable");
            }
            final result = edit.set(
              at,
              previous.value.withAuthoredPayload(
                skir.DataValue.wrapInteger(coordinate.$2.toString()),
              ),
            );
            if (result case PortablePathUnavailable(:final message)) {
              throw EditPreparationFailure(message);
            }
          }
        }
        if (!available()) throw StateError("This interaction is unavailable");
      },
    );
  }

  Future<EditStageResult> disconnect(
    AuthoringResourceDragGroup group, {
    bool Function()? isCurrent,
  }) async {
    bool available() =>
        canMutate() &&
        (group.sourceCanMutate?.call() ?? true) &&
        (isCurrent?.call() ?? true);
    if (!available()) return _pageRejected("This interaction is unavailable");
    return workspace.prepare(
      label: "Disconnect entries from page",
      apply: (edit) async {
        verifyResourceDragMemberships(edit, group, scope);
        for (final occurrence in group.memberships.values) {
          edit.disconnect(occurrence);
        }
        if (!available()) throw StateError("This interaction is unavailable");
      },
    );
  }
}

List<AuthoredResourceLinkChoice> _pageMoveChoices(
  PortableAuthoringView document,
  CheckedEditorCatalog catalog,
  skir.LinkOccurrence membership,
  skir.ResourceId destination, {
  required bool canPrepareCounterpart,
}) {
  final inverse = membership.target.opposite;
  if (inverse == null) {
    throw StateError("The page membership has no exact inverse");
  }
  final source = skir.ValueLocation(
    resource: membership.target.resource,
    path: inverse,
  );
  final record = document.resource(source.resource);
  if (record == null ||
      !catalog
          .referenceLocations(record)
          .any((location) => location.path == source.path) ||
      catalog
          .referenceCollections(record)
          .any((collection) => source.path.isAtOrBelow(collection.path))) {
    throw StateError("The resource has no scalar page reference");
  }
  final planned = document.linkPlans(catalog: catalog, source: source);
  if (planned is! PortableLinkPlanReady) {
    throw StateError(
      planned is PortableLinkPlanUnavailable
          ? planned.message
          : "The page reference is unavailable",
    );
  }
  final choices = [
    for (final plan in planned.plans)
      for (final target in plan.targets)
        if (target.resource == destination && target.disabledReason == null)
          ...resourceLinkChoices(
            plan,
            target,
            document: document,
            canPrepareCounterpart: canPrepareCounterpart,
          ),
  ];
  if (choices.isEmpty) {
    throw StateError(
      "The destination page does not accept every dragged resource",
    );
  }
  return choices;
}

EditStageResult _pageRejected(String message) =>
    EditStageResult.rejected(message, null);
