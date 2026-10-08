import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

part "tags.freezed.dart";
part "tags.g.dart";
part "tag_model.dart";

const tagGraphCellSize = 50.0;

RecordValue tagCreationPartial(
  Iterable<Tag> tags, {
  Offset? preferredGraphAnchor,
}) {
  final obstacles = [
    for (final tag in tags)
      GraphGridRect(
        x: tag.placement.x,
        y: tag.placement.y,
        width: tag.placement.width,
        height: tag.placement.height,
      ),
  ];
  final placement = const GraphIncrementalPlacer()
      .placeGroup(
        obstacles: obstacles,
        group: [GraphGridRect(x: 0, y: 0, width: 4, height: 1)],
        anchor:
            preferredGraphAnchor ??
            graphCenterOfMass(obstacles, cellSize: tagGraphCellSize) ??
            Offset.zero,
      )
      .single;
  return RecordValue({
    "placement": RecordValue({
      "x": placement.x.asValue,
      "y": placement.y.asValue,
      "width": placement.width.asValue,
      "height": placement.height.asValue,
    }),
  });
}

/// Owns the current Realm tag projection and its authoring mutations.
///
/// The provider waits for its graph selection before reading the session, then
/// follows session revisions through [ref.listen]. Creation and deletion use
/// direct guarded operations. Editing is delegated to the shared editor owner
/// so drafts, validation, and response reconciliation follow the same path as
/// other Realm resources.
@riverpod
class CanonicalTags extends _$CanonicalTags {
  @override
  Future<List<Tag>> build() async {
    final organizationId = ref.watch(organizationIdProvider);
    final realmId = ref.watch(realmIdProvider);
    if (organizationId == null || realmId == null) {
      return [];
    }
    final provider = authoringSessionProvider(organizationId, realmId);
    var session = ref.watch(provider);
    if (session.failure case final failure?) {
      throw StateError("Authoring is unavailable: $failure");
    }
    if (session.snapshot == null) {
      await ref.read(provider.notifier).ready;
      session = ref.read(provider);
      if (session.failure case final failure?) {
        throw StateError("Authoring is unavailable: $failure");
      }
    }
    return _projectTags(session);
  }

  Future<void> updateTag(Tag tag, {Tag? expected}) async {
    state.ensureReady();
    final before =
        expected ??
        state.requireValue.singleWhere(
          (candidate) => candidate.tagId == tag.tagId,
          orElse: () => throw ApiException.notFound("Tag"),
        );
    final access = ref.readAuthoringSession();
    final source = access.state.resources[tag.tagId];
    final baseline = access.state.draft;
    if (source == null || baseline == null) {
      throw ApiException.notFound("Tag");
    }
    if (Tag.fromAuthoring(source) != before) {
      throw ApiException.conflict("The Tag changed before this edit");
    }
    final draft = baseline.fork();
    if (tag.name != before.name) {
      setAuthoredFieldPayload(
        draft: draft,
        resource: tag.tagId,
        fields: const ["name"],
        payload: skir.DataValue.wrapStringValue(tag.name),
      );
    }
    if (tag.color != before.color) {
      setAuthoredFieldPayload(
        draft: draft,
        resource: tag.tagId,
        fields: const ["color"],
        payload: skir.DataValue.wrapInteger(
          tag.color.toARGB32().toUnsigned(32).toString(),
        ),
      );
    }
    _setPlacement(draft, tag, before);
    if (!const ListEquality<skir.ResourceId>().equals(
      tag.parentIds,
      before.parentIds,
    )) {
      replacePortableLinkCollection(
        draft: AuthoredDraftAuthoringDocument(draft),
        catalog: access.state.catalog!,
        resource: tag.tagId,
        field: "parents",
        expected: before.parentIds,
        proposed: tag.parentIds,
      );
    }
    await access.notifier.commitDraft(
      draft,
      conflictMessage: "The Tag changed before this edit was saved",
    );
  }

  /// Applies the graph drop action for [childId] and [parentId].
  ///
  /// Invalid links are ignored. A valid existing link is removed; a valid new
  /// link is added. The resulting patch uses the supplied projected collection
  /// and expected child, preserving the graph's cycle and missing node checks.
  Future<void> toggleTagParent(
    List<Tag> tags,
    skir.ResourceId childId,
    skir.ResourceId parentId,
  ) async {
    state.ensureReady();
    final action = tagParentDropAction(
      tags,
      childId: childId,
      parentId: parentId,
    );
    if (action == null) return;
    final child = tags.firstWhere((tag) => tag.tagId == childId);
    final parents = switch (action) {
      TagParentDropAction.link => [...child.parentIds, parentId],
      TagParentDropAction.unlink =>
        child.parentIds.where((id) => id != parentId).toList(),
    };

    await updateTag(child.copyWith(parentIds: parents), expected: child);
  }
}

void _setPlacement(AuthoredDraft draft, Tag tag, Tag before) {
  final changes = <String, int>{
    if (tag.placement.x != before.placement.x) "x": tag.placement.x,
    if (tag.placement.y != before.placement.y) "y": tag.placement.y,
    if (tag.placement.width != before.placement.width)
      "width": tag.placement.width,
    if (tag.placement.height != before.placement.height)
      "height": tag.placement.height,
  };
  for (final change in changes.entries) {
    setAuthoredFieldPayload(
      draft: draft,
      resource: tag.tagId,
      fields: ["placement", change.key],
      payload: skir.DataValue.wrapInteger(change.value.toString()),
    );
  }
}

/// Reads one tag from the canonical Realm projection.
@riverpod
Future<Tag?> canonicalTag(Ref ref, skir.ResourceId tagId) async {
  final tags = await ref.watch(canonicalTagsProvider.future);
  return tags.firstWhereOrNull((tag) => tag.tagId == tagId);
}

List<Tag> _projectTags(AuthoringSessionState value) {
  return value.resources.values
      .where((resource) => resource.definition == _tagDefinition)
      .map(Tag.fromAuthoring)
      .toList();
}

final _tagDefinition = skir.ResourceDefinitionId(value: "typewriter.tag");

/// Combines canonical tags with local editor values for UI consumers.
///
/// Canonical state remains the authority. A local value is only a temporary
@riverpod
AsyncValue<List<Tag>> projectedTags(Ref ref) =>
    ref.watch(canonicalTagsProvider);

/// Projects one tag for graph nodes that rebuild independently.
@riverpod
AsyncValue<Tag?> projectedTag(Ref ref, skir.ResourceId tagId) =>
    ref.watch(canonicalTagProvider(tagId));
