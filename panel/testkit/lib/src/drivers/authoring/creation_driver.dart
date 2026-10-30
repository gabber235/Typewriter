import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/src/drivers/panel_driver.dart";

/// Starting resource creation in the open Realm.
extension CreationDrivers on PanelDriver {
  /// Starts creating [request] in the seeded Realm, the way a creation
  /// action of the panel does, and lets the panel show what it asks first.
  ///
  /// [context] names what the creation starts from, such as the owner field
  /// it was started in. [scope] starts it for another Realm than the seeded
  /// one, such as an action left over from a Realm the user switched away
  /// from.
  Future<CreationRun> create(
    ResourceCreationRequest request, {
    CreationContext context = const CreationContext(),
    AuthoringScope? scope,
  }) async {
    final run = CreationRun._();
    final navigator = container
        .read(appRouterProvider)
        .navigatorKey
        .currentContext!;
    unawaited(
      container
          .read(resourceCreationProvider(scope ?? world.requireRealm.scope))
          .create(
            context: navigator,
            request: request,
            creationContext: context,
          )
          .then(
            (created) => run._finish(created: created),
            onError: (Object error) => run._finish(error: error),
          ),
    );
    await settle();
    return run;
  }

  /// The panel's search for what can be created in the selected working
  /// document, with its first query answered; it and the document it reads
  /// stay open until the test ends.
  Future<SourceController> creationSearch() async {
    final subscription = container.listen(
      selectedWorkingAuthoringDocumentProvider,
      (_, _) {},
    );
    addTearDown(subscription.close);
    final controller = SourceController(
      source: AuthoringCreationSearchSource(container.read(_refProvider)),
      baseSelectors: const [],
    )..triggerQuery();
    addTearDown(controller.dispose);
    await settle();
    return controller;
  }

  /// The document the panel shows for the seeded Realm, with local work.
  AuthoringDocument get workingDocument => container
      .read(workingAuthoringDocumentProvider(world.requireRealm.scope))
      .requireValue;
}

/// Reading what a creation search offers.
extension CreationSearchResults on SourceController {
  /// The one creation option the search offers for [type].
  AuthoringCreationOption creationOption(skir.TypeDefinitionId type) =>
      (snapshot.nodes.single as SearchSectionNode).children
          .whereType<SearchResultNode>()
          .map((node) => node.result.payload as AuthoringCreationOption)
          .singleWhere((option) => option.type == type);
}

/// The container's own [Ref], for panel code that reads providers through
/// one.
final _refProvider = Provider<Ref>((ref) => ref);

/// One creation the test started, and how it ended.
final class CreationRun {
  CreationRun._();

  /// Whether the creation finished, created or cancelled.
  bool done = false;

  /// The resource the creation created; null while running or once
  /// cancelled.
  AuthoringResourceIdentifier? created;

  /// The error the creation failed with, if any.
  Object? error;

  void _finish({AuthoringResourceIdentifier? created, Object? error}) {
    done = true;
    this.created = created;
    this.error = error;
  }
}
