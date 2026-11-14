import "package:typewriter_panel/typewriter_panel.dart";

/// Keys of a table whose rows are one focus stop each: Tab and Shift+Tab
/// leave the table, Up, Down, J and K move between rows, Home and End reach
/// the ends, Left, Right, H and L move between a row and its controls.
class RowFocusKeys extends HookWidget {
  const RowFocusKeys({required this.focus, required this.child, super.key});

  final RowFocus focus;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final table = useFocusNode(canRequestFocus: false, skipTraversal: true);
    bool typing() =>
        FocusManager.instance.primaryFocus?.context?.widget is EditableText;

    void leave({required bool forward}) {
      final stops = table.traversalDescendants.toList();
      if (stops.isEmpty) return;
      // Traversal moves from the scope's focused child, which a request
      // sets at once; so the edge row becomes it first. Tree order is row
      // major, which is also reading order for a table.
      if (forward) {
        stops.last
          ..requestFocus()
          ..nextFocus();
      } else {
        stops.first
          ..requestFocus()
          ..previousFocus();
      }
    }

    // Right and Left walk the focused row: its stop, then its part cell
    // controls in cell order.
    void across(TraversalDirection direction) {
      final primary = FocusManager.instance.primaryFocus;
      final id = focus.focusedId;
      final row = id == null ? null : focus.nodeOf(id);
      if (primary == null || id == null || row == null) {
        primary?.focusInDirection(direction);
        return;
      }
      final walk = [row, ...focus.controlsOf(id)];
      final at = walk.indexWhere(
        (node) => node == primary || primary.ancestors.contains(node),
      );
      if (at < 0) return;
      final next = at + (direction == TraversalDirection.right ? 1 : -1);
      if (next >= 0 && next < walk.length) walk[next].requestFocus();
    }

    void moveRow(int delta) {
      final at = focus.order.indexOf(focus.focusedId ?? const Object());
      focus.focusAt(at < 0 ? 0 : at + delta);
    }

    return Shortcuts(
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.keyJ): DirectionalFocusIntent(
          TraversalDirection.down,
        ),
        SingleActivator(LogicalKeyboardKey.keyK): DirectionalFocusIntent(
          TraversalDirection.up,
        ),
        SingleActivator(LogicalKeyboardKey.keyH): DirectionalFocusIntent(
          TraversalDirection.left,
        ),
        SingleActivator(LogicalKeyboardKey.keyL): DirectionalFocusIntent(
          TraversalDirection.right,
        ),
      },
      child: Actions(
        actions: {
          NextFocusIntent: CallbackAction<NextFocusIntent>(
            onInvoke: (_) => leave(forward: true),
          ),
          PreviousFocusIntent: CallbackAction<PreviousFocusIntent>(
            onInvoke: (_) => leave(forward: false),
          ),
          FirstItemIntent: CallbackAction<FirstItemIntent>(
            onInvoke: (_) => focus.focusAt(0),
          ),
          LastItemIntent: CallbackAction<LastItemIntent>(
            onInvoke: (_) => focus.focusAt(focus.order.length - 1),
          ),
          DirectionalFocusIntent: _RowDirection(
            enabled: () => !typing(),
            onVertical: moveRow,
            onHorizontal: across,
          ),
        },
        child: Focus(focusNode: table, child: child),
      ),
    );
  }
}

class _RowDirection extends ContextAction<DirectionalFocusIntent> {
  _RowDirection({
    required this.enabled,
    required this.onVertical,
    required this.onHorizontal,
  });

  final bool Function() enabled;
  final void Function(int delta) onVertical;
  final void Function(TraversalDirection direction) onHorizontal;

  @override
  bool isEnabled(DirectionalFocusIntent intent, [BuildContext? context]) =>
      enabled();

  @override
  void invoke(DirectionalFocusIntent intent, [BuildContext? context]) {
    switch (intent.direction) {
      case TraversalDirection.down:
        onVertical(1);
      case TraversalDirection.up:
        onVertical(-1);
      case TraversalDirection.left || TraversalDirection.right:
        onHorizontal(intent.direction);
    }
  }
}
