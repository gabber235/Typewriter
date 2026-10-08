import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook_workspace/stories/shared/editors/presentation/portable_presentation_renderer.stories.dart";

void main() {
  testWidgets("the portable host gallery writes through the shared renderer", (
    tester,
  ) async {
    await tester.pumpWidget(
      const FakeApp(child: Scaffold(body: PortablePresentationGallery())),
    );
    await tester.pumpAndSettle();

    expect(find.byType(PortablePresentationRenderer), findsOneWidget);
    expect(find.text("Portable presentation host"), findsOneWidget);
    expect(find.text("Title"), findsOneWidget);
    expect(find.text("Count"), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).at(0), "Next");
    await tester.enterText(find.byType(TextFormField).at(1), "7");
    await tester.pumpAndSettle();

    expect(find.text("Next"), findsOneWidget);
    expect(find.text("7"), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
