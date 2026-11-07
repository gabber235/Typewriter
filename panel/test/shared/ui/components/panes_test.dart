import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  /// The primary pane "source" in the top left corner, where navigation
  /// starts.
  const sourcePane = PlacedPane(
    id: "source",
    button: "source",
    left: 0,
    top: 0,
    primary: true,
  );

  testWidgets("navigates in every direction and duplicate ids coexist", (
    tester,
  ) async {
    final panes = await tester.showPanes([
      PlacedPane(
        id: "duplicate",
        button: "center",
        left: 200,
        top: 200,
        primary: true,
      ),
      PlacedPane(id: "duplicate", button: "left", left: 50, top: 200),
      PlacedPane(id: "right", button: "right", left: 350, top: 200),
      PlacedPane(id: "up", button: "up", left: 200, top: 50),
      PlacedPane(id: "down", button: "down", left: 200, top: 350),
    ]);

    await tester.pump();

    await panes.navigate(AxisDirection.left);
    expect(FocusScope.of(tester.element(find.text("left"))).hasFocus, isTrue);
    await panes.navigate(AxisDirection.right);
    expect(FocusScope.of(tester.element(find.text("center"))).hasFocus, isTrue);
    await panes.navigate(AxisDirection.up);
    expect(FocusScope.of(tester.element(find.text("up"))).hasFocus, isTrue);

    await panes.navigate(AxisDirection.down);
    expect(FocusScope.of(tester.element(find.text("center"))).hasFocus, isTrue);
  });

  testWidgets("primary is a virtual origin and disabled panes are skipped", (
    tester,
  ) async {
    final panes = await tester.showPanes([
      PlacedPane(
        id: "primary",
        button: "primary",
        left: 0,
        top: 0,
        primary: true,
      ),
      PlacedPane(
        id: "disabled",
        button: "disabled",
        left: 100,
        top: 0,
        enabled: false,
      ),
      PlacedPane(id: "target", button: "target", left: 200, top: 0),
    ]);

    await tester.pump();
    await panes.navigate(AxisDirection.right);
    expect(FocusScope.of(tester.element(find.text("target"))).hasFocus, isTrue);
  });

  testWidgets("near diagonal beats farther aligned pane", (tester) async {
    final panes = await tester.showPanes([
      sourcePane,
      PlacedPane(id: "diagonal", button: "diagonal", left: 90, top: 90),
      PlacedPane(id: "aligned", button: "aligned", left: 300, top: 0),
    ]);

    await tester.pump();
    await panes.navigate(AxisDirection.right);
    expect(
      FocusScope.of(tester.element(find.text("diagonal"))).hasFocus,
      isTrue,
    );
  });

  testWidgets("left prefers sidebar while spanning appbar remains above", (
    tester,
  ) async {
    final panes = await tester.showPanes([
      Positioned(
        left: 225,
        top: 64,
        width: 900,
        height: 500,
        child: Pane(
          id: "main",
          primary: true,
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
          margin: EdgeInsets.zero,
          child: const Text("appbar"),
        ),
      ),
    ]);

    await tester.pump();

    await panes.navigate(AxisDirection.left);
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
    final showTarget = ValueNotifier(true);
    final targetWidth = ValueNotifier(80.0);
    addTearDown(showTarget.dispose);
    addTearDown(targetWidth.dispose);
    final panes = await tester.showPanes([
      sourcePane,
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
                    margin: EdgeInsets.zero,
                    child: Text("target"),
                  ),
                ),
              )
            : const SizedBox.shrink(),
      ),
      PlacedPane(
        id: "disabled",
        button: "disabled",
        left: 240,
        top: 0,
        enabled: false,
      ),
    ]);

    await tester.pump();
    final intent = const NavigatePaneIntent(AxisDirection.right);
    expect(Actions.find<NavigatePaneIntent>(panes.context), isNotNull);
    expect(
      Actions.find<NavigatePaneIntent>(panes.context).isEnabled(intent),
      isTrue,
    );

    targetWidth.value = 0;
    await tester.pump();
    await tester.pump();
    expect(
      Actions.find<NavigatePaneIntent>(panes.context).isEnabled(intent),
      isFalse,
    );

    targetWidth.value = 80;
    await tester.pump();
    await tester.pump();
    expect(
      Actions.find<NavigatePaneIntent>(panes.context).isEnabled(intent),
      isTrue,
    );
    showTarget.value = false;
    await tester.pump();

    await tester.pump();
    expect(
      Actions.find<NavigatePaneIntent>(panes.context).isEnabled(intent),
      isFalse,
    );
  });

  testWidgets(
    "navigation is deferred and restores the previously focused child",
    (tester) async {
      final rememberedFocus = FocusNode();
      addTearDown(rememberedFocus.dispose);
      final panes = await tester.showPanes([
        Positioned(
          left: 0,
          top: 0,
          width: 80,
          height: 80,
          child: Pane(
            id: "source",
            primary: true,
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
        PlacedPane(id: "target", button: "target", left: 120, top: 0),
      ]);

      await tester.pump();
      rememberedFocus.requestFocus();

      await tester.pump();
      Actions.invoke(
        panes.context,
        const NavigatePaneIntent(AxisDirection.right),
      );
      expect(rememberedFocus.hasFocus, isTrue);
      FocusScope.of(tester.element(find.text("target"))).requestFocus();
      await tester.pump();
      await panes.navigate(AxisDirection.left);

      expect(rememberedFocus.hasFocus, isTrue);
    },
  );

  testWidgets("last active pane is fallback after focus is cleared", (
    tester,
  ) async {
    final panes = await tester.showPanes([
      PlacedPane(id: "left", button: "left", left: 0, top: 0, primary: true),
      PlacedPane(id: "middle", button: "middle", left: 120, top: 0),
      PlacedPane(id: "right", button: "right", left: 240, top: 0),
    ]);

    await tester.pump();
    Focus.of(tester.element(find.text("middle"))).requestFocus();
    await tester.pump();
    FocusManager.instance.primaryFocus!.unfocus();

    await tester.pump();
    await panes.navigate(AxisDirection.right);
    expect(FocusScope.of(tester.element(find.text("right"))).hasFocus, isTrue);
  });

  testWidgets("target selection uses pane bounds instead of child bounds", (
    tester,
  ) async {
    final panes = await tester.showPanes([
      Positioned(
        left: 0,
        top: 100,
        width: 200,
        height: 200,
        child: Pane(
          id: "source",
          primary: true,
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
      PlacedPane(id: "lower first", button: "lower first", left: 210, top: 280),
      PlacedPane(
        id: "upper second",
        button: "upper second",
        left: 220,
        top: 100,
      ),
    ]);

    await tester.pump();
    Focus.of(tester.element(find.text("source child"))).requestFocus();
    await tester.pump();

    await panes.navigate(AxisDirection.right);

    expect(
      FocusScope.of(tester.element(find.text("lower first"))).hasFocus,
      isTrue,
    );
  });

  testWidgets("equal pane-bound distance uses registration order", (
    tester,
  ) async {
    final panes = await tester.showPanes([
      PlacedPane(
        id: "source",
        button: "source",
        left: 0,
        top: 100,
        primary: true,
      ),
      PlacedPane(id: "first", button: "first", left: 120, top: 20),
      PlacedPane(id: "second", button: "second", left: 120, top: 180),
    ]);

    await tester.pump();
    await panes.navigate(AxisDirection.right);
    expect(FocusScope.of(tester.element(find.text("first"))).hasFocus, isTrue);
  });

  testWidgets(
    "multiple eligible primaries assert when navigation is processed",
    (tester) async {
      final panes = await tester.showPanes([
        PlacedPane(id: "one", button: "one", left: 0, top: 0, primary: true),
        PlacedPane(id: "two", button: "two", left: 120, top: 0, primary: true),
      ]);

      await tester.pump();
      Actions.invoke(
        panes.context,
        const NavigatePaneIntent(AxisDirection.right),
      );
      await tester.pump();
      expect(tester.takeException(), isAssertionError);
    },
  );

  for (final trap in [true, false]) {
    testWidgets(
      "tab past the last control ${trap ? "wraps inside" : "leaves"} a pane "
      "that ${trap ? "traps" : "does not trap"} focus",
      (tester) async {
        final last = FocusNode();
        addTearDown(last.dispose);
        Widget control(String label, {FocusNode? focusNode}) => ElevatedButton(
          focusNode: focusNode,
          onPressed: () {},
          child: Text(label),
        );
        final panel = await tester.pumpPanel(
          const [],
          at: PanelLocation.component(
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Pane(
                  id: "pane",
                  primary: true,
                  trapFocus: trap,
                  margin: EdgeInsets.zero,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      control("first"),
                      control("last", focusNode: last),
                    ],
                  ),
                ),
                control("outside"),
              ],
            ),
          ),
        );

        last.requestFocus();
        await panel.settle();
        expect(panel.focused, "last");
        await panel.press(LogicalKeyboardKey.tab);

        expect(panel.focused, trap ? "first" : "outside");
      },
    );
  }

  testWidgets("removing a queued target is safe", (tester) async {
    final show = ValueNotifier(true);
    addTearDown(show.dispose);
    final panes = await tester.showPanes([
      sourcePane,
      ValueListenableBuilder<bool>(
        valueListenable: show,
        builder: (context, value, child) => value
            ? PlacedPane(id: "target", button: "target", left: 120, top: 0)
            : const SizedBox.shrink(),
      ),
    ]);

    await tester.pump();
    Actions.invoke(
      panes.context,
      const NavigatePaneIntent(AxisDirection.right),
    );

    show.value = false;
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets("disposing navigator cancels a queued move", (tester) async {
    final panes = await tester.showPanes([
      sourcePane,
      PlacedPane(id: "target", button: "target", left: 120, top: 0),
    ]);

    await tester.pump();
    Actions.invoke(
      panes.context,
      const NavigatePaneIntent(AxisDirection.right),
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();

    expect(tester.takeException(), isNull);
  });

  testWidgets("active route transition defers geometry until layout", (
    tester,
  ) async {
    final navigator = GlobalKey<NavigatorState>();
    Route<void> route(String label) => PageRouteBuilder<void>(
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) => Material(
        child: Pane(
          id: label,
          primary: true,
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

    final panes = await tester.showPanes([
      PlacedPane(id: "shell", button: "shell", left: 0, top: 0),
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
    ]);

    await tester.pump();

    unawaited(navigator.currentState!.push(route("incoming")));
    await tester.pump(Duration.zero, EnginePhase.build);
    Actions.invoke(panes.context, const NavigatePaneIntent(AxisDirection.left));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(FocusScope.of(tester.element(find.text("shell"))).hasFocus, isTrue);
    expect(find.text("outgoing"), findsOneWidget);
    expect(find.text("incoming"), findsOneWidget);
  });

  testWidgets("queued moves use fresh focus and translated geometry safely", (
    tester,
  ) async {
    final panes = await tester.showPanes([
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
            margin: EdgeInsets.zero,
            child: ElevatedButton(onPressed: () {}, child: const Text("one")),
          ),
        ),
      ),
      PlacedPane(id: "two", button: "two", left: 120, top: 0),
      PlacedPane(id: "three", button: "three", left: 240, top: 0),
    ]);

    await tester.pump();
    Actions.invoke(
      panes.context,
      const NavigatePaneIntent(AxisDirection.right),
    );
    Actions.invoke(
      panes.context,
      const NavigatePaneIntent(AxisDirection.right),
    );
    await tester.pump();

    expect(FocusScope.of(tester.element(find.text("three"))).hasFocus, isTrue);
    expect(tester.takeException(), isNull);
  });
}
