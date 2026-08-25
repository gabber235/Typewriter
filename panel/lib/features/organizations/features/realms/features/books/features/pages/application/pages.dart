import "package:freezed_annotation/freezed_annotation.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/library/v1/page.dart"
    as wire_v1;
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/library/v2/authoring.dart"
    as wire_v2;
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

  factory Page.fromSkir(wire_v1.Page page) => Page(
    pageId: page.pageId,
    revision: page.revision,
    bookId: page.bookId,
    name: page.name,
    kind: PageKindRef.fromSkir(page.kind),
    chapter: page.chapter,
    priority: page.priority,
  );

  factory Page.fromV2(wire_v2.Page page) => Page(
    pageId: page.id,
    revision: page.revision,
    bookId: page.book,
    name: page.name,
    kind: PageKindRef.fromSkir(page.kind),
    chapter: page.chapter,
    priority: page.priority,
  );

  wire_v1.Page toSkir() => wire_v1.Page(
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
    ref.watch(libraryInvalidationsProvider(skir.LibraryResourceKind.page));
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
    ref.watch(libraryInvalidationsProvider(skir.LibraryResourceKind.page));
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
    final request = skir.UpdatePagesRequest(
      batchId: uuid.v4(),
      pages: [
        skir.PageUpdate(
          id: currentPage.pageId,
          expectedRevision: currentPage.revision,
          name: name ?? currentPage.name,
          chapter: chapter ?? currentPage.chapter,
          priority: priority ?? currentPage.priority,
        ),
      ],
    );

    try {
      final response = await ref.requestSkir(
        RealmServiceAddress(
          organizationId: organizationId,
          realmId: realmId,
        ).request("page.update.v2"),
        skir.UpdatePagesRequest.serializer.toBytes(request),
        skir.UpdatePagesResponse.serializer,
      );

      switch (response) {
        case skir.UpdatePagesResponse_unknown():
          throw ApiException.unknownResponseMessage();
        case skir.UpdatePagesResponse_internalErrorWrapper():
          throw ApiException.internalServerError();
        case skir.UpdatePagesResponse_successWrapper(:final value):
          state = AsyncData(Page.fromV2(value.single));
        case skir.UpdatePagesResponse_conflictWrapper(:final value):
          final actual = value.single.actual;
          if (actual != null) state = AsyncData(Page.fromV2(actual));
          throw ApiException.conflict(
            "The page changed while it was being edited",
          );
        case skir.UpdatePagesResponse_invalidWrapper(:final value):
          throw ApiException.badRequest(value.join("; "));
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
