import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  group("StaggerScope", () {
    testWidgets("orders entrances by vertical position", (tester) async {
      final panel = await tester.mountComponent(
        const StaggerStage(
          children: [
            Positioned(top: 120, left: 0, child: EnteringBox("bottom")),
            Positioned(top: 0, left: 0, child: EnteringBox("top")),
          ],
        ),
      );
      // Render schedules published by the first frame's post-frame callback.
      await tester.pump();

      await tester.pump(const Duration(milliseconds: 50));

      expect(panel.opacityOf("top"), greaterThan(0));
      expect(panel.opacityOf("bottom"), 0);
    });

    testWidgets("orders entrances left-to-right on the same row", (
      tester,
    ) async {
      final panel = await tester.mountComponent(
        const StaggerStage(
          children: [
            Positioned(top: 0, left: 120, child: EnteringBox("right")),
            Positioned(top: 0, left: 0, child: EnteringBox("left")),
          ],
        ),
      );
      // Render schedules published by the first frame's post-frame callback.
      await tester.pump();

      await tester.pump(const Duration(milliseconds: 50));

      expect(panel.opacityOf("left"), greaterThan(0));
      expect(panel.opacityOf("right"), 0);
    });

    testWidgets("nested scope reserves a contiguous group", (tester) async {
      final panel = await tester.mountComponent(
        const StaggerStage(
          children: [
            Positioned(top: 0, child: EnteringBox("before")),
            Positioned(
              top: 50,
              child: StaggerScope(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    EnteringBox("nested-one"),
                    EnteringBox("nested-two"),
                  ],
                ),
              ),
            ),
            Positioned(top: 200, child: EnteringBox("after")),
          ],
        ),
      );
      // Render schedules published by the first frame's post-frame callback.
      await tester.pump();

      await tester.pump(const Duration(milliseconds: 250));

      expect(panel.opacityOf("before"), greaterThan(0));
      expect(panel.opacityOf("nested-one"), greaterThan(0));
      expect(panel.opacityOf("nested-two"), greaterThan(0));
      expect(panel.opacityOf("after"), 0);

      await tester.pump(const Duration(milliseconds: 100));
      expect(panel.opacityOf("after"), greaterThan(0));
    });

    testWidgets("late entrance appears immediately and does not replay peers", (
      tester,
    ) async {
      final showLate = ValueNotifier(false);
      addTearDown(showLate.dispose);

      final panel = await tester.mountComponent(
        StaggerScope(
          duration: const Duration(milliseconds: 200),
          interval: const Duration(milliseconds: 100),
          curve: Curves.linear,
          slideOffset: 0,
          child: ValueListenableBuilder(
            valueListenable: showLate,
            builder: (context, visible, child) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const EnteringBox("initial"),
                if (visible) const EnteringBox("late"),
              ],
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));
      expect(panel.opacityOf("initial"), 1);

      showLate.value = true;
      await tester.pump();

      expect(panel.opacityOf("late"), 1);
      expect(panel.opacityOf("initial"), 1);
    });

    testWidgets("late nested scope appears immediately", (tester) async {
      final showLate = ValueNotifier(false);
      addTearDown(showLate.dispose);

      final panel = await tester.mountComponent(
        StaggerScope(
          duration: const Duration(milliseconds: 100),
          child: ValueListenableBuilder(
            valueListenable: showLate,
            builder: (context, visible, child) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const EnteringBox("initial"),
                if (visible)
                  const StaggerScope(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        EnteringBox("late-one"),
                        EnteringBox("late-two"),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));

      showLate.value = true;
      await tester.pump();

      expect(panel.opacityOf("late-one"), 1);
      expect(panel.opacityOf("late-two"), 1);
    });

    testWidgets("compresses a large cohort into the launch cap", (
      tester,
    ) async {
      final panel = await tester.mountComponent(
        SizedBox(
          width: 300,
          height: 300,
          child: StaggerScope(
            duration: const Duration(milliseconds: 200),
            interval: const Duration(milliseconds: 200),
            maxLaunchDuration: const Duration(milliseconds: 200),
            curve: Curves.linear,
            slideOffset: 0,
            child: Stack(
              children: const [
                Positioned(top: 0, child: EnteringBox("one")),
                Positioned(top: 50, child: EnteringBox("two")),
                Positioned(top: 100, child: EnteringBox("three")),
                Positioned(top: 150, child: EnteringBox("four")),
              ],
            ),
          ),
        ),
      );
      // Render schedules published by the first frame's post-frame callback.
      await tester.pump();

      await tester.pump(const Duration(milliseconds: 210));

      expect(panel.opacityOf("four"), greaterThan(0));
    });

    testWidgets("reduced motion reveals the initial cohort immediately", (
      tester,
    ) async {
      final panel = await tester.mountComponent(
        ReducedMotion(
          child: StaggerScope(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [EnteringBox("one"), EnteringBox("two")],
            ),
          ),
        ),
      );
      await tester.pump();

      expect(panel.opacityOf("one"), 1);
      expect(panel.opacityOf("two"), 1);
    });

    testWidgets("asserts when an entrance has no scope", (tester) async {
      await tester.mountComponent(EnteringBox("unscoped"));

      final exception = tester.takeException();
      expect(exception, isA<AssertionError>());
      expect(exception.toString(), contains("below a StaggerScope"));
    });

    testWidgets("standalone sliver scope schedules sliver entrances", (
      tester,
    ) async {
      final panel = await tester.mountComponent(
        CustomScrollView(
          slivers: [
            SliverStaggerScope(
              duration: Duration(milliseconds: 200),
              interval: Duration(milliseconds: 100),
              curve: Curves.linear,
              slideOffset: 0,
              sliver: SliverMainAxisGroup(
                slivers: [
                  EnteringSliverBox("sliver-one"),
                  EnteringSliverBox("sliver-two"),
                ],
              ),
            ),
          ],
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(panel.opacityOf("sliver-one"), greaterThan(0));
      expect(panel.opacityOf("sliver-one"), lessThan(1));
      expect(panel.opacityOf("sliver-two"), 0);
    });

    testWidgets("new scope after an async load animates the loaded cohort", (
      tester,
    ) async {
      final loaded = ValueNotifier(false);
      addTearDown(loaded.dispose);

      final panel = await tester.mountComponent(
        ValueListenableBuilder<bool>(
          valueListenable: loaded,
          builder: (context, hasData, child) => CustomScrollView(
            slivers: [
              if (!hasData)
                const SliverToBoxAdapter(
                  child: LabeledBox("loading", width: 40, height: 20),
                )
              else
                const SliverStaggerScope(
                  duration: Duration(milliseconds: 200),
                  interval: Duration(milliseconds: 100),
                  curve: Curves.linear,
                  slideOffset: 0,
                  sliver: SliverMainAxisGroup(
                    slivers: [
                      EnteringSliverBox("data-one"),
                      EnteringSliverBox("data-two"),
                    ],
                  ),
                ),
            ],
          ),
        ),
      );
      expect(panel.box("loading"), findsOneWidget);

      loaded.value = true;
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(panel.opacityOf("data-one"), greaterThan(0));
      expect(panel.opacityOf("data-one"), lessThan(1));
      expect(panel.opacityOf("data-two"), 0);
    });

    testWidgets("sliver slide moves only its painted child", (tester) async {
      final panel = await tester.mountComponent(
        CustomScrollView(
          slivers: [
            SliverStaggerScope(
              duration: Duration(milliseconds: 200),
              curve: Curves.linear,
              slideOffset: 0.5,
              sliver: SliverStaggerEntrance(
                sliver: SliverToBoxAdapter(
                  child: LabeledBox("moving-sliver", height: 100),
                ),
              ),
            ),
            SliverToBoxAdapter(child: LabeledBox("plain-sliver", height: 40)),
          ],
        ),
      );
      await tester.pump();

      final movingStart = tester.getTopLeft(panel.box("moving-sliver"));
      final plainStart = tester.getTopLeft(panel.box("plain-sliver"));
      await tester.pump(const Duration(milliseconds: 200));
      final movingEnd = tester.getTopLeft(panel.box("moving-sliver"));
      final plainEnd = tester.getTopLeft(panel.box("plain-sliver"));

      expect(movingStart.dy, greaterThan(movingEnd.dy));
      expect(movingEnd.dy, 0);
      expect(plainEnd, plainStart);
    });

    testWidgets("late sliver entrance appears immediately", (tester) async {
      final showLate = ValueNotifier(false);
      addTearDown(showLate.dispose);
      final panel = await tester.mountComponent(
        ValueListenableBuilder<bool>(
          valueListenable: showLate,
          builder: (context, visible, child) => CustomScrollView(
            slivers: [
              SliverStaggerScope(
                duration: const Duration(milliseconds: 100),
                sliver: SliverMainAxisGroup(
                  slivers: [
                    const EnteringSliverBox("initial-sliver"),
                    if (visible) const EnteringSliverBox("late-sliver"),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));
      showLate.value = true;

      await tester.pump();

      expect(panel.opacityOf("late-sliver"), 1);
    });

    testWidgets("reduced motion reveals slivers immediately", (tester) async {
      final panel = await tester.mountComponent(
        ReducedMotion(
          child: CustomScrollView(
            slivers: [
              SliverStaggerScope(sliver: EnteringSliverBox("reduced-sliver")),
            ],
          ),
        ),
      );
      await tester.pump();

      expect(panel.opacityOf("reduced-sliver"), 1);
    });

    testWidgets("asserts when a sliver entrance has no scope", (tester) async {
      final errors = <FlutterErrorDetails>[];
      final previousHandler = FlutterError.onError;
      FlutterError.onError = errors.add;
      addTearDown(() => FlutterError.onError = previousHandler);

      await tester.mountComponent(
        CustomScrollView(slivers: [EnteringSliverBox("unscoped-sliver")]),
      );

      final exception = errors.first.exception;
      expect(exception, isA<AssertionError>());
      expect(
        exception.toString(),
        contains("below a StaggerScope or SliverStaggerScope"),
      );
    });

    testWidgets("removing an entrance does not restart retained entries", (
      tester,
    ) async {
      final showSecond = ValueNotifier(true);
      addTearDown(showSecond.dispose);

      final panel = await tester.mountComponent(
        StaggerScope(
          duration: const Duration(milliseconds: 100),
          child: ValueListenableBuilder(
            valueListenable: showSecond,
            builder: (context, visible, child) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const StaggerEntrance(
                  key: ValueKey("first-entrance"),
                  child: LabeledBox("first", width: 40, height: 20),
                ),
                if (visible)
                  const StaggerEntrance(
                    key: ValueKey("second-entrance"),
                    child: LabeledBox("second", width: 40, height: 20),
                  ),
              ],
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      showSecond.value = false;
      await tester.pump();

      expect(panel.box("second"), findsNothing);
      expect(panel.opacityOf("first"), 1);
      expect(tester.takeException(), isNull);
    });
  });
}
