import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  testWidgets("a scope bounds overlays to its own area", (tester) async {
    final bounds = await tester.anchoredScopeBoundsAround(
      (probe) => AnchoredOverlayScope(
        child: SizedBox(width: 140, height: 70, child: probe),
      ),
    );

    expect(bounds?.size, const Size(140, 70));
  });

  testWidgets("without a scope overlays are not bounded", (tester) async {
    final bounds = await tester.anchoredScopeBoundsAround(
      (probe) => SizedBox(width: 200, height: 120, child: probe),
    );

    expect(bounds, isNull);
  });
}
