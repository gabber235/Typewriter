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
    ref.watch(
      realmEditorCatalogLeaseProvider(
        RealmEditorCatalogRequest(types: {referenceResourceTypes.tag}),
      ),
    );
    final catalogState = await ref.watch(realmEditorCatalogProvider.future);
    final catalog = catalogState.snapshot;
    if (catalog == null) throw StateError("The editor catalog is unavailable");
    final collectionLeases = [
      for (final selection in catalog.collectionSelections(
        catalog.presentations.values,
      ))
        ref.watch(
          authoringSelectionLeaseProvider(organizationId, realmId, selection),
        ),
    ];
    await Future.wait(collectionLeases.map((lease) => lease.ready));
    final codec = TypedAuthoringCodec(catalog);
    final provider = authoringSessionProvider(organizationId, realmId);
    ref.listen(provider, (_, value) {
      if (value.sequence != null &&
          value.generation?.value == catalog.generation.value) {
        state = AsyncData(_projectTags(value, codec));
      }
    });
    final lease = ref.watch(
      authoringSelectionLeaseProvider(
        organizationId,
        realmId,
        authoringDefinitionSelection(
          key: "tags",
          definitions: const [CoreResourceDefinitionIds.tag],
        ),
      ),
    );

    await lease.ready;
    return _projectTags(ref.read(provider), codec);
  }

  /// Saves a tag through the shared editor mutation boundary.
  ///
  /// [expected] is the caller's observed value, normally the projected value
  /// used for a graph gesture. The patch compares each changed field against
  /// that observation. Applied responses refresh the editor from authoritative
  /// content, including fields changed remotely in the same revision.
  Future<TypedMutationResult> updateTag(Tag tag, {Tag? expected}) async {
    state.ensureReady();
    final before =
        expected ??
        state.requireValue.singleWhere(
          (candidate) => candidate.tagId == tag.tagId,
          orElse: () => throw ApiException.notFound("Tag"),
        );
    return ref.updateAuthoringResource(
      id: tag.tagId,
      expected: before.inspectorValue,
      proposed: tag.inspectorValue,
      label: "Tag",
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

/// Reads one tag from the canonical Realm projection.
@riverpod
Future<Tag?> canonicalTag(Ref ref, skir.ResourceId tagId) async {
  final tags = await ref.watch(canonicalTagsProvider.future);
  return tags.firstWhereOrNull((tag) => tag.tagId == tagId);
}

List<Tag> _projectTags(AuthoringSessionState value, TypedAuthoringCodec codec) {
  return value.resources.values
      .map(codec.decodeResourceOrThrow)
      .where(
        (resource) =>
            codec.isResourceType(resource, CoreResourceDefinitionIds.tag),
      )
      .map(Tag.fromTyped)
      .toList();
}

/// Converts one canonical wire tag and its session revision into editor input.
extension AuthoringTagValue on AuthoringSessionState {
  AuthoringValue<Tag>? tagEditorValue(
    skir.ResourceId tagId,
    TypedAuthoringCodec codec,
  ) {
    final value = resources[tagId];
    final revision = sequence;
    if (value == null || revision == null) return null;
    final decoded = codec.decodeResourceOrThrow(value);
    if (!codec.isResourceType(decoded, CoreResourceDefinitionIds.tag)) {
      return null;
    }
    return AuthoringValue(value: Tag.fromTyped(decoded), revision: revision);
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
AsyncValue<Tag?> projectedTag(Ref ref, skir.ResourceId tagId) {
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
