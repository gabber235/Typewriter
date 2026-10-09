import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/support/widgetbook_utils.dart";

@widgetbook.UseCase(name: "Default", type: TagsPage)
Widget tagsPageUseCase(BuildContext context) {
  final tagsState = context.knobs.displayState(
    label: "Tags State",
    initialOption: DisplayState.fewItems,
  );
  final connectionState = context.knobs.realmConnectionState();

  return tagsPageStory(tagsState: tagsState, connectionState: connectionState);
}

Widget tagsPageStory({
  DisplayState tagsState = DisplayState.fewItems,
  RealmConnectionState connectionState = RealmConnectionState.online,
}) {
  return AuthoringFixtureApp(
    scenario: tagsState,
    state: tagsState,
    createDocument: () => fixtureAuthoringDocument(
      tags: tagsState.generateReadyBatch(generateTagBatch) ?? const [],
    ),
    overrides: [
      realmInteractionProvider.overrideWith(
        (ref) => RealmInteractionState(connectionState: connectionState),
      ),

      ...canonicalServicesProviderOverrides(state: DisplayState.manyItems),
      realmIdProvider.overrideWithValue(skir.recordId("service:widgetbook")),
      selectedRealmProvider.overrideWith((ref) async => null),
      ...organizationProviderOverrides(),
      ...organizationsProviderOverrides(state: DisplayState.fewItems),
      ...authProviderOverrides(),
      ...appearanceProviderOverrides(),
    ],
    child: OrganizationScaffold(child: TagsPage()),
  );
}
