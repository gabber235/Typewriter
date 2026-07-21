import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";

void main() {
  Widget scrollView(List<Widget> slivers) {
    return MaterialApp(
      home: Scaffold(body: CustomScrollView(slivers: slivers)),
    );
  }

  testWidgets("centers a short group as one block without scrolling", (
    tester,
  ) async {
    await tester.pumpWidget(
      scrollView([
        CenteredSliverMainAxisGroup(
          slivers: const [
            SliverToBoxAdapter(child: SizedBox(key: Key("first"), height: 40)),
            SliverToBoxAdapter(child: SizedBox(key: Key("second"), height: 60)),
          ],
        ),
      ]),
    );

    expect(tester.getTopLeft(find.byKey(const Key("first"))).dy, 250);
    expect(tester.getTopLeft(find.byKey(const Key("second"))).dy, 290);
    expect(
      tester
          .state<ScrollableState>(find.byType(Scrollable))
          .position
          .maxScrollExtent,
      0,
    );
  });

  testWidgets("overflow scrolls normally and fixed extent children stay lazy", (
    tester,
  ) async {
    var builds = 0;
    await tester.pumpWidget(
      scrollView([
        CenteredSliverMainAxisGroup(
          slivers: [
            SliverFixedExtentList.builder(
              itemExtent: 100,
              itemCount: 20,
              itemBuilder: (context, index) {
                builds++;
                return Text("item $index");
              },
            ),
          ],
        ),
      ]),
    );

    expect(builds, lessThan(20));
    expect(
      tester
          .state<ScrollableState>(find.byType(Scrollable))
          .position
          .maxScrollExtent,
      1400,
    );
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -300));
    await tester.pumpAndSettle();
    expect(
      tester.state<ScrollableState>(find.byType(Scrollable)).position.pixels,
      closeTo(300, 0.1),
    );
  });

  testWidgets(
    "trailing sliver scrolls through centered leading space before content",
    (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        scrollView([
          CenteredSliverMainAxisGroup(
            slivers: [
              SliverToBoxAdapter(
                child: GestureDetector(
                  key: const Key("centered"),
                  behavior: HitTestBehavior.opaque,
                  onTap: () => taps++,
                  child: const SizedBox(height: 100),
                ),
              ),
            ],
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 1000)),
        ]),
      );

      final position = tester
          .state<ScrollableState>(find.byType(Scrollable))
          .position;
      expect(tester.getTopLeft(find.byKey(const Key("centered"))).dy, 250);
      expect(position.maxScrollExtent, 1000);

      position.jumpTo(300);
      await tester.pump();

      expect(tester.getTopLeft(find.byKey(const Key("centered"))).dy, -50);
      await tester.tapAt(const Offset(400, 25));
      expect(taps, 1);
    },
  );

  testWidgets("centers and hit tests in a reversed scroll view", (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CustomScrollView(
            reverse: true,
            slivers: [
              CenteredSliverMainAxisGroup(
                slivers: [
                  SliverToBoxAdapter(
                    child: GestureDetector(
                      key: const Key("reversed"),
                      behavior: HitTestBehavior.opaque,
                      onTap: () => taps++,
                      child: const SizedBox(height: 100),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    expect(tester.getTopLeft(find.byKey(const Key("reversed"))).dy, 250);
    await tester.tapAt(tester.getCenter(find.byKey(const Key("reversed"))));
    expect(taps, 1);
  });

  testWidgets("re-centers after dynamic short and overflow transitions", (
    tester,
  ) async {
    final height = ValueNotifier<double>(100);
    await tester.pumpWidget(
      ValueListenableBuilder<double>(
        valueListenable: height,
        builder: (context, value, child) => scrollView([
          CenteredSliverMainAxisGroup(
            slivers: [
              SliverToBoxAdapter(
                child: SizedBox(key: const Key("content"), height: value),
              ),
            ],
          ),
        ]),
      ),
    );

    expect(tester.getTopLeft(find.byKey(const Key("content"))).dy, 250);
    height.value = 1000;
    await tester.pump();
    expect(tester.getTopLeft(find.byKey(const Key("content"))).dy, 0);
    height.value = 200;
    await tester.pump();
    expect(tester.getTopLeft(find.byKey(const Key("content"))).dy, 200);
  });

  testWidgets("removes centering for a fill remaining sliver", (tester) async {
    final fillRemaining = ValueNotifier(false);
    await tester.pumpWidget(
      ValueListenableBuilder<bool>(
        valueListenable: fillRemaining,
        builder: (context, fillsViewport, child) => scrollView([
          CenteredSliverMainAxisGroup(
            slivers: [
              if (fillsViewport)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: SizedBox(key: Key("content")),
                )
              else
                const SliverToBoxAdapter(
                  child: SizedBox(key: Key("content"), height: 100),
                ),
            ],
          ),
        ]),
      ),
    );

    expect(tester.getTopLeft(find.byKey(const Key("content"))).dy, 250);
    fillRemaining.value = true;
    await tester.pump();

    expect(tester.getTopLeft(find.byKey(const Key("content"))).dy, 0);
    expect(tester.getSize(find.byKey(const Key("content"))).height, 600);
    expect(
      tester
          .state<ScrollableState>(find.byType(Scrollable))
          .position
          .maxScrollExtent,
      0,
    );
  });

  testWidgets("hit tests content at its centered painted position", (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      scrollView([
        CenteredSliverMainAxisGroup(
          slivers: [
            SliverToBoxAdapter(
              child: GestureDetector(
                key: const Key("target"),
                behavior: HitTestBehavior.opaque,
                onTap: () => taps++,
                child: const SizedBox(height: 100),
              ),
            ),
          ],
        ),
      ]),
    );

    await tester.tapAt(tester.getCenter(find.byKey(const Key("target"))));
    expect(taps, 1);
  });

  testWidgets("centers within viewport space after a preceding sliver", (
    tester,
  ) async {
    await tester.pumpWidget(
      scrollView([
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
        CenteredSliverMainAxisGroup(
          slivers: const [
            SliverToBoxAdapter(
              child: SizedBox(key: Key("content"), height: 100),
            ),
          ],
        ),
      ]),
    );

    expect(tester.getTopLeft(find.byKey(const Key("content"))).dy, 300);
    expect(
      tester
          .state<ScrollableState>(find.byType(Scrollable))
          .position
          .maxScrollExtent,
      0,
    );
  });
}
