import "package:typewriter_panel/typewriter_panel.dart";

/// The three layouts the maintainer picks from in the hold story.
enum HoldLineLayout {
  /// The line shows over the row on the fill, from the title's left edge.
  over,

  /// The line shows in the row's trailing slot, where row actions show.
  trailing,

  /// The line floats one line under the row, over the next row, shifting
  /// nothing.
  beneath,
}

/// The layout the hold story picks; [HoldLineLayout.over] outside it.
class HoldLineLayoutScope extends InheritedWidget {
  const HoldLineLayoutScope({
    required this.layout,
    required super.child,
    super.key,
  });

  final HoldLineLayout layout;

  static HoldLineLayout of(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<HoldLineLayoutScope>()
          ?.layout ??
      HoldLineLayout.over;

  @override
  bool updateShouldNotify(HoldLineLayoutScope old) => old.layout != layout;
}

/// Places [line] by the current layout without changing the row's size.
class HoldLineSlot extends StatelessWidget {
  const HoldLineSlot({required this.line, required this.child, super.key});

  final Widget line;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final inset = EdgeInsetsDirectional.symmetric(
      horizontal: context.spacing.space3,
    );
    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        switch (HoldLineLayoutScope.of(context)) {
          HoldLineLayout.over => Positioned.fill(
            child: Padding(
              padding: inset,
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: line,
              ),
            ),
          ),
          HoldLineLayout.trailing => Positioned.fill(
            child: Padding(
              padding: inset,
              child: Align(
                alignment: AlignmentDirectional.centerEnd,
                child: line,
              ),
            ),
          ),
          HoldLineLayout.beneath => PositionedDirectional(
            start: 0,
            end: 0,
            bottom: 0,
            child: FractionalTranslation(
              translation: const Offset(0, 1),
              child: Padding(padding: inset, child: line),
            ),
          ),
        },
      ],
    );
  }
}

/// A hold on the row of [entry]: its fill, its outcome line when it leads,
/// its jam and the message of its last refusal.
///
/// Applied once per row through `entry.row` in lists, or `entry.rowLine` in
/// a table cell while the row decoration paints the fill, so no row wraps
/// itself and rows name their identity once. It selects only its own row's
/// view of the hold session, so a press run or another row's hold never
/// rebuilds it. It never moves focus. Outside a [CommandRunsScope] it shows
/// only the refusal on its entry.
class HoldRow extends HookWidget {
  const HoldRow({
    required this.entry,
    required this.child,
    this.paintsFill = true,
    super.key,
  });

  final RowEntry<Object?> entry;
  final Widget child;

  /// False in a table cell, where the row's decoration paints the fill.
  final bool paintsFill;

  @override
  Widget build(BuildContext context) {
    final runs = CommandRunsScope.maybeOf(context);
    final id = entry.id;
    // This row's view of the hold: not held, held, or held and leading.
    final view = useListenableSelector(
      runs?.session ?? const _NoHold(),
      () => switch (runs?.session.value) {
        final session?
            when session.phase == HoldPhase.holding &&
                session.attempt.ids.contains(id) =>
          session.lead == id ? _RowHold.leads : _RowHold.held,
        _ => _RowHold.none,
      },
    );
    final attempt = runs?.session.value?.attempt;
    final message = entry.failure?.message;
    // The row keeps its elements while the line or the message comes and
    // goes: its focus and the action sets that started a hold live there.
    final rowKey = useMemoized(GlobalKey.new);
    final heldKey = useMemoized(GlobalKey.new);
    final row = KeyedSubtree(key: rowKey, child: child);
    final held = KeyedSubtree(
      key: heldKey,
      child: Jam(
        failures: entry.jams,
        child: HoldFill(
          fill: !paintsFill || view == _RowHold.none ? null : runs!.fill,
          child: view == _RowHold.leads && attempt != null
              ? HoldLineSlot(
                  line: HoldLine(verb: attempt.verb, text: attempt.outcome),
                  child: row,
                )
              : row,
        ),
      ),
    );
    if (message == null) return held;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        held,
        Semantics(
          liveRegion: true,
          child: Padding(
            padding: EdgeInsetsDirectional.only(
              start: context.spacing.space3,
              end: context.spacing.space3,
              bottom: context.spacing.space1,
            ),
            child: LabeledMessage(
              message: message,
              messageStyle: context.text.sentence.copyWith(
                color: context.colors.dangerText,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

enum _RowHold { none, held, leads }

/// The hold fill of the row [id] for a decoration: the session's fill while
/// the row is held, else 0. It listens to the session only while painted,
/// and to the fill only while its row is held, so a hold repaints only its
/// own rows.
final class RowHoldAmount implements ValueListenable<double> {
  RowHoldAmount(this.runs, this.id);

  final CommandRuns runs;
  final Object id;
  final _listeners = <VoidCallback>[];
  bool _held = false;

  bool get _isHeld => switch (runs.session.value) {
    final session? =>
      session.phase == HoldPhase.holding && session.attempt.ids.contains(id),
    null => false,
  };

  @override
  double get value => _isHeld ? runs.fill.value : 0;

  @override
  void addListener(VoidCallback listener) {
    if (_listeners.isEmpty) {
      runs.session.addListener(_sessionChanged);
      _held = _isHeld;
      if (_held) runs.fill.addListener(_notify);
    }
    _listeners.add(listener);
  }

  @override
  void removeListener(VoidCallback listener) {
    _listeners.remove(listener);
    if (_listeners.isNotEmpty) return;
    runs.session.removeListener(_sessionChanged);
    if (_held) runs.fill.removeListener(_notify);
    _held = false;
  }

  void _sessionChanged() {
    final held = _isHeld;
    if (held == _held) return;
    held ? runs.fill.addListener(_notify) : runs.fill.removeListener(_notify);
    _held = held;
    _notify();
  }

  void _notify() {
    for (final listener in List.of(_listeners)) {
      listener();
    }
  }
}

/// Stands in for the session outside a [CommandRunsScope].
final class _NoHold implements ValueListenable<HoldSession?> {
  const _NoHold();

  @override
  HoldSession? get value => null;

  @override
  void addListener(VoidCallback listener) {}

  @override
  void removeListener(VoidCallback listener) {}
}

/// The outcome line, in reserved space from the first frame.
///
/// The short verb types itself with `type`; the rest of the line arrives
/// whole on a bounce with `capIn` once the verb is typed, since it is longer
/// than about 20 letters. Both land within the first third of the hold, and
/// screen readers hear the whole line at once.
class HoldLine extends HookWidget {
  HoldLine({required this.verb, required this.text, super.key})
    : assert(text.startsWith(verb), "The outcome line starts with its verb.");

  final String verb;
  final String text;

  @override
  Widget build(BuildContext context) {
    // Letters of the verb shown so far, stepped by the `type` token.
    final typed = useTyping(verb, typesIn: true);
    final arrived = typed == verb.length;
    final rest = useMotion(MotionToken.capIn, arrived ? 1.0 : 0.0);
    final style = context.text.sentence.copyWith(
      color: context.colors.contentPrimary,
    );
    final hidden = style.copyWith(color: style.color?.withValues(alpha: 0));
    // Its own node: a named row would otherwise fold the line into its name.
    return Semantics(
      container: true,
      liveRegion: true,
      label: text,
      child: ExcludeSemantics(
        // The full line lays out from the first frame, so nothing shifts.
        child: Text.rich(
          TextSpan(
            children: [
              TextSpan(text: verb.substring(0, typed)),
              TextSpan(text: verb.substring(typed), style: hidden),
              WidgetSpan(
                alignment: PlaceholderAlignment.baseline,
                baseline: TextBaseline.alphabetic,
                child: Rise(
                  progress: rest,
                  token: MotionToken.capIn,
                  child: Text(
                    text.substring(verb.length),
                    style: arrived ? style : hidden,
                  ),
                ),
              ),
            ],
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: style,
        ),
      ),
    );
  }
}
