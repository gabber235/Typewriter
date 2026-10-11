import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";

import "../../../support/test_utils.dart";

void main() {
  testWidgets("link exposes native activation actions and semantics", (
    tester,
  ) async {
    await tester.pumpTestApp(
      child: const TypeLink(
        text: "Documentation",
        lightColor: Colors.blue,
        url: "https://example.test",
      ),
    );

    final detector = tester.widget<FocusableActionDetector>(
      find.byType(FocusableActionDetector),
    );
    expect(detector.actions, contains(ActivateIntent));
    expect(detector.actions, contains(ButtonActivateIntent));

    final semantics = tester.widget<Semantics>(
      find.byWidgetPredicate(
        (widget) =>
            widget is Semantics && widget.properties.label == "Documentation",
      ),
    );
    expect(semantics.properties.label, "Documentation");
    expect(semantics.properties.onTap, isNotNull);
  });
}
