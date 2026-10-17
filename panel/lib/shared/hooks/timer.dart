import "package:typewriter_panel/typewriter_panel.dart";

/// Runs [runner] on a periodic timer owned by this hook.
///
/// The first callback occurs after [duration]. The timer is canceled when the
/// widget is disposed or when [duration], [repeat], or one of [keys] changes.
/// With [repeat] false, the callback runs once and then cancels its timer. The
/// callback receives the timer so it can cancel or inspect it directly.
void useTimer(
  Duration duration,
  Function(Timer) runner, {
  bool repeat = true,
  List<Object?> keys = const [],
}) {
  useEffect(() {
    Timer timer;
    void callback(Timer timer) {
      runner(timer);
      if (!repeat) {
        timer.cancel();
      }
    }

    timer = Timer.periodic(duration, callback);
    return () => timer.cancel();
  }, [duration, repeat, ...keys]);
}
