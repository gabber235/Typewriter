import "package:auto_route/auto_route.dart";
import "package:flutter/material.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:iconify_flutter_plus/iconify_flutter_plus.dart";
import "package:iconify_flutter_plus/icons/material_symbols.dart";
import "package:typewriter_panel/logic/organization/organization.dart";
import "package:typewriter_panel/logic/realm.dart";
import "package:typewriter_panel/utils/context.dart";
import "package:typewriter_panel/widgets/app/components/action_shortcuts.dart";
import "package:typewriter_panel/widgets/app/components/custom_appbar.dart";
import "package:typewriter_panel/widgets/app/components/interaction_mode/mode_display.dart";
import "package:typewriter_panel/widgets/app/components/organization_selector.dart";
import "package:typewriter_panel/widgets/app/components/realm_selector.dart";
import "package:typewriter_panel/widgets/app/components/realm_sidebar_content.dart";
import "package:typewriter_panel/widgets/app/components/sidebar.dart";

@RoutePage()
class RealmPage extends HookConsumerWidget {
  const RealmPage({
    @PathParam("organizationId") required this.organizationId,
    @PathParam("realmId") required this.realmId,
    super.key,
  });

  final String organizationId;
  final String realmId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RealmScaffold(child: AutoRouter());
  }
}

class RealmScaffold extends HookConsumerWidget {
  const RealmScaffold({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: CustomAppBar(
        row: [
          if (ref.watch(organizationIdProvider) != null)
            const OrganizationSelector(),
          if (ref.watch(realmIdProvider) != null) ...[
            Iconify(
              MaterialSymbols.chevron_right,
              size: 16,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const RealmSelector(),
          ],
          const Spacer(),
          if (!context.isMobile) const ModeDisplayWidget(),
        ],
        sidebar: const RealmSidebarContent(),
      ),
      body: Row(
        children: [
          if (!context.isMobile) const Sidebar(child: RealmSidebarContent()),
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
