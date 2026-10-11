import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

/// Coordinates a navigation request with controls that may mount afterwards.
class PortableLocationRevealController {
  final Map<Object, _LocationTarget> _targets = {};
  skir.ValueLocation? _pending;
  bool _scheduled = false;
  bool _closed = false;

  void request(skir.ValueLocation location) {
    if (_closed) return;
    _pending = location;
    _schedule();
  }

  void _register(Object id, skir.ValueLocation location, VoidCallback reveal) {
    if (_closed) return;
    _targets[id] = _LocationTarget(location, reveal);
    _schedule();
  }

  void _schedule() {
    if (_scheduled || _closed || _pending == null) return;
    _scheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scheduled = false;
      if (_closed) return;
      final pending = _pending;
      if (pending == null) return;
      final candidates =
          _targets.values
              .where(
                (target) =>
                    target.location.resource == pending.resource &&
                    pending.path.isAtOrBelow(target.location.path),
              )
              .toList()
            ..sort(
              (a, b) => b.location.path.segments.length.compareTo(
                a.location.path.segments.length,
              ),
            );
      if (candidates.isEmpty) return;
      _pending = null;
      candidates.first.reveal();
    });
  }

  void dispose() {
    _closed = true;
    _pending = null;
    _targets.clear();
  }
}

final class _LocationTarget {
  const _LocationTarget(this.location, this.reveal);
  final skir.ValueLocation location;
  final VoidCallback reveal;
}

class PortableLocationRevealScope extends InheritedWidget {
  const PortableLocationRevealScope({
    required this.controller,
    required super.child,
    super.key,
  });
  final PortableLocationRevealController controller;
  static PortableLocationRevealController? maybeOf(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<PortableLocationRevealScope>()
          ?.controller;
  @override
  bool updateShouldNotify(PortableLocationRevealScope oldWidget) =>
      controller != oldWidget.controller;
}

/// Registers the actual control subtree for scrolling and keyboard focus.
class PortableLocationTarget extends HookWidget {
  const PortableLocationTarget({
    required this.location,
    required this.child,
    super.key,
  });
  final skir.ValueLocation? location;
  final Widget child;
  @override
  Widget build(BuildContext context) {
    final controller = PortableLocationRevealScope.maybeOf(context);
    final identity = useMemoized(Object.new);
    final focus = useMemoized(
      () =>
          FocusScopeNode(debugLabel: "Authored location", skipTraversal: true),
    );
    useEffect(() => focus.dispose, [focus]);
    useEffect(() {
      if (controller == null || location == null) return null;
      controller._register(identity, location!, () {
        if (!context.mounted) return;
        unawaited(
          Scrollable.ensureVisible(
            context,
            alignment: .25,
            duration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : const Duration(milliseconds: 250),
          ),
        );
        final target = focus.traversalDescendants.firstOrNull;
        if (target != null) target.requestFocus();
      });
      return () => controller._targets.remove(identity);
    }, [controller, location]);
    return FocusScope(node: focus, child: child);
  }
}
