import "package:typewriter_panel/typewriter_panel.dart";

// ignore_for_file: one_member_abstracts

/// Schedules editor debounce and conflict retry work.
///
/// The abstraction keeps time outside the editor state machine, so production
/// uses timers while tests can complete scheduled work deterministically.
abstract interface class EditorDelayScheduler {
  EditorScheduledTask schedule(Duration delay);
}

/// Represents one cancellable editor scheduling decision.
abstract interface class EditorScheduledTask {
  Future<EditorTaskCompletion> get completed;

  void cancel();
}

enum EditorTaskCompletion { executed, cancelled }

final class TimerEditorDelayScheduler implements EditorDelayScheduler {
  const TimerEditorDelayScheduler();

  @override
  EditorScheduledTask schedule(Duration delay) =>
      _TimerEditorScheduledTask(delay);
}

final class _TimerEditorScheduledTask implements EditorScheduledTask {
  _TimerEditorScheduledTask(Duration delay) {
    _timer = Timer(delay, () => _complete(EditorTaskCompletion.executed));
  }

  final Completer<EditorTaskCompletion> _completion =
      Completer<EditorTaskCompletion>();
  late final Timer _timer;

  @override
  Future<EditorTaskCompletion> get completed => _completion.future;

  @override
  void cancel() {
    if (_completion.isCompleted) return;
    _timer.cancel();
    _complete(EditorTaskCompletion.cancelled);
  }

  void _complete(EditorTaskCompletion completion) {
    if (_completion.isCompleted) return;
    _completion.complete(completion);
  }
}

/// Supplies bounded random delay used to spread retry attempts.
abstract interface class EditorJitterSource {
  Duration next(Duration maximum);
}

/// Production jitter source backed by a pseudo random generator.
final class RandomEditorJitterSource implements EditorJitterSource {
  RandomEditorJitterSource([Random? random]) : _random = random ?? Random();

  final Random _random;

  @override
  Duration next(Duration maximum) {
    final upper = maximum.inMicroseconds;
    if (upper <= 0) return Duration.zero;
    return Duration(microseconds: _random.nextInt(upper + 1));
  }
}
