import "package:flutter/material.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/stories/features/organizations/features/realms/features/books/features/pages/presentation/route.stories.dart";
import "package:widgetbook_workspace/stories/features/organizations/features/realms/features/search/presentation/authoring_search_story_catalog.dart";
import "package:widgetbook_workspace/stories/features/organizations/features/realms/features/search/presentation/authoring_search_story_fixtures.dart";

@widgetbook.UseCase(name: "App bar trigger", type: PrimarySearchButton)
Widget primarySearchButtonUseCase(BuildContext context) {
  return primarySearchButtonStory(
    initialQuery: context.knobs.string(label: "Initial query"),
    searchDelay: context.knobs.duration(
      label: "Search delay",
      initialValue: const Duration(milliseconds: 180),
    ),
  );
}

Widget primarySearchButtonStory({
  String initialQuery = "",
  Duration searchDelay = const Duration(milliseconds: 180),
}) {
  const pagesState = DisplayState.fewItems;
  const entriesState = DisplayState.fewItems;
  const booksState = DisplayState.fewItems;
  const servicesState = DisplayState.fewItems;
  const organizationsState = DisplayState.fewItems;

  final storyElements = graphPageStoryElements(
    count: 6,
    direction: GraphDirection.leftToRight,
  );
  final pageDefinition = graphPageStoryDefinition(
    GraphDirection.leftToRight,
    storyElements,
  );
  final storyEntryIndex = {
    for (final element in storyElements)
      if (element case PageElementEntry(
        entry: DefinitionPageEntry(:final definition),
      ))
        definition.id: CachedPageEntry(
          pageId: "example-page-id",
          definition: definition,
        ),
  };
  final elementType =
      storyEntryIndex.values.first.definition.elementDefinition.typeId.uuid;
  final fixtures = AuthoringSearchStoryFixtures(
    elementType: elementType,
    pageKind: pageDefinition.kind.toSkir(),
  );

  return FakeApp(
    overrides: [
      primarySearchRequestProvider.overrideWith((ref) {
        final production = buildPrimarySearchRequest(ref);
        return PrimarySearchRequest(
          contributionBuilder: (_, context) => SearchContribution(
            session: fixtures.session(
              searchDelay: searchDelay,
              initialQuery: initialQuery,
            ),
            hostEffectExecutors: [
              SearchHostEffectExecutor<OpenAuthoringBookEffect>((_) async {}),
              SearchHostEffectExecutor<OpenAuthoringTagEffect>((_) async {}),
              SearchHostEffectExecutor<OpenAuthoringPageEffect>((_) async {}),
              SearchHostEffectExecutor<OpenAuthoringElementEffect>(
                (_) async {},
              ),
            ],
          ),
          searchHint: production.searchHint,
          rowRenderers: production.rowRenderers,
          previewRenderers: production.previewRenderers,
        );
      }),
      ...authoringSessionMockOverrides(
        initial: pageStoryAuthoring(pageDefinition, storyElements),
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
            Stream.value(pageStoryCatalog(rootType, storyElements)),
      ),
      realmEditorCatalogProvider.overrideWith(
        (ref) => Stream.value(
          authoringSearchStoryCatalog(
            pageStoryPageCatalog(pageDefinition, storyElements),
          ),
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
      ...pagesProviderOverrides(pageKind: pageDefinition.kind),
      ...pageIdProviderOverrides(pageId: "example-page-id"),
      ...bookIdProviderOverrides(bookId: "example-book-id"),
      ...booksProviderOverrides(state: booksState),
      ...canonicalServicesProviderOverrides(state: servicesState),
      realmIdProvider.overrideWith(
        (ref) => recordId("realm_instance:example-realm-id"),
      ),
      realmsProvider.overrideWith((ref) async => const []),
      selectedRealmProvider.overrideWith((ref) async => null),
      activeRealmEditorRuntimeProvider.overrideWith((ref) => null),
      ...organizationProviderOverrides(),
      ...organizationsProviderOverrides(state: organizationsState),
      ...authProviderOverrides(),
      ...appearanceProviderOverrides(),
    ],
    child: const Center(child: PrimarySearchButton()),
  );
}
