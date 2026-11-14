import "package:typewriter_panel/typewriter_panel.dart";

/// Publishes each page change with its direction.
final pageMovesProvider = NotifierProvider<PageMoves, PageMove?>(PageMoves.new);

/// Publishes each page change with its direction: deeper and back by path
/// depth; between pages at the same depth, down or up by where their
/// sidebar links sit.
class PageMoves extends Notifier<PageMove?> {
  @override
  PageMove? build() {
    final router = ref.watch(navigationRouterProvider);
    var path = router.currentPath;
    var link = _activeLink(router);
    var serial = 0;
    void changed() {
      final next = router.currentPath;
      if (next == path) return;
      final nextLink = _activeLink(router);
      final from = _depth(path);
      final to = _depth(next);
      final direction = to > from
          ? PageDirection.deeper
          : to < from
          ? PageDirection.back
          : (nextLink ?? 0) >= (link ?? 0)
          ? PageDirection.down
          : PageDirection.up;
      path = next;
      link = nextLink;
      state = PageMove(
        direction: direction,
        target: router.topMatch.key.toString(),
        serial: ++serial,
      );
    }

    // The history hears every change, nested routers included.
    final history = router.navigationHistory..addListener(changed);
    ref.onDispose(() => history.removeListener(changed));
    return null;
  }

  /// The top edge of the deepest active sidebar link, or null off the
  /// sidebar (a sibling with no link counts as down).
  double? _activeLink(NavigationRouter router) => ref
      .read(sidebarOrderProvider)
      .tops
      .entries
      .where((entry) => router.isRouteActive(entry.key))
      .map((entry) => entry.value)
      .maxOrNull;

  static int _depth(String path) =>
      path.split("/").where((segment) => segment.isNotEmpty).length;
}

/// Wraps every page: rows on the page a move reached ripple in from its
/// side, and the root page sinks behind an open dialog.
class PageFrame extends ConsumerWidget {
  const PageFrame({required this.child, super.key});

  final Widget child;

  /// The route transitions builder: pages swap at once, so the route's own
  /// animations are ignored.
  static Widget transition(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => PageFrame(child: child);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // The transitions builder runs above the page's RouteData scope; the
    // route's page carries it.
    final data = switch (ModalRoute.of(context)?.settings) {
      final AutoRoutePage<Object?> page => page.routeData,
      _ => null,
    };
    final move = ref.watch(pageMovesProvider);
    final page = PageArrival(
      move: move != null && move.target == data?.route.key.toString()
          ? move
          : null,
      child: child,
    );
    if (data == null || !data.router.isRoot) return page;
    return DialogBackdrop(child: page);
  }
}
