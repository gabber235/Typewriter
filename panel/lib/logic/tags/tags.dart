import "package:collection/collection.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";
import "package:typewriter_panel/generated/api/tag.pb.dart";
import "package:typewriter_panel/generated/models/book.pb.dart";
import "package:typewriter_panel/generated/models/common.pb.dart";
import "package:typewriter_panel/logic/api_exception.dart";
import "package:typewriter_panel/logic/nats.dart";
import "package:typewriter_panel/logic/organization.dart";
import "package:typewriter_panel/logic/realm.dart";
import "package:typewriter_panel/utils/riverpod.dart";

part "tags.g.dart";

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

    final request = ListTagsRequest();
    final stream = ref.requestProtoThenListen(
      subject: "realm.to.$realmId.organization.$organizationId.tag.list",
      listenSubject:
          "realm.from.$realmId.organization.$organizationId.tag.list",
      request: request,
      responseBuilder: ListTagsResponse.new,
    );

    await for (final response in stream) {
      if (response.hasError()) {
        throw ApiException.fromProto(response.error);
      }
      yield response.tags.tags.toList();
    }
  }

  Future<Tag> createTag({
    required String name,
    Color? color,
    List<String> parentIds = const [],
    int x = 0,
    int y = 0,
    int width = 4,
    int height = 1,
  }) async {
    state.ensureReady();
    final previousState = state;
    final organizationId = ref.read(organizationIdProvider);
    final realmId = ref.read(realmIdProvider);
    assert(realmId != null, "realmId must not be null when creating a tag");
    assert(
      organizationId != null,
      "organizationId must not be null when creating a tag",
    );

    final placement = Placement()
      ..x = x
      ..y = y
      ..width = width
      ..height = height;

    final request = CreateTagRequest()
      ..name = name
      ..parentIds.addAll(parentIds)
      ..placement = placement;

    if (color != null) {
      request.color = color;
    }

    try {
      final response = await ref
          .read(natsProvider)
          .requestProto(
            "realm.to.$realmId.organization.$organizationId.tag.create",
            request,
            CreateTagResponse.new,
          );

      if (response.hasError()) {
        throw ApiException.fromProto(response.error);
      }

      final current = state.value ?? [];
      state = AsyncData([...current, response.tag]);
      return response.tag;
    } catch (e) {
      state = previousState;
      rethrow;
    }
  }

  Future<void> updateTag(Tag tag) async {
    state.ensureReady();
    final previousState = state;
    final organizationId = ref.read(organizationIdProvider);
    final realmId = ref.read(realmIdProvider);
    assert(realmId != null, "realmId must not be null when updating a tag");
    assert(
      organizationId != null,
      "organizationId must not be null when updating a tag",
    );

    final current = state.requireValue;
    state = AsyncData(
      current.map((t) => t.tagId == tag.tagId ? tag : t).toList(),
    );

    final request = UpdateTagRequest()..tag = tag;

    try {
      final response = await ref
          .read(natsProvider)
          .requestProto(
            "realm.to.$realmId.organization.$organizationId.tag.update",
            request,
            UpdateTagResponse.new,
          );

      if (response.hasError()) {
        throw ApiException.fromProto(response.error);
      }

      final updated = state.requireValue;
      state = AsyncData(
        updated
            .map((t) => t.tagId == response.tag.tagId ? response.tag : t)
            .toList(),
      );
    } catch (e) {
      state = previousState;
      rethrow;
    }
  }

  Future<void> deleteTag(String tagId) async {
    state.ensureReady();
    final previousState = state;
    final organizationId = ref.read(organizationIdProvider);
    final realmId = ref.read(realmIdProvider);
    assert(realmId != null, "realmId must not be null when deleting a tag");
    assert(
      organizationId != null,
      "organizationId must not be null when deleting a tag",
    );

    final current = state.value ?? [];
    state = AsyncData(current.where((t) => t.tagId != tagId).toList());

    final request = DeleteTagRequest()..tagId = tagId;

    try {
      final response = await ref
          .read(natsProvider)
          .requestProto(
            "realm.to.$realmId.organization.$organizationId.tag.delete",
            request,
            DeleteTagResponse.new,
          );

      if (response.hasError()) {
        throw ApiException.fromProto(response.error);
      }
    } catch (e) {
      state = previousState;
      rethrow;
    }
  }

  Future<void> moveTag(String tagId, int x, int y) async {
    state.ensureReady();
    final previousState = state;
    final organizationId = ref.read(organizationIdProvider);
    final realmId = ref.read(realmIdProvider);
    assert(realmId != null, "realmId must not be null when moving a tag");
    assert(
      organizationId != null,
      "organizationId must not be null when moving a tag",
    );

    final current = state.value ?? [];
    state = AsyncData(
      current.map((t) {
        if (t.tagId != tagId) return t;
        return t.deepCopy()
          ..placement = (t.placement.deepCopy()
            ..x = x
            ..y = y);
      }).toList(),
    );

    final request = MoveTagRequest()
      ..tagId = tagId
      ..x = x
      ..y = y;

    try {
      final response = await ref
          .read(natsProvider)
          .requestProto(
            "realm.to.$realmId.organization.$organizationId.tag.move",
            request,
            MoveTagResponse.new,
          );

      if (response.hasError()) {
        throw ApiException.fromProto(response.error);
      }
    } catch (e) {
      state = previousState;
      rethrow;
    }
  }

  Future<void> resizeTag(String tagId, int width, int height) async {
    state.ensureReady();
    final previousState = state;
    final organizationId = ref.read(organizationIdProvider);
    final realmId = ref.read(realmIdProvider);
    assert(realmId != null, "realmId must not be null when resizing a tag");
    assert(
      organizationId != null,
      "organizationId must not be null when resizing a tag",
    );

    final current = state.value ?? [];
    state = AsyncData(
      current.map((t) {
        if (t.tagId != tagId) return t;
        return t.deepCopy()
          ..placement = (t.placement.deepCopy()
            ..width = width
            ..height = height);
      }).toList(),
    );

    final request = ResizeTagRequest()
      ..tagId = tagId
      ..width = width
      ..height = height;

    try {
      final response = await ref
          .read(natsProvider)
          .requestProto(
            "realm.to.$realmId.organization.$organizationId.tag.resize",
            request,
            ResizeTagResponse.new,
          );

      if (response.hasError()) {
        throw ApiException.fromProto(response.error);
      }
    } catch (e) {
      state = previousState;
      rethrow;
    }
  }
}

@riverpod
Future<Tag?> tag(Ref ref, String tagId) async {
  final tags = await ref.watch(tagsProvider.future);
  return tags.firstWhereOrNull((t) => t.tagId == tagId);
}
