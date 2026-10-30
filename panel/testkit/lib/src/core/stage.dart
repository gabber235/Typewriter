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
    // The router admits the first navigation once the app mounted it.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_world.container.read(appRouterProvider).navigate(route));
    });
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
    return UncontrolledProviderScope(
      container: _world.container,
      child: switch (widget.at) {
        ComponentLocation(:final child) => _ComponentShell(child: child),
        _ => const TypewriterPanel(),
      },
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
