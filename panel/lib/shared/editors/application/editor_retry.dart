import "dart:async";
import "dart:math";

// ignore_for_file: one_member_abstracts

abstract interface class EditorDelayScheduler {
  Future<void> wait(Duration delay);
}

final class TimerEditorDelayScheduler implements EditorDelayScheduler {
  const TimerEditorDelayScheduler();

  @override
  Future<void> wait(Duration delay) => Future<void>.delayed(delay);
}

abstract interface class EditorJitterSource {
  Duration next(Duration maximum);
}

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
