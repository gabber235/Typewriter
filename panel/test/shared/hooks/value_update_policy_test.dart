import "package:fake_async/fake_async.dart";
import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";

void main() {
  const window = Duration(milliseconds: 100);

  test("fixed windows keep progressing and publish only the latest input", () {
    fakeAsync((time) {
      final controller = const CoalesceUpdates<int>().create(0);
      final displayed = <int>[];
      controller.addListener(() => displayed.add(controller.value));
      expect(controller.value, 0);
      for (var input = 1; input <= 10; input++) {
        controller.observe(input);
        time.elapse(const Duration(milliseconds: 30));
      }
      expect(displayed, [4, 8]);
      time.elapse(const Duration(milliseconds: 40));
      expect(displayed, [4, 8, 10]);
      controller.dispose();
    });
  });

  test("returning and diverging keeps the original fixed deadline", () {
    fakeAsync((time) {
      final controller = const CoalesceUpdates<int>().create(0)..observe(1);
      time.elapse(const Duration(milliseconds: 40));
      controller.observe(0);
      time.elapse(const Duration(milliseconds: 50));
      controller.observe(2);
      time.elapse(const Duration(milliseconds: 9));
      expect(controller.value, 0);
      time.elapse(const Duration(milliseconds: 1));
      expect(controller.value, 2);
      controller.dispose();
    });
  });

  test("debounce waits for distinct input to become quiet", () {
    fakeAsync((time) {
      final controller = const DebounceUpdates<int>().create(0);
      for (var input = 1; input <= 5; input++) {
        controller.observe(input);
        time.elapse(const Duration(milliseconds: 50));
        expect(controller.value, 0);
      }
      controller.observe(5);
      time.elapse(const Duration(milliseconds: 49));
      expect(controller.value, 0);
      time.elapse(const Duration(milliseconds: 1));
      expect(controller.value, 5);
      controller.dispose();
    });
  });

  for (final policy in <ValueUpdatePolicy<int>>[
    const CoalesceUpdates<int>(),
    const DebounceUpdates<int>(),
  ]) {
    group(policy.runtimeType.toString(), () {
      test("equal values and transient returns do not notify", () {
        fakeAsync((time) {
          final controller = policy.create(0);
          var notifications = 0;
          controller
            ..addListener(() => notifications++)
            ..observe(0)
            ..observe(1);
          time.elapse(const Duration(milliseconds: 40));
          controller.observe(0);
          time.elapse(window * 2);
          expect(controller.value, 0);
          expect(notifications, 0);
          controller.dispose();
        });
      });

      test("a shared policy creates independent controller lifetimes", () {
        fakeAsync((time) {
          final first = policy.create(0);
          final second = policy.create(10);
          first.observe(1);
          time.elapse(const Duration(milliseconds: 40));
          second.observe(11);
          first.dispose();
          time.elapse(window);
          expect(second.value, 11);
          expect(time.nonPeriodicTimerCount, 0);
          second.dispose();
        });
      });

      test("disposal cancels pending notifications", () {
        fakeAsync((time) {
          policy.create(0)
            ..addListener(() => fail("Notification after disposal"))
            ..observe(1)
            ..dispose();
          expect(time.nonPeriodicTimerCount, 0);
          time.elapse(window);
        });
      });
    });
  }

  test("zero duration defers until the event turn", () {
    fakeAsync((time) {
      for (final policy in <ValueUpdatePolicy<int>>[
        const CoalesceUpdates<int>(duration: Duration.zero),
        const DebounceUpdates<int>(duration: Duration.zero),
      ]) {
        final controller = policy.create(0)..observe(1);
        expect(controller.value, 0);
        time.elapse(Duration.zero);
        expect(controller.value, 1);
        controller.dispose();
      }
    });
  });

  test("negative durations are rejected at controller creation", () {
    const negative = Duration(milliseconds: -1);
    expect(
      () => const CoalesceUpdates<int>(duration: negative).create(0),
      throwsArgumentError,
    );
    expect(
      () => const DebounceUpdates<int>(duration: negative).create(0),
      throwsArgumentError,
    );
  });
}
