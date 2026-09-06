import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";

import "../../../support/test_utils.dart";

void main() {
  testWidgets(
    "uses the shared compact relative time without changing its dot",
    (tester) async {
      await tester.pumpTestApp(
        child: StatusIndicator(
          isOnline: false,
          lastSeen: DateTime.now().subtract(
            const Duration(minutes: 5, seconds: 5),
          ),
        ),
      );

      expect(find.text("5m ago"), findsOneWidget);
      final dot = tester.widget<Container>(find.byType(Container).last);
      final decoration = dot.decoration! as BoxDecoration;
      expect(decoration.shape, BoxShape.circle);
    },
  );
}
