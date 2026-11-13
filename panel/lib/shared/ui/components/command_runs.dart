import "package:typewriter_panel/typewriter_panel.dart";

/// Where a hold stands. With no session the hold is idle or has failed;
/// refusals live on the row entries or, without rows, on the command's run
/// state.
enum HoldPhase { holding, running }

/// The one hold the panel runs now.
final class HoldSession {
  HoldSession({
    required this.command,
    required this.attempt,
    required this.ref,
    required this.input,
    this.phase = HoldPhase.holding,
  });

  final String command;
  final HoldTry attempt;
  final WidgetRef ref;
  final HoldInput input;
  final HoldPhase phase;

  HoldSession copyWith({HoldInput? input, HoldPhase? phase}) => HoldSession(
    command: command,
    attempt: attempt,
    ref: ref,
    input: input ?? this.input,
    phase: phase ?? this.phase,
  );

  /// The target that shows the outcome line: the focused row when it is
  /// held, else the first held row in list order.
  Object get lead {
    final focused = attempt.rows?.focusedId;
    return focused != null && attempt.ids.contains(focused)
        ? focused
        : attempt.ids.first;
  }
}

final class _Run {
  final controller = ButtonController();
  int holders = 0;
}

/// The one owner of every command run: a key press, a Button tap, a hold, a
/// menu entry and an action row pill all go through it, so a key press and
/// a tap of the same command share busy, refusal and jam.
///
/// A press goes through one [ButtonController] per command, the same one
/// every Button bound to that command reads. A run lives while something
/// retains it (each registered action set and each bound Button retains its
/// commands) and is dropped once the last one lets go and it is not
/// running, so per row command ids do not pile up. A hold is built on
/// [HoldClock] and runs its [HoldTry] through the same controller. Its rows
/// come from its plan; a hold without rows reports a refusal through the
/// command's run state, so its buttons jam and show the message. It keeps
/// no row registry and never requests focus.
final class CommandRuns implements CommandRunner {
  CommandRuns({required TickerProvider vsync, required this.scope}) {
    clock = HoldClock(vsync: vsync, onComplete: _complete);
    clock.fill.addListener(_drained);
  }

  /// The ref of the scope that owns these runs. Work whose starting widget
  /// left the tree (a row that sent, a button its own run replaced) goes on
  /// with it.
  final WidgetRef scope;

  final _runs = <String, _Run>{};
  final _session = ValueNotifier<HoldSession?>(null);
  late final HoldClock clock;
  var _keyListening = false;
  var _disposed = false;

  /// The current hold; rows select their own view of it.
  ValueListenable<HoldSession?> get session => _session;

  /// The fill of the current hold, 0 to 1.
  Animation<double> get fill => clock.fill;

  /// The commands a run is kept for now.
  Iterable<String> get commands => _runs.keys;

  /// Whether [command] runs now, pressed or held.
  bool isRunning(String command) =>
      _runs[command]?.controller.isLoading ?? false;

  /// The run state every Button bound to [command] reads.
  ButtonController of(ActionShortcut command) => _runFor(command.id).controller;

  _Run _runFor(String command) => _runs.putIfAbsent(command, _Run.new);

  WidgetRef _live(WidgetRef ref) => ref.context.mounted ? ref : scope;

  @override
  VoidCallback retain(String command) {
    final run = _runFor(command);
    run.holders++;
    var released = false;
    return () {
      if (released) return;
      released = true;
      run.holders--;
      _dropIfIdle(command);
    };
  }

  void _dropIfIdle(String command) {
    if (_disposed) return;
    final run = _runs[command];
    if (run == null || run.holders > 0 || run.controller.isLoading) return;
    if (_session.value?.command == command) return;
    _runs.remove(command);
    run.controller.dispose();
  }

  /// Runs [command]'s press once. Refused while that command runs, from
  /// any key or Button; a failure jams every Button bound to it.
  @override
  bool press(ActionShortcut command, WidgetRef ref) {
    if (command.run case PressRun(:final invoke)) {
      final run = _runFor(command.id).controller
        ..bind(
          onPressed: () async {
            try {
              await invoke(_live(ref));
            } finally {
              scheduleMicrotask(() => _dropIfIdle(command.id));
            }
          },
          onError: (error) {
            final context = _live(ref).context;
            if (!context.mounted) return;
            context.reportFailure(
              "${command.label} failed",
              detail: error,
              retry: () async => invoke(_live(ref)),
            );
          },
        );
      return run.trigger();
    }
    return false;
  }

  /// Starts or continues the hold of [command] from [input].
  @override
  void start(
    ActionShortcut command,
    WidgetRef ref,
    HoldInput input, {
    required ResolvedMotion<NoLanding> motion,
  }) {
    final run = command.run;
    if (run is! HoldRun) {
      throw ArgumentError.value(command.id, "command", "is not a hold");
    }
    final current = _session.value;
    if (current != null) {
      if (current.phase == HoldPhase.running) return;
      if (current.command == command.id) {
        // A key repeat or a second pointer changes nothing.
        if (clock.isDown) return;
        // A press again while the fill drains: the clock continues.
        _session.value = current.copyWith(input: input);
        _listen(input);
        _press(input, motion);
        return;
      }
      _end();
    }
    if (isRunning(command.id)) return;
    final attempt = run.plan.begin(ref);
    if (attempt == null) return;
    _runFor(command.id);
    clock.reset();
    _session.value = HoldSession(
      command: command.id,
      attempt: attempt,
      ref: ref,
      input: input,
    );
    _listen(input);
    _press(input, motion);
  }

  /// Releases the pointer hold [pointer], or any hold when null.
  void release([int? pointer]) {
    final current = _session.value;
    if (current == null || current.phase != HoldPhase.holding) return;
    if (current.input case PointerHoldInput(pointer: final held)
        when pointer != null && held != pointer) {
      return;
    }
    _unlisten();
    // The fill and the clock run back; a press again continues.
    clock.release();
  }

  void _press(HoldInput input, ResolvedMotion<NoLanding> motion) =>
      input is AssistiveHoldInput
      ? clock.completeNow(motion)
      : clock.press(motion);

  Future<void> _complete() async {
    final current = _session.value;
    if (current == null) return;
    _unlisten();
    final attempt = current.attempt;
    _session.value = current.copyWith(phase: HoldPhase.running);
    var result = const HoldResult();
    // The work runs through the command's run state, so a key press or tap
    // of the same command is refused while it runs.
    final run = _runFor(current.command).controller
      ..bind(
        onPressed: () async {
          try {
            result = await runHold(attempt, () => _live(current.ref));
          } on Object catch (error, stack) {
            final message = failureMessage(error, stack);
            result = HoldResult(
              failures: {for (final id in attempt.ids) id: message},
            );
          }
          // Without rows nothing shows a refusal but the command's buttons.
          if (attempt.rows == null && result.failures.isNotEmpty) {
            throw HoldRefused(result.failures.values.first);
          }
        },
        onError: null,
      );
    await run.handlePress();
    if (_disposed || _session.value?.attempt != attempt) return;
    _session.value = null;
    // Sent rows leave with listOut when their items go.
    clock.reset();
    _dropIfIdle(current.command);
    // Refused rows never left: focus moves to the first one in list order.
    final first = attempt.ids.firstWhereOrNull(result.failures.containsKey);
    if (first != null) attempt.rows?.focusId(first);
  }

  // A released hold ends once its fill has run back to empty.
  void _drained() {
    final current = _session.value;
    if (current == null || current.phase != HoldPhase.holding) return;
    if (clock.isDown || clock.isDone || clock.fill.value > 0) return;
    _end();
  }

  void _end() {
    final current = _session.value;
    _unlisten();
    _session.value = null;
    clock.reset();
    if (current != null) _dropIfIdle(current.command);
  }

  void _listen(HoldInput input) {
    _unlisten();
    if (input is! KeyHoldInput) return;
    HardwareKeyboard.instance.addHandler(_onKey);
    FocusManager.instance.addListener(_onFocus);
    _keyListening = true;
  }

  void _unlisten() {
    if (!_keyListening) return;
    HardwareKeyboard.instance.removeHandler(_onKey);
    FocusManager.instance.removeListener(_onFocus);
    _keyListening = false;
  }

  bool _onKey(KeyEvent event) {
    if (_session.value?.input case KeyHoldInput(:final keys)
        when event is KeyUpEvent && keys.contains(event.logicalKey)) {
      release();
    }
    // Key up stays visible to everyone else.
    return false;
  }

  void _onFocus() {
    if (_session.value?.input case KeyHoldInput(:final focus?)
        when FocusManager.instance.primaryFocus != focus) {
      release();
    }
  }

  void dispose() {
    _disposed = true;
    _unlisten();
    clock.dispose();
    _session.dispose();
    for (final run in _runs.values) {
      run.controller.dispose();
    }
    _runs.clear();
  }
}
