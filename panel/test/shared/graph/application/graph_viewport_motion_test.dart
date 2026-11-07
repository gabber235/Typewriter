import "package:flutter_test/flutter_test.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  testWidgets("reduced motion: revealing an element moves the viewport onto "
      "it on the next frame", (tester) async {
    final viewport = await tester.showViewport(reduced: true);

    viewport.centerViewportPoint(
      point: const Offset(300, 200),
      viewportCenter: Offset.zero,
    );
    await tester.pump();

    expect(viewportOrigin(viewport).dx, closeTo(300, 0.01));
    expect(viewportOrigin(viewport).dy, closeTo(200, 0.01));
  });

  testWidgets("revealing an element travels there and lands on it", (
    tester,
  ) async {
    final viewport = await tester.showViewport(reduced: false);

    viewport.centerViewportPoint(
      point: const Offset(300, 200),
      viewportCenter: Offset.zero,
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));
    expect(
      viewportOrigin(viewport).dx,
      lessThan(299),
      reason: "still on its way",
    );
    await tester.pumpAndSettle();

    expect(viewportOrigin(viewport).dx, 300);
    expect(viewportOrigin(viewport).dy, 200);
  });
}
