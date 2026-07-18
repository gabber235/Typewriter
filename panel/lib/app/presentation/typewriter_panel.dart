import "package:flutter/material.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/app/application/appearance.dart";
import "package:typewriter_panel/app/application/eager_initialization.dart";
import "package:typewriter_panel/app/application/router/app_router.dart";
import "package:typewriter_panel/app/presentation/responsive.dart";
import "package:typewriter_panel/app/presentation/scroll_behavior.dart";
import "package:typewriter_panel/app/presentation/shell/app_overlay.dart";
import "package:typewriter_panel/app/presentation/shell/app_required.dart";
import "package:typewriter_panel/app/presentation/shell/nats_connection.dart";
import "package:typewriter_panel/app/presentation/shortcuts/shortcuts.dart";
import "package:typewriter_panel/app/presentation/theme/theme.dart";

class TypewriterPanel extends HookConsumerWidget {
  const TypewriterPanel({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(appearanceProvider);

    return EagerInitialization(
      child: MaterialApp.router(
        title: "Typewriter",
        theme: buildTheme(Brightness.light),
        darkTheme: buildTheme(Brightness.dark),
        themeMode: themeMode,
        routerConfig: router.config(
          navigatorObservers: () => [
            InvalidatorNavigatorObserver(() async {
              // We don't want to invalidate during the build phase, so we wait
              await WidgetsBinding.instance.endOfFrame;
              ref
                ..invalidate(routeParamProvider)
                ..invalidate(currentRouteProvider);
            }),
            LoggerNavigatorObserver(),
          ],
        ),
        shortcuts: typewriterShortcuts,
        scrollBehavior: GlobalCustomScrollBehavior(),
        builder: (context, child) {
          return AppOverlay(
            child: Scaffold(
              body: AppRequiredWidgets(
                child: Responsive(
                  child: RequiredNatsConnection(
                    child: child ?? const SizedBox.shrink(),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
