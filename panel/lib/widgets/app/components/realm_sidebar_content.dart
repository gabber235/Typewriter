import "package:flutter/material.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:iconify_flutter_plus/icons/material_symbols.dart";
import "package:typewriter_panel/app_router.dart";
import "package:typewriter_panel/logic/organization/organization.dart";
import "package:typewriter_panel/routes/organization/route.dart";
import "package:typewriter_panel/widgets/app/components/sidebar.dart";
import "package:typewriter_panel/widgets/generic/components/icones.dart";

class RealmSidebarContent extends HookConsumerWidget {
  const RealmSidebarContent({super.key});

  static List<Widget> realmLinks() {
    return [
      const SidebarHeader(text: "Realm"),
      SidebarLink(
        icon: Icones(MaterialSymbols.library_books),
        text: "Library",
        route: LibraryRoute(),
      ),
    ];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final organizationId = ref.watch(organizationIdProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (organizationId != null) ...[
          ...realmLinks(),
          const SizedBox(height: 16),
          ...OrganizationSidebarContent.organizationLinks(),
        ],
        const Spacer(),
        UserMenu(),
      ],
    );
  }
}
