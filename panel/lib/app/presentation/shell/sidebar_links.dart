part of "sidebar.dart";

class SidebarHeader extends StatelessWidget {
  const SidebarHeader({required this.text, super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        top: context.spacing.space5,
        bottom: context.spacing.space2,
        left: context.spacing.space3,
        right: context.spacing.space3,
      ),
      child: Row(
        children: [
          Text(
            text.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ],
      ),
    );
  }
}

class SidebarLink extends HookConsumerWidget {
  const SidebarLink({
    required this.icon,
    required this.text,
    required this.route,
    this.trailing,
    this.expand = true,
    super.key,
  });
  final Widget icon;
  final String text;
  final PageRouteInfo route;
  final Widget? trailing;
  final bool expand;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final focusNode = useFocusNode(
      debugLabel: "SidebarLink-${text.snakeCase()}",
    );
    ref.watch(currentRouteProvider);
    final scope = StackRouterScope.of(context, watch: true);
    final router = scope?.controller;
    final selected =
        router?.isRouteActive(route.flattened.last.routeName) ?? false;

    final color = selected
        ? Theme.of(context).colorScheme.onSurface
        : Theme.of(context).colorScheme.onSurfaceVariant;
    final backgroundColor = selected
        ? Theme.of(context).colorScheme.surfaceContainerHighest
        : Colors.transparent;

    return Surface(
      color: backgroundColor,
      child: Material(
        color: backgroundColor,
        borderRadius: context.shapes.mediumBorderRadius,
        child: InkWell(
          focusNode: focusNode,
          onTap: router != null
              ? () {
                  if (!selected) {
                    router.navigate(route);
                  }
                }
              : null,
          hoverColor: Theme.of(
            context,
          ).colorScheme.onSurface.withValues(alpha: 0.1),
          borderRadius: context.shapes.mediumBorderRadius,
          child: Padding(
            padding: EdgeInsets.symmetric(
              vertical: context.spacing.space2,
              horizontal: context.spacing.space3,
            ),
            child: Row(
              spacing: context.spacing.space3,
              children: [
                IconTheme(
                  data: IconThemeData(color: color, size: 20),
                  child: icon,
                ),

                if (expand)
                  Expanded(
                    child: Text(
                      text,
                      style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        color: color,
                        fontSize: 14,
                      ),
                    ),
                  )
                else
                  Text(
                    text,
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      color: color,
                      fontSize: 14,
                    ),
                  ),

                ?trailing,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ExternalSidebarLink extends StatelessWidget {
  const ExternalSidebarLink({
    required this.icon,
    required this.text,
    required this.url,
    this.trailing,
    this.expand = true,
    super.key,
  });

  final Widget icon;
  final String text;
  final String url;
  final Widget? trailing;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurfaceVariant;
    final uri = Uri.parse(url);

    return Surface(
      color: Colors.transparent,
      child: Material(
        color: Colors.transparent,
        borderRadius: context.shapes.mediumBorderRadius,
        child: InkWell(
          onTap: uri.launchExternally,
          hoverColor: Theme.of(
            context,
          ).colorScheme.onSurface.withValues(alpha: 0.1),
          borderRadius: context.shapes.mediumBorderRadius,
          child: Padding(
            padding: EdgeInsets.symmetric(
              vertical: context.spacing.space2,
              horizontal: context.spacing.space3,
            ),
            child: Row(
              spacing: context.spacing.space3,
              children: [
                IconTheme(
                  data: IconThemeData(color: color, size: 20),
                  child: icon,
                ),

                if (expand)
                  Expanded(
                    child: Text(
                      text,
                      style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        color: color,
                        fontSize: 14,
                      ),
                    ),
                  )
                else
                  Text(
                    text,
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      color: color,
                      fontSize: 14,
                    ),
                  ),

                ?trailing,
                IconTheme(
                  data: IconThemeData(color: color, size: 18),
                  child: Icones(MaterialSymbols.open_in_new),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class FooterSidebarLinks extends StatelessWidget {
  const FooterSidebarLinks({
    this.compact = false,
    this.expand = true,
    super.key,
  });

  final bool compact;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: .start,
      children: [
        if (!compact) ...[
          SupportSidebarLink(expand: expand),
          DocumentationSidebarLink(expand: expand),
        ],
        UserMenu(compact: compact, expand: expand),
      ],
    );
  }
}

const discordUrl = "https://discord.gg/j5WWscvQkW";

class SupportSidebarLink extends StatelessWidget {
  const SupportSidebarLink({super.key, this.expand = false});

  final bool expand;

  @override
  Widget build(BuildContext context) {
    return ExternalSidebarLink(
      icon: Icones(MaterialSymbols.contact_support_rounded),
      text: "Support",
      url: discordUrl,
      expand: expand,
    );
  }
}

const docsUrl = "https://docs.typewritermc.com";

class DocumentationSidebarLink extends StatelessWidget {
  const DocumentationSidebarLink({super.key, this.expand = false});

  final bool expand;

  @override
  Widget build(BuildContext context) {
    return ExternalSidebarLink(
      icon: Icones(MaterialSymbols.book_outline),
      text: "Docs",
      url: docsUrl,
      expand: expand,
    );
  }
}

const userIconUrl =
    "https://api.dicebear.com/9.x/bottts-neutral/webp?backgroundColor=00897b,00acc1,039be5,1e88e5,3949ab,43a047,5e35b1,7cb342,8e24aa,b6e3f4,c0aede,c0ca33,d1d4f9,d81b60,e53935,f4511e,fb8c00,fdd835,ffb300,ffd5dc,ffdfbf&eyes=eva,frame1,frame2,robocop,roundFrame01,roundFrame02,sensor,shade01&mouth=bite,diagram,smile01,smile02&backgroundType=gradientLinear";
