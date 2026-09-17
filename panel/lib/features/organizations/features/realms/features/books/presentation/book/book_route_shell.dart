part of "route.dart";

/// Empty state shown when a book route has no selected page.
///
/// Adding a page uses the same dialog as the sidebar, so creation and initial
/// navigation follow one command path.
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
          onPressed: () => promptAndCreatePage(context: context, ref: ref),
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

    void retryConnection() =>
        ref.invalidate(organizationTopologyStreamProvider);

    return PrimarySearchShortcut(
      child: SimpleScaffold(
        appBar: CustomAppBar(
          leading: [
            if (organizationId != null) ...[
              const OrganizationSelector(),
              if (realmId != null) ...[
                Icones(
                  MaterialSymbols.chevron_right,
                  size: 16,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const RealmSelector(),
                Icones(
                  MaterialSymbols.chevron_right,
                  size: 16,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const BookSelector(),
              ],
            ],
          ],
          trailing: RealmSuspensionInline(
            suspended: interaction.suspended,
            child: const ModeDisplayWidget(),
          ),
          sidebar: RealmSuspensionBarrier(
            interaction: interaction,
            realm: selectedRealm,
            onRetry: retryConnection,
            child: const BookSidebarContent(),
          ),
        ),
        child: RealmSuspensionBarrier(
          interaction: interaction,
          realm: selectedRealm,
          onRetry: retryConnection,
          child: Row(
            children: [
              if (!context.isMobile) const Sidebar(child: BookSidebarContent()),
              Expanded(
                child: Column(
                  children: [
                    Expanded(
                      child: InspectorScaffold(
                        realmRuntime: ref.watch(
                          activeRealmEditorRuntimeProvider,
                        ),
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
    );
  }
}
