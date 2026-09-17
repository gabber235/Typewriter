import "package:collection/collection.dart";
import "package:flutter/material.dart";
import "package:freezed_annotation/freezed_annotation.dart";
import "package:riverpod/riverpod.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

part "tags.freezed.dart";
part "tags.g.dart";
part "tag_model.dart";
part "tag_collection.dart";
part "tag_inspector_presentation.dart";
part "tag_inheritance_presentation.dart";

const tagGraphCellSize = 50.0;

/// Owns the current Realm tag projection and its authoring mutations.
///
/// The provider waits for the library scope before reading the session, then
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
    ref.listen(provider, (_, value) {
      if (value.sequence != null) state = AsyncData(_projectTags(value));
    });
    final lease = ref.watch(
      authoringLibraryScopeProvider(organizationId, realmId),
    );

    await lease.ready;
    return _projectTags(ref.read(provider));
  }

  /// Creates a tag in the selected Realm and returns the requested value.
  ///
  /// The server assigns the operation result to canonical state. A conflict is
  /// surfaced as an exception, so callers must not select or display the new
  /// resource as persisted until this future succeeds.
  Future<Tag> createTag({
    required String name,
    Color? color,
    List<skir.RecordId> parentIds = const [],
    Offset? preferredGraphAnchor,
  }) async {
    state.ensureReady();
    final organizationId = ref.read(organizationIdProvider);
    final realmId = ref.read(realmIdProvider);
    final existingTags = organizationId == null || realmId == null
        ? state.requireValue
        : _projectTagValues(
            state.requireValue,
            ref.read(localWorkProvider).editorValues,
            organizationId,
            realmId,
          );
    final obstacles = [
      for (final tag in existingTags)
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
    final tag = Tag(
      tagId: newResourceId(AuthoringResource.tag),
      name: name,
      color: color ?? Colors.grey,
      parentIds: parentIds,
      placement: Placement(
        x: placement.x,
        y: placement.y,
        width: placement.width,
        height: placement.height,
      ),
    );
    final response = await ref.readAuthoringSession().notifier.createTag(
      tag.toWire(),
    );
    response.requireApplied(conflictMessage: "The tag already exists");
    return tag;
  }

  /// Saves a tag through the shared editor mutation boundary.
  ///
  /// [expected] is the caller's observed value, normally the projected value
  /// used for a graph gesture. The patch compares each changed field against
  /// that observation. Applied responses refresh the editor from authoritative
  /// content, including fields changed remotely in the same revision.
  Future<TypedMutationResult> updateTag(Tag tag, {Tag? expected}) async {
    state.ensureReady();
    final session = ref.readAuthoringSession();
    final current = session.state.tags[tag.tagId];
    if (current == null || session.state.sequence == null) {
      throw ApiException.notFound("Tag");
    }
    final before = expected ?? Tag.fromWire(current);
    final commands = session.notifier;
    final owners = EditorOwnerRegistry(
      workspace: ref.read(localWorkControllerProvider),
    );
    try {
      final owner = owners.editor(
        TagSelectable(
          resource: TagEditorResource(
            ref
                .read(resourceRepositoriesProvider)
                .authoring(commands.organizationId, commands.realmId),
            tag.tagId,
          ),
          onDelete: () => deleteTag(tag.tagId),
          id: TagIdentifier(tag.tagId),
          tag: before,
          revision: session.state.sequence!,
          tagCollection: state.requireValue.presentationCollection(),
        ),
      );
      return await owner.applyChanges(
        editorValueChanges(before.inspectorValue, tag.inspectorValue),
      );
    } finally {
      owners.dispose();
    }
  }

  /// Applies the graph drop action for [childId] and [parentId].
  ///
  /// Invalid links are ignored. A valid existing link is removed; a valid new
  /// link is added. The resulting patch uses the supplied projected collection
  /// and expected child, preserving the graph's cycle and missing node checks.
  Future<void> toggleTagParent(
    List<Tag> tags,
    skir.RecordId childId,
    skir.RecordId parentId,
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

  /// Deletes [tagId] from the selected Realm.
  ///
  /// The authoring response is required to apply. A conflict reports that the
  /// tag changed before deletion and leaves reconciliation to session refresh.
  Future<void> deleteTag(skir.RecordId tagId) async {
    state.ensureReady();
    final response = await ref.readAuthoringSession().notifier.deleteTag(tagId);
    response.requireApplied(conflictMessage: "The tag changed before deletion");
  }
}

/// Reads one tag from the canonical Realm projection.
@riverpod
Future<Tag?> canonicalTag(Ref ref, skir.RecordId tagId) async {
  final tags = await ref.watch(canonicalTagsProvider.future);
  return tags.firstWhereOrNull((tag) => tag.tagId == tagId);
}

List<Tag> _projectTags(AuthoringSessionState value) {
  return value.tags.values.map(Tag.fromWire).toList();
}

/// Converts one canonical wire tag and its session revision into editor input.
extension AuthoringTagValue on AuthoringSessionState {
  AuthoringValue<Tag>? tagEditorValue(skir.RecordId tagId) {
    final value = tags[tagId];
    final revision = sequence;
    if (value == null || revision == null) return null;
    return AuthoringValue(value: Tag.fromWire(value), revision: revision);
  }
}

/// Combines canonical tags with local editor values for UI consumers.
///
/// Canonical state remains the authority. A local value is only a temporary
/// projection keyed by organization, realm, and tag identity, and disappears
/// when the shared editor owner releases it or canonical state catches up.
@riverpod
AsyncValue<List<Tag>> projectedTags(Ref ref) {
  final canonicalTags = ref.watch(canonicalTagsProvider);
  if (canonicalTags.mapUnready<List<Tag>>() case final value?) return value;

  final local = ref.watch(
    localWorkProvider.select((state) => state.editorValues),
  );
  final organizationId = ref.watch(organizationIdProvider);
  final realmId = ref.watch(realmIdProvider);
  if (organizationId == null || realmId == null) {
    return AsyncData(canonicalTags.requireValue);
  }
  return AsyncData(
    _projectTagValues(
      canonicalTags.requireValue,
      local,
      organizationId,
      realmId,
    ),
  );
}

List<Tag> _projectTagValues(
  Iterable<Tag> canonical,
  Map<EditorResourceKey, LocalEditorValue> local,
  skir.RecordId organizationId,
  skir.RecordId realmId,
) => [
  for (final tag in canonical)
    tag.projected(
      local[EditorResourceKey(
        scope: EditorResourceScope(
          organizationId: organizationId,
          realmId: realmId,
        ),
        identity: tag.tagId,
      )],
    ),
];

/// Projects one tag for graph nodes that rebuild independently.
@riverpod
AsyncValue<Tag?> projectedTag(Ref ref, skir.RecordId tagId) {
  final canonical = ref.watch(canonicalTagProvider(tagId));
  if (canonical.mapUnready<Tag?>() case final value?) return value;
  final organizationId = ref.watch(organizationIdProvider);
  final realmId = ref.watch(realmIdProvider);
  if (organizationId == null || realmId == null) return canonical;
  final key = EditorResourceKey(
    scope: EditorResourceScope(
      organizationId: organizationId,
      realmId: realmId,
    ),
    identity: tagId,
  );
  final local = ref.watch(
    localWorkProvider.select((state) => state.editorValues[key]),
  );
  return AsyncData(canonical.requireValue?.projected(local));
}
