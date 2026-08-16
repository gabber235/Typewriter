import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";

import "../../../support/test_utils.dart";

void main() {
  testWidgets("dense card content fits a constrained grid cell", (
    tester,
  ) async {
    await tester.pumpTestApp(
      child: Center(
        child: SizedBox(
          width: 180,
          height: 160,
          child: GridSelectableCard(
            title: "A service name that needs three lines",
            baseColor: Colors.blue,
            badgeLabel: "Custom",
            header: const Icon(Icons.dns, size: 32),
            footer: const StatusIndicator(isOnline: false),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text("A service name that needs three lines"), findsOneWidget);
    expect(find.text("Never"), findsOneWidget);
  });
}
