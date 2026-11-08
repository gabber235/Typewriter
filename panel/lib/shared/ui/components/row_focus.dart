part of "animated_rows.dart";

/// A focus node that marks an item: Pane open focus and popups land on it.
/// PortableLocationTarget uses it bare to mark a block of fields.
base class ItemFocusNode extends FocusNode {
  ItemFocusNode({super.debugLabel, super.canRequestFocus, super.skipTraversal});
}

/// The focus node of one row entry: created with the entry, disposed with
/// it.
final class RowFocusNode extends ItemFocusNode {
  RowFocusNode._(this.entry, this.owner) : super(debugLabel: "Row ${entry.id}");

  /// The row this node belongs to.
  final RowEntry<Object?> entry;

  /// The list focus that moves focus between the rows of this list.
  final RowFocus owner;
}

/// What a row's node is in the tree.
enum RowRole {
  /// The row is one focus stop: table rows, cards, organization rows.
  stop,

  /// The row holds controls and is no stop (editor collections); focus
  /// lands on its [RowLanding].
  holder,

  /// Another part of a row whose stop is elsewhere: a table cell beside the
  /// stop cell, or a card body below its header.
  part,
}

/// Keyboard focus one list owns by row identity. Focus moves inside the
/// list's diff: a removed focused row hands focus to the next survivor,
/// else the previous one, else the enclosing scope; a row announced with
/// [expect] takes focus when it arrives. Other arrivals and removals never
/// move focus. RowFocus keeps no nodes of its own: order and nodes come from
/// the entries of the list it serves.
final class RowFocus {
  RowFocus({this.debugLabel}) {
    FocusManager.instance.addListener(_primaryChanged);
  }

  final String? debugLabel;

  AnimatedRows<Object?>? _rows;

  // Focused most recently in its route; survives a dialog.
  Object? _last;

  // Announced by expect, focused on arrival.
  Object? _expected;

  // A move waiting for focus to come back from another route.
  _Handoff? _handoff;

  /// The identity of the row focused last in its route, or null.
  Object? get focusedId => _last;

  /// The identities of the rows not leaving, in screen order.
  List<Object> get order => [
    for (final entry in _rows?.entries ?? const <RowEntry<Object?>>[])
      if (entry.phase != RowPhase.leaving) entry.id,
  ];

  /// The focus node of the row of [id], such as a graph card's Selector
  /// node, while the row is on screen.
  FocusNode? nodeOf(Object id) => _rows?[id]?.focus;

  /// The controls in the part cells of the row of [id], in cell order: what
  /// Right and Left reach from a table row.
  /// A part cell keeps its controls out of Tab, so each control is the
  /// outermost node that can take focus.
  List<FocusNode> controlsOf(Object id) => [
    for (final part in _rows?[id]?._parts ?? const <_RowPartNode>[])
      ...part.descendants.where(
        (node) =>
            node.canRequestFocus &&
            node.ancestors
                .takeWhile((parent) => parent != part)
                .every((parent) => !parent.canRequestFocus),
      ),
  ];

  /// The survivor focus moves to when every identity in [leaving] goes: the
  /// first survivor after [from] (default: the focused identity), else the
  /// last survivor before it, else null (the scope).
  Object? heirOf(Set<Object> leaving, {Object? from}) {
    final ids = order;
    final anchor = from ?? _last;
    final at = anchor == null ? -1 : ids.indexOf(anchor);
    if (at < 0) return null;
    bool survives(Object id) => !leaving.contains(id);
    return ids.skip(at + 1).firstWhereOrNull(survives) ??
        ids.take(at).lastWhereOrNull(survives);
  }

  /// Moves focus to the row of [id], such as the first row a hold was
  /// refused on.
  void focusId(Object id) {
    final entry = _rows?[id];
    if (entry == null || entry.phase == RowPhase.leaving) return;
    _handoff = null;
    _last = id;
    // A node not yet attached takes focus when its row mounts.
    _landingOf(entry).requestFocus();
  }

  /// Moves focus to the row at [index] in [order], clamped to the ends.
  void focusAt(int index) {
    final ids = order;
    if (ids.isNotEmpty) focusId(ids[index.clamp(0, ids.length - 1)]);
  }

  /// Focuses the row of [id] when it arrives, or now when it is already
  /// here: this user's create.
  void expect(Object id) {
    final entry = _rows?[id];
    if (entry != null && entry.phase != RowPhase.leaving) return focusId(id);
    _expected = id;
  }

  void _detach(AnimatedRows<Object?> rows) {
    if (identical(_rows, rows)) _rows = null;
  }

  void _watch(RowFocusNode node) => node.addListener(() {
    if (node.hasFocus && node.entry.phase != RowPhase.leaving) {
      _last = node.entry.id;
      _handoff = null;
    }
  });

  /// Runs inside the list's diff, before the rows of [leaving] start to
  /// leave, so the Flutter default (focus falls to the enclosing scope)
  /// never runs first.
  void _leaving(Set<Object> leaving) {
    final last = _last;
    if (last == null || !leaving.contains(last)) return;
    // The order before the change.
    final heir = heirOf(leaving, from: last);
    _hand(from: _rows![last]!, to: heir == null ? null : _rows![heir]);
    _last = heir;
  }

  /// Runs after the list merged its entries.
  void _arrived() {
    final expected = _expected;
    if (expected == null) return;
    final entry = _rows?[expected];
    if (entry == null || entry.phase == RowPhase.leaving) return;
    _expected = null;
    // The row mounts after this build, and a holder's landing with it.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_rows?[expected]?.phase case final phase?
          when phase != RowPhase.leaving) {
        focusId(expected);
      }
    });
  }

  /// The node focus lands on: the row when it is a stop, else its
  /// [RowLanding] control, else its first control.
  FocusNode _landingOf(RowEntry<Object?> entry) {
    final row = entry.focus;
    if (row.canRequestFocus) return row;
    final controls = row.traversalDescendants;
    bool landing(FocusNode node) => node.ancestors
        .takeWhile((parent) => parent != row)
        .any((parent) => parent is _LandingNode);
    return controls.firstWhereOrNull(landing) ?? controls.firstOrNull ?? row;
  }

  void _hand({
    required RowEntry<Object?> from,
    required RowEntry<Object?>? to,
  }) {
    final context = from.focus.context;
    final route = context == null ? null : ModalRoute.of(context);
    // The route's own scope is private to Flutter, so every scope around the
    // row stands for "focus came back".
    final scopes = {
      for (final ancestor in from.focus.ancestors)
        if (ancestor is FocusScopeNode) ancestor,
    };
    final primary = FocusManager.instance.primaryFocus;
    if (primary != null && _idOf(primary) == from.id) {
      // The leaving row, or a control inside it, holds focus: move now.
      if (to != null) {
        _landingOf(to).requestFocus();
      } else {
        primary.unfocus(disposition: UnfocusDisposition.scope);
      }
      return;
    }
    // A dialog over the page holds focus. Move when focus comes back.
    _handoff = _Handoff(fromId: from.id, to: to, scopes: scopes, route: route);
  }

  void _primaryChanged() {
    final primary = FocusManager.instance.primaryFocus;
    if (primary == null) return;
    final primaryContext = primary.context;
    final primaryRoute = primaryContext == null || !primaryContext.mounted
        ? null
        : ModalRoute.of(primaryContext);
    final handoff = _handoff;
    if (handoff != null) {
      // Still away.
      if (primaryRoute != null && primaryRoute != handoff.route) return;
      _handoff = null;
      final returned =
          primaryRoute == null ||
          handoff.scopes.contains(primary) ||
          _idOf(primary) == handoff.fromId;
      // The user chose something else meanwhile.
      if (!returned) return;
      final to = handoff.to;
      // Without an heir, focus already came back to the scope.
      if (to != null && to.phase != RowPhase.leaving) {
        _landingOf(to).requestFocus();
      }
      return;
    }
    // A control in a part cell of another row, such as a pointer press on
    // its roles field, makes that row the focused one.
    final held = _idOf(primary);
    if (held != null) {
      if (_rows?[held]?.phase != RowPhase.leaving) _last = held;
      return;
    }
    // Focus moved on inside the same route: forget the last row.
    final last = _last;
    if (last == null) return;
    final lastContext = _rows?[last]?.focus.context;
    final lastRoute = lastContext == null || !lastContext.mounted
        ? null
        : ModalRoute.of(lastContext);
    if (primaryRoute == lastRoute) _last = null;
  }

  /// The identity whose row holds [node]: the row node, a control inside
  /// it, or a control inside a part cell of the same row.
  Object? _idOf(FocusNode node) {
    for (FocusNode? n = node; n != null; n = n.parent) {
      if (n is RowFocusNode && n.owner == this) return n.entry.id;
      if (n is _RowPartNode && n.entry.focus.owner == this) return n.entry.id;
    }
    return null;
  }

  /// Stops listening to focus changes; the nodes belong to the entries.
  void dispose() => FocusManager.instance.removeListener(_primaryChanged);
}

final class _Handoff {
  const _Handoff({
    required this.fromId,
    required this.to,
    required this.scopes,
    required this.route,
  });

  final Object fromId;

  // Null: the enclosing scope keeps focus.
  final RowEntry<Object?>? to;
  final Set<FocusScopeNode> scopes;
  final ModalRoute<Object?>? route;
}

/// A [RowFocus] that outlives rebuilds, for a parent that passes it to
/// [useAnimatedRows], such as one that announces creates from outside the
/// list.
RowFocus useRowFocus({String? debugLabel}) {
  final focus = useMemoized(() => RowFocus(debugLabel: debugLabel));
  useEffect(() => focus.dispose, [focus]);
  return focus;
}

/// Gives [RowStop], [RowFocusKeys] and row hooks the list's [RowFocus].
class RowFocusScope extends InheritedWidget {
  const RowFocusScope({required this.focus, required super.child, super.key});

  final RowFocus focus;

  static RowFocus of(BuildContext context) => maybeOf(context)!;

  static RowFocus? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<RowFocusScope>()?.focus;

  @override
  bool updateShouldNotify(RowFocusScope oldWidget) => focus != oldWidget.focus;
}

/// The row entry a renderer is building, for the [RowStop] inside it.
class RowEntryScope extends InheritedWidget {
  const RowEntryScope({
    required this.entry,
    required super.child,
    this.partsTraversable = true,
    super.key,
  });

  final RowEntry<Object?> entry;

  /// Whether Tab reaches the controls of the row's part cells. A table
  /// keeps them out, since Right and Left reach them from the row.
  final bool partsTraversable;

  static RowEntry<Object?>? maybeOf(BuildContext context) =>
      _scopeOf(context)?.entry;

  static RowEntryScope? _scopeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<RowEntryScope>();

  @override
  bool updateShouldNotify(RowEntryScope oldWidget) =>
      entry != oldWidget.entry ||
      partsTraversable != oldWidget.partsTraversable;
}

/// Puts the enclosing row entry's focus in the tree with its ring. A row
/// places it inside its own action set, since an action set answers keys
/// only while focus is inside it. Outside a list it is its child.
class RowStop extends HookWidget {
  const RowStop({
    required this.child,
    this.role = RowRole.stop,
    this.onActivate,
    this.borderRadius,
    this.bounds = RingBounds.self,
    this.label,
    super.key,
  });

  final RowRole role;

  /// What a screen reader announces when the stop takes focus, for a row
  /// whose own content forms separate semantics nodes: the member's name.
  final String? label;

  /// Enter and Space when the row opens something.
  final VoidCallback? onActivate;
  final BorderRadiusGeometry? borderRadius;

  /// [RingBounds.tableRow] draws the ring around the whole table row.
  final RingBounds bounds;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scope = RowEntryScope._scopeOf(context);
    final entry = scope?.entry;
    final part = useMemoized(
      () => entry != null && role == RowRole.part ? _RowPartNode(entry) : null,
      [entry, role],
    );
    useEffect(() {
      if (part == null) return null;
      part.entry._parts.add(part);
      return () {
        part.entry._parts.remove(part);
        part.dispose();
      };
    }, [part]);
    // A row that mounts may be the first item a primary pane waits for.
    useEffect(() {
      if (role != RowRole.part) Pane.offerOpenFocus(context);
      return null;
    }, const []);
    if (entry == null) return child;
    if (part != null) {
      // In a table Tab passes over the cell's controls; Right and Left
      // reach them from the row (RowFocusKeys).
      return Focus(
        focusNode: part,
        canRequestFocus: false,
        skipTraversal: true,
        descendantsAreTraversable: scope!.partsTraversable,
        includeSemantics: false,
        child: child,
      );
    }
    final stop = role == RowRole.stop;
    final named = stop && label != null;
    Widget focused = Focus(
      focusNode: entry.focus,
      // Fixed for the row's life: turning canRequestFocus off on a focused
      // node would unfocus it and override the heir.
      canRequestFocus: stop,
      skipTraversal: !stop,
      includeSemantics: stop && !named,
      child: child,
    );
    if (named) {
      // Its own node, so the name never merges into a control inside.
      focused = ListenableBuilder(
        listenable: entry.focus,
        builder: (context, child) => Semantics(
          container: true,
          focusable: true,
          focused: entry.focus.hasFocus,
          label: label,
          child: child,
        ),
        child: focused,
      );
    }
    if (!stop) return focused;
    return RingTarget(
      borderRadius: borderRadius ?? BorderRadius.zero,
      bounds: bounds,
      child: Actions(
        actions: {
          if (onActivate case final activate?)
            ActivateIntent: CallbackAction<ActivateIntent>(
              onInvoke: (_) => activate(),
            ),
        },
        child: focused,
      ),
    );
  }
}

/// Marks a table cell's controls as part of the row, so focus on a roles
/// dropdown or an actions button still counts as the row.
final class _RowPartNode extends FocusNode {
  _RowPartNode(this.entry) : super(canRequestFocus: false, skipTraversal: true);

  final RowEntry<Object?> entry;
}

/// Marks the control focus lands on in a holder row: the disclosure, else
/// Remove.
class RowLanding extends HookWidget {
  const RowLanding({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final node = useMemoized(_LandingNode.new);
    useEffect(() => node.dispose, [node]);
    return Focus(
      focusNode: node,
      canRequestFocus: false,
      skipTraversal: true,
      includeSemantics: false,
      child: child,
    );
  }
}

final class _LandingNode extends FocusNode {
  _LandingNode() : super(canRequestFocus: false, skipTraversal: true);
}

/// The first item under a focus scope, where open focus lands.
extension FirstItemFocus on FocusScopeNode {
  /// The first item in tree order: a traversable row stop, or the first
  /// traversable control inside a holder row or a field marker.
  /// [traversalDescendants] is post order, so the outermost item is
  /// resolved explicitly.
  FocusNode? get firstItem {
    for (final node in traversalDescendants) {
      ItemFocusNode? outer;
      for (FocusNode? n = node; n != null && n != this; n = n.parent) {
        if (n is ItemFocusNode) outer = n;
      }
      if (outer == null) continue;
      final rowIsStop = outer.canRequestFocus && !outer.skipTraversal;
      return rowIsStop ? outer : node;
    }
    return null;
  }
}
