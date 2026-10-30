import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

const viewport = "Viewport";

void main() {
  testWidgets("centers a short group as one block without scrolling", (
    tester,
  ) async {
    final panel = await tester.showComponent(
      LabeledBox(
        viewport,
        width: 800,
        height: 600,
        child: CustomScrollView(
          slivers: [
            CenteredSliverMainAxisGroup(
              slivers: [
                SliverToBoxAdapter(child: LabeledBox("First", height: 40)),
                SliverToBoxAdapter(child: LabeledBox("Second", height: 60)),
              ],
            ),
          ],
        ),
      ),
    );

    expect(panel.positionIn("First", viewport).dy, 250);
    expect(panel.positionIn("Second", viewport).dy, 290);
    expect(panel.scrollPosition.maxScrollExtent, 0);
  });

  testWidgets("overflow scrolls normally and fixed extent children stay lazy", (
    tester,
  ) async {
    var builds = 0;
    final panel = await tester.showComponent(
      LabeledBox(
        viewport,
        width: 800,
        height: 600,
        child: CustomScrollView(
          slivers: [
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
          ],
        ),
      ),
    );

    expect(builds, lessThan(20));
    expect(panel.scrollPosition.maxScrollExtent, 1400);
    await tester.drag(find.text("item 2"), const Offset(0, -300));
    await tester.pumpAndSettle();
    expect(panel.scrollPosition.pixels, closeTo(300, 0.1));
  });

  testWidgets(
    "trailing sliver scrolls through centered leading space before content",
    (tester) async {
      var taps = 0;
      final panel = await tester.showComponent(
        LabeledBox(
          viewport,
          width: 800,
          height: 600,
          child: CustomScrollView(
            slivers: [
              CenteredSliverMainAxisGroup(
                slivers: [
                  SliverToBoxAdapter(
                    child: LabeledBox(
                      "Centered",
                      height: 100,
                      onTap: () => taps++,
                    ),
                  ),
                ],
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 1000)),
            ],
          ),
        ),
      );

      expect(panel.positionIn("Centered", viewport).dy, 250);
      expect(panel.scrollPosition.maxScrollExtent, 1000);

      panel.scrollPosition.jumpTo(300);
      await tester.pump();

      expect(panel.positionIn("Centered", viewport).dy, -50);
      await tester.tapAt(
        panel.boundsOf(viewport).topLeft + const Offset(400, 25),
      );
      expect(taps, 1);
    },
  );

  testWidgets("centers and hit tests in a reversed scroll view", (
    tester,
  ) async {
    var taps = 0;
    final panel = await tester.showComponent(
      LabeledBox(
        viewport,
        width: 800,
        height: 600,
        child: CustomScrollView(
          reverse: true,
          slivers: [
            CenteredSliverMainAxisGroup(
              slivers: [
                SliverToBoxAdapter(
                  child: LabeledBox(
                    "Reversed",
                    height: 100,
                    onTap: () => taps++,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    expect(panel.positionIn("Reversed", viewport).dy, 250);
    await tester.tapAt(panel.boundsOf("Reversed").center);
    expect(taps, 1);
  });

  testWidgets("re-centers after dynamic short and overflow transitions", (
    tester,
  ) async {
    final height = ValueNotifier<double>(100);
    addTearDown(height.dispose);
    final panel = await tester.showComponent(
      LabeledBox(
        viewport,
        width: 800,
        height: 600,
        child: ListenableBuilder(
          listenable: height,
          builder: (context, _) => CustomScrollView(
            slivers: [
              CenteredSliverMainAxisGroup(
                slivers: [
                  SliverToBoxAdapter(
                    child: LabeledBox("Content", height: height.value),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    expect(panel.positionIn("Content", viewport).dy, 250);
    height.value = 1000;
    await tester.pump();
    expect(panel.positionIn("Content", viewport).dy, 0);
    height.value = 200;
    await tester.pump();

    expect(panel.positionIn("Content", viewport).dy, 200);
  });

  testWidgets("removes centering for a fill remaining sliver", (tester) async {
    final fillRemaining = ValueNotifier(false);
    addTearDown(fillRemaining.dispose);
    final panel = await tester.showComponent(
      LabeledBox(
        viewport,
        width: 800,
        height: 600,
        child: ListenableBuilder(
          listenable: fillRemaining,
          builder: (context, _) => CustomScrollView(
            slivers: [
              CenteredSliverMainAxisGroup(
                slivers: [
                  if (fillRemaining.value)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: LabeledBox("Content"),
                    )
                  else
                    SliverToBoxAdapter(
                      child: LabeledBox("Content", height: 100),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    expect(panel.positionIn("Content", viewport).dy, 250);
    fillRemaining.value = true;
    await tester.pump();

    expect(panel.positionIn("Content", viewport).dy, 0);
    expect(panel.boundsOf("Content").height, 600);
    expect(panel.scrollPosition.maxScrollExtent, 0);
  });

  testWidgets("hit tests content at its centered painted position", (
    tester,
  ) async {
    var taps = 0;
    final panel = await tester.showComponent(
      LabeledBox(
        viewport,
        width: 800,
        height: 600,
        child: CustomScrollView(
          slivers: [
            CenteredSliverMainAxisGroup(
              slivers: [
                SliverToBoxAdapter(
                  child: LabeledBox("Target", height: 100, onTap: () => taps++),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    await tester.tapAt(panel.boundsOf("Target").center);
    expect(taps, 1);
  });

  testWidgets("centers within viewport space after a preceding sliver", (
    tester,
  ) async {
    final panel = await tester.showComponent(
      LabeledBox(
        viewport,
        width: 800,
        height: 600,
        child: CustomScrollView(
          slivers: [
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
            CenteredSliverMainAxisGroup(
              slivers: [
                SliverToBoxAdapter(child: LabeledBox("Content", height: 100)),
              ],
            ),
          ],
        ),
      ),
    );

    expect(panel.positionIn("Content", viewport).dy, 300);
    expect(panel.scrollPosition.maxScrollExtent, 0);
  });
}
