import "package:typewriter_panel/typewriter_panel.dart";

/// Connects shared capabilities to the features that drive them.
///
/// bootstrap, testApp, FakeApp and bare ProviderContainer tests install the
/// same wiring, so tests run the production graph.
List<Override> appOverrides() => [
  navigationRouterProvider.overrideWith((ref) => ref.watch(appRouterProvider)),
  realmRoutesProvider.overrideWithValue(const RealmRouteTree()),
  interactionSuspendedProvider.overrideWith(
    (ref) => ref.watch(realmInteractionProvider).suspended,
  ),
];
