import "package:freezed_annotation/freezed_annotation.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

part "pages.freezed.dart";
part "pages.g.dart";

enum PageType {
  sequence,
  static,
  scene,
  manifest;

  static PageType fromSkir(skir.PageType type) => switch (type) {
    skir.PageType.sequence => PageType.sequence,
    skir.PageType.static_ => PageType.static,
    skir.PageType.scene => PageType.scene,
    skir.PageType.manifest => PageType.manifest,
    skir.PageType_unknown() => throw ApiException.unknownResponseMessage(),
  };

  skir.PageType toSkir() => switch (this) {
    PageType.sequence => skir.PageType.sequence,
    PageType.static => skir.PageType.static_,
    PageType.scene => skir.PageType.scene,
    PageType.manifest => skir.PageType.manifest,
  };
}

@freezed
abstract class Page with _$Page {
  @Assert("name != \"\"", "Name must not be empty.")
  const factory Page({
    required skir.RecordId pageId,
    required skir.RecordId bookId,
    required String name,
    required PageType type,
    required String chapter,
    required int priority,
  }) = _Page;

  const Page._();

  factory Page.fromSkir(skir.Page page) => Page(
    pageId: page.pageId,
    bookId: page.bookId,
    name: page.name,
    type: PageType.fromSkir(page.type),
    chapter: page.chapter,
    priority: page.priority,
  );

  skir.Page toSkir() => skir.Page(
    pageId: this.pageId,
    bookId: this.bookId,
    name: name,
    type: type.toSkir(),
    chapter: chapter,
    priority: priority,
  );
}

@riverpod
class BookPages extends _$BookPages {
  @override
  Future<List<Page>> build(skir.RecordId bookId, String search) async {
    final organizationId = ref.watch(organizationIdProvider);
    final realmId = ref.watch(realmIdProvider);
    if (realmId == null) throw ApiException.badRequest("No realm selected");
    if (organizationId == null) throw ApiException.noOrganization();

    final request = skir.SearchPagesRequest(
      bookId: bookId,
      search: search.trim().isEmpty ? null : search,
    );
    final response = await ref.requestSkir(
      "service.to.${realmId.id}.organization.${organizationId.id}.realm.page.search",
      skir.SearchPagesRequest.serializer.toBytes(request),
      skir.SearchPagesResponse.serializer,
    );

    return switch (response) {
      skir.SearchPagesResponse_unknown() =>
        throw ApiException.unknownResponseMessage(),
      skir.SearchPagesResponse_internalErrorWrapper() =>
        throw ApiException.internalServerError(),
      skir.SearchPagesResponse_successWrapper(:final value) =>
        value.map(Page.fromSkir).toList(),
      skir.SearchPagesResponse_bookNotFoundErrorWrapper() =>
        throw ApiException.notFound("Book"),
      skir.SearchPagesResponse_invalidRecordIdErrorWrapper(:final value) =>
        throw ApiException.invalidRecordId(value),
    };
  }
}

@riverpod
class Pages extends _$Pages {
  @override
  Stream<Page> build(skir.RecordId pageId) async* {
    final organizationId = ref.watch(organizationIdProvider);
    final realmId = ref.watch(realmIdProvider);
    if (realmId == null) throw ApiException.badRequest("No realm selected");
    if (organizationId == null) throw ApiException.noOrganization();

    final request = skir.WatchPageRequest(pageId: pageId);
    yield* ref.watchRequest(
      subject:
          "service.to.${realmId.id}.organization.${organizationId.id}.realm.page.watch",
      listenSubject:
          "service.from.${realmId.id}.organization.${organizationId.id}.realm.page.watch",
      requestBytes: skir.WatchPageRequest.serializer.toBytes(request),
      serializer: skir.WatchPageResponse.serializer,
      transformer: (previous, response) {
        switch (response) {
          case skir.WatchPageResponse_unknown():
            throw ApiException.unknownResponseMessage();
          case skir.WatchPageResponse_internalErrorWrapper():
            throw ApiException.internalServerError();
          case skir.WatchPageResponse_initialWrapper(:final value):
          case skir.WatchPageResponse_updateWrapper(:final value):
            return Page.fromSkir(value);
          case skir.WatchPageResponse_removeWrapper():
          case skir.WatchPageResponse_pageNotFoundErrorWrapper():
            throw ApiException.notFound("Page");
          case skir.WatchPageResponse_invalidRecordIdErrorWrapper(:final value):
            throw ApiException.invalidRecordId(value);
        }
      },
    );
  }

  Future<void> updatePage({
    String? name,
    PageType? type,
    String? chapter,
    int? priority,
  }) async {
    if (name == null && type == null && chapter == null && priority == null) {
      throw ApiException.badRequest("At least one page field is required");
    }

    state.ensureReady();
    final previousState = state;
    final organizationId = ref.read(organizationIdProvider);
    final realmId = ref.read(realmIdProvider);
    if (realmId == null) throw ApiException.badRequest("No realm selected");
    if (organizationId == null) throw ApiException.noOrganization();

    final currentPage = state.requireValue;
    state = AsyncData(
      currentPage.copyWith(
        name: name ?? currentPage.name,
        type: type ?? currentPage.type,
        chapter: chapter ?? currentPage.chapter,
        priority: priority ?? currentPage.priority,
      ),
    );
    final request = skir.UpdatePageRequest(
      pageId: currentPage.pageId,
      name: name,
      type: type?.toSkir(),
      chapter: chapter,
      priority: priority,
    );

    try {
      final response = await ref.requestSkir(
        "service.to.${realmId.id}.organization.${organizationId.id}.realm.page.update",
        skir.UpdatePageRequest.serializer.toBytes(request),
        skir.UpdatePageResponse.serializer,
      );

      switch (response) {
        case skir.UpdatePageResponse_unknown():
          throw ApiException.unknownResponseMessage();
        case skir.UpdatePageResponse_internalErrorWrapper():
          throw ApiException.internalServerError();
        case skir.UpdatePageResponse_successWrapper(:final value):
          state = AsyncData(Page.fromSkir(value));
        case skir.UpdatePageResponse_pageNotFoundErrorWrapper():
          throw ApiException.notFound("Page");
        case skir.UpdatePageResponse_validationErrorWrapper(:final value):
          throw _pageValidationException(value);
        case skir.UpdatePageResponse_invalidRecordIdErrorWrapper(:final value):
          throw ApiException.invalidRecordId(value);
      }
    } catch (_) {
      state = previousState;
      rethrow;
    }
  }
}

@riverpod
skir.RecordId? pageId(Ref ref) {
  final id = ref.watch(routeParamProvider("pageId"));
  if (id == null) return null;
  return recordId("page:$id");
}

ApiException _pageValidationException(skir.PageValidationError error) {
  return switch (error.kind) {
    skir.PageValidationError_kind.unknown =>
      ApiException.unknownResponseMessage(),
    skir.PageValidationError_kind.nameRequiredConst => ApiException.badRequest(
      "Page name is required",
    ),
    skir.PageValidationError_kind.pageTypeUnknownConst =>
      ApiException.badRequest("Page type is unknown"),
  };
}
