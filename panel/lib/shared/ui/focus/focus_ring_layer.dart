import "package:typewriter_panel/typewriter_panel.dart";

/// The panel's one focus ring. It follows the claimed [RingCursor], else
/// primary focus, to its [RingTarget] and travels there with `focusMove`,
/// across panes too, at every window size.
///
/// Pointer focus shows no ring, and neither does a field being typed in,
/// since that field shows its own focused border.
class FocusRingLayer extends HookWidget {
  const FocusRingLayer({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final focused = useState<RingGeometry?>(null);
    final cursor = useMemoized(_Cursor.new);
    useEffect(() => cursor.dispose, [cursor]);
    final claimed = useValueListenable(cursor);
    final fallbackRadius = BorderRadius.circular(context.shapes.medium);
    useEffect(() {
      final manager = FocusManager.instance;
      var active = true;
      var pending = false;

      /// The geometry for primary focus, read once the frame settled so
      /// the focused element is active.
      RingGeometry? resolve() {
        final node = manager.primaryFocus;
        final context = node?.context;
        if (node == null || context == null || !context.mounted) return null;
        if (manager.highlightMode != FocusHighlightMode.traditional) {
          return null;
        }
        // A field being typed in shows its own focused border.
        if (context.findAncestorWidgetOfExactType<EditableText>() != null) {
          return null;
        }
        return RingTarget.geometryOf(node, fallbackRadius: fallbackRadius);
      }

      void follow() {
        if (pending) return;
        pending = true;
        SchedulerBinding.instance
          ..addPostFrameCallback((_) {
            pending = false;
            if (active) focused.value = resolve();
          })
          ..ensureVisualUpdate();
      }

      void modeChanged(FocusHighlightMode mode) => follow();

      manager
        ..addListener(follow)
        ..addHighlightModeListener(modeChanged);
      follow();
      return () {
        active = false;
        manager
          ..removeListener(follow)
          ..removeHighlightModeListener(modeChanged);
      };
    }, const []);
    return _RingCursorScope(
      cursor: cursor,
      child: Stack(
        children: [
          child,
          Positioned.fill(
            child: IgnorePointer(child: Ring(target: claimed ?? focused.value)),
          ),
        ],
      ),
    );
  }
}

/// The claimed cursor's geometry. A claim or release lands after a frame,
/// when the layer may be gone, so it can tell whether it was disposed.
final class _Cursor extends ValueNotifier<RingGeometry?> {
  _Cursor() : super(null);

  bool disposed = false;

  @override
  void dispose() {
    disposed = true;
    super.dispose();
  }
}

class _RingCursorScope extends InheritedWidget {
  const _RingCursorScope({required this.cursor, required super.child});

  final _Cursor cursor;

  static _Cursor? maybeOf(BuildContext context) =>
      context.getInheritedWidgetOfExactType<_RingCursorScope>()?.cursor;

  @override
  bool updateShouldNotify(_RingCursorScope oldWidget) =>
      cursor != oldWidget.cursor;
}

/// Marks [child] as a list's cursor: while [active], the ring wraps it
/// instead of the focused node. Use it only where the highlighted row is
/// not real focus, such as search results under a focused query field.
class RingCursor extends StatelessWidget {
  const RingCursor({
    required this.active,
    required this.child,
    this.borderRadius = BorderRadius.zero,
    super.key,
  });

  final bool active;
  final BorderRadiusGeometry borderRadius;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return RingTarget(
      borderRadius: borderRadius,
      child: _CursorClaim(active: active, child: child),
    );
  }
}

/// Sits inside the [RingTarget] so `geometryAt` finds it from this context.
class _CursorClaim extends HookWidget {
  const _CursorClaim({required this.active, required this.child});

  final bool active;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final cursor = _RingCursorScope.maybeOf(context);
    useEffect(() {
      if (!active || cursor == null) return null;
      final geometry = RingTarget.geometryAt(context);
      // Claims change an ancestor, so they wait for the frame to end.
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (context.mounted && !cursor.disposed) cursor.value = geometry;
      });
      return () {
        // Release only this claim; the next row may have claimed already.
        SchedulerBinding.instance.addPostFrameCallback((_) {
          if (!cursor.disposed && cursor.value == geometry) {
            cursor.value = null;
          }
        });
      };
    }, [active, cursor]);
    return child;
  }
}
