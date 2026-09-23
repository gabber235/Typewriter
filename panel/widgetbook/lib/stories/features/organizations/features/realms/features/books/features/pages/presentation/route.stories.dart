import "package:flutter/material.dart" hide Page;
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/support/widgetbook_utils.dart";

part "route_story_fixtures.dart";
part "route_story_authoring.dart";

@widgetbook.UseCase(name: "Graph", type: PagePage)
Widget pagePageGraphUseCase(BuildContext context) {
  final direction = context.knobs.object.dropdown(
    label: "Graph direction",
    options: GraphDirection.values,
    initialOption: GraphDirection.leftToRight,
    labelBuilder: (value) => value.name.formatted,
  );
  final count = context.knobs.int.slider(
    label: "Entry count",
    initialValue: 12,
    min: 0,
    max: 32,
  );
  final elements = graphPageStoryElements(count: count, direction: direction);
  return pagePageStory(
    definition: graphPageStoryDefinition(direction, elements),
    elements: elements,
    pagesState: context.knobs.displayState(
      label: "Pages state",
      initialOption: DisplayState.manyItems,
    ),
    entriesState: context.knobs.displayState(
      label: "Entries state",
      initialOption: DisplayState.manyItems,
    ),
    servicesState: context.knobs.displayState(
      label: "Services state",
      initialOption: DisplayState.manyItems,
    ),
  );
}

@widgetbook.UseCase(name: "Timeline", type: PagePage)
Widget pagePageTimelineUseCase(BuildContext context) {
  final elements = generateTimelinePageElements(
    trackCount: context.knobs.int.slider(
      label: "Track count",
      initialValue: 4,
      min: 1,
      max: 8,
    ),
    segmentsPerTrack: context.knobs.int.slider(
      label: "Segments per track",
      initialValue: 2,
      min: 1,
      max: 6,
    ),
    keyframesPerSegment: context.knobs.int.slider(
      label: "Keyframes per segment",
      initialValue: 2,
      min: 0,
      max: 8,
    ),
    nestingDepth: context.knobs.int.slider(
      label: "Nesting depth",
      initialValue: 1,
      min: 0,
      max: 2,
    ),
  );
  return pagePageStory(
    definition: timelinePageStoryDefinition(elements),
    elements: elements,
    pagesState: context.knobs.displayState(
      label: "Pages state",
      initialOption: DisplayState.manyItems,
    ),
    entriesState: context.knobs.displayState(
      label: "Entries state",
      initialOption: DisplayState.manyItems,
    ),
    servicesState: context.knobs.displayState(
      label: "Services state",
      initialOption: DisplayState.manyItems,
    ),
  );
}

Widget pagePageStory({
  required RealmPageDefinition definition,
  required List<PageElement> elements,
  DisplayState pagesState = DisplayState.fewItems,
  DisplayState entriesState = DisplayState.fewItems,
  DisplayState servicesState = DisplayState.fewItems,
}) {
  final storyElements = switch (entriesState) {
    DisplayState.loading || DisplayState.error => null,
    DisplayState.noItems => const <PageElement>[],
    DisplayState.fewItems || DisplayState.manyItems => elements,
  };
  final storyEntryIndex = {
    for (final element in storyElements ?? const <PageElement>[])
      if (element case PageElementEntry(
        entry: DefinitionPageEntry(:final definition),
      ))
        definition.id: CachedPageEntry(
          pageId: "example-page-id",
          definition: definition,
        ),
  };
  final page = Page(
    pageId: skir.ResourceId(value: "page:example-page-id"),
    bookId: skir.ResourceId(value: "book:example-book-id"),
    name: "Example",
    rootType: definition.type,
    chapter: "",
    priority: 0,
  );

  return FakeApp(
    overrides: [
      ...authoringSessionMockOverrides(
        initial: pageStoryAuthoring(definition, storyElements ?? const []),
        includeCatalog: false,
      ),
      authoringEntryIndexProvider.overrideWith(
        (ref, scope) =>
            AsyncData(AuthoringValue(value: storyEntryIndex, revision: 1)),
      ),
      realmEntryIndexProvider.overrideWith(
        (ref, scope) => AsyncData(storyEntryIndex),
      ),
      realmInteractionProvider.overrideWith(
        (ref) => const RealmInteractionState(
          connectionState: RealmConnectionState.online,
        ),
      ),
      realmConnectionProvider.overrideWith(
        (ref) => Stream.value(RealmConnectionState.online),
      ),
      realmEditorCatalogForTypeProvider.overrideWith(
        (ref, rootType) =>
            Stream.value(pageStoryCatalog(rootType, storyElements ?? const [])),
      ),
      realmEditorCatalogProvider.overrideWith(
        (ref) => Stream.value(
          pageStoryPageCatalog(definition, storyElements ?? const []),
        ),
      ),
      authoringSubjectsProvider.overrideWith(
        (ref, scope) async => pageStorySubjectProjection(
          definition,
          storyElements ?? const [],
          scope,
        ),
      ),
      realmEditorCatalogLeaseProvider.overrideWith((ref, request) => null),
      pageDocumentHealthProvider.overrideWith((ref, argument) => null),
      ...entryProviderOverrides(),
      ...pageElementsProviderOverrides(
        state: entriesState,
        elements: storyElements,
      ),
      ...bookPagesProviderOverrides(state: pagesState),
      ...pagesProviderOverrides(page: page),
      ...pageIdProviderOverrides(pageId: "example-page-id"),
      ...bookIdProviderOverrides(bookId: "example-book-id"),
      ...booksProviderOverrides(state: pagesState),
      ...canonicalServicesProviderOverrides(state: servicesState),
      realmIdProvider.overrideWith(
        (ref) => recordId("realm_instance:example-realm-id"),
      ),
      realmsProvider.overrideWith((ref) async => const []),
      selectedRealmProvider.overrideWith((ref) async => null),
      activeRealmEditorRuntimeProvider.overrideWith((ref) => null),
      ...organizationProviderOverrides(),
      ...organizationsProviderOverrides(state: DisplayState.manyItems),
      ...authProviderOverrides(),
      ...appearanceProviderOverrides(),
    ],
    child: BookScaffold(child: PagePage(pageId: "example-page-id")),
  );
}
