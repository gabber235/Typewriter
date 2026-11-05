import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
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
    final panel = await tester.pumpPanel(
      const [],
      at: PanelLocation.component(
        AnimatedBuilder(
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
    final element = tester.element(find.byWidget(control));
    expect(TickerMode.valuesOf(element).enabled, isTrue);
    expect(AppBarItemVisibility.of(element), isFalse);
    expect(focus.canRequestFocus, isFalse);
    expect(find.semantics.byLabel("Live activity"), findsNothing);
    expect(find.byWidget(control).hitTestable(), findsNothing);

    for (final width in [96.0, 0.0, 120.0]) {
      contentWidth.value = width;
      await panel.settle();
      expect(tester.element(find.byWidget(control)), same(element));
      expect(tester.getSize(find.byWidget(control)).width, width);
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
        await tester.tap(find.byWidget(control));
      } else {
        expect(focus.hasFocus, isFalse);
      }
    }
    expect(taps, 2);

    contentWidth.value = 0;
    await panel.settle();
    // At this width a compact only item is hidden, even with identical geometry.
    policy.value = const AppBarItemPolicy.compactOnly(0);
    await panel.settle();
    expect(TickerMode.valuesOf(element).enabled, isFalse);
    expect(focus.canRequestFocus, isFalse);
    contentWidth.value = 80;
    await panel.settle();
    expect(tester.getSize(find.byWidget(control)).width, 0);
    policy.value = const AppBarItemPolicy.fixed();
    await panel.settle();
    expect(TickerMode.valuesOf(element).enabled, isTrue);
    expect(tester.getSize(find.byWidget(control)).width, 80);

    routeActive.value = false;
    await panel.settle();
    expect(TickerMode.valuesOf(element).enabled, isFalse);
    routeActive.value = true;
    await panel.settle();
    expect(TickerMode.valuesOf(element).enabled, isTrue);
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });

  testWidgets("centers the primary control with asymmetric available regions", (
    tester,
  ) async {
    final panel = await tester.pumpPanel(
      const [],
      at: PanelLocation.component(SampleAppBarLayout(700)),
    );
    expect(
      tester.getCenter(panel.labeled("Search")).dx,
      tester.getCenter(find.byType(CustomAppBarLayout)).dx,
    );
    expect(tester.getSize(panel.labeled("Search")).width, 200);
    expect(tester.getSize(panel.labeled("Activity")).width, 120);
  });

  testWidgets("shortens successive groups without replacing controls", (
    tester,
  ) async {
    final width = ValueNotifier(500.0);
    addTearDown(width.dispose);
    final panel = await tester.pumpPanel(
      const [],
      at: PanelLocation.component(
        ValueListenableBuilder(
          valueListenable: width,
          builder: (context, value, _) => SampleAppBarLayout(value),
        ),
      ),
    );
    final activity = tester.element(panel.labeled("Activity"));
    width.value = 400;
    await panel.settle();
    expect(tester.getSize(panel.labeled("Search")).width, 48);
    expect(tester.getSize(panel.labeled("Activity")).width, 120);
    width.value = 250;
    await panel.settle();
    expect(tester.getSize(panel.labeled("Activity")).width, 48);
    expect(tester.element(panel.labeled("Activity")), same(activity));
    expect(tester.takeException(), isNull);
  });

  testWidgets("equal groups shorten together and reveal their disclosure", (
    tester,
  ) async {
    final panel = await tester.pumpPanel(
      const [],
      at: PanelLocation.component(
        SampleAppBarLayout(400, activityOrder: 0, modeOrder: 0),
      ),
    );
    expect(tester.getSize(panel.labeled("Search")).width, 48);
    expect(tester.getSize(panel.labeled("Activity")).width, 48);
    expect(panel.shows("Mode"), isFalse);
    expect(panel.shows("Sidebar"), isTrue);
  });

  testWidgets("hidden controls cannot keep keyboard focus", (tester) async {
    final width = ValueNotifier(700.0);
    final focus = FocusNode();
    addTearDown(width.dispose);
    addTearDown(focus.dispose);
    final panel = await tester.pumpPanel(
      const [],
      at: PanelLocation.component(
        ValueListenableBuilder(
          valueListenable: width,
          builder: (context, value, _) => SizedBox(
            width: value,
            height: 48,
            child: CustomAppBarLayout(
              spacing: 8,
              navigation: const SizedBox(width: 100),
              primary: textAppBarItem("Search", Icons.search, collapseOrder: 0),
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
    await panel.settle();
    expect(focus.hasFocus, isFalse);
    expect(focus.canRequestFocus, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    "allocated navigation and controls are painted and receive pointer input",
    (tester) async {
      final invoked = <String>[];
      final panel = await tester.pumpPanel(
        const [],
        at: PanelLocation.component(
          Material(
            child: SizedBox(
              width: 700,
              height: 48,
              child: CustomAppBarLayout(
                spacing: 8,
                navigation: TextButton(
                  onPressed: () => invoked.add("navigation"),
                  child: const Text("Workspace"),
                ),
                primary: textAppBarItem(
                  "Search",
                  Icons.search,
                  collapseOrder: 0,
                  onPressed: () => invoked.add("search"),
                ),
                actions: [
                  textAppBarItem(
                    "Inbox",
                    Icons.inbox_outlined,
                    collapseOrder: 1,
                    onPressed: () => invoked.add("inbox"),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      for (final label in ["Workspace", "Search", "Inbox"]) {
        expect(find.text(label).hitTestable(), findsOneWidget);
        await panel.tapOn(find.text(label));
      }
      expect(invoked, ["navigation", "search", "inbox"]);
    },
  );
}
