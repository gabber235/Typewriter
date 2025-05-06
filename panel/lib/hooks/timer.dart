import "dart:async";

import "package:flutter_hooks/flutter_hooks.dart";

void useTimer(Duration duration, Function(Timer) runner, {bool repeat = true}) {
  useEffect(
    () {
      Timer timer;
      void callback(Timer timer) {
        runner(timer);
        if (!repeat) {
          timer.cancel();
        }
      }

      timer = Timer.periodic(duration, callback);
      return () => timer.cancel();
    },
    [duration, repeat],
  );
}
