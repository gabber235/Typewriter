import "package:freezed_annotation/freezed_annotation.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/library/v1/authoring.dart"
    as wire;
import "package:typewriter_panel/typewriter_panel.dart";

part "pages.freezed.dart";
part "pages.g.dart";

@freezed
abstract class Page with _$Page {
  @Assert("name != \"\"", "Name must not be empty.")
  const factory Page({
    required skir.RecordId pageId,
    required int authoringSequence,
    required skir.RecordId bookId,
    required String name,
    required PageKindRef kind,
    required String chapter,
    required int priority,
  }) = _Page;

  const Page._();

  factory Page.fromWire(wire.Page page, int authoringSequence) => Page(
    pageId: page.id,
    authoringSequence: authoringSequence,
    bookId: page.book,
    name: page.name,
    kind: PageKindRef.fromSkir(page.kind),
    chapter: page.chapter,
    priority: page.priority,
  );
}

@riverpod
class BookPages extends _$BookPages {
  @override
  Future<List<Page>> build(skir.RecordId bookId, String search) async {
    final organizationId = ref.watch(organizationIdProvider);
    final realmId = ref.watch(realmIdProvider);
    if (organizationId == null) throw ApiException.noOrganization();
    if (realmId == null) throw ApiException.badRequest("No realm selected");
    final provider = authoringSessionProvider(organizationId, realmId);
    List<Page> project(AuthoringSessionState value) {
      final query = search.trim().toLowerCase();
      final sequence = value.sequence ?? 0;
      return value.pages.values
          .where((page) => page.book == bookId)
          .where((page) {
            if (query.isEmpty) return true;
            return page.name.toLowerCase().contains(query) ||
                page.chapter.toLowerCase().contains(query);
          })
          .map((page) => Page.fromWire(page, sequence))
          .toList();
    }

    ref.listen(provider, (_, value) {
      if (value.sequence != null) state = AsyncData(project(value));
    });
    final lease = ref.watch(
      authoringBookScopeProvider(organizationId, realmId, bookId),
    );
    await lease.ready;
    return project(ref.read(provider));
  }
}

@riverpod
class Pages extends _$Pages {
  @override
  Future<Page> build(skir.RecordId pageId) async {
    final organizationId = ref.watch(organizationIdProvider);
    final realmId = ref.watch(realmIdProvider);
    if (organizationId == null) throw ApiException.noOrganization();
    if (realmId == null) throw ApiException.badRequest("No realm selected");
    final provider = authoringSessionProvider(organizationId, realmId);
    ref.listen(provider, (_, value) {
      if (value.sequence == null) return;
      final page = value.pages[pageId];
      state = page == null
          ? AsyncError(ApiException.notFound("Page"), StackTrace.current)
          : AsyncData(Page.fromWire(page, value.sequence!));
    });
    final lease = ref.watch(
      authoringPageScopeProvider(organizationId, realmId, pageId),
    );
    await lease.ready;
    final value = ref.read(provider);
    final page = value.pages[pageId];
    if (page == null) throw ApiException.notFound("Page");
    return Page.fromWire(page, value.sequence ?? 0);
  }
}

@riverpod
skir.RecordId? pageId(Ref ref) {
  final id = ref.watch(routeParamProvider("pageId"));
  if (id == null) return null;
  return recordId("page:$id");
}
