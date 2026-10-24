import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

part "realm_surface_navigation.freezed.dart";
part "realm_surface_navigation.g.dart";

/// The resource the resource route opens, from its route parameter.
@riverpod
skir.ResourceId? routedResourceId(Ref ref) {
  final id = ref.watch(routeParamProvider("resourceId"));
  return id == null ? null : skir.ResourceId(value: id);
}

/// The resource the realm route of [scope] shows: the routed resource, or the
/// first section on the realm home. Null outside the realm route.
@riverpod
skir.ResourceId? routedResource(Ref ref, AuthoringScope scope) {
  if (ref.watch(realmIdProvider) != scope.realmId) return null;
  final routed = ref.watch(routedResourceIdProvider);
  if (routed != null) return routed;
  return ref.watch(
    workingAuthoringDocumentProvider(scope)
        .select((document) => document.value?.homeSection),
  );
}

/// Whether the realm shell shows the side inspector beside [scope]'s routed
/// resource. A resource without a workspace shows its inspector in the main
/// area instead.
@riverpod
bool showsSideInspector(Ref ref, AuthoringScope scope) {
  final routed = ref.watch(routedResourceProvider(scope));
  if (routed == null) return true;
  return ref.watch(
    workingAuthoringDocumentProvider(scope).select(
      (document) => switch (document.value) {
        final value? => switch (value.resource(routed)) {
          final record? => value.catalog.declaresPresentation(
            record.configuration,
            skir.PresentationRole.workspace,
          ),
          null => true,
        },
        null => true,
      },
    ),
  );
}

/// The section of the realm root that holds [scope]'s routed resource, which
/// the shell sidebar marks as routed.
@riverpod
skir.ResourceId? routedSection(Ref ref, AuthoringScope scope) {
  final routed = ref.watch(routedResourceProvider(scope));
  if (routed == null) return null;
  return ref.watch(
    workingAuthoringDocumentProvider(scope)
        .select((document) => document.value?.surfaceTrail(routed).firstOrNull),
  );
}

/// How the surface of a routed resource is laid out: the navigator in its
/// rail, if any, and whether its type declares a workspace (otherwise the
/// surface shows its inspector).
@freezed
abstract class ResourceSurfaceLayout with _$ResourceSurfaceLayout {
  const factory ResourceSurfaceLayout({
    required bool workspace,
    skir.ResourceId? rail,
  }) = _ResourceSurfaceLayout;
}

/// The layout of [resource]'s surface in [scope], or null while the resource
/// is unavailable. Selects only the layout, so edits that keep it do not
/// rebuild the surface.
@riverpod
ResourceSurfaceLayout? resourceSurfaceLayout(
  Ref ref,
  AuthoringScope scope,
  skir.ResourceId resource,
) => ref.watch(
  workingAuthoringDocumentProvider(scope).select(
    (document) => switch (document.value) {
      final value? => switch (value.resource(resource)) {
        final record? => ResourceSurfaceLayout(
          workspace: value.catalog.declaresPresentation(
            record.configuration,
            skir.PresentationRole.workspace,
          ),
          rail: value.railNavigator(resource),
        ),
        null => null,
      },
      null => null,
    },
  ),
);

/// One owning link field of a resource whose members a person may create,
/// such as the pages of a Book.
@freezed
abstract class ResourceCreationField with _$ResourceCreationField {
  const factory ResourceCreationField({
    /// The owning link field a created member joins.
    required skir.ValueLocation owner,
    required skir.TypeDefinitionId type,

    /// The action label, such as "New Page".
    required String label,
  }) = _ResourceCreationField;
}

/// The owning link fields of [resource] whose members a person may create, in
/// field order. Depends only on the resource's type and the catalog.
@riverpod
List<ResourceCreationField> resourceCreationFields(
  Ref ref,
  AuthoringScope scope,
  skir.ResourceId resource,
) {
  final document = workingAuthoringDocumentProvider(scope);
  final configuration = ref.watch(
    document.select((value) => value.value?.resource(resource)?.configuration),
  );
  final catalog = ref.watch(document.select((value) => value.value?.catalog));
  if (configuration == null || catalog == null) return const [];
  return [
    for (final field in catalog.owningFields(configuration))
      if (catalog.resourceCreationTemplate(field.memberType) != null)
        ResourceCreationField(
          owner: skir.ValueLocation(resource: resource, path: field.path),
          type: field.memberType,
          label: "New ${catalog.typeDefinitionName(field.memberType)}",
        ),
  ];
}

/// A resource a breadcrumb can show, with its appearance.
@freezed
abstract class ResourceCrumbChoice with _$ResourceCrumbChoice {
  const factory ResourceCrumbChoice({
    required skir.ResourceId resource,
    required skir.ResourceAppearance appearance,
  }) = _ResourceCrumbChoice;
}

/// One breadcrumb: [resource] and the resources sharing its owner, including
/// [resource] itself, in ownership order.
@freezed
abstract class ResourceCrumb with _$ResourceCrumb {
  const factory ResourceCrumb({
    required skir.ResourceId resource,
    required List<skir.ResourceId> siblings,
  }) = _ResourceCrumb;
}

extension ResourceBreadcrumbTrail on AuthoringDocument {
  /// The breadcrumbs of [routed]: its owners below the root, then itself,
  /// each with its siblings.
  List<ResourceCrumb> breadcrumbs(skir.ResourceId routed) {
    final ownership = relations;
    return [
      for (final id in surfaceTrail(routed))
        ResourceCrumb(
          resource: id,
          siblings: [
            for (final sibling in switch (ownership.parents[id]?.singleOrNull) {
              final owner? => ownership.ownedBy(owner),
              null => [id],
            })
              if (entry(sibling) != null) sibling,
          ],
        ),
    ];
  }
}

/// The breadcrumbs of [scope]'s routed resource. Selects only the owner
/// chain, so edits that keep it do not rebuild the crumbs.
@riverpod
List<ResourceCrumb> resourceBreadcrumbs(Ref ref, AuthoringScope scope) {
  final routed = ref.watch(routedResourceProvider(scope));
  if (routed == null) return const [];
  return ref.watch(
    workingAuthoringDocumentProvider(scope).select(
      (document) => switch (document.value) {
        final value? when value.entry(routed) != null => value.breadcrumbs(
          routed,
        ),
        _ => const <ResourceCrumb>[],
      },
    ),
  );
}

/// The resources [crumb] can switch to, ordered by label. Each choice reads
/// its own appearance, so an edit recomputes only the choices it renames.
@riverpod
List<ResourceCrumbChoice> resourceCrumbChoices(
  Ref ref,
  AuthoringScope scope,
  ResourceCrumb crumb,
) =>
    [
      for (final sibling in crumb.siblings)
        if (ref.watch(resourceAppearanceProvider(scope, sibling))
            case final appearance?)
          ResourceCrumbChoice(resource: sibling, appearance: appearance),
    ]..sort(
      (left, right) => left.appearance.label.toLowerCase().compareTo(
        right.appearance.label.toLowerCase(),
      ),
    );

/// Moves the panel to the surface of a resource through [SurfaceNavigator].
///
/// Every operation navigates first and selects afterwards, so selection
/// changes never race a route still showing another surface. Each step rechecks
/// [isCurrent], letting a newer navigation supersede this one.
class RealmSurfaceNavigation {
  const RealmSurfaceNavigation(this.ref);

  final Ref ref;

  PageRouteInfo<Object?> _surface(AuthoringScope scope, SurfaceTarget target) =>
      ref.read(realmRoutesProvider).surface(scope, target);

  /// Opens the nearest surface of [resource] and selects the resource inside
  /// it, or the routed resource itself. Returns false when the resource is
  /// unknown or the navigation was superseded.
  Future<bool> open(
    AuthoringScope scope,
    skir.ResourceId resource, {
    bool Function()? isCurrent,
  }) async {
    bool current() => ref.mounted && (isCurrent?.call() ?? true);
    final document = ref.read(workingAuthoringDocumentProvider(scope)).value;
    if (document == null || document.entry(resource) == null || !current()) {
      return false;
    }
    final target = document.open(resource);
    await ref
        .read(navigationRouterProvider)
        .navigate(_surface(scope, target), isCurrent: isCurrent);
    if (!current()) return false;
    final selected = switch (target) {
      HomeTarget(:final selected) => selected,
      ResourceTarget(:final routed, :final selected) => selected ?? routed,
    };
    ref.read(selectionProvider.notifier).selectAll([
      if (selected != null)
        AuthoringResourceIdentifier.inScope(scope, selected),
    ]);
    return true;
  }

  /// Opens the surface of [location]'s resource, then reveals its control in
  /// [presentation].
  Future<bool> reveal(
    AuthoringScope scope,
    skir.ValueLocation location, {
    bool Function()? isCurrent,
    skir.PresentationRole? presentation,
  }) async {
    if (!await open(scope, location.resource, isCurrent: isCurrent)) {
      return false;
    }
    if (!ref.mounted || !(isCurrent?.call() ?? true)) return false;
    ref
        .read(realmLocationRevealProvider(scope))
        .request(location, presentation: presentation, isCurrent: isCurrent);
    return true;
  }

  /// Returns to the nearest surviving owner when the routed resource
  /// disappears between [before] and [after].
  Future<void> recoverRemovedRoute(
    AuthoringScope scope,
    AuthoringDocument before,
    AuthoringDocument after, {
    required bool Function() isCurrent,
  }) async {
    final routed = ref.read(routedResourceIdProvider);
    if (routed == null || after.entry(routed) != null || !isCurrent()) return;
    for (final owner in before.relations.ownerPath(routed).owners) {
      if (after.entry(owner) == null) continue;
      if (await open(scope, owner, isCurrent: isCurrent)) return;
      if (!isCurrent()) return;
    }
    await ref
        .read(navigationRouterProvider)
        .navigate(
          _surface(scope, const SurfaceTarget.home()),
          isCurrent: isCurrent,
        );
  }

  /// Performs a navigation action of a presentation or resource operation.
  Future<void> navigate(
    AuthoringScope scope,
    skir.ResourceId resource,
    skir.ResourceNavigationMode mode, {
    required bool Function() isCurrent,
  }) async {
    final id = AuthoringResourceIdentifier.inScope(scope, resource);
    if (mode == skir.ResourceNavigationMode.open) {
      await open(scope, resource, isCurrent: isCurrent);
    } else if (mode == skir.ResourceNavigationMode.edit) {
      if (!isCurrent() ||
          ref
                  .read(workingAuthoringDocumentProvider(scope))
                  .value
                  ?.entry(resource) ==
              null) {
        return;
      }
      // A surface without a side inspector shows only the routed resource's
      // inspector, so another resource is inspected on its own surface.
      if (ref.read(routedResourceProvider(scope)) != resource &&
          !ref.read(showsSideInspectorProvider(scope))) {
        await ref
            .read(navigationRouterProvider)
            .navigate(
              _surface(scope, SurfaceTarget.resource(routed: resource)),
              isCurrent: isCurrent,
            );
        if (!isCurrent()) return;
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
      await reveal(
        scope,
        skir.ValueLocation(resource: resource, path: editorRootPath),
        isCurrent: isCurrent,
      );
    } else {
      throw StateError("The navigation mode is unavailable");
    }
  }
}

/// Kept alive: navigation outlives the widget or provider that started it.
@Riverpod(keepAlive: true)
RealmSurfaceNavigation realmSurfaceNavigation(Ref ref) =>
    RealmSurfaceNavigation(ref);

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
      _router = ref.read(navigationRouterProvider),
      _navigation = ref.read(navigationRouterProvider).navigationRevision,
      _selection = ref.read(selectionProvider),
      _scope = ref.read(selectedAuthoringScopeProvider);

  final Ref _ref;
  final NavigationRouter _router;
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

  /// Opens the created resource's surface and reveals its inspector.
  Future<void> reveal(AuthoringResourceIdentifier resource) async {
    if (!isCurrent) return;
    _revealing = true;
    final opened = await _ref
        .read(realmSurfaceNavigationProvider)
        .open(resource.scope, resource.resourceId, isCurrent: () => isCurrent);
    if (!opened || !_ref.mounted) return;
    // Opening selected the created resource; later reveals follow that state.
    _selection = _ref.read(selectionProvider);
    _ref
        .read(realmLocationRevealProvider(resource.scope))
        .request(
          skir.ValueLocation(
            resource: resource.resourceId,
            path: editorRootPath,
          ),
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
