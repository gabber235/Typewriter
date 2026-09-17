import "package:auto_route/auto_route.dart";
import "package:flutter/material.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:iconify_flutter_plus/icons/material_symbols.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

/// Nested workspace route for one organization.
///
/// The route parameter is resolved by [organizationIdProvider]. The page keeps
/// child navigation inside the organization scaffold while the application layer
/// verifies membership through the user's organization projection.
@RoutePage()
class OrganizationPage extends HookConsumerWidget {
  const OrganizationPage({
    @PathParam("organizationId") required this.organizationId,
    super.key,
  });

  final String organizationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return OrganizationScaffold(child: AutoRouter());
  }
}

/// Shared workspace shell for organization and realm child routes.
///
/// It owns navigation chrome and the suspension barrier around realm content. A
/// connection retry invalidates topology state, leaving resource repositories and
/// editor sessions owned by their respective application providers.
class OrganizationScaffold extends HookConsumerWidget {
  const OrganizationScaffold({required this.child, super.key});

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
              ],
            ],
          ],
          trailing: RealmSuspensionInline(
            suspended: interaction.suspended,
            child: const ModeDisplayWidget(),
          ),
          sidebar: OrganizationSidebarContent(suspended: interaction.suspended),
        ),
        child: Row(
          children: [
            if (!context.isMobile)
              Sidebar(
                child: OrganizationSidebarContent(
                  suspended: interaction.suspended,
                ),
              ),
            Expanded(
              child: RealmSuspensionBarrier(
                interaction: interaction,
                realm: selectedRealm,
                onRetry: retryConnection,
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
            ),
          ],
        ),
      ),
    );
  }
}

/// Builds organization and realm navigation from the active route selections.
///
/// Pending request count is a derived projection used only for the sidebar badge;
/// link construction remains pure and keeps route identity explicit.
class OrganizationSidebarContent extends HookConsumerWidget {
  const OrganizationSidebarContent({required this.suspended, super.key});

  final bool suspended;

  static List<Widget> organizationLinks(
    skir.RecordId organizationId,
    int pendingRequests,
  ) {
    return [
      const SidebarHeader(text: "Organization"),
      SidebarLink(
        icon: Icones(MaterialSymbols.dns),
        text: "Services",
        route: OrganizationRoute(
          organizationId: organizationId.id,
          children: [ServicesRoute()],
        ),
      ),
      SidebarLink(
        icon: Icones(MaterialSymbols.groups_rounded),
        text: "Members",
        route: OrganizationRoute(
          organizationId: organizationId.id,
          children: [
            MembersRoute(children: [const MemberListRoute()]),
          ],
        ),
      ),
      SidebarLink(
        icon: Icones(MaterialSymbols.person_add),
        text: "Join Requests",
        trailing: pendingRequests > 0
            ? Semantics(
                label: "$pendingRequests pending join requests",
                child: Badge(label: Text("$pendingRequests")),
              )
            : null,
        route: OrganizationRoute(
          organizationId: organizationId.id,
          children: [
            MembersRoute(children: [const JoinRequestsRoute()]),
          ],
        ),
      ),
      SidebarLink(
        icon: Icones(MaterialSymbols.key),
        text: "Join Codes",
        route: OrganizationRoute(
          organizationId: organizationId.id,
          children: [
            MembersRoute(children: [const JoinCodesRoute()]),
          ],
        ),
      ),
    ];
  }

  static List<Widget> realmLinks(
    skir.RecordId organizationId,
    skir.RecordId realmId,
  ) {
    return [
      const SidebarHeader(text: "Realm"),
      SidebarLink(
        icon: Icones(MaterialSymbols.library_books),
        text: "Library",
        route: OrganizationRoute(
          organizationId: organizationId.id,
          children: [
            RealmRoute(realmId: realmId.id, children: [LibraryRoute()]),
          ],
        ),
      ),
      SidebarLink(
        icon: Icones(MaterialSymbols.label),
        text: "Tags",
        route: OrganizationRoute(
          organizationId: organizationId.id,
          children: [
            RealmRoute(realmId: realmId.id, children: [TagsRoute()]),
          ],
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final organizationId = ref.watch(organizationIdProvider);
    final realmId = ref.watch(realmIdProvider);
    final pendingRequests = ref.watch(joinRequestCountProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (organizationId != null) ...[
          if (realmId != null) ...[
            RealmSuspensionInline(
              suspended: suspended,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: realmLinks(organizationId, realmId),
              ),
            ),
            SizedBox(height: context.spacing.space4),
          ],
          ...organizationLinks(organizationId, pendingRequests),
        ],
        const Spacer(),
        const FooterSidebarLinks(),
      ],
    );
  }
}
