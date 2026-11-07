import "package:typewriter_panel/typewriter_panel.dart";

/// Moves one value with motion tokens, as an animation builders can
/// listen to. Each retarget starts from the value and velocity on screen.
/// Hook widgets get one from [useMotion] or [useMotionController]; a
/// [State] creates one with itself as the [TickerProvider] and disposes it.
final class MotionController extends Animation<double>
    with AnimationWithParentMixin<double> {
  MotionController({required TickerProvider vsync, double value = 0})
    : _controller = AnimationController.unbounded(
        vsync: vsync,
        value: value,
        animationBehavior: AnimationBehavior.preserve,
      );

  final AnimationController _controller;
  double? _target;
  ResolvedMotion<Landing>? _last;
  Duration? _lastStart;

  /// Where the running move started.
  double _origin = 0;
  TickerFuture _running = TickerFuture.complete();

  @override
  Animation<double> get parent => _controller;

  @override
  double get value => _controller.value;

  double get velocity => _controller.velocity;

  /// Where the value is going, or where it rests.
  double get target => _target ?? value;

  /// The value rests on its target.
  bool get settled => !_controller.isAnimating && value == target;

  /// Moves to [target] with [resolved]. The returned future completes when
  /// the value lands; a later retarget leaves it uncompleted.
  TickerFuture to(double target, ResolvedMotion<Landing> resolved) {
    if (target == _target && _controller.isAnimating) return _running;
    final resting = !_controller.isAnimating && value == target;
    // A target on the side the move came from turns it around.
    final reverses =
        _controller.isAnimating &&
        _target != null &&
        (target - _target!) * (_origin - _target!) > 0;
    _target = target;
    if (resting) return _running = TickerFuture.complete();
    return _run(resolved, reverses: reverses);
  }

  /// Plays [resolved] again although the target did not change, as a jam
  /// or a busy word does.
  TickerFuture play(ResolvedMotion<Landing> resolved) {
    _target ??= value;
    return _run(resolved);
  }

  /// Starts again from [from] towards [target], leaving at [velocity]. A
  /// move that [reverses] plays at full length, never paced.
  TickerFuture restart(
    double from,
    double target,
    ResolvedMotion<Landing> resolved, {
    double velocity = 0,
    bool reverses = false,
  }) {
    _target = target;
    _last = resolved;
    _controller.value = from;
    final motion = _paced(resolved, reverses: reverses);
    if (motion is InstantMotion) {
      _controller.value = target;
      return _running = TickerFuture.complete();
    }
    return _running = _animate(motion, target, velocity);
  }

  /// Jumps to [value] with no motion and no velocity.
  void jumpTo(double value) {
    _target = value;
    _controller.value = value;
  }

  /// Moves the value and its target by [delta] with no motion, as when
  /// the thing under a moving ring scrolled. A running move continues
  /// towards the shifted target at the same velocity.
  void shift(double delta) {
    final target = this.target + delta;
    _target = target;
    final last = _last;
    if (!_controller.isAnimating || last == null) {
      _controller.value = value + delta;
      return;
    }
    final velocity = _controller.velocity;
    _controller.value = value + delta;
    _running = _animate(last.motion, target, velocity);
  }

  TickerFuture _run(ResolvedMotion<Landing> resolved, {bool reverses = false}) {
    _last = resolved;
    final target = _target!;
    final motion = _paced(resolved, reverses: reverses);
    if (motion is InstantMotion) {
      _controller.value = target;
      return _running = TickerFuture.complete();
    }
    return _running = _animate(motion, target, _controller.velocity);
  }

  /// Shortens a move that repeats in the same direction before the last one
  /// finished, down to a jump below the floor: a held key makes the ring
  /// jump. A move that [reverses] is no repeat and plays at full length.
  Motion _paced(ResolvedMotion<Landing> resolved, {bool reverses = false}) {
    final now = SchedulerBinding.instance.currentSystemFrameTimeStamp;
    final since = _lastStart == null ? null : now - _lastStart!;
    _lastStart = now;
    final nominal = resolved.motion.duration;
    if (reverses ||
        since == null ||
        nominal == Duration.zero ||
        since >= nominal) {
      return resolved.motion;
    }
    final pace = since.inMicroseconds / nominal.inMicroseconds;
    if (pace < resolved.repeatFloor) return Motion.instant;
    return resolved.motion.withDuration(nominal * pace);
  }

  TickerFuture _animate(Motion motion, double target, double velocity) {
    _origin = value;
    final simulation = motion.simulate(
      from: value,
      to: target,
      velocity: velocity,
    );
    final running = _controller.animateWith(simulation);
    if (simulation is SpringSimulation) {
      running.then((_) {
        if (_target == target) _controller.value = target;
      });
    }
    return running;
  }

  void dispose() => _controller.dispose();
}

/// A controller that starts at [initial] and lives as long as the widget.
/// The widget does not rebuild on ticks; listen with an AnimatedBuilder.
MotionController useMotionController({double initial = 0}) {
  final vsync = useSingleTickerProvider();
  final controller = useMemoized(
    () => MotionController(vsync: vsync, value: initial),
  );
  useEffect(() => controller.dispose, [controller]);
  return controller;
}

/// Moves a value to [target] with [token] and rebuilds the widget as it
/// moves. The value starts at [initial], or at [target] so nothing moves
/// on the first build. A changed target retargets from the value and
/// velocity on screen. [animate] false lands at once, for a change the
/// user did not cause.
MotionController useMotion<L extends Landing>(
  MotionToken<L> token,
  double target, {
  double? initial,
  MotionOverride? override,
  bool animate = true,
}) {
  final context = useContext();
  final controller = useMotionController(initial: initial ?? target);
  final resolved = resolveMotion(context, token, override: override);
  useEffect(() {
    controller.to(target, animate ? resolved : resolved.instant);
    return null;
  }, [target]);
  useListenable(controller);
  return controller;
}

/// Plays [motion] between values of [T] and returns the value to show. A
/// new [target] starts from the value on screen and keeps the progress
/// velocity. [lerp] mixes two values; [T] needs value equality.
T useMotionValue<T>(
  ResolvedMotion<Landing> motion,
  T target, {
  required T Function(T from, T to, double t) lerp,
}) {
  final from = useRef(target);
  final to = useRef(target);
  final progress = useMotionController(initial: 1);
  useListenable(progress);
  useEffect(() {
    if (target == to.value) return null;
    final shown = progress.value;
    final velocity = progress.velocity;
    // A return to where the running move started turns it around: it plays
    // at full length, and its velocity points back along the same line.
    final reverses = !progress.settled && target == from.value;
    from.value = lerp(from.value, to.value, shown);
    to.value = target;
    progress.restart(
      0,
      1,
      motion,
      velocity: reverses && shown > 0 ? -velocity / shown : velocity,
      reverses: reverses,
    );
    return null;
  }, [target]);
  return lerp(from.value, to.value, progress.value);
}

/// The motion for a value that follows interaction [states]: the move
/// `previous.moveTo(next)` picks for the latest state change, resolved
/// with the override [overrideFor] gives for that move. A rebuild with neither [states] nor [target] changed
/// keeps the move in flight; a [target] change with the same states is not
/// the user's doing and lands at once. Play the result with
/// [useMotionValue] or [MotionController.to].
ResolvedMotion<Landing> useStateMotion(
  Set<WidgetState> states, {
  Object? target,
  MotionOverride? Function(MotionToken<Landing> move)? overrideFor,
}) {
  final context = useContext();
  final seen = useRef((
    states: states,
    target: target,
    move: null as MotionToken<Landing>?,
  ));
  final last = seen.value;
  final statesChanged = !setEquals(last.states, states);
  if (statesChanged || last.target != target) {
    seen.value = (
      states: states,
      target: target,
      move: statesChanged ? last.states.moveTo(states) : null,
    );
  }
  final move = seen.value.move;
  if (move == null) return ResolvedMotion.immediate;
  return resolveMotion(context, move, override: overrideFor?.call(move));
}

/// The number of letters of [text] to show while it types with the
/// `type` token. A new text keeps the letters it shares with the old one
/// and types only the rest; [typesIn] types the first text from nothing.
int useTyping(String text, {bool typesIn = false}) {
  final context = useContext();
  final count = useMotionController(
    initial: typesIn ? 0 : text.length.toDouble(),
  );
  final previous = useRef(text);
  final resolved = resolveMotion(context, MotionToken.type);
  useEffect(() {
    if (typesIn) count.to(text.length.toDouble(), resolved);
    return null;
  }, const []);
  useEffect(() {
    final old = previous.value;
    previous.value = text;
    if (old == text) return null;
    var kept = 0;
    while (kept < old.length && kept < text.length && old[kept] == text[kept]) {
      kept++;
    }
    count
      ..jumpTo(kept.toDouble())
      ..to(text.length.toDouble(), resolved);
    return null;
  }, [text]);
  useListenable(count);
  return count.value.round().clamp(0, text.length);
}

/// A ticker provider for a hook widget that owns several motions, muted
/// with the surrounding [TickerMode] like [TickerProviderStateMixin].
TickerProvider useTickerProvider() => use(const _TickerProviderHook());

class _TickerProviderHook extends Hook<TickerProvider> {
  const _TickerProviderHook();

  @override
  _TickerProviderHookState createState() => _TickerProviderHookState();
}

class _TickerProviderHookState
    extends HookState<TickerProvider, _TickerProviderHook>
    implements TickerProvider {
  final _tickers = <_HookTicker>{};
  ValueListenable<TickerModeData>? _mode;

  @override
  Ticker createTicker(TickerCallback onTick) {
    final ticker = _HookTicker(onTick, this);
    _tickers.add(ticker);
    _apply(ticker);
    return ticker;
  }

  @override
  TickerProvider build(BuildContext context) {
    final mode = TickerMode.getValuesNotifier(context);
    if (mode != _mode) {
      _mode?.removeListener(_updateTickers);
      _mode = mode..addListener(_updateTickers);
      _updateTickers();
    }
    return this;
  }

  void _apply(Ticker ticker) {
    final mode = _mode?.value ?? TickerModeData.fallback;
    ticker
      ..muted = !mode.enabled
      ..forceFrames = mode.forceFrames;
  }

  void _updateTickers() {
    for (final ticker in _tickers) {
      _apply(ticker);
    }
  }

  @override
  void dispose() => _mode?.removeListener(_updateTickers);
}

class _HookTicker extends Ticker {
  _HookTicker(super.onTick, this._owner)
    : super(debugLabel: "useTickerProvider");

  final _TickerProviderHookState _owner;

  @override
  void dispose() {
    _owner._tickers.remove(this);
    super.dispose();
  }
}
