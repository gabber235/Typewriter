import "package:typewriter_panel/typewriter_panel.dart";

/// One surface of selectables, such as a resource list or a graph, that
/// tells the selection its items in visible order.
///
/// A Shift click or Shift with an arrow selects a range in this order, and
/// select all ([SelectEveryIntent], Command or Control+A) selects every item
/// in it, and Escape clears the selection while focus is in it. Every
/// [Selector] below registers itself, and the order is where
/// those items sit on screen: top to bottom, then in reading direction.
/// A surface that builds only some of its items, such as a graph that skips
/// nodes off screen, passes [order] instead when it knows their visible
/// order, or [every] when it knows only which items it holds, so select all
/// still reaches every item.
class SelectionSurface extends HookConsumerWidget {
  const SelectionSurface({
    required this.child,
    this.order,
    this.every,
    super.key,
  });

  /// Every item of the surface in visible order, for a surface that does
  /// not build them all; null orders the registered selectors by position.
  final List<SelectableIdentifier>? order;

  /// Every item of the surface in any order, for a surface that does not
  /// build them all nor know where they sit; ranges still follow the
  /// registered selectors' positions. Ignored when [order] is given.
  final List<SelectableIdentifier>? every;
  final Widget child;

  /// The surface around [context], or null outside every surface.
  static SelectionSurfaceItems? maybeOf(BuildContext context) =>
      context.getInheritedWidgetOfExactType<_SelectionSurfaceScope>()?.items;

  /// The surface around the primary focus, or null outside every surface.
  static SelectionSurfaceItems? ofPrimaryFocus() {
    final context = FocusManager.instance.primaryFocus?.context;
    return context == null ? null : maybeOf(context);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = useMemoized(SelectionSurfaceItems._)
      .._explicit = order
      .._every = every;
    return _SelectionSurfaceScope(
      items: items,
      child: ManagedActionSet(
        shortcuts: [
          ...ref.watch(selectionClearingShortcutsProvider),
          if (ref.watch(selectionShortcutsEnabledProvider))
            ActionShortcut.intent(
              id: "select_every",
              label: "Select All",
              description:
                  "Select every item here, or clear the selection when all "
                  "of them are selected",
              intent: SelectEveryIntent,
              priority: -10,
              run: ActionRun.press(
                (ref) =>
                    ref.read(selectionProvider.notifier).selectEvery(items.all),
              ),
            ),
        ],
        child: child,
      ),
    );
  }
}

/// The items of one [SelectionSurface]: the selectors registered in it, or
/// the order the surface passed.
final class SelectionSurfaceItems {
  SelectionSurfaceItems._();

  final _registered = <BuildContext, SelectableIdentifier>{};
  List<SelectableIdentifier>? _explicit;
  List<SelectableIdentifier>? _every;

  /// Adds the selector at [context] showing [id]; the returned callback
  /// removes it again.
  VoidCallback register(BuildContext context, SelectableIdentifier id) {
    _registered[context] = id;
    return () {
      if (_registered[context] == id) _registered.remove(context);
    };
  }

  /// Whether [id] is an item of this surface.
  bool contains(SelectableIdentifier id) =>
      _explicit?.contains(id) ??
      _every?.contains(id) ??
      _registered.containsValue(id);

  /// Every item of the surface, built or not, the ones on screen first in
  /// visible order.
  List<SelectableIdentifier> get all {
    final placed = order;
    return [
      ...placed,
      for (final id in _every ?? const <SelectableIdentifier>[])
        if (!placed.contains(id)) id,
    ];
  }

  /// Every item of the surface in visible order.
  List<SelectableIdentifier> get order {
    if (_explicit case final explicit?) return explicit;
    final placed = <(SelectableIdentifier, Offset)>[];
    var rightToLeft = false;
    for (final MapEntry(key: context, value: id) in _registered.entries) {
      if (!context.mounted) continue;
      final box = context.findRenderObject();
      if (box is! RenderBox || !box.attached || !box.hasSize) continue;
      placed.add((id, box.localToGlobal(Offset.zero)));
      rightToLeft = Directionality.maybeOf(context) == TextDirection.rtl;
    }
    placed.sort((left, right) {
      final (_, a) = left;
      final (_, b) = right;
      // Items less than a pixel apart sit on one line.
      if ((a.dy - b.dy).abs() >= 1) return a.dy.compareTo(b.dy);
      return rightToLeft ? b.dx.compareTo(a.dx) : a.dx.compareTo(b.dx);
    });
    final seen = <SelectableIdentifier>{};
    return [
      for (final (id, _) in placed)
        if (seen.add(id)) id,
    ];
  }
}

class _SelectionSurfaceScope extends InheritedWidget {
  const _SelectionSurfaceScope({required this.items, required super.child});

  final SelectionSurfaceItems items;

  @override
  bool updateShouldNotify(_SelectionSurfaceScope oldWidget) =>
      items != oldWidget.items;
}
