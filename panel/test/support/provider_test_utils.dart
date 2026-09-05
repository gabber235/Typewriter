import "dart:async";

import "package:flutter_test/flutter_test.dart";
import "package:riverpod/misc.dart" show ProviderListenable;
import "package:riverpod/riverpod.dart";

Future<T> waitForProvider<T>(
  ProviderContainer container,
  ProviderListenable<T> provider,
  bool Function(T value) condition, {
  required String description,
  Duration timeout = const Duration(seconds: 2),
}) async {
  final completer = Completer<T>();
  T? lastState;
  var observedState = false;
  final subscription = container.listen(provider, (_, next) {
    observedState = true;
    lastState = next;
    if (!completer.isCompleted && condition(next)) completer.complete(next);
  }, fireImmediately: true);
  try {
    return await completer.future.timeout(
      timeout,
      onTimeout: () => throw TestFailure(
        "Timed out waiting for $description. "
        "Last state: ${observedState ? lastState : "none"}",
      ),
    );
  } finally {
    subscription.close();
  }
}
