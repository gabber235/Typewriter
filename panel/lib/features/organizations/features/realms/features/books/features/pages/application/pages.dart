import "package:freezed_annotation/freezed_annotation.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

part "pages.freezed.dart";
part "pages.g.dart";

@freezed
abstract class Page with _$Page {
  @Assert("name != \"\"", "Name must not be empty.")
  const factory Page({
    required skir.RecordId pageId,
    required int revision,
    required skir.RecordId bookId,
    required String name,
    required PageKindRef kind,
    required String chapter,
    required int priority,
  }) = _Page;

  const Page._();

  factory Page.fromSkir(skir.Page page) => Page(
    pageId: page.pageId,
    revision: page.revision,
    bookId: page.bookId,
    name: page.name,
    kind: PageKindRef.fromSkir(page.kind),
    chapter: page.chapter,
    priority: page.priority,
  );

  skir.Page toSkir() => skir.Page(
    pageId: this.pageId,
    revision: revision,
    bookId: this.bookId,
    name: name,
    kind: kind.toSkir(),
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
      RealmServiceAddress(
        organizationId: organizationId,
        realmId: realmId,
      ).request("page.search"),
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
    final address = RealmServiceAddress(
      organizationId: organizationId,
      realmId: realmId,
    );
    yield* ref.watchRequest(
      subject: address.request("page.watch"),
      listenSubject: address.event("page.watch"),
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
    String? chapter,
    int? priority,
  }) async {
    if (name == null && chapter == null && priority == null) {
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
        chapter: chapter ?? currentPage.chapter,
        priority: priority ?? currentPage.priority,
      ),
    );
    final request = skir.UpdatePageRequest(
      pageId: currentPage.pageId,
      expectedRevision: currentPage.revision,
      name: name,
      chapter: chapter,
      priority: priority,
    );

    try {
      final response = await ref.requestSkir(
        RealmServiceAddress(
          organizationId: organizationId,
          realmId: realmId,
        ).request("page.update"),
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
        case skir.UpdatePageResponse_conflictErrorWrapper(:final value):
          state = AsyncData(Page.fromSkir(value.actual));
          throw ApiException.conflict(
            "The page changed while it was being edited",
          );
        case skir.UpdatePageResponse_pageNotFoundErrorWrapper():
          throw ApiException.notFound("Page");
        case skir.UpdatePageResponse_validationErrorWrapper(:final value):
          throw _pageValidationException(value);
        case skir.UpdatePageResponse_invalidRecordIdErrorWrapper(:final value):
          throw ApiException.invalidRecordId(value);
      }
    } on ApiException catch (failure) {
      if (failure.code != 409) state = previousState;
      rethrow;
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
    skir.PageValidationError_kind.pageKindUnknownConst =>
      ApiException.badRequest("Page kind is unknown"),
    skir.PageValidationError_kind.pageKindRevisionUnknownConst =>
      ApiException.badRequest("Page kind revision is unknown"),
  };
}
