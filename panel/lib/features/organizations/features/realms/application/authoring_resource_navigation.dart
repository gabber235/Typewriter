import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

part "authoring_resource_navigation.g.dart";

abstract interface class AuthoringResourceNavigationAdapter {
  Future<void> open(Ref ref, AuthoringResourceIdentifier resource);

  /// Navigates to the surface that can edit the resource.
  Future<void> reveal(Ref ref, AuthoringResourceIdentifier resource);
}

final class AuthoringResourceNavigationRegistry {
  AuthoringResourceNavigationRegistry(
    Map<skir.AuthoringNavigationHandler, AuthoringResourceNavigationAdapter>
    adapters,
  ) : _adapters = Map.unmodifiable(adapters);

  final Map<skir.AuthoringNavigationHandler, AuthoringResourceNavigationAdapter>
  _adapters;

  bool canOpen(Ref ref, AuthoringResourceIdentifier resource) =>
      _resolve(ref, resource) != null;

  AuthoringResourceNavigationAdapter? _resolve(
    Ref ref,
    AuthoringResourceIdentifier resource,
  ) {
    final document = ref
        .read(workingAuthoringDocumentProvider(resource.scope))
        .value;
    final entry = document?.entry(resource.resourceId);
    if (document == null || entry == null) return null;
    final handler = document.catalog.snapshot.resourceDefinitions
        .where((definition) => definition.id == entry.definition)
        .map((definition) => definition.navigationHandler)
        .firstOrNull;
    return handler == null ? null : _adapters[handler];
  }

  Future<bool> open(Ref ref, AuthoringResourceIdentifier resource) async {
    final adapter = _resolve(ref, resource);
    if (adapter == null) return false;
    await adapter.open(ref, resource);
    return true;
  }

  /// Navigates, selects the resource, then reveals its registered control.
  Future<bool> reveal(
    Ref ref,
    AuthoringScope scope,
    skir.ValueLocation location,
  ) async {
    final resource = AuthoringResourceIdentifier.inScope(
      scope,
      location.resource,
    );
    final adapter = _resolve(ref, resource);
    if (adapter == null) return false;
    await adapter.reveal(ref, resource);
    if (!ref.mounted) return false;
    ref.read(selectionProvider.notifier).selectAll([resource]);
    ref.read(realmLocationRevealProvider(scope)).request(location);
    return true;
  }
}

@Riverpod(keepAlive: true)
AuthoringResourceNavigationRegistry authoringResourceNavigationRegistry(
  Ref ref,
) => AuthoringResourceNavigationRegistry(const {
  skir.AuthoringNavigationHandler.book: BookAuthoringNavigationAdapter(),
  skir.AuthoringNavigationHandler.page: PageAuthoringNavigationAdapter(),
  skir.AuthoringNavigationHandler.pageElement:
      PageElementAuthoringNavigationAdapter(),
  skir.AuthoringNavigationHandler.tags: TagAuthoringNavigationAdapter(),
});

@riverpod
PortableLocationRevealController realmLocationReveal(
  Ref ref,
  AuthoringScope scope,
) {
  final controller = PortableLocationRevealController();
  ref.onDispose(controller.dispose);
  return controller;
}
