import "package:typewriter_panel/typewriter_panel.dart";

/// Brings [child] in with [token]: from the landing's offset to its place,
/// fading in on the way.
///
/// Without [progress] it runs itself. A loadIn Enter joins the run of the
/// nearest [EnterRun] and starts at its slot; it shows at once without a
/// run, or when it joins after the run's first frame. Any other token
/// plays at mount. With [progress] the caller owns the timing and Enter
/// paints at that progress. Enters sharing [group] take one slot.
class Enter extends HookWidget {
  const Enter({
    required this.child,
    this.token = MotionToken.rowIn,
    this.progress,
    this.group,
    super.key,
  });

  final Widget child;
  final MotionToken<EnterLanding> token;
  final Animation<double>? progress;
  final Object? group;

  @override
  Widget build(BuildContext context) {
    final resolved = resolveMotion(context, token);
    final run = token == MotionToken.loadIn && progress == null
        ? context.dependOnInheritedWidgetOfExactType<_EnterRunScope>()?.run
        : null;
    final own = useMotionController(
      initial: resolved.travels && progress == null ? 0 : 1,
    );
    final arrived = useRef(!resolved.travels);
    final slot = useRef<Object>(group ?? Object());

    // A loadIn row on a page a move reached comes from the move's side, and
    // joins the run again when a new move reaches the page.
    final arrival = PageArrival.maybeOf(context);
    useEffect(() {
      if (progress != null || !resolved.travels) return null;
      if (token != MotionToken.loadIn) {
        own.to(1, resolved);
        return null;
      }
      if (run == null) {
        own.jumpTo(1);
        return null;
      }
      // A new move to a kept page starts the row over.
      if (arrival != null) own.jumpTo(0);
      return run.join(
        slot: slot.value,
        context: context,
        start: (delay) {
          if (delay == Duration.zero) {
            own.to(1, resolved);
            return null;
          }
          final timer = Timer(delay, () => own.to(1, resolved));
          return timer.cancel;
        },
        late: () => own.jumpTo(1),
      );
    }, [arrival?.serial]);

    final shown = progress ?? own;
    final from = token == MotionToken.loadIn
        ? resolved.landing.from.towards(arrival?.direction)
        : resolved.landing.from;
    return AnimatedBuilder(
      animation: shown,
      child: child,
      builder: (context, child) {
        final value = shown.value;
        if (value >= 1) arrived.value = true;
        return Opacity(
          opacity: arrived.value ? 1 : value.clamp(0.0, 1.0),
          child: Transform.translate(offset: from * (1 - value), child: child),
        );
      },
    );
  }
}

/// The boundary of one loadIn run: the Enters that join it in its first
/// frame start in visual order, top to bottom then start to end, spread
/// by the loadIn stagger so the last starts within its bound. Later
/// joiners show at once. Remount it to run again.
class EnterRun extends HookWidget {
  const EnterRun({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final run = useMemoized(() => _LoadRun(context));
    final serial = PageArrival.maybeOf(context)?.serial;
    useEffect(() => run.dispose, [run]);
    // A new move reopens the run for one frame, so the rows that rejoin
    // start in visual order again; effects run parent first.
    useEffect(() {
      if (serial != null) run.reopen();
      return null;
    }, [serial]);
    return _EnterRunScope(run: run, child: child);
  }
}

/// The state of one run, owned by its EnterRun.
final class _LoadRun {
  _LoadRun(this.context);

  final BuildContext context;
  final _waiting = <Object, List<_Joined>>{};
  bool _open = true;
  bool _scheduled = false;

  /// Opens the run until its next launch.
  void reopen() => _open = true;
  final _cancels = <VoidCallback>[];

  /// Joins the run; returns the cleanup for the joiner's effect.
  VoidCallback? join({
    required Object slot,
    required BuildContext context,
    required VoidCallback? Function(Duration delay) start,
    required VoidCallback late,
  }) {
    if (!_open) {
      late();
      return null;
    }
    final joined = _Joined(context, start);
    _waiting.putIfAbsent(slot, () => []).add(joined);
    if (!_scheduled) {
      _scheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _launch());
    }
    return () {
      joined.cancelled = true;
      joined.stop?.call();
    };
  }

  void _launch() {
    _open = false;
    _scheduled = false;
    if (!context.mounted) return;
    final box = context.findRenderObject();
    final slots =
        _waiting.entries
            .map((entry) => (entry.value, _positionOf(entry.value, box)))
            .where((slot) => slot.$2 != null)
            .toList()
          ..sort((a, b) {
            final dy = a.$2!.dy.compareTo(b.$2!.dy);
            return dy != 0 ? dy : a.$2!.dx.compareTo(b.$2!.dx);
          });
    final stagger = resolveMotion(context, MotionToken.loadIn).landing.stagger;
    for (final (index, (members, _)) in slots.indexed) {
      final delay = stagger?.delayOf(index, slots.length) ?? Duration.zero;
      for (final member in members) {
        if (member.cancelled) continue;
        final cancel = member.start(delay);
        member.stop = cancel;
        if (cancel != null) _cancels.add(cancel);
      }
    }
    _waiting.clear();
  }

  Offset? _positionOf(List<_Joined> members, RenderObject? scope) {
    Offset? first;
    for (final member in members) {
      if (member.cancelled || !member.context.mounted) continue;
      final box = member.context.findRenderObject();
      if (box is! RenderBox || !box.hasSize) continue;
      final at = box.localToGlobal(Offset.zero, ancestor: scope);
      if (first == null ||
          at.dy < first.dy ||
          (at.dy == first.dy && at.dx < first.dx)) {
        first = at;
      }
    }
    return first;
  }

  void dispose() {
    for (final cancel in _cancels) {
      cancel();
    }
  }
}

final class _Joined {
  _Joined(this.context, this.start);

  final BuildContext context;
  final VoidCallback? Function(Duration delay) start;
  bool cancelled = false;

  /// Stops a start still waiting for its slot, when the joiner leaves.
  VoidCallback? stop;
}

class _EnterRunScope extends InheritedWidget {
  const _EnterRunScope({required this.run, required super.child});

  final _LoadRun run;

  @override
  bool updateShouldNotify(_EnterRunScope oldWidget) => oldWidget.run != run;
}

extension on Offset {
  /// The loadIn offset (rows rise from below) turned to come from the side a
  /// page move gives; the distance stays the landing's.
  Offset towards(PageDirection? direction) {
    final reach = distance;
    return switch (direction) {
      PageDirection.deeper => Offset(reach, 0),
      PageDirection.back => Offset(-reach, 0),
      PageDirection.down || null => Offset(0, reach),
      PageDirection.up => Offset(0, -reach),
    };
  }
}
