import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

/// Composes the global search contribution from the route scope at opening.
///
/// Organization search is always available. Organization and realm route
/// parameters add realm discovery and authoring operations respectively.
/// Commands produce host effects so this application boundary owns navigation
/// and selection while search sources remain independent of the router.
PrimarySearchRequest buildPrimarySearchRequest(Ref ref) {
  final organizationId = ref.read(organizationIdProvider);
  final realmId = ref.read(realmIdProvider);
  final searchables = [
    if (realmId != null) "resources",
    if (organizationId != null) "realms",
    "organizations",
  ];

  return PrimarySearchRequest(
    searchHint: "Search ${searchables.join(", ")}",
    rowRenderers: {
      organizationSearchResultType.rowRendererId: (context) =>
          OrganizationSearchResultItem.organization(
            organization: context.result.payload as skir.Organization,
            focused: context.focused,
            selected: context.selected,
            loading: context.loading,
            onTap: context.onTap,
            shortcutActivator: context.shortcutActivator,
          ),
      createOrganizationSearchResultType.rowRendererId: (context) =>
          CreateOrganizationSearchResultItem(
            focused: context.focused,
            selected: context.selected,
            loading: context.loading,
            onTap: context.onTap,
            shortcutActivator: context.shortcutActivator,
          ),
      realmSearchResultType.rowRendererId: (context) =>
          RealmSearchResultItem.realm(
            realm: context.result.payload as skir.RealmInstance,
            focused: context.focused,
            selected: context.selected,
            loading: context.loading,
            onTap: context.onTap,
            shortcutActivator: context.shortcutActivator,
          ),
      authoringResourceSearchResultType.rowRendererId:
          buildAuthoringResourceSearchResultItem,
      authoringCreationSearchResultType.rowRendererId:
          buildAuthoringCreationSearchResultItem,
    },
    previewRenderers: const {},
    contributionBuilder: _builder,
  );
}

SearchContribution<void> _builder(Ref ref, BuildContext context) {
  final organizationId = ref.read(organizationIdProvider);
  final realmId = ref.read(realmIdProvider);
  final sources = <SearchSource>[];
  final commands = <SearchCommand>[
    openOrganizationCommand(),
    createOrganizationCommand(),
  ];
  sources.add(OrganizationsSearchSource(ref.valued(organizationsProvider)));

  if (organizationId != null) {
    final realms = ref.valued(realmsProvider);
    sources.add(RealmsSearchSource(realms));
    commands.add(
      openRealmCommand(
        organizationId: organizationId,
        availability: ref.valued(realmsAvailabilityProvider),
      ),
    );

    if (realmId != null) {
      final scope = AuthoringScope(
        organizationId: organizationId,
        realmId: realmId,
      );
      sources.addAll([
        AuthoringCreationSearchSource(ref),
        RealmAuthoringSearchSource(
          ref: ref,
          organizationId: organizationId,
          realmId: realmId,
          hostContext: HostContext(
            activeResource: ref.read(routedResourceProvider(scope)),
          ),
        ).debounced(100.ms).cached(),
      ]);
      commands.addAll([
        ...openAuthoringCommands(organizationId, realmId),
        createAuthoringResourceCommand(ref: ref, scope: scope),
      ]);
    }
  }

  return SearchContribution(
    session: SearchSession(
      source: sources.reversed.merged(),
      scope: const AllSearchScope(),
      interaction: SearchInteraction(
        activation: SearchActivation.command(
          resolve: _primaryCommandId,
          dependencies: const [],
        ),
        selectionMode: SearchSelectionMode.single,
        commands: commands,
      ),
      initialQuery: "",
    ),
    hostEffectExecutors: _buildHostEffectExecutors(ref),
  );
}

SearchCommandId? _primaryCommandId(SearchResult result) =>
    switch (result.type) {
      organizationSearchResultType => openOrganizationCommandId,
      createOrganizationSearchResultType => createOrganizationCommandId,
      realmSearchResultType => openRealmCommandId,
      authoringResourceSearchResultType => openAuthoringResourceCommandId,
      authoringCreationSearchResultType => createAuthoringResourceCommandId,
      _ => null,
    };

List<SearchHostEffectExecutor<SearchHostEffect>> _buildHostEffectExecutors(
  Ref ref,
) => [
  SearchHostEffectExecutor<OpenOrganizationEffect>((effect) async {
    await ref
        .read(navigationRouterProvider)
        .navigate(OrganizationRoute(organizationId: effect.organizationId.id));
  }),
  SearchHostEffectExecutor<CreateOrganizationEffect>((effect) async {
    await ref.read(navigationRouterProvider).navigate(IndexRoute());
  }),
  SearchHostEffectExecutor<OpenRealmEffect>((effect) async {
    await ref
        .read(navigationRouterProvider)
        .navigate(realmNavigationRoute(effect.organizationId, effect.realmId));
  }),
  SearchHostEffectExecutor<RevealCreatedAuthoringResourceEffect>(
    (effect) => effect.intent.reveal(effect.resource),
  ),
  SearchHostEffectExecutor<OpenAuthoringResourceEffect>((effect) async {
    final resource = effect.resource;
    await ref
        .read(realmSurfaceNavigationProvider)
        .open(resource.scope, resource.resourceId);
  }),
];
