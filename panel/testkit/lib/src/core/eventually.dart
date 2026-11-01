import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";

/// How long a test waits for an outcome before it fails.
const eventuallyTimeout = Duration(seconds: 5);

/// The one way a widget test waits: until [check] passes or [timeout] of
/// test time passed.
///
/// Advances fake time frame by frame, so it never sleeps and returns on the
/// first frame [check] holds. A [check] still failing at the deadline fails
/// the test with its own message.
extension Eventually on WidgetTester {
  Future<void> eventually(
    FutureOr<void> Function() check, {
    Duration timeout = eventuallyTimeout,
  }) async {
    const frame = Duration(milliseconds: 16);
    var waited = Duration.zero;
    while (true) {
      try {
        await check();
        return;
      } on TestFailure {
        if (waited >= timeout) rethrow;
      }
      await pump(frame);
      waited += frame;
    }
  }
}

/// The one way a test without widgets waits: until [check] passes or
/// [timeout] passed.
///
/// Lets pending work run between attempts and fails with [check]'s own
/// message at the deadline.
Future<void> eventually(
  FutureOr<void> Function() check, {
  Duration timeout = eventuallyTimeout,
}) async {
  final deadline = clock.now().add(timeout);
  while (true) {
    try {
      await check();
      return;
    } on TestFailure {
      if (!clock.now().isBefore(deadline)) rethrow;
    }
    await Future<void>.delayed(const Duration(milliseconds: 1));
  }
}

/// The one way a provider test waits: until [provider] holds a value
/// [condition] accepts, or [timeout] passed.
///
/// Listens instead of polling, so it returns the value that first satisfied
/// [condition]. The failure names [description] and the last value seen.
extension EventuallyProvider on ProviderContainer {
  Future<T> eventually<T>(
    ProviderListenable<T> provider,
    bool Function(T value) condition, {
    required String description,
    Duration timeout = eventuallyTimeout,
  }) async {
    final reached = Completer<T>();
    T? last;
    var observed = false;
    final subscription = listen(provider, (_, next) {
      observed = true;
      last = next;
      if (!reached.isCompleted && condition(next)) reached.complete(next);
    }, fireImmediately: true);
    try {
      return await reached.future.timeout(
        timeout,
        onTimeout: () => throw TestFailure(
          "Timed out waiting for $description. "
          "Last value: ${observed ? last : "none"}",
        ),
      );
    } finally {
      subscription.close();
    }
  }
}

/// The one way a test waits on a [Listenable] owner, such as an editing
/// workspace: until [read] gives a value [condition] accepts, or [timeout]
/// passed.
///
/// Listens instead of polling, so it serves plain and widget tests alike and
/// returns the value that first satisfied [condition]. The failure names
/// [description] and the last value seen.
extension EventuallyListenable on Listenable {
  Future<T> eventually<T>(
    T Function() read,
    bool Function(T value) condition, {
    required String description,
    Duration timeout = eventuallyTimeout,
  }) async {
    final reached = Completer<T>();
    var last = read();
    void check() {
      last = read();
      if (!reached.isCompleted && condition(last)) reached.complete(last);
    }

    addListener(check);
    try {
      check();
      return await reached.future.timeout(
        timeout,
        onTimeout: () => throw TestFailure(
          "Timed out waiting for $description. Last value: $last",
        ),
      );
    } finally {
      removeListener(check);
    }
  }
}
