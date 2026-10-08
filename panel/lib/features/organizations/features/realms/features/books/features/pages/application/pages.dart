import "package:riverpod_annotation/riverpod_annotation.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

part "pages.g.dart";

/// Immutable page metadata used by library and page editor consumers.
///
/// The wire authoring session is canonical. This model is a typed read model;
/// local editor values are overlaid only by [projected] and never written back
/// into canonical state by the model itself.
final class Page {
  const Page({
    required this.pageId,
    required this.authoredRecord,
    required this.bookId,
    required this.name,
    required this.configuration,
    required this.chapter,
    required this.priority,
  }) : assert(name != "", "Name must not be empty.");

  factory Page.fromAuthoring(skir.AuthoringResource resource) {
    final value = decodeAuthoredPage(resource);
    return Page(
      pageId: value.id,
      authoredRecord: resource.content,
      bookId: value.book,
      name: value.name,
      configuration: value.configuration,
      chapter: value.chapter,
      priority: value.priority,
    );
  }

  final skir.ResourceId pageId;

  /// Exact observation retained for chapter moves, separate from display defaults.
  final skir.AuthoringRecord authoredRecord;
  final skir.ResourceId? bookId;
  final String name;
  final skir.TypeSelection configuration;
  final String chapter;
  final int priority;

  skir.NamedTypeUse? get rootType => switch (configuration) {
    skir.TypeSelection_completeWrapper(:final value) => value,
    _ => null,
  };

  Page copyWith({
    skir.ResourceId? pageId,
    skir.ResourceId? bookId,
    String? name,
    skir.TypeSelection? configuration,
    String? chapter,
    int? priority,
  }) => Page(
    pageId: pageId ?? this.pageId,
    authoredRecord: authoredRecord,
    bookId: bookId ?? this.bookId,
    name: name ?? this.name,
    configuration: configuration ?? this.configuration,
    chapter: chapter ?? this.chapter,
    priority: priority ?? this.priority,
  );
}

/// Retains and exposes canonical pages belonging to one book.
///
/// The realm authoring session owns the data and server sequence. This provider
/// leases the registered book page selection, refreshes on sequenced session
/// observations, and does not include local editor drafts.
@riverpod
class CanonicalBookPages extends _$CanonicalBookPages {
  @override
  Future<List<Page>> build(skir.ResourceId bookId) async {
    final organizationId = ref.watch(organizationIdProvider);
    final realmId = ref.watch(realmIdProvider);
    if (organizationId == null) throw ApiException.noOrganization();
    if (realmId == null) throw ApiException.badRequest("No realm selected");
    final provider = authoringSessionProvider(organizationId, realmId);
    var session = ref.watch(provider);
    if (session.failure case final failure?) {
      throw StateError("Authoring is unavailable: $failure");
    }
    if (session.snapshot == null) {
      await ref.read(provider.notifier).ready;
      session = ref.read(provider);
    }
    return _projectPages(session)
        .where((page) => page.bookId == bookId)
        .toList();
  }
}

/// Retains one canonical page through a typed resource selection lease.
///
/// Missing pages become a not found outcome after the authoritative snapshot or
/// a later sequenced removal. Draft values are intentionally supplied by
/// [projectedPage], not this provider.
@riverpod
class CanonicalPage extends _$CanonicalPage {
  @override
  Future<Page> build(skir.ResourceId pageId) async {
    final organizationId = ref.watch(organizationIdProvider);
    final realmId = ref.watch(realmIdProvider);
    if (organizationId == null) throw ApiException.noOrganization();
    if (realmId == null) throw ApiException.badRequest("No realm selected");
    final provider = authoringSessionProvider(organizationId, realmId);
    var session = ref.watch(provider);
    if (session.failure case final failure?) {
      throw StateError("Authoring is unavailable: $failure");
    }
    if (session.snapshot == null) {
      await ref.read(provider.notifier).ready;
      session = ref.read(provider);
    }
    return _projectPages(session)
            .where((page) => page.pageId == pageId)
            .firstOrNull ??
        (throw ApiException.notFound("Page"));
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
  skir.ResourceId bookId,
  String search,
) {
  final canonical = ref.watch(canonicalBookPagesProvider(bookId));
  if (canonical.mapUnready<List<Page>>() case final value?) return value;
  final organizationId = ref.watch(organizationIdProvider);
  final realmId = ref.watch(realmIdProvider);
  if (organizationId == null || realmId == null) {
    return AsyncData(canonical.requireValue);
  }
  final query = search.trim().toLowerCase();
  return AsyncData([
    for (final page in canonical.requireValue)
      if (query.isEmpty ||
          page.name.toLowerCase().contains(query) ||
          page.chapter.toLowerCase().contains(query))
        page,
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
AsyncValue<Page> projectedPage(Ref ref, skir.ResourceId pageId) {
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
  return canonical;
}

/// Resolves the route's string parameter to the typed page record identity.
@riverpod
skir.ResourceId? pageId(Ref ref) {
  final id = ref.watch(routeParamProvider("pageId"));
  if (id == null) return null;
  return skir.ResourceId(value: id);
}

List<Page> _projectPages(AuthoringSessionState session) => session
    .resources
    .values
    .where((resource) => resource.definition == _pageDefinition)
    .map(Page.fromAuthoring)
    .toList(growable: false);

final _pageDefinition = skir.ResourceDefinitionId(value: "typewriter.page");
