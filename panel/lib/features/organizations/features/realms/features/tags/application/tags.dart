import "package:collection/collection.dart";
import "package:flutter/material.dart";
import "package:freezed_annotation/freezed_annotation.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

part "tags.freezed.dart";
part "tags.g.dart";

@freezed
abstract class Placement with _$Placement {
  const factory Placement({
    required int x,
    required int y,
    required int width,
    required int height,
  }) = _Placement;

  const Placement._();

  factory Placement.fromSkir(skir.Placement placement) => Placement(
    x: placement.x,
    y: placement.y,
    width: placement.width,
    height: placement.height,
  );

  skir.Placement toSkir() =>
      skir.Placement(x: x, y: y, width: width, height: height);
}

@freezed
abstract class Tag with _$Tag {
  @Assert("name != \"\"", "Name must not be empty.")
  const factory Tag({
    required skir.RecordId tagId,
    required String name,
    required Color color,
    required List<skir.RecordId> parentIds,
    required Placement placement,
  }) = _Tag;

  const Tag._();

  factory Tag.fromSkir(skir.Tag tag) => Tag(
    tagId: tag.tagId,
    name: tag.name,
    color: tag.color.toFlutterColor(),
    parentIds: tag.parentIds.toList(),
    placement: Placement.fromSkir(tag.placement),
  );

  skir.Tag toSkir() => skir.Tag(
    tagId: tagId,
    name: name,
    color: color.toSkirColor(),
    parentIds: parentIds,
    placement: placement.toSkir(),
  );
}

class TagMovePayload {
  const TagMovePayload({required this.id, required this.x, required this.y});

  final skir.RecordId id;
  final int x;
  final int y;
}

@riverpod
class Tags extends _$Tags {
  final Map<skir.RecordId, int> _moveVersions = {};

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
            return previous.upsertByKey(
              (tag) => tag.tagId,
              Tag.fromSkir(value),
            );
          case skir.WatchTagsResponse_updateWrapper(:final value):
            return previous.upsertByKey(
              (tag) => tag.tagId,
              Tag.fromSkir(value),
            );
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
          state = AsyncData(
            state.requireValue.upsertByKey((tag) => tag.tagId, tag),
          );
          return tag;
      }
    } catch (_) {
      state = previousState;
      rethrow;
    }
  }

  Future<void> updateTag(Tag tag) async {
    state.ensureReady();
    final previousState = state;
    final organizationId = ref.read(organizationIdProvider);
    final realmId = ref.read(realmIdProvider);
    if (realmId == null) throw ApiException.badRequest("No realm selected");
    if (organizationId == null) throw ApiException.noOrganization();

    state = AsyncData(
      state.requireValue.upsertByKey((value) => value.tagId, tag),
    );

    final request = skir.UpdateTagRequest(
      tagId: tag.tagId,
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
          throw ApiException.unknownResponseMessage();
        case skir.UpdateTagResponse_internalErrorWrapper():
          throw ApiException.internalServerError();
        case skir.UpdateTagResponse_tagNotFoundErrorWrapper():
          throw ApiException.notFound("Tag");
        case skir.UpdateTagResponse_parentsNotFoundErrorWrapper():
          throw ApiException.notFound("Parent tags");
        case skir.UpdateTagResponse_validationErrorWrapper(:final value):
          throw _tagValidationException(value);
        case skir.UpdateTagResponse_invalidRecordIdErrorWrapper(:final value):
          throw ApiException.invalidRecordId(value);
        case skir.UpdateTagResponse_successWrapper(:final value):
          final updatedTag = Tag.fromSkir(value);
          state = AsyncData(
            state.requireValue.upsertByKey((tag) => tag.tagId, updatedTag),
          );
      }
    } catch (_) {
      state = previousState;
      rethrow;
    }
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

  Future<void> moveTag(skir.RecordId tagId, int x, int y) =>
      moveTags([TagMovePayload(id: tagId, x: x, y: y)]);

  Future<void> moveTags(List<TagMovePayload> changes) async {
    if (changes.isEmpty) return;
    state.ensureReady();
    final organizationId = ref.read(organizationIdProvider);
    final realmId = ref.read(realmIdProvider);
    if (realmId == null) throw ApiException.badRequest("No realm selected");
    if (organizationId == null) throw ApiException.noOrganization();

    final changesById = {for (final change in changes) change.id: change};
    assert(
      changesById.length == changes.length,
      "Tag move identifiers must be unique",
    );
    final previousTags = {
      for (final tag in state.requireValue)
        if (changesById.containsKey(tag.tagId)) tag.tagId: tag,
    };
    final versions = <skir.RecordId, int>{};
    for (final change in changes) {
      final version = (_moveVersions[change.id] ?? 0) + 1;
      _moveVersions[change.id] = version;
      versions[change.id] = version;
    }
    state = AsyncData(
      state.requireValue.map((tag) {
        final change = changesById[tag.tagId];
        if (change == null) return tag;
        return tag.copyWith(
          placement: tag.placement.copyWith(x: change.x, y: change.y),
        );
      }).toList(),
    );

    await Future.wait(
      changes.map((change) async {
        final version = versions[change.id]!;
        try {
          final movedTag = await _requestMoveTag(
            organizationId.id,
            realmId.id,
            change,
          );
          if (_moveVersions[change.id] != version) return;
          state = AsyncData(
            state.requireValue.upsertByKey((tag) => tag.tagId, movedTag),
          );
        } catch (error, stackTrace) {
          if (_moveVersions[change.id] == version) {
            final previousTag = previousTags[change.id];
            if (previousTag != null) {
              state = AsyncData(
                state.requireValue.upsertByKey((tag) => tag.tagId, previousTag),
              );
            }
          }
          Error.throwWithStackTrace(error, stackTrace);
        }
      }),
    );
  }

  Future<Tag> _requestMoveTag(
    String organizationId,
    String realmId,
    TagMovePayload change,
  ) async {
    final request = skir.MoveTagRequest(
      tagId: change.id,
      x: change.x,
      y: change.y,
    );
    final response = await ref.requestSkir(
      "service.to.$realmId.organization.$organizationId.realm.tag.move",
      skir.MoveTagRequest.serializer.toBytes(request),
      skir.MoveTagResponse.serializer,
    );

    return switch (response) {
      skir.MoveTagResponse_unknown() =>
        throw ApiException.unknownResponseMessage(),
      skir.MoveTagResponse_internalErrorWrapper() =>
        throw ApiException.internalServerError(),
      skir.MoveTagResponse_tagNotFoundErrorWrapper() =>
        throw ApiException.notFound("Tag"),
      skir.MoveTagResponse_validationErrorWrapper(:final value) =>
        throw _tagValidationException(value),
      skir.MoveTagResponse_invalidRecordIdErrorWrapper(:final value) =>
        throw ApiException.invalidRecordId(value),
      skir.MoveTagResponse_successWrapper(:final value) => Tag.fromSkir(value),
    };
  }

  Future<void> resizeTag(skir.RecordId tagId, int width, int height) async {
    state.ensureReady();
    final previousState = state;
    final organizationId = ref.read(organizationIdProvider);
    final realmId = ref.read(realmIdProvider);
    if (realmId == null) throw ApiException.badRequest("No realm selected");
    if (organizationId == null) throw ApiException.noOrganization();

    state = AsyncData(
      state.requireValue
          .map(
            (tag) => tag.tagId == tagId
                ? tag.copyWith(
                    placement: tag.placement.copyWith(
                      width: width,
                      height: height,
                    ),
                  )
                : tag,
          )
          .toList(),
    );
    final request = skir.ResizeTagRequest(
      tagId: tagId,
      width: width,
      height: height,
    );

    try {
      final response = await ref.requestSkir(
        "service.to.${realmId.id}.organization.${organizationId.id}.realm.tag.resize",
        skir.ResizeTagRequest.serializer.toBytes(request),
        skir.ResizeTagResponse.serializer,
      );

      switch (response) {
        case skir.ResizeTagResponse_unknown():
          throw ApiException.unknownResponseMessage();
        case skir.ResizeTagResponse_internalErrorWrapper():
          throw ApiException.internalServerError();
        case skir.ResizeTagResponse_tagNotFoundErrorWrapper():
          throw ApiException.notFound("Tag");
        case skir.ResizeTagResponse_validationErrorWrapper(:final value):
          throw _tagValidationException(value);
        case skir.ResizeTagResponse_invalidRecordIdErrorWrapper(:final value):
          throw ApiException.invalidRecordId(value);
        case skir.ResizeTagResponse_successWrapper(:final value):
          final resizedTag = Tag.fromSkir(value);
          state = AsyncData(
            state.requireValue.upsertByKey((tag) => tag.tagId, resizedTag),
          );
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
  return switch (error.kind) {
    skir.TagValidationError_kind.unknown =>
      ApiException.unknownResponseMessage(),
    skir.TagValidationError_kind.nameRequiredConst => ApiException.badRequest(
      "Tag name is required",
    ),
    skir.TagValidationError_kind.positionRequiredConst =>
      ApiException.badRequest("Tag position is required"),
    skir.TagValidationError_kind.sizeRequiredConst => ApiException.badRequest(
      "Tag size is required",
    ),
    skir.TagValidationError_kind.widthInvalidConst => ApiException.badRequest(
      "Tag width is invalid",
    ),
    skir.TagValidationError_kind.heightInvalidConst => ApiException.badRequest(
      "Tag height is invalid",
    ),
  };
}
