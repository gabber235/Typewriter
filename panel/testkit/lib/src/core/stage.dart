import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/src/core/trait.dart";
import "package:typewriter_testkit/src/core/world.dart";

/// Where a panel opens.
sealed class PanelLocation {
  const PanelLocation();

  /// The page [route] leads to, through the real router and its guards.
  const factory PanelLocation.route(PageRouteInfo route) = RouteLocation;

  /// One component inside the panel shell, for components no route shows on
  /// their own, such as shared primitives.
  ///
  /// The component gets the theme, shortcuts, overlays and connection
  /// boundary every page gets; only the router is left out.
  const factory PanelLocation.component(Widget child) = ComponentLocation;
}

/// A location the real router opens.
final class RouteLocation extends PanelLocation {
  const RouteLocation(this.route);

  final PageRouteInfo route;
}

/// A component mounted inside the panel shell without routing.
final class ComponentLocation extends PanelLocation {
  const ComponentLocation(this.child);

  final Widget child;
}

/// The real panel over a test [World], for widget tests and stories alike.
///
/// The stage owns its world: unmounting it disposes the container and every
/// double. With a route location it runs the production app, router, guards
/// and all; a component location mounts the component inside the same shell.
class PanelStage extends StatefulWidget {
  /// The panel over a world built from [traits], opened [at] a location or
  /// at the world's home.
  PanelStage(List<Trait> traits, {PanelLocation? at, Key? key})
    : this.world(World.build(traits), at: at, key: key);

  /// The panel over an existing [world]; the stage takes it over.
  const PanelStage.world(this.world, {this.at, super.key});

  final World world;
  final PanelLocation? at;

  @override
  State<PanelStage> createState() => _PanelStageState();
}

class _PanelStageState extends State<PanelStage> {
  World get _world => widget.world;

  @override
  void initState() {
    super.initState();
    _world.start();
    if (widget.at case ComponentLocation()) return;
    final route = switch (widget.at) {
      RouteLocation(:final route) => route,
      _ => _world.home,
    };
    // The router admits the first navigation once the app mounted it and
    // settled its own initial route, so the test's location always lands
    // last instead of racing the guards of that initial route.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final router = _world.container.read(appRouterProvider);
      await _initialRouteSettled(router);
      if (!mounted) return;
      unawaited(router.navigate(route));
    });
  }

  /// Completes once [router] holds the page its initial route resolved to.
  Future<void> _initialRouteSettled(StackRouter router) {
    if (router.stack.isNotEmpty) return Future.value();
    final settled = Completer<void>();
    void check() {
      if (router.stack.isEmpty) return;
      router.removeListener(check);
      settled.complete();
    }

    router.addListener(check);
    return settled.future;
  }

  @override
  void didUpdateWidget(covariant PanelStage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.world, widget.world)) {
      unawaited(oldWidget.world.dispose());
    }
  }

  @override
  void dispose() {
    unawaited(_world.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final panel = UncontrolledProviderScope(
      container: _world.container,
      child: switch (widget.at) {
        ComponentLocation(:final child) => _ComponentShell(child: child),
        _ => const TypewriterPanel(),
      },
    );
    if (!_world.reducedMotion) return panel;
    final platform =
        MediaQuery.maybeOf(context) ??
        MediaQueryData.fromView(View.of(context));
    return MediaQuery(
      data: platform.copyWith(disableAnimations: true),
      child: panel,
    );
  }
}

/// The shell [TypewriterPanel] builds around routed pages, around one
/// component instead of the router.
class _ComponentShell extends ConsumerWidget {
  const _ComponentShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return WorkSessionUnloadBoundary(
      child: EagerInitialization(
        child: MaterialApp(
          title: "Typewriter",
          debugShowCheckedModeBanner: false,
          theme: buildTheme(Brightness.light),
          darkTheme: buildTheme(Brightness.dark),
          themeMode: ref.watch(appearanceProvider),
          shortcuts: typewriterShortcuts,
          scrollBehavior: GlobalCustomScrollBehavior(),
          builder: TypewriterPanel.shell,
          home: Center(child: child),
        ),
      ),
    );
  }
}
