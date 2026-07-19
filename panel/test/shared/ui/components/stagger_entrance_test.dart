import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/shared/ui/components/stagger_entrance.dart";

void main() {
  group("StaggerScope", () {
    testWidgets("orders entrances by vertical position", (tester) async {
      await _pumpScope(
        tester,
        children: const [
          Positioned(
            top: 120,
            left: 0,
            child: StaggerEntrance(child: _Box("bottom")),
          ),
          Positioned(
            top: 0,
            left: 0,
            child: StaggerEntrance(child: _Box("top")),
          ),
        ],
      );

      await tester.pump(const Duration(milliseconds: 50));

      expect(_opacity(tester, "top"), greaterThan(0));
      expect(_opacity(tester, "bottom"), 0);
    });

    testWidgets("orders entrances left-to-right on the same row", (
      tester,
    ) async {
      await _pumpScope(
        tester,
        children: const [
          Positioned(
            top: 0,
            left: 120,
            child: StaggerEntrance(child: _Box("right")),
          ),
          Positioned(
            top: 0,
            left: 0,
            child: StaggerEntrance(child: _Box("left")),
          ),
        ],
      );

      await tester.pump(const Duration(milliseconds: 50));

      expect(_opacity(tester, "left"), greaterThan(0));
      expect(_opacity(tester, "right"), 0);
    });

    testWidgets("nested scope reserves a contiguous group", (tester) async {
      await _pumpScope(
        tester,
        children: const [
          Positioned(top: 0, child: StaggerEntrance(child: _Box("before"))),
          Positioned(
            top: 50,
            child: StaggerScope(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  StaggerEntrance(child: _Box("nested-one")),
                  StaggerEntrance(child: _Box("nested-two")),
                ],
              ),
            ),
          ),
          Positioned(top: 200, child: StaggerEntrance(child: _Box("after"))),
        ],
      );

      await tester.pump(const Duration(milliseconds: 250));

      expect(_opacity(tester, "before"), greaterThan(0));
      expect(_opacity(tester, "nested-one"), greaterThan(0));
      expect(_opacity(tester, "nested-two"), greaterThan(0));
      expect(_opacity(tester, "after"), 0);

      await tester.pump(const Duration(milliseconds: 100));
      expect(_opacity(tester, "after"), greaterThan(0));
    });

    testWidgets("late entrance appears immediately and does not replay peers", (
      tester,
    ) async {
      final showLate = ValueNotifier(false);
      addTearDown(showLate.dispose);

      await tester.pumpWidget(
        _TestApp(
          child: StaggerScope(
            duration: const Duration(milliseconds: 200),
            interval: const Duration(milliseconds: 100),
            curve: Curves.linear,
            slideOffset: 0,
            child: ValueListenableBuilder(
              valueListenable: showLate,
              builder: (context, visible, child) => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const StaggerEntrance(child: _Box("initial")),
                  if (visible) const StaggerEntrance(child: _Box("late")),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));
      expect(_opacity(tester, "initial"), 1);

      showLate.value = true;
      await tester.pump();

      expect(_opacity(tester, "late"), 1);
      expect(_opacity(tester, "initial"), 1);
    });

    testWidgets("late nested scope appears immediately", (tester) async {
      final showLate = ValueNotifier(false);
      addTearDown(showLate.dispose);

      await tester.pumpWidget(
        _TestApp(
          child: StaggerScope(
            duration: const Duration(milliseconds: 100),
            child: ValueListenableBuilder(
              valueListenable: showLate,
              builder: (context, visible, child) => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const StaggerEntrance(child: _Box("initial")),
                  if (visible)
                    const StaggerScope(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          StaggerEntrance(child: _Box("late-one")),
                          StaggerEntrance(child: _Box("late-two")),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));

      showLate.value = true;
      await tester.pump();

      expect(_opacity(tester, "late-one"), 1);
      expect(_opacity(tester, "late-two"), 1);
    });

    testWidgets("compresses a large cohort into the launch cap", (
      tester,
    ) async {
      await _pumpScope(
        tester,
        interval: const Duration(milliseconds: 200),
        maxLaunchDuration: const Duration(milliseconds: 200),
        children: const [
          Positioned(top: 0, child: StaggerEntrance(child: _Box("one"))),
          Positioned(top: 50, child: StaggerEntrance(child: _Box("two"))),
          Positioned(top: 100, child: StaggerEntrance(child: _Box("three"))),
          Positioned(top: 150, child: StaggerEntrance(child: _Box("four"))),
        ],
      );

      await tester.pump(const Duration(milliseconds: 210));

      expect(_opacity(tester, "four"), greaterThan(0));
    });

    testWidgets("reduced motion reveals the initial cohort immediately", (
      tester,
    ) async {
      await tester.pumpWidget(
        const _TestApp(
          disableAnimations: true,
          child: StaggerScope(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                StaggerEntrance(child: _Box("one")),
                StaggerEntrance(child: _Box("two")),
              ],
            ),
          ),
        ),
      );
      await tester.pump();

      expect(_opacity(tester, "one"), 1);
      expect(_opacity(tester, "two"), 1);
    });

    testWidgets("asserts when an entrance has no scope", (tester) async {
      await tester.pumpWidget(
        const _TestApp(child: StaggerEntrance(child: _Box("unscoped"))),
      );

      final exception = tester.takeException();
      expect(exception, isA<AssertionError>());
      expect(exception.toString(), contains("below a StaggerScope"));
    });

    testWidgets("standalone sliver scope schedules sliver entrances", (
      tester,
    ) async {
      await tester.pumpWidget(
        const _TestApp(
          child: CustomScrollView(
            slivers: [
              SliverStaggerScope(
                duration: Duration(milliseconds: 200),
                interval: Duration(milliseconds: 100),
                curve: Curves.linear,
                slideOffset: 0,
                sliver: SliverMainAxisGroup(
                  slivers: [
                    SliverStaggerEntrance(
                      sliver: SliverToBoxAdapter(child: _Box("sliver-one")),
                    ),
                    SliverStaggerEntrance(
                      sliver: SliverToBoxAdapter(child: _Box("sliver-two")),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(_opacity(tester, "sliver-one"), greaterThan(0));
      expect(_opacity(tester, "sliver-one"), lessThan(1));
      expect(_opacity(tester, "sliver-two"), 0);
    });

    testWidgets("new scope after an async load animates the loaded cohort", (
      tester,
    ) async {
      final loaded = ValueNotifier(false);
      addTearDown(loaded.dispose);

      await tester.pumpWidget(
        _TestApp(
          child: ValueListenableBuilder<bool>(
            valueListenable: loaded,
            builder: (context, hasData, child) => CustomScrollView(
              slivers: [
                if (!hasData)
                  const SliverToBoxAdapter(child: _Box("loading"))
                else
                  const SliverStaggerScope(
                    duration: Duration(milliseconds: 200),
                    interval: Duration(milliseconds: 100),
                    curve: Curves.linear,
                    slideOffset: 0,
                    sliver: SliverMainAxisGroup(
                      slivers: [
                        SliverStaggerEntrance(
                          sliver: SliverToBoxAdapter(child: _Box("data-one")),
                        ),
                        SliverStaggerEntrance(
                          sliver: SliverToBoxAdapter(child: _Box("data-two")),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
      expect(find.byKey(const ValueKey("loading")), findsOneWidget);

      loaded.value = true;
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(_opacity(tester, "data-one"), greaterThan(0));
      expect(_opacity(tester, "data-one"), lessThan(1));
      expect(_opacity(tester, "data-two"), 0);
    });

    testWidgets("sliver slide moves only its painted child", (tester) async {
      await tester.pumpWidget(
        const _TestApp(
          child: CustomScrollView(
            slivers: [
              SliverStaggerScope(
                duration: Duration(milliseconds: 200),
                curve: Curves.linear,
                slideOffset: 0.5,
                sliver: SliverStaggerEntrance(
                  sliver: SliverToBoxAdapter(
                    child: SizedBox(
                      key: ValueKey("moving-sliver"),
                      height: 100,
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(key: ValueKey("plain-sliver"), height: 40),
              ),
            ],
          ),
        ),
      );
      await tester.pump();

      final movingStart = tester.getTopLeft(
        find.byKey(const ValueKey("moving-sliver")),
      );
      final plainStart = tester.getTopLeft(
        find.byKey(const ValueKey("plain-sliver")),
      );
      await tester.pump(const Duration(milliseconds: 200));
      final movingEnd = tester.getTopLeft(
        find.byKey(const ValueKey("moving-sliver")),
      );
      final plainEnd = tester.getTopLeft(
        find.byKey(const ValueKey("plain-sliver")),
      );

      expect(movingStart.dy, greaterThan(movingEnd.dy));
      expect(movingEnd.dy, 0);
      expect(plainEnd, plainStart);
    });

    testWidgets("late sliver entrance appears immediately", (tester) async {
      final showLate = ValueNotifier(false);
      addTearDown(showLate.dispose);
      await tester.pumpWidget(
        _TestApp(
          child: ValueListenableBuilder<bool>(
            valueListenable: showLate,
            builder: (context, visible, child) => CustomScrollView(
              slivers: [
                SliverStaggerScope(
                  duration: const Duration(milliseconds: 100),
                  sliver: SliverMainAxisGroup(
                    slivers: [
                      const SliverStaggerEntrance(
                        sliver: SliverToBoxAdapter(
                          child: _Box("initial-sliver"),
                        ),
                      ),
                      if (visible)
                        const SliverStaggerEntrance(
                          sliver: SliverToBoxAdapter(
                            child: _Box("late-sliver"),
                          ),
                        ),
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

      expect(_opacity(tester, "late-sliver"), 1);
    });

    testWidgets("reduced motion reveals slivers immediately", (tester) async {
      await tester.pumpWidget(
        const _TestApp(
          disableAnimations: true,
          child: CustomScrollView(
            slivers: [
              SliverStaggerScope(
                sliver: SliverStaggerEntrance(
                  sliver: SliverToBoxAdapter(child: _Box("reduced-sliver")),
                ),
              ),
            ],
          ),
        ),
      );
      await tester.pump();

      expect(_opacity(tester, "reduced-sliver"), 1);
    });

    testWidgets("asserts when a sliver entrance has no scope", (tester) async {
      final errors = <FlutterErrorDetails>[];
      final previousHandler = FlutterError.onError;
      FlutterError.onError = errors.add;
      addTearDown(() => FlutterError.onError = previousHandler);

      await tester.pumpWidget(
        const _TestApp(
          child: CustomScrollView(
            slivers: [
              SliverStaggerEntrance(
                sliver: SliverToBoxAdapter(child: _Box("unscoped-sliver")),
              ),
            ],
          ),
        ),
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

      await tester.pumpWidget(
        _TestApp(
          child: StaggerScope(
            duration: const Duration(milliseconds: 100),
            child: ValueListenableBuilder(
              valueListenable: showSecond,
              builder: (context, visible, child) => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const StaggerEntrance(
                    key: ValueKey("first-entrance"),
                    child: _Box("first"),
                  ),
                  if (visible)
                    const StaggerEntrance(
                      key: ValueKey("second-entrance"),
                      child: _Box("second"),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      showSecond.value = false;
      await tester.pump();

      expect(find.byKey(const ValueKey("second")), findsNothing);
      expect(_opacity(tester, "first"), 1);
      expect(tester.takeException(), isNull);
    });
  });
}

Future<void> _pumpScope(
  WidgetTester tester, {
  required List<Widget> children,
  Duration interval = const Duration(milliseconds: 100),
  Duration maxLaunchDuration = const Duration(seconds: 2),
}) async {
  await tester.pumpWidget(
    _TestApp(
      child: SizedBox(
        width: 300,
        height: 300,
        child: StaggerScope(
          duration: const Duration(milliseconds: 200),
          interval: interval,
          maxLaunchDuration: maxLaunchDuration,
          curve: Curves.linear,
          slideOffset: 0,
          child: Stack(children: children),
        ),
      ),
    ),
  );
  // Render schedules published by the first frame's post-frame callback.
  await tester.pump();
}

double _opacity(WidgetTester tester, String key) {
  final child = find.byKey(ValueKey(key));
  expect(child, findsOneWidget);

  final sliverFade = find.ancestor(
    of: child,
    matching: find.byType(SliverFadeTransition),
  );
  if (sliverFade.evaluate().isNotEmpty) {
    return tester.widget<SliverFadeTransition>(sliverFade.first).opacity.value;
  }

  final sliverOpacity = find.ancestor(
    of: child,
    matching: find.byType(SliverOpacity),
  );
  if (sliverOpacity.evaluate().isNotEmpty) {
    return tester.widget<SliverOpacity>(sliverOpacity.first).opacity;
  }

  final fade = find.ancestor(of: child, matching: find.byType(FadeTransition));
  if (fade.evaluate().isNotEmpty) {
    return tester.widget<FadeTransition>(fade.first).opacity.value;
  }

  final opacity = find.ancestor(of: child, matching: find.byType(Opacity));
  if (opacity.evaluate().isNotEmpty) {
    return tester.widget<Opacity>(opacity.first).opacity;
  }

  return 1;
}

class _Box extends StatelessWidget {
  const _Box(this.id);

  final String id;

  @override
  Widget build(BuildContext context) {
    return SizedBox(key: ValueKey(id), width: 40, height: 20);
  }
}

class _TestApp extends StatelessWidget {
  const _TestApp({required this.child, this.disableAnimations = false});

  final Widget child;
  final bool disableAnimations;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: disableAnimations),
        child: Scaffold(body: child),
      ),
    );
  }
}
