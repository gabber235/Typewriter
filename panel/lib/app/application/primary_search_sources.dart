import "package:flutter/widgets.dart";
import "package:flutter_animate/flutter_animate.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

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
      organizationSearchResultType.id: (context) =>
          OrganizationSearchResultItem.organization(
            organization: context.result.payload as OrganizationData,
            focused: context.focused,
            selected: context.selected,
            loading: context.loading,
            onTap: context.onTap,
            shortcutActivator: context.shortcutActivator,
          ),
      createOrganizationSearchResultType.id: (context) =>
          CreateOrganizationSearchResultItem(
            focused: context.focused,
            selected: context.selected,
            loading: context.loading,
            onTap: context.onTap,
            shortcutActivator: context.shortcutActivator,
          ),
      realmSearchResultType.id: (context) => RealmSearchResultItem.realm(
        realm: context.result.payload as TopologyRealm,
        focused: context.focused,
        selected: context.selected,
        loading: context.loading,
        onTap: context.onTap,
        shortcutActivator: context.shortcutActivator,
      ),
      authoringResourceSearchResultType.id: (context) =>
          AuthoringSearchResultItem(
            payload: context.result.payload as AuthoringSearchResultPayload,
            focused: context.focused,
            selected: context.selected,
            loading: context.loading,
            onTap: context.onTap,
            shortcutActivator: context.shortcutActivator,
          ),
      authoringCreationSearchResultType.id:
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
      final catalog = ref.valued(realmEditorCatalogProvider);
      sources.addAll([
        AuthoringCreationSearchSource(catalog),
        RealmAuthoringSearchSource(
          ref: ref,
          organizationId: organizationId,
          realmId: realmId,
        ).debounced(100.ms).cached(),
      ]);
      commands.addAll([
        ...openAuthoringCommands(organizationId, realmId),
        createAuthoringResourceCommand(ref: ref),
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
        .read(appRouterProvider)
        .navigate(OrganizationRoute(organizationId: effect.organizationId.id));
  }),
  SearchHostEffectExecutor<CreateOrganizationEffect>((effect) async {
    await ref.read(appRouterProvider).navigate(IndexRoute());
  }),
  SearchHostEffectExecutor<OpenRealmEffect>((effect) async {
    await ref
        .read(appRouterProvider)
        .navigate(realmNavigationRoute(effect.organizationId, effect.realmId));
  }),
  SearchHostEffectExecutor<OpenAuthoringResourceEffect>((effect) async {
    final navigationHandler = ref
        .read(realmEditorCatalogProvider)
        .value
        ?.snapshot
        ?.resourceDefinitions[effect.definition]
        ?.navigationHandler;
    final registry = AuthoringResourceNavigationRegistry(const [
      BookAuthoringNavigationAdapter(),
      TagAuthoringNavigationAdapter(),
    ]);
    if (await registry.open(ref, navigationHandler, effect)) return;
    await ref
        .read(appRouterProvider)
        .navigate(realmNavigationRoute(effect.organizationId, effect.realmId));
    ref
        .read(selectionProvider.notifier)
        .select(
          AuthoringResourceIdentifier(
            organizationId: effect.organizationId,
            realmId: effect.realmId,
            resourceId: effect.resourceId,
          ),
        );
  }),
];
