import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

part "pages.g.dart";

/// Immutable page metadata used by library and page editor consumers.
///
/// The shared workspace owns authored values. This model is a pure typed view.
final class Page {
  const Page({
    required this.pageId,
    required this.bookId,
    required this.name,
    required this.configuration,
    required this.chapter,
    required this.priority,
  }) : assert(name != "", "Name must not be empty.");

  factory Page.fromAuthoring(skir.AuthoringResource resource) {
    final content = resource.content;
    return Page(
      pageId: resource.id,
      bookId: content.authoredField("book")?.authoredLink?.target.resource,
      name: (content.authoredField("name")?.authoredString).displayLabel(
        "Unnamed Page",
      ),
      configuration: content.configuration,
      chapter: content.authoredField("chapter")?.authoredString ?? "",
      priority:
          content.authoredField("priority")?.authoredInteger?.toInt() ?? 0,
    );
  }

  final skir.ResourceId pageId;

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
    bookId: bookId ?? this.bookId,
    name: name ?? this.name,
    configuration: configuration ?? this.configuration,
    chapter: chapter ?? this.chapter,
    priority: priority ?? this.priority,
  );
}

/// All pages in the working document, including resources without a book yet.
@riverpod
AsyncValue<List<Page>> workingPages(Ref ref) {
  final source = ref.watch(selectedWorkingAuthoringDocumentProvider);
  if (source.mapUnready<List<Page>>() case final pending?) return pending;
  return AsyncData(
    source.requireValue.entries.values
        .where((entry) => entry.definition == corePageResourceDefinition)
        .map(Page.fromAuthoring)
        .toList(growable: false),
  );
}

@riverpod
AsyncValue<List<Page>> workingBookPages(
  Ref ref,
  skir.ResourceId bookId,
  String search,
) {
  final source = ref.watch(workingPagesProvider);
  if (source.mapUnready<List<Page>>() case final pending?) return pending;
  final query = search.trim().toLowerCase();
  return AsyncData(
    source.requireValue
        .where(
          (page) =>
              page.bookId == bookId &&
              (query.isEmpty ||
                  page.name.toLowerCase().contains(query) ||
                  page.chapter.toLowerCase().contains(query)),
        )
        .toList(growable: false),
  );
}

@riverpod
AsyncValue<Page> workingPage(Ref ref, skir.ResourceId pageId) {
  final source = ref.watch(workingPagesProvider);
  if (source.mapUnready<Page>() case final pending?) return pending;
  final page = source.requireValue.firstWhereOrNull(
    (page) => page.pageId == pageId,
  );
  return page == null
      ? AsyncError(ApiException.notFound("Page"), StackTrace.current)
      : AsyncData(page);
}

/// Resolves the route's string parameter to the typed page record identity.
@riverpod
skir.ResourceId? pageId(Ref ref) {
  final id = ref.watch(routeParamProvider("pageId"));
  if (id == null) return null;
  return skir.ResourceId(value: id);
}
