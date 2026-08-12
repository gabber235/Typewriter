import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";

import "../../../support/test_utils.dart";

void main() {
  testWidgets("vertically centers one line beside the upper left icon", (
    tester,
  ) async {
    const surfaceKey = Key("diagnosticSurface");

    await tester.pumpTestApp(
      child: Center(
        child: SizedBox(
          key: surfaceKey,
          width: 400,
          height: 120,
          child: Builder(
            builder: (context) => presentationDiagnostic(context, [
              _diagnostic("Unable to render this field"),
            ]),
          ),
        ),
      ),
    );

    final surface = tester.getRect(find.byKey(surfaceKey));
    final message = tester.getRect(find.text("Unable to render this field"));
    final icon = tester.getRect(find.byIcon(Icons.error_outline));

    expect(message.left, closeTo(surface.left + 46, 0.01));
    expect(message.center.dy, closeTo(surface.center.dy, 0.01));
    expect(icon.left, closeTo(surface.left + 12, 0.01));
    expect(icon.top, closeTo(surface.top + 12, 0.01));
  });

  testWidgets("grows naturally with left aligned multiple diagnostic lines", (
    tester,
  ) async {
    const surfaceKey = Key("diagnosticSurface");

    await tester.pumpTestApp(
      child: Center(
        child: SizedBox(
          key: surfaceKey,
          width: 400,
          child: Builder(
            builder: (context) => presentationDiagnostic(context, [
              _diagnostic("First diagnostic line"),
              _diagnostic("Second diagnostic line"),
              _diagnostic("Third diagnostic line"),
            ]),
          ),
        ),
      ),
    );

    final surface = tester.getRect(find.byKey(surfaceKey));
    final message = tester.getRect(
      find.text(
        "First diagnostic line\nSecond diagnostic line\nThird diagnostic line",
      ),
    );
    final text = tester.widget<Text>(
      find.text(
        "First diagnostic line\nSecond diagnostic line\nThird diagnostic line",
      ),
    );

    expect(surface.height, greaterThan(48));
    expect(message.left, closeTo(surface.left + 46, 0.01));
    expect(message.center.dy, closeTo(surface.center.dy, 0.01));
    expect(text.textAlign, TextAlign.left);
  });
}

TypeDiagnostic _diagnostic(String message) => TypeDiagnostic(
  code: TypeDiagnosticCode.invalidPresentation,
  message: message,
);
