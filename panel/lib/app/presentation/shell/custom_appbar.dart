import "package:typewriter_panel/typewriter_panel.dart";

/// Provides the shared route app bar for desktop and mobile layouts.
///
/// Route shells compose navigation and controls once. Measured widths shorten
/// ordered groups while each control retains its popup and focus identity.
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CustomAppBar({
    required this.navigation,
    required this.primary,
    required this.actions,
    this.backgroundColor,
    this.height = 48.0,
    super.key,
  });

  /// Color used for the bar and its surface. The app bar theme is the fallback.
  final Color? backgroundColor;

  /// Bar height in logical pixels.
  final double height;

  /// Route owned workspace navigation.
  final Widget navigation;

  /// One persistent primary control.
  final AppBarItem primary;

  /// Keyed controls using ordered fitting groups.
  final List<AppBarItem> actions;

  @override
  Size get preferredSize => Size.fromHeight(height);

  @override
  Widget build(BuildContext context) {
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
              foreground: backgroundColor == null
                  ? context.colors.contentPrimary
                  : color.on(context),
              secondaryForeground: backgroundColor == null
                  ? context.colors.contentSecondary
                  : null,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: context.spacing.space2,
                ),
                child: CustomAppBarLayout(
                  spacing: context.spacing.space2,
                  navigation: navigation,
                  primary: primary,
                  actions: actions,
                  debugReservation: context.debugShowCheckedModeBanner ? 40 : 0,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Opens the route supplied navigation surface with its provider scope intact.
class SidebarMenuButton extends StatelessWidget {
  const SidebarMenuButton({required this.sidebar, super.key});

  final Widget sidebar;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: "Open navigation",
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
    );
  }
}

class _MobileSidebarMenu extends StatelessWidget {
  const _MobileSidebarMenu({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Surface(
      color: Theme.of(context).scaffoldBackgroundColor,
      foreground: context.colors.contentPrimary,
      secondaryForeground: context.colors.contentSecondary,
      child: DecoratedBox(
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
      ),
    );
  }
}

/// Composes workspace selectors with shared spacing and horizontal scrolling.
///
/// Route selection and selector popup ownership remain with each child.
class AppBarBreadcrumbs extends StatelessWidget {
  const AppBarBreadcrumbs({required this.children, super.key});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(
      mainAxisSize: MainAxisSize.min,
      spacing: context.spacing.space2,
      children: [
        for (var index = 0; index < children.length; index++) ...[
          if (index > 0)
            Icones(
              MaterialSymbols.chevron_right,
              size: 16,
              color: context.colors.contentSecondary,
            ),
          children[index],
        ],
      ],
    ),
  );
}
