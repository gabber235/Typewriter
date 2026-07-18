import "package:auto_route/auto_route.dart";
import "package:flutter/material.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:iconify_flutter_plus/iconify_flutter_plus.dart";
import "package:iconify_flutter_plus/icons/material_symbols.dart";
import "package:typewriter_panel/app/application/router/app_router.dart";
import "package:typewriter_panel/app/presentation/shell/custom_appbar.dart";
import "package:typewriter_panel/app/presentation/shell/sidebar.dart";
import "package:typewriter_panel/app/presentation/shortcuts/action_shortcuts.dart";
import "package:typewriter_panel/features/organizations/organizations.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/converters.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart" as skir;
import "package:typewriter_panel/shared/ui/components/icons.dart";
import "package:typewriter_panel/shared/ui/components/simple_scaffold.dart";
import "package:typewriter_panel/shared/utilities/context.dart";

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

class OrganizationScaffold extends HookConsumerWidget {
  const OrganizationScaffold({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final organizationId = ref.watch(organizationIdProvider);
    final realmId = ref.watch(realmIdProvider);
    return SimpleScaffold(
      appBar: CustomAppBar(
        row: [
          if (organizationId != null) ...[
            const OrganizationSelector(),
            if (realmId != null) ...[
              Iconify(
                MaterialSymbols.chevron_right,
                size: 16,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const RealmSelector(),
            ],
          ],
          const Spacer(),
          if (!context.isMobile) const ModeDisplayWidget(),
        ],
        sidebar: const OrganizationSidebarContent(),
      ),
      child: Row(
        children: [
          if (!context.isMobile)
            const Sidebar(child: OrganizationSidebarContent()),
          Expanded(
            child: Column(
              children: [
                Expanded(child: child),
                ActionRow(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class OrganizationSidebarContent extends HookConsumerWidget {
  const OrganizationSidebarContent({super.key});

  static List<Widget> organizationLinks(skir.RecordId organizationId) {
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
          children: [MembersRoute()],
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (organizationId != null) ...[
          if (realmId != null) ...[
            ...realmLinks(organizationId, realmId),
            const SizedBox(height: 16),
          ],
          ...organizationLinks(organizationId),
        ],
        const Spacer(),
        UserMenu(),
      ],
    );
  }
}
