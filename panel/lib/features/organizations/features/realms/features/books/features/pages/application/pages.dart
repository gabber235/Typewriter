import "package:riverpod_annotation/riverpod_annotation.dart";
import "package:typewriter_panel/infrastructure/protocols/protobuf/generated/api/page.pb.dart";
import "package:typewriter_panel/infrastructure/protocols/protobuf/generated/models/book.pb.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

part "pages.g.dart";

@riverpod
class BookPages extends _$BookPages {
  @override
  FutureOr<List<Page>> build(String bookId, String search) async {
    final organizationId = ref.watch(organizationIdProvider);
    final realmId = ref.watch(realmIdProvider);
    assert(
      realmId != null,
      "realmId must not be null when fetching book pages",
    );
    assert(
      organizationId != null,
      "organizationId must not be null when fetching book pages",
    );

    final request = SearchPagesRequest()
      ..bookId = bookId
      ..search = search;

    final response = await ref
        .read(natsProvider)
        .requestProto(
          "realm.to.$realmId.organization.$organizationId.page.search",
          request,
          SearchPagesResponse.new,
        );

    if (response.hasError()) {
      throw Exception("Failed to search pages: ${response.error.message}");
    }

    assert(
      response.hasPages(),
      "No pages were provided even though there was no error",
    );

    return response.pages.pages;
  }
}

@riverpod
class Pages extends _$Pages {
  @override
  FutureOr<Page> build(String pageId) async {
    final organizationId = ref.watch(organizationIdProvider);
    final realmId = ref.watch(realmIdProvider);
    if (realmId == null || organizationId == null) {
      throw Exception("No realm selected");
    }

    final request = GetPageRequest()..pageId = pageId;

    final response = await ref
        .read(natsProvider)
        .requestProto(
          "realm.to.$realmId.organization.$organizationId.page.get",
          request,
          GetPageResponse.new,
        );

    if (response.hasError()) {
      throw Exception("Failed to get page: ${response.error.message}");
    }

    assert(
      response.hasPage(),
      "No page was provided even though there was no error",
    );

    return response.page;
  }

  Future<void> changeChapter(String chapter) async {
    state.ensureReady();

    final organizationId = ref.read(organizationIdProvider);
    final realmId = ref.read(realmIdProvider);
    assert(realmId != null, "realmId must not be null when changing chapter");
    assert(
      organizationId != null,
      "organizationId must not be null when changing chapter",
    );

    final currentPage = state.requireValue;

    final optimisticUpdate = currentPage.deepCopy()..chapter = chapter;
    state = AsyncData(optimisticUpdate);

    try {
      final request = ChangePageChapterRequest()
        ..pageId = currentPage.pageId
        ..chapter = chapter;

      final response = await ref
          .read(natsProvider)
          .requestProto(
            "realm.to.$realmId.organization.$organizationId.page.chapter",
            request,
            ChangePageChapterResponse.new,
          );

      if (response.hasError()) {
        throw Exception("Failed to change chapter: ${response.error.message}");
      }

      ref.invalidateSelf();
    } catch (e) {
      state = AsyncData(currentPage);
      rethrow;
    }
  }

  Future<void> changePriority(int priority) async {
    state.ensureReady();

    final organizationId = ref.read(organizationIdProvider);
    final realmId = ref.read(realmIdProvider);
    assert(realmId != null, "realmId must not be null when changing priority");
    assert(
      organizationId != null,
      "organizationId must not be null when changing priority",
    );

    final currentPage = state.value;
    if (currentPage == null) return;

    final optimisticUpdate = currentPage.deepCopy()..priority = priority;
    state = AsyncData(optimisticUpdate);

    try {
      final request = ChangePagePriorityRequest()
        ..pageId = currentPage.pageId
        ..priority = priority;

      final response = await ref
          .read(natsProvider)
          .requestProto(
            "realm.to.$realmId.organization.$organizationId.page.priority",
            request,
            ChangePagePriorityResponse.new,
          );

      if (response.hasError()) {
        throw Exception("Failed to change priority: ${response.error.message}");
      }

      ref.invalidateSelf();
    } catch (e) {
      state = AsyncData(currentPage);
      rethrow;
    }
  }

  Future<void> renamePage(String name) async {
    state.ensureReady();

    final organizationId = ref.read(organizationIdProvider);
    final realmId = ref.read(realmIdProvider);
    assert(realmId != null, "realmId must not be null when renaming page");
    assert(
      organizationId != null,
      "organizationId must not be null when renaming page",
    );

    final currentPage = state.value;
    if (currentPage == null) return;

    final optimisticUpdate = currentPage.deepCopy()..name = name;
    state = AsyncData(optimisticUpdate);

    try {
      final request = RenamePageRequest()
        ..pageId = currentPage.pageId
        ..name = name;

      final response = await ref
          .read(natsProvider)
          .requestProto(
            "realm.to.$realmId.organization.$organizationId.page.rename",
            request,
            RenamePageResponse.new,
          );

      if (response.hasError()) {
        throw Exception("Failed to rename page: ${response.error.message}");
      }

      ref.invalidateSelf();
    } catch (e) {
      state = AsyncData(currentPage);
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
