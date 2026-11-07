import "dart:async";

import "package:flutter/widgets.dart";
import "package:flutter_test/flutter_test.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  // Each timer stands for a saved feedback expiry. Flutter fails a widget
  // test whose timer outlives the widget tree, so these tests fail unless
  // the panel releases the timer when it unmounts.
  testWidgets("a resource made before the pump ends with the panel", (
    tester,
  ) async {
    endWithTest(Timer(const Duration(seconds: 5), () {}).cancel);
    await tester.pumpPanel(
      const [],
      at: const PanelLocation.component(SizedBox()),
    );
  });

  testWidgets("a resource made after the pump ends with the panel", (
    tester,
  ) async {
    await tester.pumpPanel(
      const [],
      at: const PanelLocation.component(SizedBox()),
    );
    endWithTest(Timer(const Duration(seconds: 5), () {}).cancel);
  });

  testWidgets("pumping another panel keeps the test's resources", (
    tester,
  ) async {
    final timer = Timer(const Duration(seconds: 5), () {});
    endWithTest(timer.cancel);
    await tester.pumpPanel(
      const [],
      at: const PanelLocation.component(SizedBox()),
    );
    await tester.pumpPanel(
      const [],
      at: const PanelLocation.component(SizedBox()),
    );
    expect(timer.isActive, isTrue);
  });

  test("without a panel, resources end in tear down, newest first", () {
    final released = <String>[];
    addTearDown(() => expect(released, ["newer", "older"]));
    endWithTest(() => released.add("older"));
    endWithTest(() => released.add("newer"));
    expect(released, isEmpty);
  });
}
