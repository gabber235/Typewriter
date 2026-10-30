import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/src/core/offline_network.dart";
import "package:typewriter_testkit/src/core/trait.dart";
import "package:typewriter_testkit/src/core/world.dart";

/// Builds the world [traits] describe for an application test that needs no
/// widget tree, starts it and disposes it with the test. Like a pumped
/// panel, it never reaches the network.
///
/// Read the panel's providers through [World.container]. A test that needs a
/// route, such as the organization in scope, pumps the panel instead.
World testWorld(List<Trait> traits) {
  keepOffline();
  final world = World.build(traits);
  addTearDown(world.dispose);
  world.start();
  return world;
}

/// Waiting for what the panel resolves before it shows anything.
extension WorldStartup on World {
  /// Waits until the panel has what a signed in page shows behind: the
  /// sentinel credentials, the identity provider session and, for a signed
  /// in user, the NATS connection.
  Future<void> initialized() async {
    await container.read(sentinelCredentialsProvider.future);
    if (await container.read(authSessionProvider.future) == null) return;
    await container.read(natsProvider.future);
  }
}

/// Watching the panel's state from a test without widgets.
extension WorldWatching on World {
  /// Keeps [provider] watched until the test ends, the way a page showing
  /// it does, and returns the subscription that reads it.
  ProviderSubscription<T> watch<T>(ProviderListenable<T> provider) {
    final subscription = container.listen(provider, (_, _) {});
    addTearDown(subscription.close);
    return subscription;
  }
}
