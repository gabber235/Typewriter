part of "route.dart";

class EmptyBookPage extends StatelessWidget {
  const EmptyBookPage({super.key});

  Future<String?> _showAddPageDialog(BuildContext context) async =>
      showAdvancedDialog(
        context: context,
        builder: (context) => const AddPageDialogue(),
      );

  @override
  Widget build(BuildContext context) {
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
          onPressed: () => _showAddPageDialog(context),
        ),
      ),
    );
  }
}

class BookScaffold extends HookConsumerWidget {
  const BookScaffold({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final organizationId = ref.watch(organizationIdProvider);
    final realmId = ref.watch(realmIdProvider);
    final interaction = ref.watch(realmInteractionProvider);
    final selectedRealm = ref.watch(selectedRealmProvider).value;

    void retryConnection() => ref.invalidate(servicesProvider);

    return SimpleScaffold(
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
            ],
          ],
        ],
        trailing: !context.isMobile
            ? RealmSuspensionInline(
                suspended: interaction.suspended,
                child: const ModeDisplayWidget(),
              )
            : null,
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
    );
  }
}
