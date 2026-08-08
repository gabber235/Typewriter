import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";

void main() {
  group("AdaptiveLeadingLayout", () {
    testWidgets("positions center at the widget midpoint when space allows", (
      tester,
    ) async {
      const centerKey = ValueKey("center");

      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: SizedBox(
              width: 300,
              height: 50,
              child: AdaptiveLeadingLayout(
                leading: SizedBox(width: 100, height: 20),
                center: SizedBox(key: centerKey, width: 60, height: 20),
              ),
            ),
          ),
        ),
      );

      final layoutCenter = tester.getCenter(find.byType(AdaptiveLeadingLayout));
      final centerCenter = tester.getCenter(find.byKey(centerKey));

      expect(centerCenter.dx, layoutCenter.dx);
    });

    testWidgets("positions center after leading when midpoint would overlap", (
      tester,
    ) async {
      const leadingKey = ValueKey("leading");
      const centerKey = ValueKey("center");

      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: SizedBox(
              width: 160,
              height: 50,
              child: AdaptiveLeadingLayout(
                leading: SizedBox(key: leadingKey, width: 100, height: 20),
                center: SizedBox(key: centerKey, width: 40, height: 20),
              ),
            ),
          ),
        ),
      );

      final leadingRight = tester.getTopRight(find.byKey(leadingKey)).dx;
      final centerLeft = tester.getTopLeft(find.byKey(centerKey)).dx;

      expect(centerLeft, leadingRight + 8);
    });
  });
}
