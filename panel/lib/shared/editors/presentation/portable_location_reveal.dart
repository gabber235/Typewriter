import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

/// Where a reveal puts keyboard focus inside the revealed location.
enum RevealFocus {
  /// The location's first field.
  first,

  /// The first field below the location whose bound value is empty, else
  /// the first field: a resource just created.
  firstEmptyField,
}

/// Coordinates the latest navigation request with controls that may mount later.
/// Requests stay pending until a matching ancestor location registers. The most
/// specific mounted target wins, optionally restricted to a presentation role.
/// The caller owns disposal and can invalidate a request through isCurrent.
class PortableLocationRevealController {
  final Map<Object, _LocationTarget> _targets = {};
  skir.ValueLocation? _pending;
  skir.PresentationRole? _pendingPresentation;
  RevealFocus _pendingFocus = RevealFocus.first;
  bool Function()? _pendingIsCurrent;
  bool _scheduled = false;
  bool _closed = false;

  void request(
    skir.ValueLocation location, {
    skir.PresentationRole? presentation,
    RevealFocus focus = RevealFocus.first,
    bool Function()? isCurrent,
  }) {
    if (_closed) return;
    _pending = location;
    _pendingPresentation = presentation;
    _pendingFocus = focus;
    _pendingIsCurrent = isCurrent;
    _schedule();
  }

  void _register(
    Object id,
    skir.ValueLocation location,
    void Function(RevealFocus focus) reveal,
    skir.PresentationRole? presentation, {
    required FocusNode focus,
    bool Function()? isEmpty,
  }) {
    if (_closed) return;
    _targets[id] = _LocationTarget(
      location,
      reveal,
      presentation,
      focus: focus,
      isEmpty: isEmpty,
    );
    _schedule();
  }

  /// The registered fields below [location] whose bound value is empty, in
  /// registration order.
  Iterable<FocusNode> _emptyFieldsUnder(skir.ValueLocation location) => [
    for (final target in _targets.values)
      if (target.location.resource == location.resource &&
          target.location.path.isAtOrBelow(location.path) &&
          (target.isEmpty?.call() ?? false))
        target.focus,
  ];

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
      final focus = _pendingFocus;
      _pending = null;
      _pendingPresentation = null;
      _pendingFocus = RevealFocus.first;
      _pendingIsCurrent = null;
      candidates.first.reveal(focus);
    });
    // A post frame callback alone waits for whatever draws the next frame; an
    // idle panel draws none.
    WidgetsBinding.instance.ensureVisualUpdate();
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
  const _LocationTarget(
    this.location,
    this.reveal,
    this.presentation, {
    required this.focus,
    this.isEmpty,
  });
  final skir.PresentationRole? presentation;
  final skir.ValueLocation location;
  final void Function(RevealFocus focus) reveal;

  /// The target's marker node; its fields are below it.
  final FocusNode focus;

  /// Whether the field's bound value is empty; null for a block of fields.
  final bool Function()? isEmpty;
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
/// Its node marks the fields as an item, so a pane's open focus lands on the
/// first field.
class PortableLocationTarget extends HookWidget {
  const PortableLocationTarget({
    required this.location,
    required this.child,
    this.onFocusChange,
    this.focusWhenEmpty = false,
    this.isEmpty,
    super.key,
  });
  final ValueChanged<bool>? onFocusChange;
  final skir.ValueLocation? location;
  final Widget child;

  /// Lets an inspection root receive focus when all controls are read only.
  final bool focusWhenEmpty;

  /// Whether the field's bound value is empty, for
  /// [RevealFocus.firstEmptyField]; null for a block of fields.
  final bool Function()? isEmpty;
  @override
  Widget build(BuildContext context) {
    final scope = PortableLocationRevealScope.maybeOf(context);
    final controller = scope?.controller;
    final identity = useMemoized(Object.new);
    final focus = useMemoized(
      () => ItemFocusNode(
        debugLabel: "Authored location",
        skipTraversal: true,
        canRequestFocus: focusWhenEmpty,
      ),
    );
    useEffect(() => focus.dispose, [focus]);
    useEffect(() {
      Pane.offerOpenFocus(context);
      return null;
    }, const []);
    useEffect(() {
      if (controller == null || location == null) return null;
      controller._register(
        identity,
        location!,
        (mode) {
          if (!context.mounted) return;
          final move = motionTimeline(context, MotionToken.focusMove);
          unawaited(
            Scrollable.ensureVisible(
              context,
              alignment: .25,
              duration: move.duration,
              curve: move.curve,
            ),
          );
          final first = focus.traversalDescendants.firstOrNull;
          final target = switch (mode) {
            RevealFocus.first => first,
            RevealFocus.firstEmptyField =>
              controller
                      ._emptyFieldsUnder(location!)
                      .firstOrNull
                      ?.traversalDescendants
                      .firstOrNull ??
                  first,
          };
          if (target != null) {
            target.requestFocus();
          } else if (focusWhenEmpty) {
            focus.requestFocus();
          }
        },
        scope?.presentation,
        focus: focus,
        isEmpty: () => isEmpty?.call() ?? false,
      );
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
