import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/src/core/eventually.dart";
import "package:typewriter_testkit/src/core/stage.dart";
import "package:typewriter_testkit/src/core/test_world.dart";
import "package:typewriter_testkit/src/core/trait.dart";
import "package:typewriter_testkit/src/core/world.dart";

/// The [testWorld] of [traits] once its signed in session resolved, see
/// [RealmWorld.whenSignedIn].
Future<World> signedInWorld(List<Trait> traits) async {
  final world = testWorld(traits);
  await world.whenSignedIn();
  return world;
}

/// The panel's authoring state of a world's seeded Realm, for application
/// tests that need no widget tree.
extension RealmWorld on World {
  /// Waits until the panel can connect to NATS and knows who is signed in,
  /// so work scoped to the user is not replaced under the test once the
  /// session resolves.
  Future<void> whenSignedIn() async {
    await initialized();
    await container.read(userIdProvider.future);
  }

  /// Keeps [provider] alive until the world is disposed, the way an open
  /// surface keeps what it shows.
  void keepOpen(ProviderListenable<Object?> provider) {
    final subscription = container.listen(provider, (_, _) {});
    addCleanup(subscription.close);
  }

  /// The panel's editing of the seeded Realm once the session resolved, kept
  /// alive until the world is disposed, as an open surface keeps it.
  Future<RealmEditing> openRealmEditing() async {
    await whenSignedIn();
    final subscription = container.listen(
      realmEditingProvider(requireRealm.scope),
      (_, _) {},
    );
    return subscription.read();
  }

  /// Mounts the panel over this world, so its session and connection
  /// resolve, and opens [resource] in a form of its Realm editing, closed
  /// when the test ends.
  Future<RealmEditingBinding> mountEditing(
    WidgetTester tester,
    skir.ResourceId resource,
  ) async {
    await tester.pumpWidget(
      PanelStage.world(this, at: const PanelLocation.component(SizedBox())),
    );
    final opening = openRealmEditing();
    await tester.pumpAndSettle();
    final binding = (await opening).attach(
      resource,
      policy: EditorCommitPolicy.applyResource,
    );
    addTearDown(binding.detach);
    return binding;
  }

  /// The panel's publication view of the seeded Realm.
  RealmPublicationProvider get realmPublication => realmPublicationProvider(
    requireRealm.scope.organizationId,
    requireRealm.scope.realmId,
  );

  /// Waits until [realmPublication] is a [T], reviewing [review] when given,
  /// and returns it. Someone must keep the view open while the test waits.
  Future<T> publicationView<T extends RealmPublicationView>({
    skir.PublicationStatus? review,
  }) async {
    final value = await container.eventually(
      realmPublication,
      (view) =>
          view.value is T && (review == null || view.value!.review == review),
      description: "a $T publication view",
    );
    return value.requireValue as T;
  }

  /// The local work entry the panel keeps for the work of [domain], such as
  /// "publication".
  WorkEntryState workEntry(String domain) => container
      .read(localWorkProvider)
      .entries
      .values
      .singleWhere((entry) => entry.id.driver.domain == domain);

  /// The panel's search over the seeded Realm, disposed with the test. It
  /// searches once on its own.
  SourceController realmSearch() {
    final scope = requireRealm.scope;
    final controller = SourceController(
      source: RealmAuthoringSearchSource(
        ref: container.read(_refProvider),
        organizationId: scope.organizationId,
        realmId: scope.realmId,
      ),
      baseSelectors: const [],
    );
    addTearDown(controller.dispose);
    return controller;
  }
}

/// The world's own [Ref], for panel code that reads providers through one.
final _refProvider = Provider<Ref>((ref) => ref);
