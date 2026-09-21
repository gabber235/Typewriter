import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/stories/features/organizations/features/realms/features/books/features/pages/presentation/route.stories.dart";
import "package:widgetbook_workspace/stories/features/organizations/features/realms/features/search/presentation/authoring_search_story_catalog.dart";
import "package:widgetbook_workspace/stories/features/organizations/features/realms/features/search/presentation/authoring_search_story_fixtures.dart";

@widgetbook.UseCase(name: "Book result", type: AuthoringSearchResultItem)
Widget authoringBookSearchResultItemUseCase(BuildContext context) =>
    _authoringSearchResultStory(
      context,
      (fixtures, state) => AuthoringSearchResultItem(
        payload: fixtures.mainQuest,
        selected: state.selected,
        focused: state.focused,
        loading: state.loading,
        onTap: () {},
        shortcutActivator: state.shortcut,
      ),
    );

@widgetbook.UseCase(name: "Tag result", type: AuthoringSearchResultItem)
Widget authoringTagSearchResultItemUseCase(BuildContext context) =>
    _authoringSearchResultStory(
      context,
      (fixtures, state) => AuthoringSearchResultItem(
        payload: fixtures.mainQuestTag,
        selected: state.selected,
        focused: state.focused,
        loading: state.loading,
        onTap: () {},
        shortcutActivator: state.shortcut,
      ),
    );

@widgetbook.UseCase(name: "Page result", type: AuthoringSearchResultItem)
Widget authoringPageSearchResultItemUseCase(BuildContext context) =>
    _authoringSearchResultStory(
      context,
      (fixtures, state) => AuthoringSearchResultItem(
        payload: fixtures.meetTheMayor,
        selected: state.selected,
        focused: state.focused,
        loading: state.loading,
        onTap: () {},
        shortcutActivator: state.shortcut,
      ),
    );

@widgetbook.UseCase(name: "Element result", type: AuthoringSearchResultItem)
Widget authoringElementSearchResultItemUseCase(BuildContext context) =>
    _authoringSearchResultStory(
      context,
      (fixtures, state) => AuthoringSearchResultItem(
        payload: fixtures.mayorGreeting,
        selected: state.selected,
        focused: state.focused,
        loading: state.loading,
        onTap: () {},
        shortcutActivator: state.shortcut,
      ),
    );

Widget _authoringSearchResultStory(
  BuildContext context,
  Widget Function(AuthoringSearchStoryFixtures, _ResultStoryState) builder,
) {
  final storyElements = graphPageStoryElements(
    count: 6,
    direction: GraphDirection.leftToRight,
  );
  final pageDefinition = graphPageStoryDefinition(
    GraphDirection.leftToRight,
    storyElements,
  );
  final definition = switch (storyElements.first) {
    PageElementEntry(entry: DefinitionPageEntry(:final definition)) =>
      definition.elementDefinition,
    _ => throw StateError(
      "The authoring search story needs an entry definition",
    ),
  };
  final fixtures = AuthoringSearchStoryFixtures(
    elementType: definition.typeId.uuid,
    pageKind: pageDefinition.kind.toSkir(),
  );
  final state = _ResultStoryState(
    selected: context.knobs.boolean(label: "Selected"),
    focused: context.knobs.boolean(label: "Focused", initialValue: true),
    loading: context.knobs.boolean(label: "Loading"),
    shortcut: context.knobs.boolean(label: "Shortcut", initialValue: true)
        ? const SingleActivator(LogicalKeyboardKey.enter)
        : null,
  );

  return FakeApp(
    overrides: [
      pageIdProvider.overrideWith((ref) => null),
      realmEditorCatalogProvider.overrideWith(
        (ref) => Stream.value(
          authoringSearchStoryCatalog(
            pageStoryPageCatalog(pageDefinition, storyElements),
          ),
        ),
      ),
      ...appearanceProviderOverrides(),
    ],
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 760),
      child: builder(fixtures, state),
    ),
  );
}

Widget authoringSearchResultGalleryStory() {
  final storyElements = graphPageStoryElements(
    count: 6,
    direction: GraphDirection.leftToRight,
  );
  final pageDefinition = graphPageStoryDefinition(
    GraphDirection.leftToRight,
    storyElements,
  );
  final definition = switch (storyElements.first) {
    PageElementEntry(entry: DefinitionPageEntry(:final definition)) =>
      definition.elementDefinition,
    _ => throw StateError(
      "The authoring search story needs an entry definition",
    ),
  };
  final fixtures = AuthoringSearchStoryFixtures(
    elementType: definition.typeId.uuid,
    pageKind: pageDefinition.kind.toSkir(),
  );

  return FakeApp(
    overrides: [
      pageIdProvider.overrideWith((ref) => null),
      realmEditorCatalogProvider.overrideWith(
        (ref) => Stream.value(
          authoringSearchStoryCatalog(
            pageStoryPageCatalog(pageDefinition, storyElements),
          ),
        ),
      ),
      ...appearanceProviderOverrides(),
    ],
    child: SizedBox(
      width: 760,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: 8,
        children: [
          AuthoringSearchResultItem(
            payload: fixtures.mainQuest,
            selected: false,
            focused: true,
            loading: false,
            onTap: () {},
            shortcutActivator: null,
          ),
          AuthoringSearchResultItem(
            payload: fixtures.mainQuestTag,
            selected: false,
            focused: false,
            loading: false,
            onTap: () {},
            shortcutActivator: null,
          ),
          AuthoringSearchResultItem(
            payload: fixtures.meetTheMayor,
            selected: false,
            focused: false,
            loading: false,
            onTap: () {},
            shortcutActivator: null,
          ),
          AuthoringSearchResultItem(
            payload: fixtures.mayorGreeting,
            selected: false,
            focused: false,
            loading: false,
            onTap: () {},
            shortcutActivator: null,
          ),
        ],
      ),
    ),
  );
}

final class _ResultStoryState {
  const _ResultStoryState({
    required this.selected,
    required this.focused,
    required this.loading,
    required this.shortcut,
  });

  final bool selected;
  final bool focused;
  final bool loading;
  final ShortcutActivator? shortcut;
}
