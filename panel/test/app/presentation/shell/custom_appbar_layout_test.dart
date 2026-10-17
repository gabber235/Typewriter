import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";

import "../../../support/test_utils.dart";

void main() {
  const navigationKey = ValueKey("navigation_content");
  const searchKey = ValueKey("search_content");
  const activityKey = ValueKey("activity_content");
  const modeKey = ValueKey("mode_content");
  const sidebarKey = ValueKey("sidebar_content");

  Widget layout(double width, {int activityOrder = 1, int modeOrder = 2}) =>
      SizedBox(
        width: width,
        height: 48,
        child: CustomAppBarLayout(
          spacing: 8,
          navigation: const SizedBox(
            key: navigationKey,
            width: 100,
            height: 20,
          ),
          primary: AppBarItem.adaptive(
            key: const ValueKey("search"),
            collapseOrder: 0,
            child: const SizedBox(key: searchKey, width: 200, height: 40),
          ),
          actions: [
            AppBarItem.adaptive(
              key: const ValueKey("activity"),
              collapseOrder: activityOrder,
              child: const SizedBox(key: activityKey, width: 120, height: 40),
            ),
            AppBarItem.expandedOnly(
              key: const ValueKey("mode"),
              collapseOrder: modeOrder,
              child: const SizedBox(key: modeKey, width: 50, height: 40),
            ),
            AppBarItem.compactOnly(
              key: const ValueKey("sidebar"),
              collapseOrder: modeOrder,
              child: const SizedBox(key: sidebarKey, width: 48, height: 40),
            ),
          ],
        ),
      );

  testWidgets("empty allocated controls stay live without interaction", (
    tester,
  ) async {
    final contentWidth = ValueNotifier(0.0);
    final policy = ValueNotifier<AppBarItemPolicy>(
      const AppBarItemPolicy.fixed(),
    );
    final routeActive = ValueNotifier(true);
    final focus = FocusNode();
    addTearDown(contentWidth.dispose);
    addTearDown(policy.dispose);
    addTearDown(routeActive.dispose);
    addTearDown(focus.dispose);
    final semantics = tester.ensureSemantics();
    final extent = Provider((ref) {
      contentWidth.addListener(ref.invalidateSelf);
      ref.onDispose(() => contentWidth.removeListener(ref.invalidateSelf));
      return contentWidth.value;
    });
    var taps = 0;
    final control = Consumer(
      key: const ValueKey("live control"),
      builder: (context, ref, _) => Focus(
        focusNode: focus,
        child: Semantics(
          label: "Live activity",
          button: true,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => taps++,
            child: SizedBox(width: ref.watch(extent), height: 40),
          ),
        ),
      ),
    );
    await tester.pumpTestApp(
      child: Center(
        child: AnimatedBuilder(
          animation: Listenable.merge([policy, routeActive]),
          builder: (context, _) => TickerMode(
            enabled: routeActive.value,
            child: SizedBox(
              width: 700,
              height: 48,
              child: CustomAppBarLayout(
                navigation: const SizedBox(width: 100),
                primary: AppBarItem.fixed(
                  key: const ValueKey("primary"),
                  child: const SizedBox(width: 200),
                ),
                actions: [
                  AppBarItem(
                    key: const ValueKey("activity"),
                    policy: policy.value,
                    child: control,
                  ),
                ],
                spacing: 8,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final element = tester.element(find.byKey(const ValueKey("live control")));
    expect(TickerMode.valuesOf(element).enabled, isTrue);
    expect(AppBarItemVisibility.of(element), isFalse);
    expect(focus.canRequestFocus, isFalse);
    expect(find.semantics.byLabel("Live activity"), findsNothing);
    expect(
      find.byKey(const ValueKey("live control")).hitTestable(),
      findsNothing,
    );

    for (final width in [96.0, 0.0, 120.0]) {
      contentWidth.value = width;
      await tester.pumpAndSettle();
      expect(
        tester.element(find.byKey(const ValueKey("live control"))),
        same(element),
      );
      expect(
        tester.getSize(find.byKey(const ValueKey("live control"))).width,
        width,
      );
      expect(TickerMode.valuesOf(element).enabled, isTrue);
      expect(focus.canRequestFocus, width > 0);
      expect(AppBarItemVisibility.of(element), width > 0);
      expect(
        find.semantics.byLabel("Live activity"),
        width > 0 ? findsOne : findsNothing,
      );
      if (width > 0) {
        focus.requestFocus();
        await tester.pump();
        expect(focus.hasFocus, isTrue);
        await tester.tap(find.byKey(const ValueKey("live control")));
      } else {
        expect(focus.hasFocus, isFalse);
      }
    }
    expect(taps, 2);

    contentWidth.value = 0;
    await tester.pumpAndSettle();
    // At this width a compact only item is hidden, even with identical geometry.
    policy.value = const AppBarItemPolicy.compactOnly(0);
    await tester.pumpAndSettle();
    expect(TickerMode.valuesOf(element).enabled, isFalse);
    expect(focus.canRequestFocus, isFalse);
    contentWidth.value = 80;
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byKey(const ValueKey("live control"))).width, 0);
    policy.value = const AppBarItemPolicy.fixed();
    await tester.pumpAndSettle();
    expect(TickerMode.valuesOf(element).enabled, isTrue);
    expect(
      tester.getSize(find.byKey(const ValueKey("live control"))).width,
      80,
    );

    routeActive.value = false;
    await tester.pumpAndSettle();
    expect(TickerMode.valuesOf(element).enabled, isFalse);
    routeActive.value = true;
    await tester.pumpAndSettle();
    expect(TickerMode.valuesOf(element).enabled, isTrue);
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });

  testWidgets("centers the primary control with asymmetric available regions", (
    tester,
  ) async {
    await tester.pumpTestApp(child: Center(child: layout(700)));
    expect(
      tester.getCenter(find.byKey(searchKey)).dx,
      tester.getCenter(find.byType(CustomAppBarLayout)).dx,
    );
    expect(tester.getSize(find.byKey(searchKey)).width, 200);
    expect(tester.getSize(find.byKey(activityKey)).width, 120);
  });

  testWidgets("shortens successive groups without replacing controls", (
    tester,
  ) async {
    final width = ValueNotifier(500.0);
    addTearDown(width.dispose);
    await tester.pumpTestApp(
      child: Center(
        child: ValueListenableBuilder(
          valueListenable: width,
          builder: (context, value, _) => layout(value),
        ),
      ),
    );
    final activity = tester.element(find.byKey(activityKey));
    width.value = 400;
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byKey(searchKey)).width, 48);
    expect(tester.getSize(find.byKey(activityKey)).width, 120);
    width.value = 250;
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byKey(activityKey)).width, 48);
    expect(tester.element(find.byKey(activityKey)), same(activity));
    expect(tester.takeException(), isNull);
  });

  testWidgets("equal groups shorten together and reveal their disclosure", (
    tester,
  ) async {
    await tester.pumpTestApp(
      child: Center(child: layout(400, activityOrder: 0, modeOrder: 0)),
    );
    expect(tester.getSize(find.byKey(searchKey)).width, 48);
    expect(tester.getSize(find.byKey(activityKey)).width, 48);
    expect(
      AppBarItemVisibility.of(tester.element(find.byKey(modeKey))),
      isFalse,
    );
    expect(
      AppBarItemVisibility.of(tester.element(find.byKey(sidebarKey))),
      isTrue,
    );
  });

  testWidgets("hidden controls cannot keep keyboard focus", (tester) async {
    final width = ValueNotifier(700.0);
    final focus = FocusNode();
    addTearDown(width.dispose);
    addTearDown(focus.dispose);
    await tester.pumpTestApp(
      child: Center(
        child: ValueListenableBuilder(
          valueListenable: width,
          builder: (context, value, _) => SizedBox(
            width: value,
            height: 48,
            child: CustomAppBarLayout(
              spacing: 8,
              navigation: const SizedBox(width: 100),
              primary: AppBarItem.adaptive(
                key: const ValueKey("search"),
                collapseOrder: 0,
                child: AppBarControl.text(
                  contentBuilder: (context, compact) => AppBarControlContent(
                    compact: compact,
                    icon: const Icon(Icons.search),
                    label: "Search",
                  ),
                  tooltip: "Search",
                  semanticLabel: "Search",
                  onPressed: () {},
                ),
              ),
              actions: [
                AppBarItem.expandedOnly(
                  key: const ValueKey("mode"),
                  collapseOrder: 1,
                  child: TextButton(
                    focusNode: focus,
                    onPressed: () {},
                    child: const Text("Mode"),
                  ),
                ),
                AppBarItem.compactOnly(
                  key: const ValueKey("sidebar"),
                  collapseOrder: 1,
                  child: IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.menu),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    focus.requestFocus();
    await tester.pump();
    expect(focus.hasFocus, isTrue);
    width.value = 110;
    await tester.pumpAndSettle();
    expect(focus.hasFocus, isFalse);
    expect(focus.canRequestFocus, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    "allocated navigation and controls are painted and receive pointer input",
    (tester) async {
      final invoked = <String>[];
      await tester.pumpTestApp(
        child: Material(
          child: Center(
            child: SizedBox(
              width: 700,
              height: 48,
              child: CustomAppBarLayout(
                spacing: 8,
                navigation: TextButton(
                  onPressed: () => invoked.add("navigation"),
                  child: const Text("Workspace"),
                ),
                primary: AppBarItem.adaptive(
                  key: const ValueKey("search"),
                  collapseOrder: 0,
                  child: AppBarControl.text(
                    contentBuilder: (context, compact) => AppBarControlContent(
                      compact: compact,
                      icon: const Icon(Icons.search),
                      label: "Search",
                    ),
                    tooltip: "Search",
                    semanticLabel: "Search",
                    onPressed: () => invoked.add("search"),
                  ),
                ),
                actions: [
                  AppBarItem.adaptive(
                    key: const ValueKey("inbox"),
                    collapseOrder: 1,
                    child: AppBarControl.text(
                      contentBuilder: (context, compact) =>
                          AppBarControlContent(
                            compact: compact,
                            icon: const Icon(Icons.inbox_outlined),
                            label: "Inbox",
                          ),
                      tooltip: "Inbox",
                      semanticLabel: "Inbox",
                      onPressed: () => invoked.add("inbox"),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      for (final label in ["Workspace", "Search", "Inbox"]) {
        expect(find.text(label).hitTestable(), findsOneWidget);
        await tester.tap(find.text(label));
        await tester.pump();
      }
      expect(invoked, ["navigation", "search", "inbox"]);
    },
  );
}
