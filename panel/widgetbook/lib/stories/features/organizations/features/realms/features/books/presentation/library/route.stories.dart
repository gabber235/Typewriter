import "package:flutter/material.dart";
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
  final tags = tagsState.generateReadyBatch(generateTagBatch);
  final books = displayState.generateReady(
    generateRandomBook(tags ?? const []),
  );
  return FakeApp(
    overrides: [
      ...authoringSessionMockOverrides(
        books: books ?? const [],
        tags: tags ?? const [],
      ),
      realmInteractionProvider.overrideWith(
        (ref) => RealmInteractionState(connectionState: connectionState),
      ),
      ...booksProviderOverrides(state: displayState, books: books),
      ...tagsProviderOverrides(state: tagsState, tags: tags),
      ...canonicalServicesProviderOverrides(state: DisplayState.manyItems),
      realmIdProvider.overrideWithValue(recordId("service:widgetbook")),
      selectedRealmProvider.overrideWith((ref) async => null),
      ...organizationProviderOverrides(),
      ...organizationsProviderOverrides(state: DisplayState.manyItems),
      ...authProviderOverrides(),
      ...appearanceProviderOverrides(),
    ],
    child: OrganizationScaffold(child: LibraryPage()),
  );
}
