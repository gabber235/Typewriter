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
    final document = ref.watch(workingAuthoringDocumentProvider(scope));
    if (section == null) {
      return _SurfaceState(
        document: document,
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
/// link fields above its workspace or, without one, its inspector.
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
    final source = ref.watch(workingAuthoringDocumentProvider(scope));
    final document = source.value;
    final record = document?.resource(resource);
    if (document == null || record == null) {
      return _SurfaceState(
        document: source,
        missing: "This resource is no longer available",
      );
    }
    final rail = document.railNavigator(resource);
    final workspace = document.catalog.declaresPresentation(
      record.configuration,
      skir.PresentationRole.workspace,
    );
    final editing = ref.watch(realmEditingProvider(scope));
    final commands = ref.watch(authoredResourceCommandsProvider(scope));
    void open(skir.ResourceId target) =>
        ref.read(realmSurfaceNavigationProvider).open(scope, target);
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
        right: context.isMobile ? context.spacing.space2 : 0,
      ),
      child: Material(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ResourceHeading(scope: scope, resource: resource),
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(context.spacing.space2),
                child: workspace ? body : SingleChildScrollView(child: body),
              ),
            ),
          ],
        ),
      ),
    );
    if (rail == null || context.isMobile) return main;
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

class _SurfaceState extends StatelessWidget {
  const _SurfaceState({required this.document, required this.missing});

  final AsyncValue<AuthoringDocument> document;
  final String missing;

  @override
  Widget build(BuildContext context) => Center(
    child: switch (document) {
      AsyncValue(:final error?) => Text("Authoring is unavailable: $error"),
      AsyncValue(hasValue: false) => const CircularProgressIndicator(),
      _ => Text(missing),
    },
  );
}

/// The routed resource's name, icon and accent from its appearance, with one
/// creation button per owning link field whose members a person may create.
/// The first such field is also reachable with the creation shortcut.
class ResourceHeading extends ConsumerWidget {
  const ResourceHeading({
    required this.scope,
    required this.resource,
    super.key,
  });

  final AuthoringScope scope;
  final skir.ResourceId resource;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appearance = ref.watch(resourceAppearanceProvider(scope, resource));
    final document = ref.watch(workingAuthoringDocumentProvider(scope)).value;
    final record = document?.resource(resource);
    if (appearance == null || document == null || record == null) {
      return const SizedBox.shrink();
    }
    final catalog = document.catalog;
    final description =
        catalog.selectionDisplay(record.configuration)?.description ?? "";
    final creations = [
      for (final field in catalog.owningFields(record.configuration))
        if (catalog.resourceCreationTemplate(field.memberType) != null)
          (
            label: "New ${catalog.typeDefinitionName(field.memberType)}",
            create: () => ref.createSelectedResource(
              context: context,
              type: field.memberType,
              owner: skir.ValueLocation(resource: resource, path: field.path),
            ),
          ),
    ];
    return ManagedActionSet(
      shortcuts: [
        if (creations.firstOrNull case final primary?)
          ActionShortcut(
            id: "resource.create",
            label: primary.label,
            description: primary.label,
            activators: const [
              SingleActivator(LogicalKeyboardKey.keyN),
              SingleActivator(LogicalKeyboardKey.keyA),
              SingleActivator(LogicalKeyboardKey.numpadAdd),
            ],
            priority: 100,
            icon: const Icon(Icons.add),
            onInvoke: (_) => primary.create(),
          ),
      ],
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
                onPressed: creation.create,
                icon: const Icon(Icons.add),
                label: Text(creation.label),
              ),
          ],
        ),
      ),
    );
  }
}
