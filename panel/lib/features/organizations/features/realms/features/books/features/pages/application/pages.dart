import "package:freezed_annotation/freezed_annotation.dart";
import "package:riverpod/riverpod.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

part "pages.freezed.dart";
part "pages.g.dart";

/// Immutable page metadata used by library and page editor consumers.
///
/// The wire authoring session is canonical. This model is a typed read model;
/// local editor values are overlaid only by [projected] and never written back
/// into canonical state by the model itself.
@freezed
abstract class Page with _$Page {
  @Assert("name != \"\"", "Name must not be empty.")
  const factory Page({
    required skir.RecordId pageId,
    required skir.RecordId bookId,
    required String name,
    required PageKindRef kind,
    required String chapter,
    required int priority,
  }) = _Page;

  const Page._();

  /// Converts the authoring contract into the panel's page read model.
  factory Page.fromWire(skir.Page page) => Page(
    pageId: page.id,
    bookId: page.book,
    name: page.name,
    kind: PageKindRef.fromSkir(page.kind),
    chapter: page.chapter,
    priority: page.priority,
  );

  /// Encodes editable metadata for the shared transactional editor boundary.
  RecordValue get editorValue => RecordValue({
    "name": name.asValue,
    "chapter": chapter.asValue,
    "priority": priority.asValue,
  });

  /// Applies a validated metadata record, or returns null for an invalid shape.
  ///
  /// Name, chapter, and priority must be present with their expected value
  /// types. This keeps malformed local work from replacing a visible page.
  Page? withEditorValue(DataValue value) {
    if (value is! RecordValue) return null;
    final name = value.fields["name"];
    final chapter = value.fields["chapter"];
    final priority = value.fields["priority"];
    if (name is! StringValue ||
        name.value.trim().isEmpty ||
        chapter is! StringValue ||
        priority is! IntegerValue) {
      return null;
    }
    return copyWith(
      name: name.value,
      chapter: chapter.value,
      priority: priority.value.toInt(),
    );
  }

  /// Overlays local draft state while retaining this canonical page as fallback.
  Page projected(LocalEditorValue? local) {
    if (local == null) return this;
    return withEditorValue(local.projectOnto(editorValue)) ?? this;
  }
}

/// Retains and exposes canonical pages belonging to one book.
///
/// The realm authoring session owns the data and server sequence. This provider
/// leases the book scope for its lifetime, refreshes on sequenced session
/// observations, and does not include local editor drafts.
@riverpod
class CanonicalBookPages extends _$CanonicalBookPages {
  @override
  Future<List<Page>> build(skir.RecordId bookId) async {
    final organizationId = ref.watch(organizationIdProvider);
    final realmId = ref.watch(realmIdProvider);
    if (organizationId == null) throw ApiException.noOrganization();
    if (realmId == null) throw ApiException.badRequest("No realm selected");
    final provider = authoringSessionProvider(organizationId, realmId);
    List<Page> project(AuthoringSessionState value) {
      return value.pages.values
          .where((page) => page.book == bookId)
          .map(Page.fromWire)
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

/// Retains one canonical page through a page scope lease.
///
/// Missing pages become a not found outcome after the authoritative snapshot or
/// a later sequenced removal. Draft values are intentionally supplied by
/// [projectedPage], not this provider.
@riverpod
class CanonicalPage extends _$CanonicalPage {
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
          : AsyncData(Page.fromWire(page));
    });

    final lease = ref.watch(
      authoringPageScopeProvider(organizationId, realmId, pageId),
    );
    await lease.ready;
    final value = ref.read(provider);
    final page = value.pages[pageId];
    if (page == null) throw ApiException.notFound("Page");
    return Page.fromWire(page);
  }
}

/// Produces the book page list visible to the library sidebar.
///
/// Canonical pages are overlaid with current local drafts, then filtered by
/// page name or chapter. Missing organization or realm context falls back to
/// canonical data because no scoped local projection can be selected.
@riverpod
AsyncValue<List<Page>> projectedBookPages(
  Ref ref,
  skir.RecordId bookId,
  String search,
) {
  final canonical = ref.watch(canonicalBookPagesProvider(bookId));
  if (canonical.mapUnready<List<Page>>() case final value?) return value;
  final organizationId = ref.watch(organizationIdProvider);
  final realmId = ref.watch(realmIdProvider);
  if (organizationId == null || realmId == null) {
    return AsyncData(canonical.requireValue);
  }
  final local = ref.watch(
    localWorkProvider.select((state) => state.editorValues),
  );
  final query = search.trim().toLowerCase();
  return AsyncData([
    for (final page in canonical.requireValue)
      if (page.projected(
            local[EditorResourceKey(
              scope: EditorResourceScope(
                organizationId: organizationId,
                realmId: realmId,
              ),
              identity: page.pageId,
            )],
          )
          case final projected
          when query.isEmpty ||
              projected.name.toLowerCase().contains(query) ||
              projected.chapter.toLowerCase().contains(query))
        projected,
  ]);
}

/// Produces all projected pages in the active realm.
@riverpod
AsyncValue<List<Page>> projectedPages(Ref ref) {
  final books = ref.watch(projectedBooksProvider);
  if (books.mapUnready<List<Page>>() case final value?) return value;

  final pages = [
    for (final book in books.requireValue)
      ref.watch(projectedBookPagesProvider(book.bookId, "")),
  ];
  for (final value in pages) {
    if (value.mapUnready<List<Page>>() case final pending?) return pending;
  }
  return AsyncData([for (final value in pages) ...value.requireValue]);
}

/// Produces one page with its current local metadata projection.
///
/// Canonical loading and errors pass through. An invalid draft projection is
/// ignored by [Page.projected], preserving the last valid visible metadata.
@riverpod
AsyncValue<Page> projectedPage(Ref ref, skir.RecordId pageId) {
  final canonical = ref.watch(canonicalPageProvider(pageId));
  if (canonical.mapUnready<Page>() case final value?) return value;
  final organizationId = ref.watch(organizationIdProvider);
  final realmId = ref.watch(realmIdProvider);
  if (organizationId == null) {
    return AsyncError(ApiException.noOrganization(), StackTrace.current);
  }
  if (realmId == null) {
    return AsyncError(
      ApiException.badRequest("No realm selected"),
      StackTrace.current,
    );
  }
  final key = EditorResourceKey(
    scope: EditorResourceScope(
      organizationId: organizationId,
      realmId: realmId,
    ),
    identity: pageId,
  );
  final local = ref.watch(
    localWorkProvider.select((state) => state.editorValues[key]),
  );
  return AsyncData(canonical.requireValue.projected(local));
}

/// Resolves the route's string parameter to the typed page record identity.
@riverpod
skir.RecordId? pageId(Ref ref) {
  final id = ref.watch(routeParamProvider("pageId"));
  if (id == null) return null;
  return recordId("page:$id");
}
