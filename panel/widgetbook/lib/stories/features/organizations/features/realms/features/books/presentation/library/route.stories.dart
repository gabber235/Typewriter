import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/support/widgetbook_utils.dart";

@widgetbook.UseCase(name: "Default", type: LibraryPage)
Widget libraryPageUseCase(BuildContext context) {
  final displayState = context.knobs.displayState();
  final connectionState = context.knobs.realmConnectionState();

  return libraryPageStory(
    displayState: displayState,
    connectionState: connectionState,
  );
}

Widget libraryPageStory({
  DisplayState displayState = DisplayState.fewItems,
  DisplayState tagsState = DisplayState.manyItems,
  RealmConnectionState connectionState = RealmConnectionState.online,
}) {
  return AuthoringFixtureApp(
    scenario: (displayState, tagsState),
    state: displayState,
    createDocument: () {
      final tags =
          tagsState.generateReadyBatch(generateTagBatch) ?? const <Tag>[];
      final books =
          displayState.generateReady(generateRandomBook(tags)) ??
          const <Book>[];
      return fixtureAuthoringDocument(books: books, tags: tags);
    },
    overrides: [
      realmInteractionProvider.overrideWith(
        (ref) => RealmInteractionState(connectionState: connectionState),
      ),

      ...canonicalServicesProviderOverrides(state: DisplayState.manyItems),
      realmIdProvider.overrideWithValue(skir.recordId("service:widgetbook")),
      selectedRealmProvider.overrideWith((ref) async => null),
      ...organizationProviderOverrides(),
      ...organizationsProviderOverrides(state: DisplayState.manyItems),
      ...authProviderOverrides(),
      ...appearanceProviderOverrides(),
    ],
    child: OrganizationScaffold(child: LibraryPage()),
  );
}
