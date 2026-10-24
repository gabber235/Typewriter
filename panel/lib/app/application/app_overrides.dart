import "package:typewriter_panel/typewriter_panel.dart";

/// Connects shared capabilities to the features that drive them.
///
/// bootstrap, testApp, FakeApp and bare ProviderContainer tests install the
/// same wiring, so tests run the production graph. [replacing] names providers
/// a test overrides itself; Riverpod asserts on duplicate overrides, so those
/// are left out here instead of being overridden twice.
List<Override> appOverrides({
  Set<ProviderBase<Object?>> replacing = const {},
}) => [
  if (!replacing.contains(navigationRouterProvider))
    navigationRouterProvider.overrideWith(
      (ref) => ref.watch(appRouterProvider),
    ),
  if (!replacing.contains(interactionSuspendedProvider))
    interactionSuspendedProvider.overrideWith(
      (ref) => ref.watch(realmInteractionProvider).suspended,
    ),
];
