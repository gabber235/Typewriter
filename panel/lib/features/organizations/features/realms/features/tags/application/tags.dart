import "package:collection/collection.dart";
import "package:flutter/material.dart";
import "package:freezed_annotation/freezed_annotation.dart";
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

@riverpod
class Tags extends _$Tags {
  @override
  Stream<List<Tag>> build() async* {
    final organizationId = ref.watch(organizationIdProvider);
    final realmId = ref.watch(realmIdProvider);
    if (realmId == null || organizationId == null) {
      yield [];
      return;
    }

    final request = skir.WatchTagsRequest();
    yield* ref.watchRequest(
      subject:
          "service.to.${realmId.id}.organization.${organizationId.id}.realm.tag.watch",
      listenSubject:
          "service.from.${realmId.id}.organization.${organizationId.id}.realm.tag.watch",
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
    final previousState = state;
    final organizationId = ref.read(organizationIdProvider);
    final realmId = ref.read(realmIdProvider);
    if (realmId == null) throw ApiException.badRequest("No realm selected");
    if (organizationId == null) throw ApiException.noOrganization();

    final request = skir.CreateTagRequest(
      name: name,
      color: color?.toSkirColor(),
      parentIds: parentIds,
      placement: skir.Placement(x: x, y: y, width: width, height: height),
    );

    try {
      final response = await ref.requestSkir(
        "service.to.${realmId.id}.organization.${organizationId.id}.realm.tag.create",
        skir.CreateTagRequest.serializer.toBytes(request),
        skir.CreateTagResponse.serializer,
      );

      switch (response) {
        case skir.CreateTagResponse_unknown():
          throw ApiException.unknownResponseMessage();
        case skir.CreateTagResponse_internalErrorWrapper():
          throw ApiException.internalServerError();
        case skir.CreateTagResponse_parentsNotFoundErrorWrapper():
          throw ApiException.notFound("Parent tags");
        case skir.CreateTagResponse_validationErrorWrapper(:final value):
          throw _tagValidationException(value);
        case skir.CreateTagResponse_invalidRecordIdErrorWrapper(:final value):
          throw ApiException.invalidRecordId(value);
        case skir.CreateTagResponse_successWrapper(:final value):
          final tag = Tag.fromSkir(value);
          final upsert = _upsertCanonicalTag(state.requireValue, tag);
          state = AsyncData(upsert.values);
          return upsert.canonical;
      }
    } on Object catch (_) {
      state = previousState;
      rethrow;
    }
  }

  Future<TypedMutationResult> updateTag(Tag tag) async {
    state.ensureReady();
    final organizationId = ref.read(organizationIdProvider);
    final realmId = ref.read(realmIdProvider);
    if (realmId == null) throw ApiException.badRequest("No realm selected");
    if (organizationId == null) throw ApiException.noOrganization();

    final request = skir.UpdateTagRequest(
      tagId: tag.tagId,
      expectedRevision: tag.revision,
      name: tag.name,
      color: tag.color.toSkirColor(),
      parentIds: tag.parentIds,
      placement: tag.placement.toSkir(),
    );

    try {
      final response = await ref.requestSkir(
        "service.to.${realmId.id}.organization.${organizationId.id}.realm.tag.update",
        skir.UpdateTagRequest.serializer.toBytes(request),
        skir.UpdateTagResponse.serializer,
      );

      switch (response) {
        case skir.UpdateTagResponse_unknown():
          return unavailableMutation("The server returned an unknown response");
        case skir.UpdateTagResponse_internalErrorWrapper():
          return unavailableMutation("The server could not update the tag");
        case skir.UpdateTagResponse_conflictErrorWrapper(:final value):
          final actual = Tag.fromSkir(value.actual);
          final upsert = _upsertCanonicalTag(state.requireValue, actual);
          state = AsyncData(upsert.values);
          return TypedMutationResult.conflict(
            expectedRevision: value.expectedRevision,
            actualRevision: upsert.canonical.revision,
            actualValue: upsert.canonical.inspectorValue,
          );
        case skir.UpdateTagResponse_tagNotFoundErrorWrapper():
          return unavailableMutation(
            "The tag no longer exists",
            targetDeleted: true,
          );
        case skir.UpdateTagResponse_parentsNotFoundErrorWrapper():
          return invalidMutation("One or more parent tags no longer exist");
        case skir.UpdateTagResponse_validationErrorWrapper(:final value):
          return invalidMutation(_tagValidationMessage(value));
        case skir.UpdateTagResponse_invalidRecordIdErrorWrapper():
          return invalidMutation("The tag contains an invalid reference");
        case skir.UpdateTagResponse_successWrapper(:final value):
          final updatedTag = Tag.fromSkir(value);
          final upsert = _upsertCanonicalTag(state.requireValue, updatedTag);
          state = AsyncData(upsert.values);
          return TypedMutationResult.success(
            revision: upsert.canonical.revision,
            value: upsert.canonical.inspectorValue,
          );
      }
    } on Object catch (_) {
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
    final parentIds = switch (action) {
      TagParentDropAction.link => [...child.parentIds, parentId],
      TagParentDropAction.unlink =>
        child.parentIds.where((id) => id != parentId).toList(),
    };
    await updateTag(child.copyWith(parentIds: parentIds));
  }

  Future<void> deleteTag(skir.RecordId tagId) async {
    state.ensureReady();
    final previousState = state;
    final organizationId = ref.read(organizationIdProvider);
    final realmId = ref.read(realmIdProvider);
    if (realmId == null) throw ApiException.badRequest("No realm selected");
    if (organizationId == null) throw ApiException.noOrganization();

    state = AsyncData(
      state.requireValue.where((tag) => tag.tagId != tagId).toList(),
    );
    final request = skir.DeleteTagRequest(tagId: tagId);

    try {
      final response = await ref.requestSkir(
        "service.to.${realmId.id}.organization.${organizationId.id}.realm.tag.delete",
        skir.DeleteTagRequest.serializer.toBytes(request),
        skir.DeleteTagResponse.serializer,
      );

      switch (response) {
        case skir.DeleteTagResponse_unknown():
          throw ApiException.unknownResponseMessage();
        case skir.DeleteTagResponse_internalErrorWrapper():
          throw ApiException.internalServerError();
        case skir.DeleteTagResponse_tagNotFoundErrorWrapper():
          throw ApiException.notFound("Tag");
        case skir.DeleteTagResponse_invalidRecordIdErrorWrapper(:final value):
          throw ApiException.invalidRecordId(value);
        case skir.DeleteTagResponse_successWrapper():
      }
    } catch (_) {
      state = previousState;
      rethrow;
    }
  }
}

@riverpod
Future<Tag?> tag(Ref ref, skir.RecordId tagId) async {
  final tags = await ref.watch(tagsProvider.future);
  return tags.firstWhereOrNull((tag) => tag.tagId == tagId);
}

ApiException _tagValidationException(skir.TagValidationError error) {
  return ApiException.badRequest(_tagValidationMessage(error));
}

String _tagValidationMessage(skir.TagValidationError error) {
  return switch (error.kind) {
    skir.TagValidationError_kind.unknown =>
      "The server returned an unknown Tag validation error",
    skir.TagValidationError_kind.nameRequiredConst => "Tag name is required",
    skir.TagValidationError_kind.widthInvalidConst =>
      "Tag width must be greater than zero",
    skir.TagValidationError_kind.heightInvalidConst =>
      "Tag height must be greater than zero",
    skir.TagValidationError_kind.inheritanceCycleConst =>
      "Tag parents cannot create an inheritance cycle",
  };
}
