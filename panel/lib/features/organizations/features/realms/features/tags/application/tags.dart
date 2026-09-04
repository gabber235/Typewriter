import "package:collection/collection.dart";
import "package:flutter/material.dart";
import "package:freezed_annotation/freezed_annotation.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/library/v1/tag.dart"
    as wire_v1;
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/library/v2/authoring.dart"
    as wire_v2;
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
  Stream<List<Tag>> build() async* {
    ref.invalidateOnLibraryChange(skir.LibraryResourceKind.tag);
    final organizationId = ref.watch(organizationIdProvider);
    final realmId = ref.watch(realmIdProvider);
    if (realmId == null || organizationId == null) {
      yield [];
      return;
    }

    final request = skir.WatchTagsRequest();
    final address = RealmServiceAddress(
      organizationId: organizationId,
      realmId: realmId,
    );
    yield* ref.watchRequest(
      subject: address.request("tag.watch"),
      listenSubject: address.event("tag.watch"),
      requestBytes: skir.WatchTagsRequest.serializer.toBytes(request),
      serializer: skir.WatchTagsResponse.serializer,
      transformer: (previous, response) {
        switch (response) {
          case skir.WatchTagsResponse_unknown():
            throw ApiException.unknownResponseMessage();
          case skir.WatchTagsResponse_internalErrorWrapper():
            throw ApiException.internalServerError();
          case skir.WatchTagsResponse_listWrapper(:final value):
            return value.map(Tag.fromSkir).toList();
          case skir.WatchTagsResponse_addWrapper(:final value):
            return _upsertCanonicalTag(previous, Tag.fromSkir(value)).values;
          case skir.WatchTagsResponse_updateWrapper(:final value):
            return _upsertCanonicalTag(previous, Tag.fromSkir(value)).values;
          case skir.WatchTagsResponse_removeWrapper(:final value):
            return previous?.where((tag) => tag.tagId != value).toList() ?? [];
        }
      },
    );
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
    final organizationId = ref.read(organizationIdProvider);
    final realmId = ref.read(realmIdProvider);
    if (realmId == null) throw ApiException.badRequest("No realm selected");
    if (organizationId == null) throw ApiException.noOrganization();

    final request = skir.CreateTagsRequest(
      batchId: uuid.v4(),
      tags: [
        skir.TagCreate(
          id: recordId("tag:${uuid.v4()}"),
          name: name,
          color: (color ?? Colors.grey).toSkirColor(),
          parents: parentIds,
          placement: skir.GraphPlacement(
            x: x,
            y: y,
            width: width,
            height: height,
          ),
        ),
      ],
    );

    final response = await runPanelMutation(
      operation: PanelMutationOperation.createTag,
      mutation: () => ref.requestSkir(
        RealmServiceAddress(
          organizationId: organizationId,
          realmId: realmId,
        ).request("tag.create.v2"),
        skir.CreateTagsRequest.serializer.toBytes(request),
        skir.CreateTagsResponse.serializer,
      ),
    );

    switch (response) {
      case skir.CreateTagsResponse_unknown():
        throw ApiException.unknownResponseMessage();
      case skir.CreateTagsResponse_internalErrorWrapper():
        throw ApiException.internalServerError();
      case skir.CreateTagsResponse_conflictWrapper():
        throw ApiException.conflict("The tag already exists");
      case skir.CreateTagsResponse_invalidWrapper(:final value):
        throw ApiException.badRequest(value.join("; "));
      case skir.CreateTagsResponse_successWrapper(:final value):
        final tag = Tag.fromV2(value.single);
        final upsert = _upsertCanonicalTag(state.requireValue, tag);
        state = AsyncData(upsert.values);
        return upsert.canonical;
    }
  }

  Future<TypedMutationResult> updateTag(Tag tag) async {
    state.ensureReady();
    final organizationId = ref.read(organizationIdProvider);
    final realmId = ref.read(realmIdProvider);
    if (realmId == null) throw ApiException.badRequest("No realm selected");
    if (organizationId == null) throw ApiException.noOrganization();

    final request = skir.UpdateTagsRequest(
      batchId: uuid.v4(),
      tags: [
        skir.TagUpdate(
          id: tag.tagId,
          expectedRevision: tag.revision,
          name: tag.name,
          color: tag.color.toSkirColor(),
          parents: tag.parentIds,
          placement: skir.GraphPlacement(
            x: tag.placement.x,
            y: tag.placement.y,
            width: tag.placement.width,
            height: tag.placement.height,
          ),
        ),
      ],
    );

    final response = await runPanelMutation<skir.UpdateTagsResponse?>(
      operation: PanelMutationOperation.updateTag,
      mutation: () => ref.requestSkir(
        RealmServiceAddress(
          organizationId: organizationId,
          realmId: realmId,
        ).request("tag.update.v2"),
        skir.UpdateTagsRequest.serializer.toBytes(request),
        skir.UpdateTagsResponse.serializer,
      ),
      recover: (_, _) => null,
    );

    switch (response) {
      case null:
        return unavailableMutation("The tag update could not be completed");
      case skir.UpdateTagsResponse_unknown():
        return unavailableMutation("The server returned an unknown response");
      case skir.UpdateTagsResponse_internalErrorWrapper():
        return unavailableMutation("The server could not update the tag");
      case skir.UpdateTagsResponse_conflictWrapper(:final value):
        final actual = value.single.actual;
        if (actual == null) {
          return unavailableMutation(
            "The tag no longer exists",
            targetDeleted: true,
          );
        }
        final actualTag = Tag.fromV2(actual);
        final upsert = _upsertCanonicalTag(state.requireValue, actualTag);
        state = AsyncData(upsert.values);
        return TypedMutationResult.conflict(
          expectedRevision: tag.revision,
          actualRevision: actualTag.revision,
          actualValue: actualTag.inspectorValue,
        );
      case skir.UpdateTagsResponse_invalidWrapper(:final value):
        return invalidMutation(value.join("; "));
      case skir.UpdateTagsResponse_successWrapper(:final value):
        final updatedTag = Tag.fromV2(value.single);
        final upsert = _upsertCanonicalTag(state.requireValue, updatedTag);
        state = AsyncData(upsert.values);
        return TypedMutationResult.success(
          revision: upsert.canonical.revision,
          value: upsert.canonical.inspectorValue,
        );
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
    final parentIds = switch (action) {
      TagParentDropAction.link => [...child.parentIds, parentId],
      TagParentDropAction.unlink =>
        child.parentIds.where((id) => id != parentId).toList(),
    };
    await updateTag(child.copyWith(parentIds: parentIds));
  }

  Future<void> deleteTag(skir.RecordId tagId) async {
    state.ensureReady();
    final organizationId = ref.read(organizationIdProvider);
    final realmId = ref.read(realmIdProvider);
    if (realmId == null) throw ApiException.badRequest("No realm selected");
    if (organizationId == null) throw ApiException.noOrganization();

    final removed = state.requireValue.firstWhere((tag) => tag.tagId == tagId);
    state = AsyncData(
      state.requireValue.where((tag) => tag.tagId != tagId).toList(),
    );
    final request = skir.DeleteTagsRequest(
      batchId: uuid.v4(),
      tags: [skir.TagDeletion(id: tagId, expectedRevision: removed.revision)],
    );

    final response = await runPanelMutation(
      operation: PanelMutationOperation.deleteTag,
      mutation: () => ref.requestSkir(
        RealmServiceAddress(
          organizationId: organizationId,
          realmId: realmId,
        ).request("tag.delete.v2"),
        skir.DeleteTagsRequest.serializer.toBytes(request),
        skir.DeleteTagsResponse.serializer,
      ),
      recover: (error, stackTrace) {
        _restoreTag(removed);
        Error.throwWithStackTrace(error, stackTrace);
      },
    );

    switch (response) {
      case skir.DeleteTagsResponse_unknown():
        _restoreTag(removed);
        throw ApiException.unknownResponseMessage();
      case skir.DeleteTagsResponse_internalErrorWrapper():
        _restoreTag(removed);
        throw ApiException.internalServerError();
      case skir.DeleteTagsResponse_conflictWrapper():
        _restoreTag(removed);
        throw ApiException.notFound("Tag");
      case skir.DeleteTagsResponse_invalidWrapper(:final value):
        _restoreTag(removed);
        throw ApiException.badRequest(value.join("; "));
      case skir.DeleteTagsResponse_successWrapper():
    }
  }

  void _restoreTag(Tag removed) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(_upsertCanonicalTag(current, removed).values);
  }
}

@riverpod
Future<Tag?> tag(Ref ref, skir.RecordId tagId) async {
  final tags = await ref.watch(tagsProvider.future);
  return tags.firstWhereOrNull((tag) => tag.tagId == tagId);
}
