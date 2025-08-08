import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:responsive_framework/responsive_framework.dart";
import "package:typewriter_panel/widgets/generic/components/panes.dart";

void main() {
  Widget createTestApp({required Widget child}) {
    return ResponsiveBreakpoints.builder(
      breakpoints: const [
        Breakpoint(start: 0, end: 450, name: MOBILE),
        Breakpoint(start: 451, end: 800, name: TABLET),
        Breakpoint(start: 801, end: 1920, name: DESKTOP),
        Breakpoint(start: 1921, end: double.infinity, name: "4K"),
      ],
      child: ProviderScope(
        child: MaterialApp(
          home: Scaffold(body: child),
        ),
      ),
    );
  }

  group("Core Functionality Tests", () {
    testWidgets("panes register and unregister correctly", (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: Consumer(
            builder: (context, ref, child) {
              final panes = ref.watch(panesProvider);
              return Column(
                children: [
                  const Pane(
                    id: "test-pane",
                    child: Text("Test Pane"),
                  ),
                  Text("Pane count: ${panes.length}"),
                  if (panes.containsKey("test-pane"))
                    Text("Has test-pane: ${panes["test-pane"]?.enabled}"),
                ],
              );
            },
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text("Pane count: 1"), findsOneWidget);
      expect(find.text("Has test-pane: true"), findsOneWidget);
    });

    testWidgets("disabled panes register as disabled", (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: Consumer(
            builder: (context, ref, child) {
              final panes = ref.watch(panesProvider);
              final testPane = panes["disabled-pane"];
              return Column(
                children: [
                  const Pane(
                    id: "disabled-pane",
                    enabled: false,
                    child: Text("Disabled Pane"),
                  ),
                  if (testPane != null) Text("Enabled: ${testPane.enabled}"),
                ],
              );
            },
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text("Enabled: false"), findsOneWidget);
    });

    testWidgets("multiple panes register correctly", (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: Consumer(
            builder: (context, ref, child) {
              final panes = ref.watch(panesProvider);
              return Column(
                children: [
                  const Pane(id: "pane-1", child: Text("Pane 1")),
                  const Pane(id: "pane-2", child: Text("Pane 2")),
                  const Pane(id: "pane-3", child: Text("Pane 3")),
                  Text("Total panes: ${panes.length}"),
                ],
              );
            },
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text("Total panes: 3"), findsOneWidget);
    });
  });

  group("Navigation Logic Tests", () {
    testWidgets("navigation with empty state returns false", (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: GlobalPaneNavigator(
            child: Text("Empty state test"),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final container = tester.container();

      final result = container
          .read(panesProvider.notifier)
          .navigateInDirection(AxisDirection.right);

      expect(result, false);
    });

    testWidgets("navigation with only disabled panes returns false",
        (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: GlobalPaneNavigator(
            child: Column(
              children: [
                const Pane(
                  id: "disabled",
                  enabled: false,
                  child: Text("Disabled Pane"),
                ),
                Text("Test content"),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final container = tester.container();

      final panes = container.read(panesProvider);
      expect(panes.containsKey("disabled"), true);
      expect(panes["disabled"]?.enabled, false);

      final result = container
          .read(panesProvider.notifier)
          .navigateInDirection(AxisDirection.right);

      expect(result, false);
    });

    testWidgets("navigation logic works with focus management", (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: GlobalPaneNavigator(
            child: Row(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  margin: const EdgeInsets.all(10),
                  child: const Pane(
                    id: "left-pane",
                    trapFocus: false,
                    child: Text("Left"),
                  ),
                ),
                Container(
                  width: 100,
                  height: 100,
                  margin: const EdgeInsets.all(10),
                  child: const Pane(
                    id: "right-pane",
                    trapFocus: false,
                    child: Text("Right"),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final container = ProviderScope.containerOf(
        tester.element(find.byType(GlobalPaneNavigator)),
      );
      final notifier = container.read(panesProvider.notifier);
      final panes = container.read(panesProvider);

      panes["left-pane"]!.focusNode.requestFocus();
      await tester.pumpAndSettle();

      expect(panes["left-pane"]!.focusNode.hasFocus, true);
      expect(panes["right-pane"]!.focusNode.hasFocus, false);

      final result = notifier.navigateInDirection(AxisDirection.right);
      await tester.pumpAndSettle();

      expect(result, true);
      expect(panes["left-pane"]!.focusNode.hasFocus, false);
      expect(panes["right-pane"]!.focusNode.hasFocus, true);
    });

    testWidgets("horizontal navigation between panes works", (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: GlobalPaneNavigator(
            child: Row(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  margin: const EdgeInsets.all(10),
                  child: const Pane(
                    id: "left-pane",
                    trapFocus: false,
                    child: Text("Left"),
                  ),
                ),
                Container(
                  width: 100,
                  height: 100,
                  margin: const EdgeInsets.all(10),
                  child: const Pane(
                    id: "right-pane",
                    trapFocus: false,
                    child: Text("Right"),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final container = ProviderScope.containerOf(
        tester.element(find.byType(GlobalPaneNavigator)),
      );
      final notifier = container.read(panesProvider.notifier);
      final panes = container.read(panesProvider);

      panes["left-pane"]!.focusNode.requestFocus();
      await tester.pumpAndSettle();

      expect(panes["left-pane"]!.focusNode.hasFocus, true);
      expect(panes["right-pane"]!.focusNode.hasFocus, false);

      final rightResult = notifier.navigateInDirection(AxisDirection.right);
      await tester.pumpAndSettle();

      expect(rightResult, true);
      expect(panes["left-pane"]!.focusNode.hasFocus, false);
      expect(panes["right-pane"]!.focusNode.hasFocus, true);

      final leftResult = notifier.navigateInDirection(AxisDirection.left);
      await tester.pumpAndSettle();

      expect(leftResult, true);
      expect(panes["left-pane"]!.focusNode.hasFocus, true);
      expect(panes["right-pane"]!.focusNode.hasFocus, false);
    });

    testWidgets("vertical navigation between panes works", (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: GlobalPaneNavigator(
            child: Column(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  margin: const EdgeInsets.all(10),
                  child: const Pane(
                    id: "top-pane",
                    trapFocus: false,
                    child: Text("Top"),
                  ),
                ),
                Container(
                  width: 100,
                  height: 100,
                  margin: const EdgeInsets.all(10),
                  child: const Pane(
                    id: "bottom-pane",
                    trapFocus: false,
                    child: Text("Bottom"),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final container = ProviderScope.containerOf(
        tester.element(find.byType(GlobalPaneNavigator)),
      );
      final notifier = container.read(panesProvider.notifier);
      final panes = container.read(panesProvider);

      panes["top-pane"]!.focusNode.requestFocus();
      await tester.pumpAndSettle();

      expect(panes["top-pane"]!.focusNode.hasFocus, true);
      expect(panes["bottom-pane"]!.focusNode.hasFocus, false);

      final downResult = notifier.navigateInDirection(AxisDirection.down);
      await tester.pumpAndSettle();

      expect(downResult, true);
      expect(panes["top-pane"]!.focusNode.hasFocus, false);
      expect(panes["bottom-pane"]!.focusNode.hasFocus, true);

      final upResult = notifier.navigateInDirection(AxisDirection.up);
      await tester.pumpAndSettle();

      expect(upResult, true);
      expect(panes["top-pane"]!.focusNode.hasFocus, true);
      expect(panes["bottom-pane"]!.focusNode.hasFocus, false);
    });

    testWidgets("navigation skips disabled panes", (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: GlobalPaneNavigator(
            child: Row(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  margin: const EdgeInsets.all(10),
                  child: const Pane(
                    id: "pane-1",
                    trapFocus: false,
                    child: Text("Pane 1"),
                  ),
                ),
                Container(
                  width: 100,
                  height: 100,
                  margin: const EdgeInsets.all(10),
                  child: const Pane(
                    id: "pane-2",
                    enabled: false,
                    trapFocus: false,
                    child: Text("Pane 2 (Disabled)"),
                  ),
                ),
                Container(
                  width: 100,
                  height: 100,
                  margin: const EdgeInsets.all(10),
                  child: const Pane(
                    id: "pane-3",
                    trapFocus: false,
                    child: Text("Pane 3"),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final container = ProviderScope.containerOf(
        tester.element(find.byType(GlobalPaneNavigator)),
      );
      final notifier = container.read(panesProvider.notifier);
      final panes = container.read(panesProvider);

      panes["pane-1"]!.focusNode.requestFocus();
      await tester.pumpAndSettle();

      expect(panes["pane-1"]!.focusNode.hasFocus, true);
      expect(panes["pane-2"]!.focusNode.hasFocus, false);
      expect(panes["pane-3"]!.focusNode.hasFocus, false);

      final result = notifier.navigateInDirection(AxisDirection.right);
      await tester.pumpAndSettle();

      expect(result, true);
      expect(panes["pane-1"]!.focusNode.hasFocus, false);
      expect(panes["pane-2"]!.focusNode.hasFocus, false);
      expect(panes["pane-3"]!.focusNode.hasFocus, true);
    });

    testWidgets("navigation with no valid target returns false",
        (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: GlobalPaneNavigator(
            child: Column(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  margin: const EdgeInsets.all(10),
                  child: const Pane(
                    id: "only-pane",
                    child: Text("Only Pane"),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final container = ProviderScope.containerOf(
        tester.element(find.byType(GlobalPaneNavigator)),
      );
      final notifier = container.read(panesProvider.notifier);
      final panes = container.read(panesProvider);

      panes["only-pane"]!.focusNode.requestFocus();
      await tester.pumpAndSettle();

      final rightResult = notifier.navigateInDirection(AxisDirection.right);
      expect(rightResult, false);

      final leftResult = notifier.navigateInDirection(AxisDirection.left);
      expect(leftResult, false);

      final upResult = notifier.navigateInDirection(AxisDirection.up);
      expect(upResult, false);

      final downResult = notifier.navigateInDirection(AxisDirection.down);
      expect(downResult, false);

      expect(panes["only-pane"]!.focusNode.hasFocus, true);
    });

    testWidgets("navigation action system works", (tester) async {
      var callbackCalled = false;
      AxisDirection? capturedDirection;

      await tester.pumpWidget(
        createTestApp(
          child: Actions(
            actions: {
              NavigatePaneIntent: NavigationAction(
                isActionEnabled: true,
                callback: (direction) {
                  callbackCalled = true;
                  capturedDirection = direction;
                },
              ),
            },
            child: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    Actions.invoke(
                      context,
                      const NavigatePaneIntent(AxisDirection.down),
                    );
                  },
                  child: const Text("Navigate"),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text("Navigate"));
      await tester.pumpAndSettle();

      expect(callbackCalled, true);
      expect(capturedDirection, AxisDirection.down);
    });

    testWidgets("ray-casting finds closest pane in direction", (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: GlobalPaneNavigator(
            child: SizedBox(
              width: 600,
              height: 300,
              child: Stack(
                children: [
                  Positioned(
                    left: 50,
                    top: 100,
                    width: 100,
                    height: 100,
                    child: const Pane(
                      id: "center",
                      trapFocus: false,
                      child: Text("Center"),
                    ),
                  ),
                  Positioned(
                    left: 200,
                    top: 100,
                    width: 100,
                    height: 100,
                    child: const Pane(
                      id: "right-close",
                      trapFocus: false,
                      child: Text("Right Close"),
                    ),
                  ),
                  Positioned(
                    left: 350,
                    top: 100,
                    width: 100,
                    height: 100,
                    child: const Pane(
                      id: "right-far",
                      trapFocus: false,
                      child: Text("Right Far"),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final container = ProviderScope.containerOf(
        tester.element(find.byType(GlobalPaneNavigator)),
      );
      final notifier = container.read(panesProvider.notifier);
      final panes = container.read(panesProvider);

      panes["center"]!.focusNode.requestFocus();
      await tester.pumpAndSettle();

      expect(panes["center"]!.focusNode.hasFocus, true);
      expect(panes["right-close"]!.focusNode.hasFocus, false);
      expect(panes["right-far"]!.focusNode.hasFocus, false);

      final result = notifier.navigateInDirection(AxisDirection.right);
      await tester.pumpAndSettle();

      expect(result, true);
      expect(panes["center"]!.focusNode.hasFocus, false);
      expect(panes["right-close"]!.focusNode.hasFocus, true);
      expect(panes["right-far"]!.focusNode.hasFocus, false);
    });

    testWidgets("navigation works in complex grid layout", (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: GlobalPaneNavigator(
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      margin: const EdgeInsets.all(5),
                      child: const Pane(
                        id: "top-left",
                        trapFocus: false,
                        child: Text("TL"),
                      ),
                    ),
                    Container(
                      width: 100,
                      height: 100,
                      margin: const EdgeInsets.all(5),
                      child: const Pane(
                        id: "top-right",
                        trapFocus: false,
                        child: Text("TR"),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      margin: const EdgeInsets.all(5),
                      child: const Pane(
                        id: "bottom-left",
                        trapFocus: false,
                        child: Text("BL"),
                      ),
                    ),
                    Container(
                      width: 100,
                      height: 100,
                      margin: const EdgeInsets.all(5),
                      child: const Pane(
                        id: "bottom-right",
                        trapFocus: false,
                        child: Text("BR"),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final container = ProviderScope.containerOf(
        tester.element(find.byType(GlobalPaneNavigator)),
      );
      final notifier = container.read(panesProvider.notifier);
      final panes = container.read(panesProvider);

      panes["top-left"]!.focusNode.requestFocus();
      await tester.pumpAndSettle();
      expect(panes["top-left"]!.focusNode.hasFocus, true);

      final rightResult = notifier.navigateInDirection(AxisDirection.right);
      await tester.pumpAndSettle();
      expect(rightResult, true);
      expect(panes["top-right"]!.focusNode.hasFocus, true);

      final downResult = notifier.navigateInDirection(AxisDirection.down);
      await tester.pumpAndSettle();
      expect(downResult, true);
      expect(panes["bottom-right"]!.focusNode.hasFocus, true);

      final leftResult = notifier.navigateInDirection(AxisDirection.left);
      await tester.pumpAndSettle();
      expect(leftResult, true);
      expect(panes["bottom-left"]!.focusNode.hasFocus, true);

      final upResult = notifier.navigateInDirection(AxisDirection.up);
      await tester.pumpAndSettle();
      expect(upResult, true);
      expect(panes["top-left"]!.focusNode.hasFocus, true);
    });

    testWidgets("pane registration updates state correctly", (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: Consumer(
            builder: (context, ref, child) {
              final panes = ref.watch(panesProvider);
              return Column(
                children: [
                  const Pane(
                    id: "test-pane",
                    child: Text("Test Pane"),
                  ),
                  Text("Registered panes: ${panes.keys.join(', ')}"),
                ],
              );
            },
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text("Test Pane"), findsOneWidget);
      expect(find.text("Registered panes: test-pane"), findsOneWidget);

      final container = ProviderScope.containerOf(
        tester.element(find.byType(Consumer)),
      );
      final panes = container.read(panesProvider);
      expect(panes.containsKey("test-pane"), true);
      expect(panes["test-pane"]?.enabled, true);
    });
  });

  group("Widget Integration Tests", () {
    testWidgets("GlobalPaneNavigator renders and manages actions",
        (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: GlobalPaneNavigator(
            child: Consumer(
              builder: (context, ref, child) {
                final panes = ref.watch(panesProvider);
                return Column(
                  children: [
                    const Pane(id: "test", child: Text("Test")),
                    Text("Has panes: ${panes.isNotEmpty}"),
                  ],
                );
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text("Has panes: true"), findsOneWidget);
      expect(find.byType(GlobalPaneNavigator), findsOneWidget);
    });

    testWidgets("pane with custom properties works correctly", (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: GlobalPaneNavigator(
            child: Consumer(
              builder: (context, ref, child) {
                final panes = ref.watch(panesProvider);
                final customPane = panes["custom"];
                final enabledPane = panes["enabled"];
                return Column(
                  children: [
                    const Pane(
                      id: "enabled",
                      enabled: true,
                      trapFocus: false,
                      child: Text("Enabled Pane"),
                    ),
                    const Pane(
                      id: "custom",
                      enabled: false,
                      highlightOnFocus: false,
                      trapFocus: false,
                      margin: EdgeInsets.all(16),
                      child: Text("Custom Pane"),
                    ),
                    if (customPane != null)
                      Text("Custom enabled: ${customPane.enabled}"),
                    if (enabledPane != null)
                      Text("Enabled: ${enabledPane.enabled}"),
                  ],
                );
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text("Custom Pane"), findsOneWidget);
      expect(find.text("Enabled Pane"), findsOneWidget);

      expect(find.text("Custom enabled: false"), findsOneWidget);
      expect(find.text("Enabled: true"), findsOneWidget);

      final container = ProviderScope.containerOf(
        tester.element(find.byType(GlobalPaneNavigator)),
      );
      final notifier = container.read(panesProvider.notifier);
      final panes = container.read(panesProvider);

      panes["enabled"]!.focusNode.requestFocus();
      await tester.pumpAndSettle();
      expect(panes["enabled"]!.focusNode.hasFocus, true);

      final result = notifier.navigateInDirection(AxisDirection.down);
      expect(result, false);
      expect(panes["enabled"]!.focusNode.hasFocus, true);
      expect(panes["custom"]!.focusNode.hasFocus, false);
    });
  });

  group("Focus System Integration", () {
    testWidgets("focus and focus scope panes can coexist", (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: Consumer(
            builder: (context, ref, child) {
              final panes = ref.watch(panesProvider);
              return Column(
                children: [
                  const Pane(
                    id: "focus-scope",
                    trapFocus: true,
                    child: Text("Focus Scope"),
                  ),
                  const Pane(
                    id: "regular-focus",
                    trapFocus: false,
                    child: Text("Regular Focus"),
                  ),
                  Text("Total: ${panes.length}"),
                ],
              );
            },
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text("Focus Scope"), findsOneWidget);
      expect(find.text("Regular Focus"), findsOneWidget);
      expect(find.text("Total: 2"), findsOneWidget);
    });
  });

  group("PaneInfo Tests", () {
    test("PaneInfo bounds returns null when no render box", () {
      final focusNode = FocusNode();
      final key = GlobalKey();
      final paneInfo = PaneInfo(
        id: "test",
        focusNode: focusNode,
        key: key,
        enabled: true,
      );

      expect(paneInfo.bounds, isNull);
      expect(paneInfo.center, isNull);
    });
  });

  group("Provider State Management", () {
    test("panes provider registration", () {
      final container = ProviderContainer.test();
      final notifier = container.read(panesProvider.notifier);
      final focusNode = FocusNode();
      final key = GlobalKey();

      notifier.register("test", focusNode, key, enabled: true);

      final state = container.read(panesProvider);
      expect(state.length, 1);
      expect(state.containsKey("test"), true);
      expect(state["test"]?.id, "test");
      expect(state["test"]?.enabled, true);
    });

    test("panes provider unregistration", () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(panesProvider.notifier);
      final focusNode = FocusNode();
      final key = GlobalKey();

      notifier.register("test", focusNode, key, enabled: true);
      expect(container.read(panesProvider).length, 1);

      notifier.unregister("test");
      expect(container.read(panesProvider).length, 0);
    });

    test("unregistering nonexistent pane does nothing", () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(panesProvider.notifier);
      final focusNode = FocusNode();
      final key = GlobalKey();

      notifier.register("existing", focusNode, key, enabled: true);
      final initialState = container.read(panesProvider);

      notifier.unregister("nonexistent");
      final finalState = container.read(panesProvider);

      expect(finalState, equals(initialState));
      expect(finalState.containsKey("existing"), true);
    });
  });
}
