import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook_workspace/stories/shared/editors/presentation/portable_presentation_renderer.stories.dart";

void main() {
  testWidgets("field diagnostics remain editable and clear after correction", (
    tester,
  ) async {
    await tester.pumpWidget(
      FakeApp(
        child: Scaffold(
          body: PortableDiagnosticGallery(
            severity: skir.DiagnosticSeverity.error,
            role: skir.PresentationRole.inspector,
            general: false,
            readOnly: false,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    const message = "Use at least three characters";
    expect(
      find.descendant(
        of: find.byType(PortableDiagnosticFrame),
        matching: find.text(message),
      ),
      findsOneWidget,
    );
    final field = find.byType(TextFormField).first;
    await tester.showKeyboard(field);
    await tester.pumpAndSettle();
    final before = tester.state<EditableTextState>(
      find.byType(EditableText).first,
    );
    await tester.enterText(field, "Corrected title");
    await tester.pumpAndSettle();
    expect(find.text(message), findsNothing);
    expect(
      tester.state<EditableTextState>(find.byType(EditableText).first),
      same(before),
    );
    expect(before.widget.focusNode.hasPrimaryFocus, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets("a collapsed header keeps its descendant diagnostic visible", (
    tester,
  ) async {
    await tester.pumpWidget(
      FakeApp(
        child: Scaffold(
          body: PortableDiagnosticGallery(
            severity: skir.DiagnosticSeverity.warning,
            role: skir.PresentationRole.inspector,
            general: false,
            readOnly: false,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(PortableDiagnosticHeaderMarker), findsOneWidget);
    await tester.tap(find.byTooltip("Collapse"));
    await tester.pumpAndSettle();
    expect(find.byType(TextFormField), findsNothing);
    expect(find.byType(PortableDiagnosticHeaderMarker), findsOneWidget);
    expect(find.byTooltip("1 field diagnostic"), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    "a numeric parser error remains beside its draft and clears on correction",
    (tester) async {
      await tester.pumpWidget(
        FakeApp(
          child: Scaffold(
            body: PortableDiagnosticGallery(
              severity: skir.DiagnosticSeverity.error,
              role: skir.PresentationRole.inspector,
              general: false,
              readOnly: false,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(TextFormField).first,
        "Corrected title",
      );
      await tester.pumpAndSettle();
      final field = find.byType(TextFormField).last;
      await tester.showKeyboard(field);
      await tester.pumpAndSettle();
      await tester.pumpAndSettle();
      final before = tester.state<EditableTextState>(
        find.byType(EditableText).last,
      );
      await tester.enterText(field, "-");
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: find.byType(PortableDiagnosticFrame),
          matching: find.text("Enter a valid number"),
        ),
        findsOneWidget,
      );
      expect(before.widget.controller.text, "-");
      expect(before.widget.focusNode.hasPrimaryFocus, isTrue);
      expect(find.byType(PortableDiagnosticHeaderMarker), findsOneWidget);
      await tester.enterText(field, "7");
      await tester.pumpAndSettle();
      expect(find.text("Enter a valid number"), findsNothing);
      expect(
        tester.state<EditableTextState>(find.byType(EditableText).last),
        same(before),
      );
      expect(before.widget.focusNode.hasPrimaryFocus, isTrue);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets("general compact feedback anchors its tooltip to the icon", (
    tester,
  ) async {
    await tester.pumpWidget(
      FakeApp(
        child: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 480,
              child: PortableDiagnosticGallery(
                severity: skir.DiagnosticSeverity.error,
                role: skir.PresentationRole.authoringResult,
                general: true,
                readOnly: true,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final tooltip = find.byWidgetPredicate(
      (widget) =>
          widget is Tooltip &&
          widget.message == "Use at least three characters",
    );
    expect(tooltip, findsOneWidget);
    final icon = find.descendant(
      of: tooltip,
      matching: find.byType(IconButton),
    );
    expect(icon, findsOneWidget);
    expect(tester.getSize(tooltip), tester.getSize(icon));
    var iconFocused = false;
    for (var attempt = 0; attempt < 20; attempt++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      iconFocused = identical(
        FocusManager.instance.primaryFocus?.context
            ?.findAncestorWidgetOfExactType<IconButton>(),
        tester.widget<IconButton>(icon),
      );
      if (iconFocused) break;
    }
    expect(
      iconFocused,
      isTrue,
      reason: "General feedback must be reachable by keyboard",
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.text("Use at least three characters"), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
