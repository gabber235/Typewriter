import "dart:math";

import "package:auto_route/auto_route.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_animate/flutter_animate.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:iconify_flutter_plus/icons/material_symbols.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";
import "package:typewriter_panel/typewriter_panel.dart";

part "sidebar.g.dart";

const double kSidebarResizeSmallStep = 10;
const double kSidebarResizeLargeStep = 50;

const double kSidebarMinSize = 150;
const double kSidebarDefaultSize = 220;
const double kSidebarMaxFactor = 1 / 3;

@riverpod
class SidebarSize extends _$SidebarSize {
  @override
  double build() {
    return kSidebarDefaultSize;
  }

  void size(double size) {
    state = max(size, kSidebarMinSize);
  }
}

class Sidebar extends HookConsumerWidget {
  const Sidebar({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final size = ref.watch(sidebarSizeProvider);

    final screenSize = MediaQuery.of(context).size;

    final maxSize =
        (screenSize.width * kSidebarMaxFactor).floorToDouble() - 1.0;
    final minSize = min(kSidebarMinSize, maxSize);

    final effectiveSize = size.clamp(max<double>(0.0, minSize), maxSize);

    final isDragging = useState(false);

    return ManagedActionSet(
      shortcuts: [
        ActionShortcut(
          id: "sidebar-shrink",
          label: "Shrink Sidebar",
          description: "Shrink the sidebar size",
          activators: [
            const SingleActivator(LogicalKeyboardKey.less),
            const SingleActivator(LogicalKeyboardKey.less, shift: true),
            const SingleActivator(LogicalKeyboardKey.comma),
            const SingleActivator(LogicalKeyboardKey.comma, shift: true),
          ],
          priority: -1,
          onInvoke: (ref) {
            final step = HardwareKeyboard.instance.isShiftPressed
                ? kSidebarResizeLargeStep
                : kSidebarResizeSmallStep;
            final newSize = (effectiveSize - step).clamp(
              max<double>(0.0, minSize),
              maxSize,
            );
            ref.read(sidebarSizeProvider.notifier).size(newSize);
          },
          show: false,
        ),
        ActionShortcut(
          id: "sidebar-expand",
          label: "Expand Sidebar",
          description: "Expand the sidebar size",
          activators: [
            const SingleActivator(LogicalKeyboardKey.greater),
            const SingleActivator(LogicalKeyboardKey.greater, shift: true),
            const SingleActivator(LogicalKeyboardKey.period),
            const SingleActivator(LogicalKeyboardKey.period, shift: true),
          ],
          priority: -1,
          onInvoke: (ref) {
            final step = HardwareKeyboard.instance.isShiftPressed
                ? kSidebarResizeLargeStep
                : kSidebarResizeSmallStep;
            final newSize = (effectiveSize + step).clamp(
              max<double>(0.0, minSize),
              maxSize,
            );
            ref.read(sidebarSizeProvider.notifier).size(newSize);
          },
          show: false,
        ),
        ActionShortcut(
          id: "sidebar-resize",
          label: "Resize Sidebar",
          description: "Resize the sidebar size",
          activators: [
            const SingleActivator(LogicalKeyboardKey.period),
            const SingleActivator(LogicalKeyboardKey.comma),
            const SingleActivator(LogicalKeyboardKey.greater),
            const SingleActivator(LogicalKeyboardKey.less),
          ],
          priority: -1,
        ),
      ],
      child: AnimatedContainer(
        duration: isDragging.value ? 0.ms : 1000.ms,
        curve: ElasticOutCurve(0.9),
        width: effectiveSize,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Pane(
                id: "sidebar",
                margin: EdgeInsets.only(left: 4, top: 4, bottom: 4),
                borderRadius: BorderRadius.circular(8),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Surface(
                      color: Theme.of(context).colorScheme.surface,
                      child: child,
                    ),
                  ),
                ),
              ),
            ),
            DragHandle(
              axis: Axis.horizontal,
              minSize: kSidebarMinSize,
              maxSize: maxSize,
              getSize: () => effectiveSize,
              onSizeChange: (v) => ref
                  .read(sidebarSizeProvider.notifier)
                  .size(v.clamp(minSize, maxSize)),
              onDragStart: () => isDragging.value = true,
              onDragEnd: () => isDragging.value = false,
              hitThickness: 8,
            ),
          ],
        ),
      ),
    );
  }
}

class SidebarHeader extends StatelessWidget {
  const SidebarHeader({required this.text, super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 8, left: 12, right: 12),
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
        borderRadius: BorderRadius.circular(8),
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
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            child: Row(
              spacing: 12,
              children: [
                IconTheme(
                  data: IconThemeData(color: color, size: 20),
                  child: icon,
                ),

                if (expand)
                  Expanded(
                    child: Text(
                      text,
                      style: TextStyle(color: color, fontSize: 14),
                    ),
                  )
                else
                  Text(text, style: TextStyle(color: color, fontSize: 14)),

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
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: uri.launchExternally,
          hoverColor: Theme.of(
            context,
          ).colorScheme.onSurface.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            child: Row(
              spacing: 12,
              children: [
                IconTheme(
                  data: IconThemeData(color: color, size: 20),
                  child: icon,
                ),

                if (expand)
                  Expanded(
                    child: Text(
                      text,
                      style: TextStyle(color: color, fontSize: 14),
                    ),
                  )
                else
                  Text(text, style: TextStyle(color: color, fontSize: 14)),

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
          final router = ref.read(appRouterProvider);
          try {
            await ref.read(authProvider.notifier).signOut();
          } on Exception catch (e) {
            debugPrint(e.toString());
          }
          ref
            ..invalidate(isAuthenticatedProvider)
            ..invalidate(accessTokenProvider);
          await Future.delayed(const Duration(milliseconds: 500));
          await router.reevaluateGuards();
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
              borderRadius: BorderRadius.circular(8),
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
                      const SizedBox(width: 12),
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
