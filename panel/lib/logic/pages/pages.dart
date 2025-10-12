import "package:riverpod_annotation/riverpod_annotation.dart";
import "package:typewriter_panel/app_router.dart";
import "package:typewriter_panel/generated/api/page.pb.dart";
import "package:typewriter_panel/generated/models/book.pb.dart";
import "package:typewriter_panel/logic/nats.dart";
import "package:typewriter_panel/utils/riverpod.dart";

part "pages.g.dart";

@riverpod
class BookPages extends _$BookPages {
  @override
  FutureOr<List<Page>> build(String bookId, String search) async {
    final request = SearchPagesRequest()
      ..bookId = bookId
      ..search = search;

    final response = await ref
        .watch(natsProvider)
        .requestProto("pages.search", request, SearchPagesResponse.new);

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
    final request = GetPageRequest()..id = pageId;

    final response = await ref
        .watch(natsProvider)
        .requestProto("pages.get", request, GetPageResponse.new);

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

    final currentPage = state.requireValue;

    final optimisticUpdate = currentPage.deepCopy()..chapter = chapter;
    state = AsyncData(optimisticUpdate);

    try {
      final request = ChangePageChapterRequest()
        ..pageId = currentPage.id
        ..chapter = chapter;

      final response = await ref
          .watch(natsProvider)
          .requestProto(
            "pages.change_chapter",
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

    final currentPage = state.value;
    if (currentPage == null) return;

    final optimisticUpdate = currentPage.deepCopy()..priority = priority;
    state = AsyncData(optimisticUpdate);

    try {
      final request = ChangePagePriorityRequest()
        ..pageId = currentPage.id
        ..priority = priority;

      final response = await ref
          .watch(natsProvider)
          .requestProto(
            "pages.change_priority",
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

    final currentPage = state.value;
    if (currentPage == null) return;

    final optimisticUpdate = currentPage.deepCopy()..name = name;
    state = AsyncData(optimisticUpdate);

    try {
      final request = RenamePageRequest()
        ..pageId = currentPage.id
        ..name = name;

      final response = await ref
          .watch(natsProvider)
          .requestProto("pages.rename", request, RenamePageResponse.new);

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
String? pageId(Ref ref) {
  final routeData = ref.watch(currentRouteDataProvider(RouteRoute.name));
  return routeData?.params.getString("pageId");
}
