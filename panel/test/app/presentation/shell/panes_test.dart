import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/app/presentation/shell/panes.dart";

void main() {
  Future<void> navigate(
    WidgetTester tester,
    GlobalKey actionContext,
    AxisDirection direction,
  ) async {
    Actions.invoke(
      actionContext.currentContext!,
      NavigatePaneIntent(direction),
    );
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump(const Duration(milliseconds: 1));
  }

  Widget harness({
    required GlobalKey actionContext,
    required List<Widget> children,
  }) => ProviderScope(
    child: MaterialApp(
      home: GlobalPaneNavigator(
        child: Builder(
          key: actionContext,
          builder: (context) => Scaffold(body: Stack(children: children)),
        ),
      ),
    ),
  );

  Widget positionedPane({
    required String id,
    required String button,
    required double left,
    required double top,
    bool enabled = true,
    bool primary = false,
  }) => Positioned(
    left: left,
    top: top,
    width: 80,
    height: 80,
    child: Pane(
      id: id,
      enabled: enabled,
      primary: primary,
      highlightOnFocus: false,
      margin: EdgeInsets.zero,
      child: ElevatedButton(onPressed: () {}, child: Text(button)),
    ),
  );

  testWidgets("navigates in every direction and duplicate ids coexist", (
    tester,
  ) async {
    final context = GlobalKey();
    await tester.pumpWidget(
      harness(
        actionContext: context,
        children: [
          positionedPane(
            id: "duplicate",
            button: "center",
            left: 200,
            top: 200,
            primary: true,
          ),
          positionedPane(id: "duplicate", button: "left", left: 50, top: 200),
          positionedPane(id: "right", button: "right", left: 350, top: 200),
          positionedPane(id: "up", button: "up", left: 200, top: 50),
          positionedPane(id: "down", button: "down", left: 200, top: 350),
        ],
      ),
    );
    await tester.pump();

    await navigate(tester, context, AxisDirection.left);
    expect(FocusScope.of(tester.element(find.text("left"))).hasFocus, isTrue);
    await navigate(tester, context, AxisDirection.right);
    expect(FocusScope.of(tester.element(find.text("center"))).hasFocus, isTrue);
    await navigate(tester, context, AxisDirection.up);
    expect(FocusScope.of(tester.element(find.text("up"))).hasFocus, isTrue);
    await navigate(tester, context, AxisDirection.down);
    expect(FocusScope.of(tester.element(find.text("center"))).hasFocus, isTrue);
  });

  testWidgets("primary is a virtual origin and disabled panes are skipped", (
    tester,
  ) async {
    final context = GlobalKey();
    await tester.pumpWidget(
      harness(
        actionContext: context,
        children: [
          positionedPane(
            id: "primary",
            button: "primary",
            left: 0,
            top: 0,
            primary: true,
          ),
          positionedPane(
            id: "disabled",
            button: "disabled",
            left: 100,
            top: 0,
            enabled: false,
          ),
          positionedPane(id: "target", button: "target", left: 200, top: 0),
        ],
      ),
    );
    await tester.pump();
    await navigate(tester, context, AxisDirection.right);
    expect(FocusScope.of(tester.element(find.text("target"))).hasFocus, isTrue);
  });

  testWidgets("near diagonal beats farther aligned pane", (tester) async {
    final context = GlobalKey();
    await tester.pumpWidget(
      harness(
        actionContext: context,
        children: [
          positionedPane(
            id: "source",
            button: "source",
            left: 0,
            top: 0,
            primary: true,
          ),
          positionedPane(id: "diagonal", button: "diagonal", left: 90, top: 90),
          positionedPane(id: "aligned", button: "aligned", left: 300, top: 0),
        ],
      ),
    );
    await tester.pump();
    await navigate(tester, context, AxisDirection.right);
    expect(
      FocusScope.of(tester.element(find.text("diagonal"))).hasFocus,
      isTrue,
    );
  });

  testWidgets("left prefers sidebar while spanning appbar remains above", (
    tester,
  ) async {
    final context = GlobalKey();
    await tester.pumpWidget(
      harness(
        actionContext: context,
        children: [
          Positioned(
            left: 225,
            top: 64,
            width: 900,
            height: 500,
            child: Pane(
              id: "main",
              primary: true,
              highlightOnFocus: false,
              margin: EdgeInsets.zero,
              child: const Text("main"),
            ),
          ),
          Positioned(
            left: 4,
            top: 64,
            width: 200,
            height: 500,
            child: Pane(
              id: "sidebar",
              highlightOnFocus: false,
              margin: EdgeInsets.zero,
              child: const Text("sidebar"),
            ),
          ),
          Positioned(
            left: 2,
            top: 2,
            width: 1120,
            height: 58,
            child: Pane(
              id: "appbar",
              highlightOnFocus: false,
              margin: EdgeInsets.zero,
              child: const Text("appbar"),
            ),
          ),
        ],
      ),
    );
    await tester.pump();

    await navigate(tester, context, AxisDirection.left);
    expect(
      FocusScope.of(tester.element(find.text("sidebar"))).hasFocus,
      isTrue,
    );
    expect(
      FocusScope.of(tester.element(find.text("appbar"))).hasFocus,
      isFalse,
    );
  });

  testWidgets("action eligibility follows removal, disabled, and zero size", (
    tester,
  ) async {
    final context = GlobalKey();
    final showTarget = ValueNotifier(true);
    final targetWidth = ValueNotifier(80.0);
    addTearDown(showTarget.dispose);
    addTearDown(targetWidth.dispose);
    await tester.pumpWidget(
      harness(
        actionContext: context,
        children: [
          positionedPane(
            id: "source",
            button: "source",
            left: 0,
            top: 0,
            primary: true,
          ),
          ValueListenableBuilder<bool>(
            valueListenable: showTarget,
            builder: (context, visible, child) => visible
                ? ValueListenableBuilder<double>(
                    valueListenable: targetWidth,
                    builder: (context, width, child) => Positioned(
                      left: 120,
                      top: 0,
                      width: width,
                      height: 80,
                      child: const Pane(
                        id: "target",
                        highlightOnFocus: false,
                        margin: EdgeInsets.zero,
                        child: Text("target"),
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          positionedPane(
            id: "disabled",
            button: "disabled",
            left: 240,
            top: 0,
            enabled: false,
          ),
        ],
      ),
    );
    await tester.pump();
    final intent = const NavigatePaneIntent(AxisDirection.right);
    expect(
      Actions.find<NavigatePaneIntent>(context.currentContext!),
      isNotNull,
    );
    expect(
      Actions.find<NavigatePaneIntent>(
        context.currentContext!,
      ).isEnabled(intent),
      isTrue,
    );

    targetWidth.value = 0;
    await tester.pump();
    await tester.pump();
    expect(
      Actions.find<NavigatePaneIntent>(
        context.currentContext!,
      ).isEnabled(intent),
      isFalse,
    );

    targetWidth.value = 80;
    await tester.pump();
    await tester.pump();
    expect(
      Actions.find<NavigatePaneIntent>(
        context.currentContext!,
      ).isEnabled(intent),
      isTrue,
    );
    showTarget.value = false;
    await tester.pump();
    await tester.pump();
    expect(
      Actions.find<NavigatePaneIntent>(
        context.currentContext!,
      ).isEnabled(intent),
      isFalse,
    );
  });

  testWidgets(
    "navigation is deferred and restores the previously focused child",
    (tester) async {
      final context = GlobalKey();
      final rememberedFocus = FocusNode();
      addTearDown(rememberedFocus.dispose);
      await tester.pumpWidget(
        harness(
          actionContext: context,
          children: [
            Positioned(
              left: 0,
              top: 0,
              width: 80,
              height: 80,
              child: Pane(
                id: "source",
                primary: true,
                highlightOnFocus: false,
                margin: EdgeInsets.zero,
                child: Column(
                  children: [
                    const Text("first"),
                    Focus(
                      focusNode: rememberedFocus,
                      child: const Text("remember"),
                    ),
                  ],
                ),
              ),
            ),
            positionedPane(id: "target", button: "target", left: 120, top: 0),
          ],
        ),
      );
      await tester.pump();
      rememberedFocus.requestFocus();
      await tester.pump();
      Actions.invoke(
        context.currentContext!,
        const NavigatePaneIntent(AxisDirection.right),
      );
      expect(rememberedFocus.hasFocus, isTrue);
      FocusScope.of(tester.element(find.text("target"))).requestFocus();
      await tester.pump();
      await navigate(tester, context, AxisDirection.left);
      expect(rememberedFocus.hasFocus, isTrue);
    },
  );

  testWidgets("last active pane is fallback after focus is cleared", (
    tester,
  ) async {
    final context = GlobalKey();
    await tester.pumpWidget(
      harness(
        actionContext: context,
        children: [
          positionedPane(
            id: "left",
            button: "left",
            left: 0,
            top: 0,
            primary: true,
          ),
          positionedPane(id: "middle", button: "middle", left: 120, top: 0),
          positionedPane(id: "right", button: "right", left: 240, top: 0),
        ],
      ),
    );
    await tester.pump();
    Focus.of(tester.element(find.text("middle"))).requestFocus();
    await tester.pump();
    FocusManager.instance.primaryFocus!.unfocus();
    await tester.pump();
    await navigate(tester, context, AxisDirection.right);
    expect(FocusScope.of(tester.element(find.text("right"))).hasFocus, isTrue);
  });

  testWidgets("target selection uses pane bounds instead of child bounds", (
    tester,
  ) async {
    final context = GlobalKey();
    await tester.pumpWidget(
      harness(
        actionContext: context,
        children: [
          Positioned(
            left: 0,
            top: 100,
            width: 200,
            height: 200,
            child: Pane(
              id: "source",
              primary: true,
              highlightOnFocus: false,
              margin: EdgeInsets.zero,
              child: Align(
                alignment: Alignment.topLeft,
                child: ElevatedButton(
                  onPressed: () {},
                  child: const Text("source child"),
                ),
              ),
            ),
          ),
          positionedPane(
            id: "lower first",
            button: "lower first",
            left: 210,
            top: 280,
          ),
          positionedPane(
            id: "upper second",
            button: "upper second",
            left: 220,
            top: 100,
          ),
        ],
      ),
    );
    await tester.pump();
    Focus.of(tester.element(find.text("source child"))).requestFocus();
    await tester.pump();

    await navigate(tester, context, AxisDirection.right);

    expect(
      FocusScope.of(tester.element(find.text("lower first"))).hasFocus,
      isTrue,
    );
  });

  testWidgets("equal pane-bound distance uses registration order", (
    tester,
  ) async {
    final context = GlobalKey();
    await tester.pumpWidget(
      harness(
        actionContext: context,
        children: [
          positionedPane(
            id: "source",
            button: "source",
            left: 0,
            top: 100,
            primary: true,
          ),
          positionedPane(id: "first", button: "first", left: 120, top: 20),
          positionedPane(id: "second", button: "second", left: 120, top: 180),
        ],
      ),
    );
    await tester.pump();
    await navigate(tester, context, AxisDirection.right);
    expect(FocusScope.of(tester.element(find.text("first"))).hasFocus, isTrue);
  });

  testWidgets(
    "multiple eligible primaries assert when navigation is processed",
    (tester) async {
      final context = GlobalKey();
      await tester.pumpWidget(
        harness(
          actionContext: context,
          children: [
            positionedPane(
              id: "one",
              button: "one",
              left: 0,
              top: 0,
              primary: true,
            ),
            positionedPane(
              id: "two",
              button: "two",
              left: 120,
              top: 0,
              primary: true,
            ),
          ],
        ),
      );
      await tester.pump();
      Actions.invoke(
        context.currentContext!,
        const NavigatePaneIntent(AxisDirection.right),
      );
      await tester.pump();
      expect(tester.takeException(), isAssertionError);
    },
  );

  testWidgets("trapFocus configures traversal edge behavior", (tester) async {
    final context = GlobalKey();
    await tester.pumpWidget(
      harness(
        actionContext: context,
        children: [
          positionedPane(
            id: "closed",
            button: "closed",
            left: 0,
            top: 0,
            primary: true,
          ),
          const Positioned(
            left: 120,
            top: 0,
            width: 80,
            height: 80,
            child: Pane(
              id: "parent",
              trapFocus: false,
              highlightOnFocus: false,
              margin: EdgeInsets.zero,
              child: Text("parent"),
            ),
          ),
        ],
      ),
    );
    expect(
      FocusScope.of(tester.element(find.text("closed"))).traversalEdgeBehavior,
      TraversalEdgeBehavior.closedLoop,
    );
    expect(
      FocusScope.of(tester.element(find.text("parent"))).traversalEdgeBehavior,
      TraversalEdgeBehavior.parentScope,
    );
  });

  testWidgets("removing a queued target is safe", (tester) async {
    final context = GlobalKey();
    final show = ValueNotifier(true);
    addTearDown(show.dispose);
    await tester.pumpWidget(
      harness(
        actionContext: context,
        children: [
          positionedPane(
            id: "source",
            button: "source",
            left: 0,
            top: 0,
            primary: true,
          ),
          ValueListenableBuilder<bool>(
            valueListenable: show,
            builder: (context, value, child) => value
                ? positionedPane(
                    id: "target",
                    button: "target",
                    left: 120,
                    top: 0,
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
    await tester.pump();
    Actions.invoke(
      context.currentContext!,
      const NavigatePaneIntent(AxisDirection.right),
    );
    show.value = false;
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets("disposing navigator cancels a queued move", (tester) async {
    final context = GlobalKey();
    await tester.pumpWidget(
      harness(
        actionContext: context,
        children: [
          positionedPane(
            id: "source",
            button: "source",
            left: 0,
            top: 0,
            primary: true,
          ),
          positionedPane(id: "target", button: "target", left: 120, top: 0),
        ],
      ),
    );
    await tester.pump();
    Actions.invoke(
      context.currentContext!,
      const NavigatePaneIntent(AxisDirection.right),
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();

    expect(tester.takeException(), isNull);
  });

  testWidgets("active route transition defers geometry until layout", (
    tester,
  ) async {
    final context = GlobalKey();
    final navigator = GlobalKey<NavigatorState>();
    Route<void> route(String label) => PageRouteBuilder<void>(
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) => Material(
        child: Pane(
          id: label,
          primary: true,
          highlightOnFocus: false,
          margin: EdgeInsets.zero,
          child: Center(child: Text(label)),
        ),
      ),
      transitionsBuilder: (context, animation, secondaryAnimation, child) =>
          SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1, 0),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
    );

    await tester.pumpWidget(
      harness(
        actionContext: context,
        children: [
          positionedPane(id: "shell", button: "shell", left: 0, top: 0),
          Positioned(
            left: 120,
            top: 0,
            width: 300,
            height: 300,
            child: Navigator(
              key: navigator,
              onGenerateRoute: (_) => route("outgoing"),
            ),
          ),
        ],
      ),
    );
    await tester.pump();

    navigator.currentState!.push(route("incoming"));
    await tester.pump(Duration.zero, EnginePhase.build);
    Actions.invoke(
      context.currentContext!,
      const NavigatePaneIntent(AxisDirection.left),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(FocusScope.of(tester.element(find.text("shell"))).hasFocus, isTrue);
    expect(find.text("outgoing"), findsOneWidget);
    expect(find.text("incoming"), findsOneWidget);
  });

  testWidgets("queued moves use fresh focus and translated geometry safely", (
    tester,
  ) async {
    final context = GlobalKey();
    await tester.pumpWidget(
      harness(
        actionContext: context,
        children: [
          Positioned(
            left: 0,
            top: 0,
            width: 80,
            height: 80,
            child: FractionalTranslation(
              translation: const Offset(0.1, 0),
              child: Pane(
                id: "one",
                primary: true,
                highlightOnFocus: false,
                margin: EdgeInsets.zero,
                child: ElevatedButton(
                  onPressed: () {},
                  child: const Text("one"),
                ),
              ),
            ),
          ),
          positionedPane(id: "two", button: "two", left: 120, top: 0),
          positionedPane(id: "three", button: "three", left: 240, top: 0),
        ],
      ),
    );
    await tester.pump();
    Actions.invoke(
      context.currentContext!,
      const NavigatePaneIntent(AxisDirection.right),
    );
    Actions.invoke(
      context.currentContext!,
      const NavigatePaneIntent(AxisDirection.right),
    );
    await tester.pump();
    expect(FocusScope.of(tester.element(find.text("three"))).hasFocus, isTrue);
    expect(tester.takeException(), isNull);
  });
}
