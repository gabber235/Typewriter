part of "route.dart";

/// Empty state shown when a book route has no selected page.
///
/// Adding a page prepares and stages a shared working resource, then opens
/// its editor through the same creation path as the sidebar.
class EmptyBookPage extends ConsumerWidget {
  const EmptyBookPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Pane(
      id: "empty_book_page",
      primary: true,
      borderRadius: context.shapes.largeBorderRadius,
      margin: EdgeInsets.only(
        top: context.spacing.space2,
        left: context.spacing.space2,
        right: context.isMobile ? context.spacing.space2 : 0,
      ),
      child: Section(
        margin: EdgeInsets.zero,
        child: EmptyScreen(
          title: "Select a page to edit or",
          buttonText: "Add Page",
          onPressed: () => createPage(context: context, ref: ref),
        ),
      ),
    );
  }
}

/// Shared shell for the book route and its nested page routes.
///
/// This shell owns layout only. Realm suspension and retry handling are applied
/// around both the sidebar and editor content, while page selection and page
/// mutations remain owned by their feature providers and commands.
class BookScaffold extends HookConsumerWidget {
  const BookScaffold({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final organizationId = ref.watch(organizationIdProvider);
    final realmId = ref.watch(realmIdProvider);
    final interaction = ref.watch(realmInteractionProvider);
    final selectedRealm = ref.watch(selectedRealmProvider).value;

    void retryConnection() {
      if (organizationId == null) return;
      ref
          .read(organizationTopologyControllerProvider(organizationId).notifier)
          .refresh();
    }

    return RealmInboxShortcut(
      child: PrimarySearchShortcut(
        child: SimpleScaffold(
          appBar: CustomAppBar(
            navigation: AppBarBreadcrumbs(
              children: [
                if (organizationId != null) ...[
                  const OrganizationSelector(),
                  if (realmId != null) ...[
                    const RealmSelector(),
                    const BookSelector(),
                  ],
                ],
              ],
            ),
            primary: AppBarItem.adaptive(
              key: const ValueKey("search"),
              collapseOrder: 0,
              child: const PrimarySearchButton(),
            ),
            actions: [
              AppBarItem.adaptive(
                key: const ValueKey("activity"),
                collapseOrder: 1,
                child: const WorkspaceActivityButton(),
              ),
              AppBarItem.expandedOnly(
                key: const ValueKey("mode"),
                collapseOrder: 2,
                child: RealmSuspensionInline(
                  suspended: interaction.suspended,
                  child: const ModeDisplayWidget(),
                ),
              ),
              AppBarItem.compactOnly(
                key: const ValueKey("sidebar"),
                collapseOrder: 2,
                child: SidebarMenuButton(
                  sidebar: RealmSuspensionBarrier(
                    interaction: interaction,
                    realm: selectedRealm,
                    onRetry: retryConnection,
                    child: const BookSidebarContent(),
                  ),
                ),
              ),
            ],
          ),
          child: RealmSuspensionBarrier(
            interaction: interaction,
            realm: selectedRealm,
            onRetry: retryConnection,
            child: Row(
              children: [
                if (!context.isMobile)
                  const Sidebar(child: BookSidebarContent()),
                Expanded(
                  child: Column(
                    children: [
                      Expanded(
                        child: InspectorScaffold(
                          margin: EdgeInsets.only(
                            top: context.spacing.space2,
                            right: context.spacing.space2,
                          ),
                          child: child,
                        ),
                      ),
                      ActionRow(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
