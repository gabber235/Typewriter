import "package:typewriter_panel/typewriter_panel.dart";

part "row_focus.dart";

/// How a row came to be on screen; fixed for the row's life.
enum RowArrival {
  /// Present when the content loaded; it joins the load run.
  load,

  /// Added after the load; it slides in with rowIn.
  insert,
}

/// Where a row is in its life on screen.
enum RowPhase {
  /// Added after the load; sliding in with rowIn.
  arriving,

  /// In place.
  present,

  /// Gone from the data; squashing shut with listOut.
  leaving,
}

/// Where the command a user ran on the row stands; independent of
/// [RowPhase].
enum RowRun {
  /// No command runs.
  idle,

  /// A removal command runs or has succeeded and the data has not dropped
  /// the item yet. The row is struck through and busy, and stays so while
  /// it leaves.
  sending,
}

/// One row of an animated list, keyed by its item's identity.
/// [useAnimatedRows] creates it when the identity first appears and
/// disposes it once the row has left. Per row state of later work lands
/// here as typed fields, each disposed in [_dispose].
final class RowEntry<T> {
  RowEntry._({
    required this.id,
    required this._item,
    required this.arrival,
    required this.presence,
    required RowFocus focusOwner,
  }) : _phase = arrival == RowArrival.load
           ? RowPhase.present
           : RowPhase.arriving,
       _slides = arrival == RowArrival.insert {
    focus = RowFocusNode._(this, focusOwner);
  }

  /// The identity given to [useAnimatedRows]; the row's only id.
  final Object id;

  /// How the row came to be on screen.
  final RowArrival arrival;

  /// Presence from 0 (gone) to 1 (in place). One controller for the row's
  /// life; it ticks only while the row moves.
  final MotionController presence;

  /// The row's focus node. [RowStop] puts it in the tree.
  late final RowFocusNode focus;

  // The part cells of a table row; each RowStop of the part role adds and
  // removes its own.
  final _parts = <_RowPartNode>[];

  /// The latest item with this identity; kept while the row leaves.
  T get item => _item;
  T _item;

  /// Presence on screen; only the data and the motion move it.
  RowPhase get phase => _phase;
  RowPhase _phase;

  /// The user's command on the row; only [AnimatedRows.sending] moves it.
  RowRun get run => _run;
  RowRun _run = RowRun.idle;

  /// Whether the row was still arriving when it started to leave.
  bool get leftWhileArriving => _leftWhileArriving;
  bool _leftWhileArriving = false;

  // Which look [presence] drives: the slide of rowIn, the squash of
  // listOut, or both for a row removed mid arrival. A row that comes back
  // while it leaves turns around in the look it left with.
  bool _slides;
  bool _squashes = false;

  void _dispose() {
    focus.dispose();
    presence.dispose();
  }
}

/// Builds the content of one list row; the mechanic adds motion and the
/// sending look.
typedef AnimatedRowBuilder<T> = Widget Function(
  BuildContext context,
  RowEntry<T> entry,
);

/// Builds the cells of one table row; the mechanic adds motion and the
/// sending look.
typedef AnimatedTableRowBuilder<T> = TableRow Function(
  BuildContext context,
  RowEntry<T> entry,
);

/// The rows of one animated list in screen order, leaving rows where they
/// were. [useAnimatedRows] owns it; [AnimatedTable], [SliverAnimatedRows]
/// and the editor collections render it.
final class AnimatedRows<T> {
  AnimatedRows._(this._hook);

  final _AnimatedRowsHookState<T> _hook;

  /// Every row on screen in order, leaving rows included.
  List<RowEntry<T>> get entries => List.unmodifiable(_hook._entries);

  /// The items in the data, in order: every entry that is not leaving.
  List<T> get items => [
    for (final entry in _hook._entries)
      if (entry.phase != RowPhase.leaving) entry.item,
  ];

  /// The row of [id] while it is on screen.
  RowEntry<T>? operator [](Object id) => _hook._byId[id];

  /// Whether a row was ever on screen. An empty state arrives with rowIn
  /// after the last row left, with loadIn otherwise.
  bool get everHadRows => _hook._everHadRows;

  /// Where focus goes when rows of this list leave or arrive.
  RowFocus get focus => _hook._focus;

  /// Runs [command] with the rows of [ids] sending: they stay in place,
  /// struck through and busy, and ignore input. When [command] fails their
  /// run returns to idle with no motion and the error is rethrown. When it
  /// succeeds they stay sending until their items leave the data, then play
  /// listOut.
  Future<R> sending<R>(Iterable<Object> ids, Future<R> Function() command) =>
      _hook._sending(ids.toSet(), command);
}

/// Keeps one entry per identity of [items]. Rows present when [ready] is
/// first true join the load run, so a tab creates its rows once, above its
/// data builder, with the data or nothing while it loads, and hands the
/// same rows to its list, its table and its bulk bar. Later rows arrive
/// with rowIn; an identity that leaves [items] squashes shut with listOut,
/// and one that comes back while leaving turns around from where it is. A
/// reorder moves rows in place with no motion. [identity] must be unique
/// among [items]; a duplicate throws an [ArgumentError] and leaves the rows
/// as they were. [arrival] and [leave] are a service's overrides of rowIn
/// and listOut; null plays the tokens. [focus] is passed by a parent that
/// announces creates from outside the list; without it the hook owns one.
AnimatedRows<T> useAnimatedRows<T>({
  required List<T> items,
  required Object Function(T item) identity,
  bool ready = true,
  MotionOverride? arrival,
  MotionOverride? leave,
  RowFocus? focus,
}) {
  final vsync = useTickerProvider();
  return use(
    _AnimatedRowsHook<T>(items, identity, ready, arrival, leave, vsync, focus),
  );
}

class _AnimatedRowsHook<T> extends Hook<AnimatedRows<T>> {
  const _AnimatedRowsHook(
    this.items,
    this.identity,
    this.ready,
    this.arrival,
    this.leave,
    this.vsync,
    this.focus,
  );

  final List<T> items;
  final Object Function(T item) identity;
  final bool ready;
  final MotionOverride? arrival;
  final MotionOverride? leave;
  final TickerProvider vsync;
  final RowFocus? focus;

  @override
  _AnimatedRowsHookState<T> createState() => _AnimatedRowsHookState<T>();
}

/// Owns every entry and its controller. Each controller is disposed exactly
/// once, by the leave that finishes it or by [dispose]. The two can meet in
/// one frame: the web engine runs a frame's two halves without flushing
/// microtasks between them, so the list can leave the tree after a move
/// ended and before the code awaiting that move runs; a finished leave
/// checks [_disposed] first.
class _AnimatedRowsHookState<T>
    extends HookState<AnimatedRows<T>, _AnimatedRowsHook<T>> {
  late final _rows = AnimatedRows<T>._(this);
  final _entries = <RowEntry<T>>[];
  final _byId = <Object, RowEntry<T>>{};
  bool _everHadRows = false;
  bool _loaded = false;
  bool _disposed = false;
  late final RowFocus _focus = hook.focus ?? (_ownFocus = RowFocus());
  RowFocus? _ownFocus;

  @override
  void initHook() {
    super.initHook();
    _focus._rows = _rows;
    _sync();
  }

  // Runs during the owner's build, which follows, so it mutates without
  // setState. A caller may change its list in place, so every build syncs.
  @override
  void didUpdateHook(_AnimatedRowsHook<T> oldHook) {
    super.didUpdateHook(oldHook);
    assert(
      identical(oldHook.focus, hook.focus),
      "A list keeps one RowFocus for its life",
    );
    _sync();
  }

  void _sync() {
    if (!hook.ready) return;
    final ids = [for (final item in hook.items) hook.identity(item)];
    if (ids.toSet().length != ids.length) {
      throw ArgumentError.value(
        ids,
        "items",
        "Animated row identities must be unique",
      );
    }
    // The first data after loading is the load, not an arrival.
    final arrival = _loaded ? RowArrival.insert : RowArrival.load;
    _loaded = true;
    final present = [
      for (final (index, item) in hook.items.indexed)
        _present(ids[index], item, arrival),
    ];
    final kept = present.toSet();
    final leaving = [
      for (final entry in _entries)
        if (!kept.contains(entry) && entry.phase != RowPhase.leaving) entry,
    ];
    // Focus moves before any leaving row rebuilds, against the order before
    // the change.
    _focus._leaving({for (final entry in leaving) entry.id});
    leaving.forEach(_leave);
    final merged = _merge(present, kept);
    _entries
      ..clear()
      ..addAll(merged);
    // A create announced before the row arrived, even before the load.
    _focus._arrived();
  }

  RowEntry<T> _present(Object id, T item, RowArrival arrival) {
    final entry = _byId[id];
    if (entry == null) {
      _everHadRows = true;
      final added = _byId[id] = RowEntry<T>._(
        id: id,
        item: item,
        arrival: arrival,
        presence: MotionController(
          vsync: hook.vsync,
          value: arrival == RowArrival.load ? 1 : 0,
        ),
        focusOwner: _focus,
      );
      _focus._watch(added.focus);
      if (arrival == RowArrival.insert) {
        _play(added, RowPhase.arriving, MotionToken.rowIn, hook.arrival, 1);
      }
      return added;
    }
    entry._item = item;
    if (entry.phase == RowPhase.leaving) {
      // Back in the data: the item was not removed after all.
      entry._run = RowRun.idle;
      _play(entry, RowPhase.arriving, MotionToken.rowIn, hook.arrival, 1);
    }
    return entry;
  }

  void _leave(RowEntry<T> entry) {
    final arriving = entry.phase == RowPhase.arriving;
    entry
      .._leftWhileArriving = arriving
      .._squashes = true;
    // A row removed mid arrival slides back towards its origin as it
    // squashes; a settled row only squashes.
    if (!arriving) entry._slides = false;
    _play(entry, RowPhase.leaving, MotionToken.listOut, hook.leave, 0);
  }

  // A later phase retargets the same controller, which leaves this future
  // uncompleted.
  void _play(
    RowEntry<T> entry,
    RowPhase phase,
    MotionToken<Landing> token,
    MotionOverride? override,
    double target,
  ) {
    entry._phase = phase;
    entry.presence
        .to(target, resolveMotion(context, token, override: override))
        .then<void>((_) {
          if (_disposed || entry.phase != phase || _byId[entry.id] != entry) {
            return;
          }
          if (phase == RowPhase.arriving) {
            setState(() {
              entry
                .._phase = RowPhase.present
                .._squashes = false;
            });
            return;
          }
          setState(() {
            _entries.remove(entry);
            _byId.remove(entry.id);
          });
          entry._dispose();
        });
  }

  // Present rows take the order of the data; each leaving row stays right
  // after the row that preceded it on screen.
  List<RowEntry<T>> _merge(List<RowEntry<T>> present, Set<RowEntry<T>> kept) {
    final leavingAfter = <RowEntry<T>?, List<RowEntry<T>>>{};
    RowEntry<T>? previous;
    for (final entry in _entries) {
      if (kept.contains(entry)) {
        previous = entry;
      } else {
        (leavingAfter[previous] ??= []).add(entry);
      }
    }
    return [
      ...?leavingAfter[null],
      for (final entry in present) ...[entry, ...?leavingAfter[entry]],
    ];
  }

  // Only the run moves here; presence is never touched, so a refusal moves
  // nothing.
  Future<R> _sending<R>(Set<Object> ids, Future<R> Function() command) async {
    final sent = [
      for (final entry in _entries)
        if (ids.contains(entry.id) && entry.phase != RowPhase.leaving) entry,
    ];
    for (final entry in sent) {
      final row = entry.focus;
      // A control inside a sending row hands focus to the row, which keeps
      // it.
      if (row.hasFocus && !row.hasPrimaryFocus && row.canRequestFocus) {
        row.requestFocus();
      }
    }
    setState(() {
      for (final entry in sent) {
        entry._run = RowRun.sending;
      }
    });
    try {
      return await command();
    } catch (_) {
      if (!_disposed) {
        setState(() {
          for (final entry in sent) {
            if (entry.run == RowRun.sending) entry._run = RowRun.idle;
          }
        });
      }
      rethrow;
    }
  }

  @override
  AnimatedRows<T> build(BuildContext context) => _rows;

  @override
  void dispose() {
    _disposed = true;
    _focus._detach(_rows);
    for (final entry in _byId.values) {
      entry._dispose();
    }
    _ownFocus?.dispose();
    super.dispose();
  }

  @override
  String get debugLabel => "useAnimatedRows";
}

/// The motion and sending look every renderer of [AnimatedRows] applies.
extension RowEntryMotion on RowEntry<Object?> {
  /// Cell motion: [content] with the row's arrival and leave, applied to
  /// every cell of a table row and once to a list row. The shape is the
  /// same in every phase, so a row that starts leaving keeps its element
  /// tree. [anchors] false keeps the row out of an enclosing
  /// [SliverRowAnchor], for lists that own no scroll.
  Widget motion(Widget content, {bool anchors = true}) {
    final moving = Leave(
      progress: _squashes ? presence : kAlwaysCompleteAnimation,
      child: Enter(
        token: arrival == RowArrival.load
            ? MotionToken.loadIn
            : MotionToken.rowIn,
        progress: arrival == RowArrival.load
            ? null
            : (_slides ? presence : kAlwaysCompleteAnimation),
        group: this,
        child: _Quiet(
          quiet: phase == RowPhase.leaving || run == RowRun.sending,
          child: _SendingText(sending: run == RowRun.sending, child: content),
        ),
      ),
    );
    if (!anchors) return moving;
    return RowAnchorMarker(id: id, child: moving);
  }

  /// The per row hook point: applied exactly once per row by every list
  /// renderer, inside [motion], around the whole row.
  Widget row(Widget child) =>
      _SendingFill(sending: run == RowRun.sending, child: child);

  /// The per row hook point of a table, whose rows are not widgets: the
  /// TableRow decoration. [AnimatedTable] applies it once per row.
  Decoration? rowDecoration(BuildContext context, Decoration? source) {
    if (run != RowRun.sending) return source;
    final fill = Theme.of(context).colorScheme.onSurface
        .withValues(alpha: context.stateTokens.pressedOpacity);
    return switch (source) {
      BoxDecoration(:final color?) => source.copyWith(
        color: Color.alphaBlend(fill, color),
      ),
      BoxDecoration() => source.copyWith(color: fill),
      null => BoxDecoration(color: fill),
      _ => source,
    };
  }
}

// A sending row reads as pressed in, like a held key, with its text struck
// through: the fill is onSurface at the pressed opacity, the text onSurface
// at the disabled foreground opacity. The look lands at once; the hold that
// sent the command already moved. The text is per cell, so a table strikes
// every cell; the fill is per row.
class _SendingText extends StatelessWidget {
  const _SendingText({required this.sending, required this.child});

  final bool sending;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return DefaultTextStyle.merge(
      style: sending
          ? DefaultTextStyle.of(context).style.copyWith(
              decoration: TextDecoration.lineThrough,
              color: onSurface.withValues(
                alpha: context.stateTokens.disabledForegroundOpacity,
              ),
            )
          : null,
      child: child,
    );
  }
}

/// Semantics, pointer and traversal off for a leaving or sending row. Focus
/// is never taken away here: ExcludeFocus would unfocus a focused
/// descendant, and a sending row keeps its focus.
class _Quiet extends StatelessWidget {
  const _Quiet({required this.quiet, required this.child});

  final bool quiet;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      excluding: quiet,
      child: Focus(
        canRequestFocus: false,
        skipTraversal: true,
        includeSemantics: false,
        descendantsAreTraversable: !quiet,
        child: IgnorePointer(ignoring: quiet, child: child),
      ),
    );
  }
}

class _SendingFill extends StatelessWidget {
  const _SendingFill({required this.sending, required this.child});

  final bool sending;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: sending
            ? onSurface.withValues(alpha: context.stateTokens.pressedOpacity)
            : null,
      ),
      child: child,
    );
  }
}

/// A sliver list that animates the rows of [rows] in and out, the sliver
/// form of [AnimatedTable]. Flutter's `SliverAnimatedList` is not used: it
/// disposes a finished row's controller a second time when the list leaves
/// the tree in that frame (flutter/flutter#192533).
class SliverAnimatedRows<T> extends StatelessWidget {
  const SliverAnimatedRows({
    required this.rows,
    required this.itemBuilder,
    super.key,
  });

  final AnimatedRows<T> rows;
  final AnimatedRowBuilder<T> itemBuilder;

  @override
  Widget build(BuildContext context) {
    final entries = rows.entries;
    return RowFocusScope(
      focus: rows.focus,
      child: SliverRowAnchor(
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final entry = entries[index];
              return RowEntryScope(
                key: ValueKey(entry.id),
                entry: entry,
                child: entry.motion(entry.row(itemBuilder(context, entry))),
              );
            },
            childCount: entries.length,
            // A row keeps its element when rows above it change.
            findChildIndexCallback: (key) {
              final index = entries.indexWhere(
                (entry) => ValueKey(entry.id) == key,
              );
              return index < 0 ? null : index;
            },
          ),
        ),
      ),
    );
  }
}
