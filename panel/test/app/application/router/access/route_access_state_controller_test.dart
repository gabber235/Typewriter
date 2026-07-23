import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/app/application/router/access/route_access_state_controller.dart";

void main() {
  test("stable initial state emits once when it changes", () {
    final controller = RouteAccessStateController<String, String>(
      initialState: "a",
      isPending: (_) => false,
      stableStateOf: (state) => state,
    );
    var notifications = 0;
    controller.reevaluation.addListener(() => notifications++);

    controller.transitionTo("b");

    expect(notifications, 1);
    controller.dispose();
  });

  test("stable initial state emits nothing when unchanged", () {
    final controller = RouteAccessStateController<String, String>(
      initialState: "a",
      isPending: (_) => false,
      stableStateOf: (state) => state,
    );
    var notifications = 0;
    controller.reevaluation.addListener(() => notifications++);

    controller.transitionTo("a");

    expect(notifications, 0);
    controller.dispose();
  });

  test("filters reevaluation by stable projection", () async {
    final controller = RouteAccessStateController<String, String>(
      initialState: "loading",
      isPending: (state) => state == "loading",
      stableStateOf: (state) =>
          state == "loading" || state == "unavailable" ? null : state,
    );
    var ready = false;
    final waiting = controller.waitUntilReady().then((_) => ready = true);
    var notifications = 0;
    controller.reevaluation.addListener(() => notifications++);

    await Future<void>.value();
    expect(ready, isFalse);
    controller.transitionTo("a");
    await waiting;
    expect(notifications, 0);

    controller
      ..transitionTo("loading")
      ..transitionTo("unavailable")
      ..transitionTo("a");
    expect(notifications, 0);

    controller
      ..transitionTo("loading")
      ..transitionTo("b")
      ..transitionTo("b");
    expect(notifications, 1);
    controller.dispose();
  });

  test("disposal completes readiness and is idempotent", () async {
    final controller = RouteAccessStateController<String, String>(
      initialState: "loading",
      isPending: (state) => state == "loading",
      stableStateOf: (state) => state == "loading" ? null : state,
    );
    final waiting = controller.waitUntilReady();
    controller
      ..dispose()
      ..dispose();
    await waiting;
    expect(
      () => controller.transitionTo("ready"),
      throwsA(isA<AssertionError>()),
    );
  });
}
