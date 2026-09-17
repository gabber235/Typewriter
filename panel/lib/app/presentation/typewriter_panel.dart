import "package:flutter/material.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/typewriter_panel.dart";

/// Composes the panel application boundary.
///
/// This widget watches the router and appearance providers, binds live route
/// access before router construction, and installs themes, global shortcuts,
/// responsive breakpoints, scroll behavior, required interaction widgets, and
/// the NATS connection boundary around routed content. Route navigation also
/// invalidates route derived providers after the frame completes.
class TypewriterPanel extends HookConsumerWidget {
  const TypewriterPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(appearanceProvider);

    return EagerInitialization(
      child: RouteAccessBinding(
        access: router.access,
        builder: (context) => MaterialApp.router(
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
      ),
    );
  }
}
