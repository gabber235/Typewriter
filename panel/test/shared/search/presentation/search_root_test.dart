import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  testWidgets("a child shows the selection as it changes", (tester) async {
    late SearchController controller;
    final panel = await tester.pumpPanel(
      const [],
      at: PanelLocation.component(
        SearchRoot(
          create: (ref) => controller = SearchController(
            session: searchSession(FakeSearchSource()),
            baseSelectors: const [],
          ),
          child: const SearchProbe(),
        ),
      ),
    );
    expect(panel.shows("Results selected: 0"), isTrue);

    controller.toggleSelected("alpha");
    await panel.settle();

    expect(panel.shows("Results selected: 1"), isTrue);
  });

  testWidgets("a child shows the results the source sends", (tester) async {
    final source = FakeSearchSource();
    final panel = await tester.pumpPanel(
      const [],
      at: PanelLocation.component(
        SearchRoot(
          create: (ref) => SearchController(
            session: searchSession(source),
            baseSelectors: const [],
          ),
          child: const SearchProbe(),
        ),
      ),
    );
    expect(panel.shows("Status: idle, nodes: 0"), isTrue);

    source.emitSnapshot(readySnapshot(nodes: [resultNode("alpha")]));
    await panel.settle();

    expect(panel.shows("Status: ready, nodes: 1"), isTrue);
  });

  testWidgets("a replaced child receives later changes", (tester) async {
    late SearchController controller;
    final second = ValueNotifier(false);
    addTearDown(second.dispose);
    final panel = await tester.pumpPanel(
      const [],
      at: PanelLocation.component(
        ValueListenableBuilder(
          valueListenable: second,
          builder: (context, isSecond, _) => SearchRoot(
            create: (ref) => controller = SearchController(
              session: searchSession(FakeSearchSource()),
              baseSelectors: const [],
            ),
            child: SearchProbe(label: isSecond ? "Second" : "First"),
          ),
        ),
      ),
    );
    expect(panel.shows("First selected: 0"), isTrue);

    second.value = true;
    await panel.settle();
    controller.toggleSelected("alpha");
    await panel.settle();

    expect(panel.shows("First selected: 0"), isFalse);
    expect(panel.shows("Second selected: 1"), isTrue);
  });

  testWidgets("a root that creates its controller disposes its source", (
    tester,
  ) async {
    final source = FakeSearchSource();
    final shown = ValueNotifier(true);
    addTearDown(shown.dispose);
    final panel = await tester.pumpPanel(
      const [],
      at: PanelLocation.component(
        ValueListenableBuilder(
          valueListenable: shown,
          builder: (context, isShown, _) => isShown
              ? SearchRoot(
                  create: (_) => SearchController(
                    session: searchSession(source),
                    baseSelectors: const [],
                  ),
                  child: const SearchProbe(label: "Owned"),
                )
              : const SizedBox(),
        ),
      ),
    );

    shown.value = false;
    await panel.settle();

    expect(source.disposeCount, 1);
  });

  testWidgets("a borrowed root leaves disposal to the controller's owner", (
    tester,
  ) async {
    final source = FakeSearchSource();
    final controller = SearchController(
      session: searchSession(source),
      baseSelectors: const [],
    );
    final shown = ValueNotifier(true);
    addTearDown(shown.dispose);
    final panel = await tester.pumpPanel(
      const [],
      at: PanelLocation.component(
        ValueListenableBuilder(
          valueListenable: shown,
          builder: (context, isShown, _) => isShown
              ? SearchRoot.borrowed(
                  controller: controller,
                  child: const SearchProbe(label: "Borrowed"),
                )
              : const SizedBox(),
        ),
      ),
    );

    shown.value = false;
    await panel.settle();
    expect(source.disposeCount, 0);

    controller.dispose();
    expect(source.disposeCount, 1);
  });

  testWidgets(
    "a borrowed root follows a replaced controller and keeps its child state",
    (tester) async {
      final first = SearchController(
        session: searchSession(FakeSearchSource()),
        baseSelectors: const [],
      );
      final second = SearchController(
        session: searchSession(FakeSearchSource()),
        baseSelectors: const [],
      );
      final current = ValueNotifier(first);
      addTearDown(first.dispose);
      addTearDown(second.dispose);
      addTearDown(current.dispose);
      final panel = await tester.pumpPanel(
        const [],
        at: PanelLocation.component(
          ValueListenableBuilder(
            valueListenable: current,
            builder: (context, controller, _) => SearchRoot.borrowed(
              controller: controller,
              child: const SearchProbe(),
            ),
          ),
        ),
      );
      await tester.tap(find.text("Taps: 0"));
      await panel.settle();

      current.value = second;
      await panel.settle();
      second.toggleSelected("alpha");
      first
        ..toggleSelected("beta")
        ..toggleSelected("gamma");
      await panel.settle();

      expect(panel.shows("Taps: 1, selected: 1"), isTrue);
    },
  );
}
