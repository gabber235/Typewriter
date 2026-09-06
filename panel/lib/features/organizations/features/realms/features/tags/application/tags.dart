import "package:collection/collection.dart";
import "package:flutter/material.dart";
import "package:freezed_annotation/freezed_annotation.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/library/v1/authoring.dart"
    as wire;
import "package:typewriter_panel/typewriter_panel.dart";

part "tags.freezed.dart";
part "tags.g.dart";
part "tag_model.dart";
part "tag_collection.dart";
part "tag_inspector_presentation.dart";
part "tag_inheritance_presentation.dart";

@riverpod
class Tags extends _$Tags {
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

  Future<Tag> createTag({
    required String name,
    Color? color,
    List<skir.RecordId> parentIds = const [],
    int x = 0,
    int y = 0,
    int width = 4,
    int height = 1,
  }) async {
    state.ensureReady();
    final tag = Tag(
      tagId: newResourceId(AuthoringResource.tag),
      authoringSequence: ref.readAuthoringSession().state.sequence ?? 0,
      name: name,
      color: color ?? Colors.grey,
      parentIds: parentIds,
      placement: Placement(x: x, y: y, width: width, height: height),
    );
    state = AsyncData([...state.requireValue, tag]);
    try {
      final response = await ref.readAuthoringSession().notifier.createTag(
        tag.toWire(),
      );
      response.requireApplied(conflictMessage: "The tag already exists");
      return tag;
    } on Object {
      _replaceFromSession();
      rethrow;
    }
  }

  Future<TypedMutationResult> updateTag(Tag tag, {Tag? expected}) async {
    state.ensureReady();
    final before =
        expected ??
        state.requireValue.firstWhere((value) => value.tagId == tag.tagId);
    state = AsyncData([
      for (final current in state.requireValue)
        if (current.tagId == tag.tagId) tag else current,
    ]);
    try {
      final response = await ref.readAuthoringSession().notifier.patchTag(
        tag,
        expected: before,
      );
      switch (response) {
        case wire.ApplyAuthoringBatchResponse_appliedWrapper(:final value):
          return TypedMutationResult.success(
            revision: value.sequence,
            value: tag.inspectorValue,
          );
        case wire.ApplyAuthoringBatchResponse_conflictWrapper():
          return _tagConflict(before);
        case wire.ApplyAuthoringBatchResponse_invalidWrapper() ||
            wire.ApplyAuthoringBatchResponse_internalErrorWrapper() ||
            wire.ApplyAuthoringBatchResponse_unknown():
          _replaceFromSession();
          return response.toMutationFailure(
            unavailableMessage: "The tag update could not be completed",
          );
      }
    } on Object {
      _replaceFromSession();
      return unavailableMutation("The tag update could not be completed");
    }
  }

  Future<void> toggleTagParent(
    skir.RecordId childId,
    skir.RecordId parentId,
  ) async {
    state.ensureReady();
    final tags = state.requireValue;
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

  Future<void> deleteTag(skir.RecordId tagId) async {
    state.ensureReady();
    state = AsyncData(
      state.requireValue.where((tag) => tag.tagId != tagId).toList(),
    );
    try {
      final response = await ref.readAuthoringSession().notifier.deleteTag(
        tagId,
      );
      response.requireApplied(
        conflictMessage: "The tag changed before deletion",
      );
    } on Object {
      _replaceFromSession();
      rethrow;
    }
  }

  TypedMutationResult _tagConflict(Tag expected) {
    final session = ref.readAuthoringSession();
    final canonical = session.state.tags[expected.tagId];
    if (canonical == null) {
      return unavailableMutation(
        "The tag no longer exists",
        targetDeleted: true,
      );
    }
    final actual = Tag.fromWire(canonical, session.state.sequence ?? 0);
    state = AsyncData([
      for (final tag in state.requireValue)
        if (tag.tagId == actual.tagId) actual else tag,
    ]);
    return TypedMutationResult.conflict(
      expectedRevision: expected.authoringSequence,
      actualRevision: actual.authoringSequence,
      actualValue: actual.inspectorValue,
    );
  }

  void _replaceFromSession() {
    state = AsyncData(_projectTags(ref.readAuthoringSession().state));
  }
}

@riverpod
Future<Tag?> tag(Ref ref, skir.RecordId tagId) async {
  final tags = await ref.watch(tagsProvider.future);
  return tags.firstWhereOrNull((tag) => tag.tagId == tagId);
}

List<Tag> _projectTags(AuthoringSessionState value) {
  final sequence = value.sequence ?? 0;
  return value.tags.values.map((tag) => Tag.fromWire(tag, sequence)).toList();
}
