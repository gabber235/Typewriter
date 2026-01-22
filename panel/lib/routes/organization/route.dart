import "package:auto_route/auto_route.dart";
import "package:flutter/material.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:iconify_flutter_plus/icons/material_symbols.dart";
import "package:typewriter_panel/app_router.dart";
import "package:typewriter_panel/logic/organization.dart";
import "package:typewriter_panel/utils/context.dart";
import "package:typewriter_panel/widgets/app/components/action_shortcuts.dart";
import "package:typewriter_panel/widgets/app/components/custom_appbar.dart";
import "package:typewriter_panel/widgets/app/components/interaction_mode/mode_display.dart";
import "package:typewriter_panel/widgets/app/components/organization_selector.dart";
import "package:typewriter_panel/widgets/app/components/sidebar.dart";
import "package:typewriter_panel/widgets/generic/components/icones.dart";

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
    return Scaffold(
      appBar: CustomAppBar(
        row: [
          if (ref.watch(organizationIdProvider) != null)
            const OrganizationSelector(),
          const Spacer(),
          if (!context.isMobile) const ModeDisplayWidget(),
        ],
        sidebar: const OrganizationSidebarContent(),
      ),
      body: Row(
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final organizationId = ref.watch(organizationIdProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SidebarHeader(text: "Organization"),
        if (organizationId != null) ...[
          SidebarLink(
            icon: Icones(MaterialSymbols.dns),
            text: "Services",
            route: ServicesRoute(),
          ),
          SidebarLink(
            icon: Icones(MaterialSymbols.groups_rounded),
            text: "Members",
            route: MembersRoute(),
          ),
        ],
        const Spacer(),
        UserMenu(),
      ],
    );
  }
}
