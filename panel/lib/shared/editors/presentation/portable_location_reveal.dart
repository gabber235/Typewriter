import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

/// Coordinates the latest navigation request with controls that may mount later.
/// Requests stay pending until a matching ancestor location registers. The most
/// specific mounted target wins, optionally restricted to a presentation role.
/// The caller owns disposal and can invalidate a request through isCurrent.
class PortableLocationRevealController {
  final Map<Object, _LocationTarget> _targets = {};
  skir.ValueLocation? _pending;
  skir.PresentationRole? _pendingPresentation;
  bool Function()? _pendingIsCurrent;
  bool _scheduled = false;
  bool _closed = false;

  void request(
    skir.ValueLocation location, {
    skir.PresentationRole? presentation,
    bool Function()? isCurrent,
  }) {
    if (_closed) return;
    _pending = location;
    _pendingPresentation = presentation;
    _pendingIsCurrent = isCurrent;
    _schedule();
  }

  void _register(
    Object id,
    skir.ValueLocation location,
    VoidCallback reveal,
    skir.PresentationRole? presentation,
  ) {
    if (_closed) return;
    _targets[id] = _LocationTarget(location, reveal, presentation);
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
      if (!(_pendingIsCurrent?.call() ?? true)) {
        _pending = null;
        _pendingIsCurrent = null;
        return;
      }
      final candidates =
          _targets.values
              .where(
                (target) =>
                    target.location.resource == pending.resource &&
                    (_pendingPresentation == null ||
                        target.presentation == _pendingPresentation) &&
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
      _pendingPresentation = null;
      _pendingIsCurrent = null;
      candidates.first.reveal();
    });
  }

  void dispose() {
    _closed = true;
    _pending = null;
    _pendingPresentation = null;
    _pendingIsCurrent = null;
    _targets.clear();
  }
}

final class _LocationTarget {
  const _LocationTarget(this.location, this.reveal, this.presentation);
  final skir.PresentationRole? presentation;
  final skir.ValueLocation location;
  final VoidCallback reveal;
}

class PortableLocationRevealScope extends InheritedWidget {
  const PortableLocationRevealScope({
    required this.controller,
    required super.child,
    this.presentation,
    super.key,
  });
  final PortableLocationRevealController controller;
  final skir.PresentationRole? presentation;
  static PortableLocationRevealScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<PortableLocationRevealScope>();
  @override
  bool updateShouldNotify(PortableLocationRevealScope oldWidget) =>
      controller != oldWidget.controller ||
      presentation != oldWidget.presentation;
}

/// Registers the actual control subtree for scrolling and keyboard focus.
class PortableLocationTarget extends HookWidget {
  const PortableLocationTarget({
    required this.location,
    required this.child,
    this.onFocusChange,
    this.focusWhenEmpty = false,
    super.key,
  });
  final ValueChanged<bool>? onFocusChange;
  final skir.ValueLocation? location;
  final Widget child;

  /// Lets an inspection root receive focus when all controls are read only.
  final bool focusWhenEmpty;
  @override
  Widget build(BuildContext context) {
    final scope = PortableLocationRevealScope.maybeOf(context);
    final controller = scope?.controller;
    final identity = useMemoized(Object.new);
    final focus = useMemoized(
      () => FocusNode(
        debugLabel: "Authored location",
        skipTraversal: true,
        canRequestFocus: focusWhenEmpty,
      ),
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
        if (target != null) {
          target.requestFocus();
        } else if (focusWhenEmpty) {
          focus.requestFocus();
        }
      }, scope?.presentation);
      return () => controller._targets.remove(identity);
    }, [controller, location, scope?.presentation, focusWhenEmpty]);
    return Focus(
      focusNode: focus,
      canRequestFocus: focusWhenEmpty,
      onFocusChange: onFocusChange,
      child: child,
    );
  }
}
