import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

/// The realm home: the surface of the root's first section.
@RoutePage()
class RealmHomePage extends ConsumerWidget {
  const RealmHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scope = ref.watch(selectedAuthoringScopeProvider);
    if (scope == null) return const SizedBox.shrink();
    final section = ref.watch(routedResourceProvider(scope));
    if (section == null) {
      return _SurfaceState(
        scope: scope,
        missing: "This realm has no sections yet",
      );
    }
    return ResourceSurface(scope: scope, resource: section);
  }
}

/// The surface of one resource: its workspace beside its navigator, or its
/// inspector when its type declares no workspace.
@RoutePage()
class ResourcePage extends ConsumerWidget {
  const ResourcePage({
    @PathParam("resourceId") required this.resourceId,
    super.key,
  });

  final String resourceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scope = ref.watch(selectedAuthoringScopeProvider);
    if (scope == null) return const SizedBox.shrink();
    return ResourceSurface(
      scope: scope,
      resource: skir.ResourceId(value: resourceId),
    );
  }
}

/// Shows [resource] as the routed resource of [scope]: the rail with the
/// nearest navigator, then a heading from the resource's appearance and owning
/// link fields above its workspace or, without one, its inspector. On narrow
/// layouts the rail opens from a menu button in the heading. The creation
/// shortcut works anywhere in the heading and body.
class ResourceSurface extends ConsumerWidget {
  const ResourceSurface({
    required this.scope,
    required this.resource,
    super.key,
  });

  final AuthoringScope scope;
  final skir.ResourceId resource;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final layout = ref.watch(resourceSurfaceLayoutProvider(scope, resource));
    if (layout == null) {
      return _SurfaceState(
        scope: scope,
        missing: "This resource is no longer available",
      );
    }
    final ResourceSurfaceLayout(:workspace, :rail) = layout;
    final editing = ref.watch(realmEditingProvider(scope));
    final commands = ref.watch(authoredResourceCommandsProvider(scope));
    final creation = ref
        .watch(resourceCreationFieldsProvider(scope, resource))
        .firstOrNull;
    void open(skir.ResourceId target) =>
        ref.read(realmSurfaceNavigationProvider).open(scope, target);
    final compact = context.isMobile;
    final body = AuthoredResourceInspection(
      key: ValueKey((resource, workspace)),
      resource: resource,
      workspace: editing,
      commands: commands,
      role: workspace
          ? skir.PresentationRole.workspace
          : skir.PresentationRole.inspector,
      routedResource: resource,
      openResource: open,
    );
    final main = Pane(
      id: "resource",
      primary: true,
      borderRadius: context.shapes.largeBorderRadius,
      margin: EdgeInsets.only(
        top: context.spacing.space2,
        left: context.spacing.space2,
        right: compact ? context.spacing.space2 : 0,
      ),
      child: Material(
        child: ManagedActionSet(
          shortcuts: [
            if (creation != null)
              ActionShortcut(
                id: "resource.create",
                label: creation.label,
                description: creation.label,
                activators: const [
                  SingleActivator(LogicalKeyboardKey.keyN),
                  SingleActivator(LogicalKeyboardKey.keyA),
                  SingleActivator(LogicalKeyboardKey.numpadAdd),
                ],
                priority: 100,
                icon: const Icon(Icons.add),
                onInvoke: (_) => ref.createSelectedResource(
                  context: context,
                  type: creation.type,
                  owner: creation.owner,
                ),
              ),
          ],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ResourceHeading(
                scope: scope,
                resource: resource,
                leading: rail != null && compact
                    ? ResourceRailMenuButton(
                        scope: scope,
                        rail: rail,
                        routedResource: resource,
                      )
                    : null,
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(context.spacing.space2),
                  child: workspace ? body : SingleChildScrollView(child: body),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (rail == null || compact) return main;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          width: 280,
          child: Pane(
            id: "resource-rail",
            borderRadius: context.shapes.largeBorderRadius,
            margin: EdgeInsets.only(
              top: context.spacing.space2,
              left: context.spacing.space2,
            ),
            child: Material(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(context.spacing.space2),
                child: AuthoredResourceNavigator(
                  key: ValueKey(rail),
                  scope: scope,
                  resource: rail,
                  routedResource: resource,
                  showHeader: true,
                ),
              ),
            ),
          ),
        ),
        Expanded(child: main),
      ],
    );
  }
}

/// Opens the rail navigator of a narrow surface in a sheet. Opening a member
/// closes the sheet.
class ResourceRailMenuButton extends ConsumerWidget {
  const ResourceRailMenuButton({
    required this.scope,
    required this.rail,
    required this.routedResource,
    super.key,
  });

  final AuthoringScope scope;

  /// The resource whose navigator the sheet shows.
  final skir.ResourceId rail;
  final skir.ResourceId routedResource;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final label = ref.watch(resourceAppearanceProvider(scope, rail))?.label;
    return SidebarMenuButton(
      tooltip: label == null ? "Open navigator" : "Open $label",
      icon: const Icon(Icons.menu_open),
      // The sheet paints its own surface, so list tiles need a Material.
      sidebar: Builder(
        builder: (sheet) => Material(
          type: MaterialType.transparency,
          child: SingleChildScrollView(
            child: AuthoredResourceNavigator(
              key: ValueKey(rail),
              scope: scope,
              resource: rail,
              routedResource: routedResource,
              showHeader: true,
              onOpen: () => Navigator.pop(sheet),
            ),
          ),
        ),
      ),
    );
  }
}

/// Explains why no surface shows: the document is loading, failed, or lacks
/// the resource.
class _SurfaceState extends ConsumerWidget {
  const _SurfaceState({required this.scope, required this.missing});

  final AuthoringScope scope;
  final String missing;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Center(
    child: switch (ref.watch(workingAuthoringDocumentProvider(scope))) {
      AsyncValue(:final error?) => Text("Authoring is unavailable: $error"),
      AsyncValue(hasValue: false) => const CircularProgressIndicator(),
      _ => Text(missing),
    },
  );
}

/// The routed resource's name, icon and accent from its appearance, with one
/// creation button per owning link field whose members a person may create.
/// [leading] precedes the icon, such as the rail menu of a narrow surface.
class ResourceHeading extends ConsumerWidget {
  const ResourceHeading({
    required this.scope,
    required this.resource,
    this.leading,
    super.key,
  });

  final AuthoringScope scope;
  final skir.ResourceId resource;
  final Widget? leading;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appearance = ref.watch(resourceAppearanceProvider(scope, resource));
    final document = workingAuthoringDocumentProvider(scope);
    final configuration = ref.watch(
      document.select(
        (value) => value.value?.resource(resource)?.configuration,
      ),
    );
    final catalog = ref.watch(document.select((value) => value.value?.catalog));
    final creations = ref.watch(
      resourceCreationFieldsProvider(scope, resource),
    );
    if (appearance == null || configuration == null || catalog == null) {
      return const SizedBox.shrink();
    }
    final description =
        catalog.selectionDisplay(configuration)?.description ?? "";
    // Dropping resources onto the heading drops them onto the resource.
    return ResourceDropTarget.at(
      scope: scope,
      destination: DropDestination.resource(resource),
      builder: (context, hover) => ResourceDropHighlight(
        hover: hover,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            context.spacing.space4,
            context.spacing.space4,
            context.spacing.space4,
            context.spacing.space2,
          ),
          child: Row(
            spacing: context.spacing.space3,
            children: [
              ?leading,
              ResourceIcon(
                icon: appearance.icon,
                color: appearance.accent,
                size: 32,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Semantics(
                      header: true,
                      child: Text(
                        appearance.label,
                        overflow: TextOverflow.ellipsis,
                        style: context.theme.textTheme.headlineSmall,
                      ),
                    ),
                    if (description.isNotEmpty)
                      Text(
                        description,
                        overflow: TextOverflow.ellipsis,
                        style: context.theme.textTheme.bodySmall?.copyWith(
                          color: context.colors.contentDisabled,
                        ),
                      ),
                  ],
                ),
              ),
              for (final creation in creations)
                FilledButton.tonalIcon(
                  onPressed: () => ref.createSelectedResource(
                    context: context,
                    type: creation.type,
                    owner: creation.owner,
                  ),
                  icon: const Icon(Icons.add),
                  label: Text(creation.label),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
