import "package:collection/collection.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";
import "package:typewriter_panel/generated/api/tag.pb.dart";
import "package:typewriter_panel/generated/models/book.pb.dart";
import "package:typewriter_panel/generated/models/common.pb.dart";
import "package:typewriter_panel/logic/nats.dart";
import "package:typewriter_panel/logic/proto/api_exception.dart";
import "package:typewriter_panel/logic/realm.dart";
import "package:typewriter_panel/utils/riverpod.dart";

part "tags.g.dart";

@riverpod
class Tags extends _$Tags {
  @override
  Stream<List<Tag>> build() async* {
    final realmId = ref.watch(realmIdProvider);
    if (realmId == null) {
      yield [];
      return;
    }

    final request = ListTagsRequest();
    final stream = ref.requestProtoThenListen(
      subject: "realm.$realmId.tag.list",
      listenSubject: "realm.$realmId.tag.list",
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

  Future<Tag?> createTag({
    required String name,
    Color? color,
    List<String> parentIds = const [],
    int x = 0,
    int y = 0,
    int width = 4,
    int height = 1,
  }) async {
    final realmId = ref.read(realmIdProvider);
    if (realmId == null) return null;

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

    final response = await ref
        .read(natsProvider)
        .requestProto(
          "realm.$realmId.tag.create",
          request,
          CreateTagResponse.new,
        );

    if (response.hasError()) {
      throw ApiException.fromProto(response.error);
    }

    ref.invalidateSelf();
    return response.tag;
  }

  Future<void> updateTag(Tag tag) async {
    final realmId = ref.read(realmIdProvider);
    if (realmId == null) return;

    final request = UpdateTagRequest()..tag = tag;

    final response = await ref
        .read(natsProvider)
        .requestProto(
          "realm.$realmId.tag.update",
          request,
          UpdateTagResponse.new,
        );

    if (response.hasError()) {
      throw ApiException.fromProto(response.error);
    }

    ref.invalidateSelf();
  }

  Future<void> deleteTag(String tagId) async {
    final realmId = ref.read(realmIdProvider);
    if (realmId == null) return;

    final request = DeleteTagRequest()..id = tagId;

    final response = await ref
        .read(natsProvider)
        .requestProto(
          "realm.$realmId.tag.delete",
          request,
          DeleteTagResponse.new,
        );

    if (response.hasError()) {
      throw ApiException.fromProto(response.error);
    }

    ref.invalidateSelf();
  }

  Future<void> moveTag(String tagId, int x, int y) async {
    final realmId = ref.read(realmIdProvider);
    if (realmId == null) return;

    final request = MoveTagRequest()
      ..id = tagId
      ..x = x
      ..y = y;

    final response = await ref
        .read(natsProvider)
        .requestProto("realm.$realmId.tag.move", request, MoveTagResponse.new);

    if (response.hasError()) {
      throw ApiException.fromProto(response.error);
    }

    ref.invalidateSelf();
  }

  Future<void> resizeTag(String tagId, int width, int height) async {
    final realmId = ref.read(realmIdProvider);
    if (realmId == null) return;

    final request = ResizeTagRequest()
      ..id = tagId
      ..width = width
      ..height = height;

    final response = await ref
        .read(natsProvider)
        .requestProto(
          "realm.$realmId.tag.resize",
          request,
          ResizeTagResponse.new,
        );

    if (response.hasError()) {
      throw ApiException.fromProto(response.error);
    }

    ref.invalidateSelf();
  }
}

@riverpod
Tag? tag(Ref ref, String tagId) {
  final tagsAsync = ref.watch(tagsProvider);
  return tagsAsync.whenOrNull(
    data: (tags) => tags.firstWhereOrNull((t) => t.id == tagId),
  );
}
