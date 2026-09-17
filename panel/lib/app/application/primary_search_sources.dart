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
    if (realmId != null) ...["books", "tags", "pages", "elements"],
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
      authoringBookSearchResultType.id: (context) =>
          AuthoringBookSearchResultItem(
            book: context.result.payload as skir.AuthoringSearchBook,
            focused: context.focused,
            selected: context.selected,
            loading: context.loading,
            onTap: context.onTap,
            shortcutActivator: context.shortcutActivator,
          ),
      authoringTagSearchResultType.id: (context) =>
          AuthoringTagSearchResultItem(
            tag: context.result.payload as skir.AuthoringSearchTag,
            focused: context.focused,
            selected: context.selected,
            loading: context.loading,
            onTap: context.onTap,
            shortcutActivator: context.shortcutActivator,
          ),
      authoringPageSearchResultType.id: (context) =>
          AuthoringPageSearchResultItem(
            page: context.result.payload as skir.AuthoringSearchPage,
            focused: context.focused,
            selected: context.selected,
            loading: context.loading,
            onTap: context.onTap,
            shortcutActivator: context.shortcutActivator,
          ),
      authoringElementSearchResultType.id: (context) =>
          AuthoringElementSearchResultItem(
            element: context.result.payload as skir.AuthoringSearchElement,
            focused: context.focused,
            selected: context.selected,
            loading: context.loading,
            onTap: context.onTap,
            shortcutActivator: context.shortcutActivator,
          ),
      pageKindSearchResultType.id: (context) => PageKindSearchResultItem(
        definition: context.result.payload as RealmPageDefinition,
        focused: context.focused,
        selected: context.selected,
        loading: context.loading,
        onTap: context.onTap,
        shortcutActivator: context.shortcutActivator,
      ),
      elementTypeSearchResultType.id: buildElementTypeSearchResultItem,
    },
    previewRenderers: const {},
    contributionBuilder: _builder,
  );
}

SearchContribution<void> _builder(Ref ref, BuildContext context) {
  final organizationId = ref.read(organizationIdProvider);
  final realmId = ref.read(realmIdProvider);
  final pageId = ref.read(pageIdProvider);
  final sources = <SearchSource>[];
  final commands = <SearchCommand>[
    openOrganizationCommand(),
    createOrganizationCommand(),
  ];
  SearchScope scope = const AllSearchScope();

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
      final books = ref.valued(projectedBooksProvider);
      final pages = ref.valued(projectedPagesProvider);
      final pagePolicies = ref.valued(pageEntryCreationPoliciesProvider);
      final catalog = ref.valued(realmEditorCatalogProvider);
      sources.addAll([
        PageKindSearchSource(
          definitions: ref.valued(realmPageDefinitionsProvider),
        ),
        ElementTypeSearchSource(
          definitions: ref.valued(availableElementDefinitionsFutureProvider),
        ),
        RealmAuthoringSearchSource(
          ref: ref,
          organizationId: organizationId,
          realmId: realmId,
          contextPage: pageId,
        ).debounced(100.ms).cached(),
      ]);
      commands.addAll([
        ...openAuthoringCommands(organizationId, realmId),
        createPageCommand(
          ref: ref,
          organizationId: organizationId,
          realmId: realmId,
          books: books,
        ),
        createElementCommand(
          ref: ref,
          organizationId: organizationId,
          realmId: realmId,
        ),
      ]);
      scope = primarySearchScope(
        books: books,
        pages: pages,
        pagePolicies: pagePolicies,
        catalog: catalog,
      );
    }
  }

  return SearchContribution(
    session: SearchSession(
      source: sources.reversed.merged(),
      scope: scope,
      interaction: SearchInteraction(
        activation: SearchActivation.command(
          resolve: _primaryCommandId,
          dependencies: const [],
        ),
        selectionMode: SearchSelectionMode.single,
        commands: commands,
      ),
      initialQuery: _buildInitialQuery(ref),
    ),
    hostEffectExecutors: _buildHostEffectExecutors(ref),
  );
}

SearchCommandId? _primaryCommandId(SearchResult result) =>
    switch (result.type) {
      organizationSearchResultType => openOrganizationCommandId,
      createOrganizationSearchResultType => createOrganizationCommandId,
      realmSearchResultType => openRealmCommandId,
      authoringBookSearchResultType => openAuthoringBookCommandId,
      authoringTagSearchResultType => openAuthoringTagCommandId,
      authoringPageSearchResultType => openAuthoringPageCommandId,
      authoringElementSearchResultType => openAuthoringElementCommandId,
      pageKindSearchResultType => createPageCommandId,
      elementTypeSearchResultType => createElementCommandId,
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
  SearchHostEffectExecutor<OpenAuthoringBookEffect>((effect) async {
    await _openBook(ref, effect.organizationId, effect.realmId, effect.bookId);
  }),
  SearchHostEffectExecutor<OpenAuthoringTagEffect>((effect) async {
    await _openTags(ref, effect.organizationId, effect.realmId);
    ref.read(selectionProvider.notifier).select(TagIdentifier(effect.tagId));
  }),
  SearchHostEffectExecutor<OpenAuthoringPageEffect>((effect) async {
    await _openBook(
      ref,
      effect.organizationId,
      effect.realmId,
      effect.bookId,
      pageId: effect.pageId,
    );
  }),
  SearchHostEffectExecutor<OpenAuthoringElementEffect>((effect) async {
    await _openBook(
      ref,
      effect.organizationId,
      effect.realmId,
      effect.bookId,
      pageId: effect.pageId,
    );
    final elementIdentifier = effect.elementIdentifier;
    if (elementIdentifier == null) return;
    ref.read(selectionProvider.notifier).select(elementIdentifier);
  }),
];

String _buildInitialQuery(Ref ref) {
  final bookId = ref.read(bookIdProvider);
  final pageId = ref.read(pageIdProvider);

  final book = bookId == null
      ? null
      : ref.read(projectedBookProvider(bookId)).value;

  final page = pageId == null
      ? null
      : ref.read(projectedPageProvider(pageId)).value;

  return [
    if (book != null) "book:${_selectorValue(book.title)}",
    if (page != null) "page:${_selectorValue(page.name)}",
  ].join(" ");
}

String _selectorValue(String value) =>
    value.contains(" ") ? "\"${value.replaceAll("\"", "")}\"" : value;

Future<void> _openTags(
  Ref ref,
  skir.RecordId organizationId,
  skir.RecordId realmId,
) => ref
    .read(appRouterProvider)
    .navigate(
      OrganizationRoute(
        organizationId: organizationId.id,
        children: [
          RealmRoute(realmId: realmId.id, children: [const TagsRoute()]),
        ],
      ),
    );

Future<void> _openBook(
  Ref ref,
  skir.RecordId organizationId,
  skir.RecordId realmId,
  skir.RecordId bookId, {
  skir.RecordId? pageId,
}) => ref
    .read(appRouterProvider)
    .navigate(
      BookRoute(
        organizationId: organizationId.id,
        realmId: realmId.id,
        bookId: bookId.id,
        children: [if (pageId != null) RouteRoute(pageId: pageId.id)],
      ),
    );
