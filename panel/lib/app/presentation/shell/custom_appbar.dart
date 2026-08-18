import "package:flutter/material.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/typewriter_panel.dart";

/// A customizable app bar for flexible layouts, always including the organization selector if available.
class CustomAppBar extends HookConsumerWidget implements PreferredSizeWidget {
  const CustomAppBar({
    required this.leading,
    required this.sidebar,
    this.trailing,
    this.backgroundColor,
    this.height = 48.0,
    super.key,
  });

  final Color? backgroundColor;
  final double height;

  final List<Widget> leading;
  final Widget? trailing;
  final Widget sidebar;

  @override
  Size get preferredSize => Size.fromHeight(height);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color =
        backgroundColor ??
        Theme.of(context).appBarTheme.backgroundColor ??
        Theme.of(context).colorScheme.surface;

    return Pane(
      id: "appbar",
      margin: EdgeInsets.only(top: 2, left: 2, right: 2),
      borderRadius: context.shapes.mediumBorderRadius,
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: height,
          child: Material(
            color: color,
            borderRadius: context.shapes.mediumBorderRadius,
            child: Surface(
              color: color,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final showTrailing =
                      trailing != null && constraints.maxWidth >= 600;
                  return Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: context.spacing.space2,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      spacing: context.spacing.space2,
                      children: [
                        ...leading,
                        const Spacer(),
                        if (showTrailing) trailing!,
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
                                  child: _MobileSidebarMenu(child: sidebar),
                                ),
                              );
                            },
                          ),
                        if (context.debugShowCheckedModeBanner)
                          const SizedBox(width: 40),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MobileSidebarMenu extends StatelessWidget {
  const _MobileSidebarMenu({required this.child});

  final Widget child;

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
                padding: EdgeInsets.symmetric(
                  horizontal: context.spacing.space4,
                ),
                child: child,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
