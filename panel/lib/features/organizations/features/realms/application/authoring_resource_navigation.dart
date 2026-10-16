import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

part "authoring_resource_navigation.g.dart";

abstract interface class AuthoringResourceNavigationAdapter {
  Future<void> open(
    Ref ref,
    AuthoringResourceIdentifier resource, {
    bool Function()? isCurrent,
  });

  /// Navigates to the surface that can edit the resource.
  Future<void> reveal(
    Ref ref,
    AuthoringResourceIdentifier resource, {
    bool Function()? isCurrent,
  });
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

  Future<bool> open(
    Ref ref,
    AuthoringResourceIdentifier resource, {
    bool Function()? isCurrent,
  }) async {
    final adapter = _resolve(ref, resource);
    if (adapter == null || !(isCurrent?.call() ?? true)) return false;
    await adapter.open(ref, resource, isCurrent: isCurrent);
    return true;
  }

  /// Navigates, selects the resource, then reveals its registered control.
  Future<bool> reveal(
    Ref ref,
    AuthoringScope scope,
    skir.ValueLocation location, {
    bool Function()? isCurrent,
    skir.PresentationRole? presentation,
  }) async {
    final resource = AuthoringResourceIdentifier.inScope(
      scope,
      location.resource,
    );
    final adapter = _resolve(ref, resource);
    if (adapter == null || !(isCurrent?.call() ?? true)) return false;
    await adapter.reveal(ref, resource, isCurrent: isCurrent);
    if (!ref.mounted || !(isCurrent?.call() ?? true)) return false;
    ref.read(selectionProvider.notifier).selectAll([resource]);
    ref
        .read(realmLocationRevealProvider(scope))
        .request(location, presentation: presentation, isCurrent: isCurrent);
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

/// Owns one standalone creation action through preparation and reveal.
/// Prompt dismissal is pageless and does not supersede its route intent.
final class ResourceCreationNavigationIntent {
  ResourceCreationNavigationIntent(Ref ref)
    : _ref = ref,
      _router = ref.read(appRouterProvider),
      _navigation = ref.read(appRouterProvider).navigationRevision,
      _selection = ref.read(selectionProvider),
      _scope = ref.read(selectedAuthoringScopeProvider);

  final Ref _ref;
  final AppRouter _router;
  final int _navigation;
  final AuthoringScope? _scope;
  List<SelectableIdentifier> _selection;
  bool _revealing = false;

  bool get isCurrent =>
      _ref.mounted &&
      _ref.read(selectedAuthoringScopeProvider) == _scope &&
      identical(_ref.read(selectionProvider), _selection) &&
      (_router.navigationRevision == _navigation ||
          _revealing && _router.navigationRevision == _navigation + 1);

  Future<void> reveal(AuthoringResourceIdentifier resource) async {
    if (!isCurrent) return;
    _revealing = true;
    final registry = _ref.read(authoringResourceNavigationRegistryProvider);
    final location = skir.ValueLocation(
      resource: resource.resourceId,
      path: skir.ValuePath(segments: const []),
    );
    final revealed = await registry.reveal(
      _ref,
      resource.scope,
      location,
      isCurrent: () => isCurrent,
      presentation: skir.PresentationRole.inspector,
    );
    if (!revealed) {
      if (!isCurrent) return;
      await _router.navigate(
        realmNavigationRoute(resource.organizationId, resource.realmId),
        isCurrent: () => isCurrent,
      );
      if (!isCurrent) return;
      _ref.read(selectionProvider.notifier).selectAll([resource]);
    }
    if (!_ref.mounted) return;
    _selection = _ref.read(selectionProvider);
    _ref
        .read(realmLocationRevealProvider(resource.scope))
        .request(
          location,
          presentation: skir.PresentationRole.inspector,
          isCurrent: () => isCurrent,
        );
  }
}

extension ResourceCreationAction on ResourceCreationSession {
  ResourceCreationNavigationIntent beginNavigation() =>
      ResourceCreationNavigationIntent(ref);

  Future<AuthoringResourceIdentifier?> createAndReveal({
    required BuildContext context,
    required ResourceCreationRequest request,
    CreationContext? creationContext,
  }) async {
    final intent = beginNavigation();
    final resource = await create(
      context: context,
      request: request,
      creationContext: creationContext,
    );
    if (resource != null) await intent.reveal(resource);
    return resource;
  }
}

/// Bridges widget invocation lifetimes to the provider owned routing adapters.
final class ResourceOperationNavigation {
  const ResourceOperationNavigation(this.ref);
  final Ref ref;

  /// Returns to the nearest surviving owner when the displayed route disappears.
  Future<void> recoverRemovedRoute(
    AuthoringScope scope,
    AuthoringDocument before,
    AuthoringDocument after, {
    required bool Function() isCurrent,
  }) async {
    final routed = ref.read(pageIdProvider) ?? ref.read(bookIdProvider);
    if (routed == null || after.entry(routed) != null || !isCurrent()) return;
    final registry = ref.read(authoringResourceNavigationRegistryProvider);
    for (final owner in before.relations.ownerPath(routed).owners) {
      if (after.entry(owner) == null) continue;
      if (await registry.open(
        ref,
        AuthoringResourceIdentifier.inScope(scope, owner),
        isCurrent: isCurrent,
      )) {
        return;
      }
      if (!isCurrent()) return;
    }
    await ref
        .read(appRouterProvider)
        .navigate(
          realmNavigationRoute(scope.organizationId, scope.realmId),
          isCurrent: isCurrent,
        );
  }

  Future<void> navigate(
    AuthoringScope scope,
    skir.ResourceId resource,
    skir.ResourceNavigationMode mode, {
    required bool Function() isCurrent,
  }) async {
    final registry = ref.read(authoringResourceNavigationRegistryProvider);
    final id = AuthoringResourceIdentifier.inScope(scope, resource);
    if (mode == skir.ResourceNavigationMode.open) {
      await registry.open(ref, id, isCurrent: isCurrent);
    } else if (mode == skir.ResourceNavigationMode.edit) {
      if (!isCurrent() ||
          ref
                  .read(workingAuthoringDocumentProvider(scope))
                  .value
                  ?.entry(resource) ==
              null) {
        return;
      }
      ref.read(selectionProvider.notifier).selectAll([id]);
      ref
          .read(realmLocationRevealProvider(scope))
          .request(
            skir.ValueLocation(resource: resource, path: editorRootPath),
            presentation: skir.PresentationRole.inspector,
            isCurrent: isCurrent,
          );
    } else if (mode == skir.ResourceNavigationMode.reveal) {
      await registry.reveal(
        ref,
        scope,
        skir.ValueLocation(resource: resource, path: editorRootPath),
        isCurrent: isCurrent,
      );
    } else {
      throw StateError("The navigation mode is unavailable");
    }
  }
}

@riverpod
ResourceOperationNavigation resourceOperationNavigation(Ref ref) =>
    ResourceOperationNavigation(ref);
