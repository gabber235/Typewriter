import "package:auto_route/auto_route.dart";
import "package:flutter/material.dart" hide ConnectionState;
import "package:flutter_animate/flutter_animate.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter/app_router.dart";
import "package:typewriter/hooks/delayed_execution.dart";
import "package:typewriter/l10n/l10n_provider.dart";
import "package:typewriter/models/book.dart";
import "package:typewriter/models/communicator.dart";
import "package:typewriter/models/entry_blueprint.dart";
import "package:typewriter/pages/connect_page.dart";
import "package:typewriter/utils/icons.dart";
import "package:typewriter/widgets/components/app/search_bar.dart";
import "package:typewriter/widgets/components/app/writers.dart";
import "package:typewriter/widgets/components/general/iconify.dart";
import "package:url_launcher/url_launcher.dart";

@RoutePage()
class BookPage extends HookConsumerWidget {
  const BookPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectionState = ref.watch(connectionStateProvider);

    return AutoTabsRouter(
      routes: const [
        PagesListRoute(),
      ],
      transitionBuilder: (context, child, animation) => FadeTransition(
        opacity: animation,
        child: child,
      ),
      builder: (context, child) {
        return Stack(
          children: [
            SearchBarWrapper(
              child: Scaffold(
                body: Row(
                  children: [
                    const _SideRail(),
                    Expanded(
                      child: child,
                    ),
                  ],
                ),
              ),
            ),
            if (connectionState == ConnectionState.disconnected) ...[
              const ModalBarrier(
                dismissible: false,
                color: Colors.black54,
              ),
              const _ReconnectOverlay(),
            ],
          ],
        );
      },
    );
  }
}

class _ReconnectOverlay extends HookConsumerWidget {
  const _ReconnectOverlay();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = ref.watch(l10nProvider);
    final controller = useAnimationController(
      duration: 30.seconds,
    )..forward();

    // We want to animate the color of the progress bar, blue -> red, starting at 0.5
    final colorTween = ColorTween(
      begin: Colors.blue,
      end: Colors.red,
    ).animate(
      CurvedAnimation(
        parent: controller,
        curve: const Interval(0.5, 1),
      ),
    );

    useAnimation(controller);

    useDelayedExecution(() {
      // When this widget is mounted, we want to close all the popups
      while (ModalRoute.of(context)?.isCurrent != true) {
        Navigator.of(context).pop();
      }
    });

    return Dialog(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 420,
            child: LinearProgressIndicator(
              value: 1 - controller.value,
              valueColor: colorTween,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.reconnectTitle,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                const ConnectionScroller(
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SideRail extends HookConsumerWidget {
  const _SideRail();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    var index = 0;
    return Container(
      width: 60,
      color: const Color(0xFF11274f),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(13.0),
            child: Image.asset("assets/typewriter-icon.png"),
          ),
          const SizedBox(height: 10),
          Flexible(
            child: Column(
              children: [
                _RailButton(index++, icon: TWIcons.filePen),
                const Spacer(),
                const GlobalWriters(direction: Axis.vertical),
                const SizedBox(height: 5),
                const _DiscordButton(),
                const SizedBox(height: 5),
                const _WikiButton(),
                const SizedBox(height: 5),
                const _ReloadBookButton(),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}

class _RailButton extends HookConsumerWidget {
  const _RailButton(
    this.index, {
    required this.icon,
  });
  final int index;
  final String icon;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tabRouter = context.tabsRouter;
    final isSelected = tabRouter.activeIndex == index;
    return Material(
      color: isSelected ? Colors.white.withValues(alpha:0.15) : Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: () => tabRouter.setActiveIndex(index),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Iconify(
            icon,
            color: isSelected ? Colors.white : Colors.white54,
            size: 20,
          ),
        ),
      ),
    );
  }
}

class _SimpleButton extends HookConsumerWidget {
  const _SimpleButton({
    required this.tooltip,
    required this.icon,
    required this.onTap,
  });

  final String tooltip;
  final String icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = useAnimationController(duration: 2.seconds);

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        onHover: (hover) {
          if (hover) {
            controller.forward(from: 0);
          } else {
            controller.reset();
          }
        },
        borderRadius: BorderRadius.circular(8),
        child: Tooltip(
          message: tooltip,
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Iconify(
              icon,
              color: Colors.white54,
              size: 20,
            ),
          )
              .animate(controller: controller)
              .scaleXY(
                begin: 1,
                end: 1.1,
                curve: Curves.easeInOutCubicEmphasized,
                duration: 500.ms,
              )
              .shake(delay: 300.ms, duration: 700.ms)
              .scaleXY(
                begin: 1.1,
                end: 1,
                curve: Curves.easeInOut,
                delay: 700.ms,
                duration: 500.ms,
              ),
        ),
      ),
    );
  }
}

class _DiscordButton extends HookConsumerWidget {
  const _DiscordButton();

  void _launchDiscord() {
    launchUrl(
      Uri.parse("https://discord.gg/gs5QYhfv9x"),
      webOnlyWindowName: "_blank",
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = ref.watch(l10nProvider);
    return _SimpleButton(
      tooltip: l10n.joinDiscord,
      icon: "bi:discord",
      onTap: _launchDiscord,
    );
  }
}

class _WikiButton extends HookConsumerWidget {
  const _WikiButton();

  void _launchWiki() {
    launchUrl(
      Uri.parse(wikiBaseUrl),
      webOnlyWindowName: "_blank",
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = ref.watch(l10nProvider);
    return _SimpleButton(
      tooltip: l10n.openWiki,
      icon: "oi:book",
      onTap: _launchWiki,
    );
  }
}

class _ReloadBookButton extends HookConsumerWidget {
  const _ReloadBookButton() : super();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = ref.watch(l10nProvider);
    return _SimpleButton(
      tooltip: l10n.reloadData,
      icon: "fa6-solid:arrows-rotate",
      onTap: () => ref.read(bookProvider.notifier).reload(),
    );
  }
}
