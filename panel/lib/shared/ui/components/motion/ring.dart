import "package:typewriter_panel/typewriter_panel.dart";

/// What a ring wraps: the target itself, or the whole table row it sits in.
enum RingBounds { self, tableRow }

/// Where a ring goes: a target to measure each frame, or a node's rect.
@immutable
final class RingGeometry {
  const RingGeometry._(
    this._context,
    this._node,
    this.bounds,
    this.borderRadius,
  );

  final BuildContext? _context;
  final FocusNode? _node;
  final RingBounds bounds;
  final BorderRadiusGeometry borderRadius;

  /// The rect in [scope]'s coordinates and the visible clip, or null when
  /// the target is not laid out.
  (Rect, Rect)? measure(RenderBox scope) {
    final context = _context;
    if (context == null) {
      final node = _node;
      // A node whose widget left the tree has no rect to ring.
      if (node == null || !(node.context?.mounted ?? false)) return null;
      final rect = node.rect;
      final origin = scope.localToGlobal(Offset.zero);
      return (rect.shift(-origin), Rect.largest);
    }
    if (!context.mounted) return null;
    var box = context.findRenderObject();
    if (box is! RenderBox || !box.attached || !box.hasSize) return null;
    var rect = Offset.zero & box.size;
    if (bounds == RingBounds.tableRow) {
      RenderObject? cell = box;
      while (cell != null && cell.parentData is! TableCellParentData) {
        cell = cell.parent;
      }
      final table = cell?.parent;
      if (cell is RenderBox && table is RenderTable) {
        final y = (cell.parentData! as TableCellParentData).y!;
        box = table;
        rect = table.getRowBox(y);
      }
    }
    var clip = Rect.largest;
    var viewport = RenderAbstractViewport.maybeOf(box);
    while (viewport != null) {
      clip = clip.intersect(
        MatrixUtils.transformRect(
          viewport.getTransformTo(scope),
          viewport.paintBounds,
        ),
      );
      viewport = RenderAbstractViewport.maybeOf(viewport.parent);
    }
    return (MatrixUtils.transformRect(box.getTransformTo(scope), rect), clip);
  }

  @override
  bool operator ==(Object other) =>
      other is RingGeometry &&
      other._context == _context &&
      other._node == _node &&
      other.bounds == bounds &&
      other.borderRadius == borderRadius;

  @override
  int get hashCode => Object.hash(_context, _node, bounds, borderRadius);
}

/// Marks [child] as a place a ring wraps when focus is on it or inside it,
/// unless a nearer target inside holds it.
class RingTarget extends StatelessWidget {
  const RingTarget({
    required this.child,
    this.borderRadius = BorderRadius.zero,
    this.bounds = RingBounds.self,
    super.key,
  });

  final Widget child;
  final BorderRadiusGeometry borderRadius;
  final RingBounds bounds;

  /// The ring geometry of the nearest RingTarget at or above [context], or
  /// null when there is none.
  static RingGeometry? geometryAt(BuildContext context) {
    var found = context.widget is _RingTargetMarker ? context : null;
    if (found == null) {
      context.visitAncestorElements((element) {
        if (element.widget is! _RingTargetMarker) return true;
        found = element;
        return false;
      });
    }
    if (found case final BuildContext target) {
      final marker = target.widget as _RingTargetMarker;
      return RingGeometry._(target, null, marker.bounds, marker.borderRadius);
    }
    return null;
  }

  /// The ring geometry for [node]: the nearest RingTarget between the
  /// node's own element and its parent node's element, else the node's
  /// own rect with the control radius. A scope without a RingTarget, such
  /// as a route or the root, has none: only a marked scope, a pane, is
  /// ringed.
  static RingGeometry? geometryOf(
    FocusNode node, {
    BorderRadiusGeometry? fallbackRadius,
  }) {
    final context = node.context;
    if (context == null) return null;
    final stop = node.parent?.context;
    var found = context.widget is _RingTargetMarker ? context : null;
    if (found == null) {
      context.visitAncestorElements((element) {
        if (element == stop) return false;
        if (element.widget is! _RingTargetMarker) return true;
        found = element;
        return false;
      });
    }
    if (found case final BuildContext target) {
      final marker = target.widget as _RingTargetMarker;
      return RingGeometry._(target, null, marker.bounds, marker.borderRadius);
    }
    if (node is FocusScopeNode) return null;
    return RingGeometry._(
      null,
      node,
      RingBounds.self,
      fallbackRadius ?? BorderRadius.circular(context.shapes.medium),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _RingTargetMarker(
      bounds: bounds,
      borderRadius: borderRadius,
      child: child,
    );
  }
}

class _RingTargetMarker extends StatelessWidget {
  const _RingTargetMarker({
    required this.bounds,
    required this.borderRadius,
    required this.child,
  });

  final RingBounds bounds;
  final BorderRadiusGeometry borderRadius;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return child;
  }
}

/// The one ring. It travels with `focusMove` from its last [target] to
/// the next, follows a target that scrolls or reflows without motion,
/// and hides when [target] is null. Place it in a Stack over everything
/// it may ring.
class Ring extends HookWidget {
  const Ring({required this.target, super.key});

  final RingGeometry? target;

  /// Finds the ring in tests.
  static const ringKey = ValueKey<String>("focus ring");

  @override
  Widget build(BuildContext context) {
    final vsync = useTickerProvider();
    final follower = useMemoized(() => _RingFollower(context, vsync));
    useEffect(() => follower.dispose, [follower]);
    final previous = usePrevious(target);
    useEffect(() {
      follower.retarget(
        target,
        appearing: previous == null || !follower.shown.value,
      );
      return null;
    }, [target]);
    final shown = useValueListenable(follower.shown);
    final clip = useValueListenable(follower.clip);
    final ringWidth = context.shapes.ringWidth;
    final ringed = target;
    if (ringed == null || !shown) return const SizedBox.expand();
    return AnimatedBuilder(
      animation: Listenable.merge(follower.edges),
      builder: (context, _) {
        final edges = follower.edges;
        final rect = Rect.fromLTRB(
          edges[0].value,
          edges[1].value,
          edges[2].value,
          edges[3].value,
        ).inflate(ringWidth);
        return ClipRect(
          clipper: _RectClipper(clip, ringWidth),
          child: Stack(
            children: [
              Positioned.fromRect(
                rect: rect,
                child: DecoratedBox(
                  key: Ring.ringKey,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: context.colors.focusRing,
                      width: ringWidth,
                    ),
                    borderRadius: ringed.borderRadius.add(
                      BorderRadius.circular(ringWidth),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Moves the ring's edges to its target, owned by one Ring.
final class _RingFollower {
  _RingFollower(this.context, TickerProvider vsync)
    // Left, top, right and bottom move apart so each keeps its velocity.
    : edges = [for (var i = 0; i < 4; i++) MotionController(vsync: vsync)];

  final BuildContext context;
  final List<MotionController> edges;
  final shown = ValueNotifier(false);
  final clip = ValueNotifier(Rect.largest);
  RingGeometry? _target;
  bool _travelPending = false;
  bool _appearing = true;
  bool _following = false;
  bool _disposed = false;

  void retarget(RingGeometry? target, {required bool appearing}) {
    _target = target;
    if (target == null) {
      shown.value = false;
      return;
    }
    _travelPending = true;
    _appearing = appearing;
    _follow();
  }

  /// Measures after each frame: starts a pending travel, or keeps the ring
  /// on a target that moved without the user moving focus.
  void _follow() {
    if (_following) return;
    _following = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _following = false;
      final target = _target;
      if (_disposed || !context.mounted || target == null) return;
      final scope = context.findRenderObject();
      if (scope is! RenderBox) return;
      final measured = target.measure(scope);
      if (measured != null) {
        final (rect, measuredClip) = measured;
        final targets = [rect.left, rect.top, rect.right, rect.bottom];
        if (_travelPending) {
          _travelPending = false;
          final resolved = resolveMotion(context, MotionToken.focusMove);
          final motion = _appearing ? resolved.instant : resolved;
          for (var i = 0; i < 4; i++) {
            edges[i].to(targets[i], motion);
          }
        } else {
          for (var i = 0; i < 4; i++) {
            final delta = targets[i] - edges[i].target;
            if (delta.abs() > precisionErrorTolerance) edges[i].shift(delta);
          }
        }
        clip.value = measuredClip;
        shown.value = true;
      }
      _follow();
    });
  }

  void dispose() {
    _disposed = true;
    for (final edge in edges) {
      edge.dispose();
    }
    shown.dispose();
    clip.dispose();
  }
}

class _RectClipper extends CustomClipper<Rect> {
  _RectClipper(this.rect, this.ringWidth);

  final Rect rect;
  final double ringWidth;

  @override
  Rect getClip(Size size) => rect.inflate(ringWidth);

  @override
  bool shouldReclip(_RectClipper old) =>
      old.rect != rect || old.ringWidth != ringWidth;
}
