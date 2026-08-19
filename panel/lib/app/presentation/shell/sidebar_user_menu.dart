part of "sidebar.dart";

class UserMenu extends HookConsumerWidget {
  const UserMenu({this.compact = false, this.expand = true, super.key});

  final bool compact;
  final bool expand;

  List<MenuItem> _buildMenuItems(
    BuildContext context,
    WidgetRef ref,
    ThemeMode currentThemeMode,
  ) {
    return [
      const MenuItem(label: "Account", icon: Icones(MaterialSymbols.person)),
      MenuItem.submenu(
        label: "Appearance",
        icon: Icones(MaterialSymbols.palette),
        items: [
          MenuItem(
            label: "System",
            icon: currentThemeMode == ThemeMode.system
                ? Icones(MaterialSymbols.check)
                : Icones(MaterialSymbols.brightness_auto),
            color: currentThemeMode == ThemeMode.system
                ? Theme.of(context).colorScheme.primary
                : null,
            onPressed: currentThemeMode == ThemeMode.system
                ? null
                : () {
                    ref
                        .read(appearanceProvider.notifier)
                        .mode(ThemeMode.system);
                  },
          ),
          MenuItem(
            label: "Light",
            icon: currentThemeMode == ThemeMode.light
                ? Icones(MaterialSymbols.check)
                : Icones(MaterialSymbols.light_mode),
            color: currentThemeMode == ThemeMode.light
                ? Theme.of(context).colorScheme.primary
                : null,
            onPressed: currentThemeMode == ThemeMode.light
                ? null
                : () {
                    ref.read(appearanceProvider.notifier).mode(ThemeMode.light);
                  },
          ),
          MenuItem(
            label: "Dark",
            icon: currentThemeMode == ThemeMode.dark
                ? Icones(MaterialSymbols.check)
                : Icones(MaterialSymbols.dark_mode),
            color: currentThemeMode == ThemeMode.dark
                ? Theme.of(context).colorScheme.primary
                : null,
            onPressed: currentThemeMode == ThemeMode.dark
                ? null
                : () {
                    ref.read(appearanceProvider.notifier).mode(ThemeMode.dark);
                  },
          ),
        ],
      ),
      const MenuItem.divider(),
      MenuItem(
        label: "Help & Support",
        icon: Icones(MaterialSymbols.contact_support_rounded),
        onPressed: () => Uri.parse(discordUrl).launchExternally(),
      ),
      MenuItem(
        label: "Documentation",
        icon: Icones(MaterialSymbols.book),
        onPressed: () => Uri.parse(docsUrl).launchExternally(),
      ),
      const MenuItem.divider(),
      MenuItem(
        label: "Logout",
        icon: Icones(MaterialSymbols.logout),
        color: Theme.of(context).colorScheme.error,
        onPressed: () async {
          try {
            await ref.read(authProvider.notifier).signOut();
          } on Object catch (_) {
            if (!context.mounted) return;
            showErrorSnackBar(context, "Could not sign out. Please try again.");
          }
        },
      ),
    ];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userInfoAsync = ref.watch(authUserInfoProvider);
    final currentThemeMode = ref.watch(appearanceProvider);

    final controller = useMenuController();
    final focusNode = useFocusNode(debugLabel: "UserMenu");

    return userInfoAsync(
      name: "user info",
      builder: (user) {
        final name = user.name ?? user.username ?? user.sub;
        final avatarUrl = user.avatarUrl ?? "$userIconUrl&seed=${user.sub}";

        final text = Text(
          name,
          style: Theme.of(context).textTheme.bodyMedium,
          overflow: TextOverflow.ellipsis,
        );

        return ContextMenuRegion(
          items: _buildMenuItems(context, ref, currentThemeMode),
          enableGestures: false,
          childFocusNode: focusNode,
          controller: controller,
          child: Material(
            child: InkWell(
              onTap: ContextMenuRegion.onPress(controller),
              borderRadius: context.shapes.mediumBorderRadius,
              focusNode: focusNode,
              child: Padding(
                padding: EdgeInsets.all(compact ? 8 : 12),
                child: Row(
                  mainAxisSize: compact ? MainAxisSize.min : MainAxisSize.max,
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundImage: NetworkImage(avatarUrl),
                    ),
                    if (!compact) ...[
                      SizedBox(width: context.spacing.space3),
                      if (expand) Expanded(child: text) else text,
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
