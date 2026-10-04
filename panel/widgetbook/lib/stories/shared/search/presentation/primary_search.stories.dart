import "package:flutter/material.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/stories/features/organizations/features/realms/features/search/presentation/authoring_search_story_fixtures.dart";

@widgetbook.UseCase(name: "App bar trigger", type: PrimarySearchButton)
Widget primarySearchButtonUseCase(BuildContext context) =>
    primarySearchButtonStory(
      initialQuery: context.knobs.string(label: "Initial query"),
      searchDelay: context.knobs.duration(
        label: "Search delay",
        initialValue: const Duration(milliseconds: 180),
      ),
    );

Widget primarySearchButtonStory({
  String initialQuery = "",
  Duration searchDelay = const Duration(milliseconds: 180),
}) {
  final fixtures = AuthoringSearchStoryFixtures();
  return FakeApp(
    overrides: [
      primarySearchRequestProvider.overrideWith(
        (ref) => PrimarySearchRequest(
          searchHint: "Search authored resources",
          contributionBuilder: (_, _) => SearchContribution(
            session: fixtures.session(
              searchDelay: searchDelay,
              initialQuery: initialQuery,
            ),
            hostEffectExecutors: [
              SearchHostEffectExecutor<OpenAuthoringResourceEffect>(
                (_) async {},
              ),
            ],
          ),
          rowRenderers: {
            authoringResourceSearchResultType.rowRendererId: (context) =>
                AuthoringSearchResultItem(
                  payload:
                      context.result.payload as AuthoringSearchResultPayload,
                  focused: context.focused,
                  selected: context.selected,
                  loading: context.loading,
                  onTap: context.onTap,
                  shortcutActivator: context.shortcutActivator,
                ),
          },
        ),
      ),
      ...appearanceProviderOverrides(),
    ],
    child: const Center(child: PrimarySearchButton()),
  );
}
