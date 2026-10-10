import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

part "pages.g.dart";
part "pages.freezed.dart";

/// Immutable page metadata used by library and page editor consumers.
///
/// The shared workspace owns authored values. This model is a pure typed view.
@freezed
abstract class Page with _$Page {
  @Assert("name != \"\"", "Name must not be empty.")
  const factory Page({
    required skir.ResourceId pageId,
    required skir.ResourceId? bookId,
    required String name,
    required skir.TypeSelection configuration,
    required String chapter,
    required int priority,
  }) = _Page;

  const Page._();

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

  skir.NamedTypeUse? get rootType => switch (configuration) {
    skir.TypeSelection_completeWrapper(:final value) => value,
    _ => null,
  };
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
