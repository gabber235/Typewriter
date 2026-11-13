import "package:typewriter_panel/typewriter_panel.dart";

/// Composes the panel application boundary.
///
/// This widget watches the router and appearance providers, binds live route
/// access before installing the router configuration. It installs themes,
/// global shortcuts, responsive breakpoints, scroll behavior, interaction widgets, and
/// the NATS connection boundary around routed content. Route navigation also
/// invalidates route derived providers after the frame completes.
class TypewriterPanel extends HookConsumerWidget {
  const TypewriterPanel({super.key});

  /// The boundary around the whole app that end to end screenshots capture.
  static const screenshotKey = ValueKey("typewriter-panel");

  /// Wraps the app's content in the interaction widgets, responsive
  /// breakpoints and NATS connection boundary every page needs.
  ///
  /// The [MaterialApp] builder of the panel; test stages that render one
  /// component instead of the router reuse it.
  static Widget shell(BuildContext context, Widget? child) {
    return Surface(
      color: Theme.of(context).scaffoldBackgroundColor,
      foreground: context.colors.contentPrimary,
      secondaryForeground: context.colors.contentSecondary,
      child: AppOverlay(
        child: Scaffold(
          body: Responsive(
            child: AppRequiredWidgets(
              child: RequiredNatsConnection(
                child: child ?? const SizedBox.shrink(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(appearanceProvider);
    final motion = ref.watch(motionTableProvider);

    return RepaintBoundary(
      key: screenshotKey,
      child: WorkSessionUnloadBoundary(
        child: EagerInitialization(
          child: RouteAccessBinding(
            access: router.access,
            builder: (context) => MaterialApp.router(
              title: "Typewriter",
              debugShowCheckedModeBanner: false,
              theme: buildTheme(Brightness.light, motion: motion),
              darkTheme: buildTheme(Brightness.dark, motion: motion),
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
                  RouteSettlingObserver(ref.read(routeSettlingProvider)),
                ],
              ),
              shortcuts: typewriterShortcuts,
              scrollBehavior: GlobalCustomScrollBehavior(),
              builder: shell,
            ),
          ),
        ),
      ),
    );
  }
}
