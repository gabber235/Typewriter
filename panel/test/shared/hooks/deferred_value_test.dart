import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  testWidgets("initial output is immediate and equal policies keep deadlines", (
    tester,
  ) async {
    var input = 0;
    ValueUpdatePolicy<int>? policy;
    Future<void> build() => tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: HookBuilder(
          builder: (context) =>
              Text("${useDeferredValue(input, policy: policy)}"),
        ),
      ),
    );
    await build();
    expect(find.text("0"), findsOneWidget);
    input = 1;
    await build();
    await tester.pump(const Duration(milliseconds: 40));
    policy = CoalesceUpdates<int>();
    input = 2;
    await build();
    await tester.pump(const Duration(milliseconds: 59));
    expect(find.text("0"), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1));
    expect(find.text("2"), findsOneWidget);
  });

  testWidgets(
    "policy replacement retains output and cancels the old deadline",
    (tester) async {
      var input = 0;
      ValueUpdatePolicy<int> policy = const CoalesceUpdates<int>();
      Future<void> build() => tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: HookBuilder(
            builder: (context) =>
                Text("${useDeferredValue(input, policy: policy)}"),
          ),
        ),
      );
      await build();
      input = 1;
      await build();
      await tester.pump(const Duration(milliseconds: 40));
      policy = const DebounceUpdates<int>();
      await build();
      await tester.pump(const Duration(milliseconds: 60));
      expect(find.text("0"), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 40));
      expect(find.text("1"), findsOneWidget);

      input = 2;
      await build();
      await tester.pump(const Duration(milliseconds: 40));
      policy = const DebounceUpdates<int>(
        duration: Duration(milliseconds: 200),
      );
      await build();
      await tester.pump(const Duration(milliseconds: 199));
      expect(find.text("1"), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 1));
      expect(find.text("2"), findsOneWidget);
    },
  );

  testWidgets("widget keys reset output and disposal cancels pending work", (
    tester,
  ) async {
    var input = 0;
    var scope = "first";
    Future<void> build() => tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: HookBuilder(
          key: ValueKey(scope),
          builder: (context) => Text("${useDeferredValue(input)}"),
        ),
      ),
    );
    await build();
    input = 1;
    await build();
    scope = "second";
    input = 2;
    await build();
    expect(find.text("2"), findsOneWidget);
    input = 3;
    await build();
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    "custom controllers can notify during observation and afterward",
    (tester) async {
      final policy = ImmediateUpdatePolicy();
      var input = 0;
      var builds = 0;
      Future<void> build() => tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: HookBuilder(
            builder: (context) {
              builds++;
              return Text("${useDeferredValue(input, policy: policy)}");
            },
          ),
        ),
      );
      await build();
      input = 1;
      await build();
      expect(find.text("1"), findsOneWidget);
      final settledBuilds = builds;
      await tester.pump();
      expect(builds, settledBuilds);
      policy.controller.value = 2;
      await tester.pump();
      expect(find.text("2"), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      expect(policy.controller.disposed, isTrue);
    },
  );
}
