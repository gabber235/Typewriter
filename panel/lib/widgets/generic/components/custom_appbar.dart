import "package:flutter/material.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/logic/organization.dart";
import "package:typewriter_panel/utils/context.dart";
import "package:typewriter_panel/widgets/generic/components/modal_header.dart";
import "package:typewriter_panel/widgets/generic/components/organization_selector.dart";
import "package:typewriter_panel/widgets/generic/components/sidebar.dart";

/// A customizable app bar for flexible layouts, always including the organization selector if available.
class CustomAppBar extends HookConsumerWidget implements PreferredSizeWidget {
  const CustomAppBar({
    this.backgroundColor,
    this.height = 48.0,
    super.key,
  });

  final Color? backgroundColor;
  final double height;

  @override
  Size get preferredSize => Size.fromHeight(height);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Material(
      color: backgroundColor ??
          Theme.of(context).appBarTheme.backgroundColor ??
          Theme.of(context).colorScheme.surface,
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: height,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              spacing: 8,
              children: [
                if (ref.watch(organizationIdProvider) != null)
                  const OrganizationSelector(),
                const Spacer(),
                if (context.isMobile)
                  IconButton(
                    icon: const Icon(Icons.menu),
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (ctx) => UncontrolledProviderScope(
                          container: ProviderScope.containerOf(context),
                          child: const _MobileSidebarMenu(),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MobileSidebarMenu extends StatelessWidget {
  const _MobileSidebarMenu();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ModalHeader(),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SidebarContent(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
