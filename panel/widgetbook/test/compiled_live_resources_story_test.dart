import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:widgetbook_workspace/stories/authoring/search/presentation/compiled_search_results.stories.dart";

import "support/network_images.dart";

void main() {
  testWidgetsWithNetworkImages(
    "compiled live story updates linked labels and native selection",
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1000, 760));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(const CompiledLiveResourceResults());
      await tester.pumpAndSettle();
      expect(find.byType(AuthoredResourceSearchResult), findsNWidgets(4));
      expect(find.text("Compiled result fixture"), findsOneWidget);
      await tester.enterText(find.byType(TextField).at(0), "The Coast");
      await tester.pumpAndSettle();
      expect(find.text("The Coast"), findsWidgets);
      expect(find.text("Main Quest"), findsNothing);
      await tester.enterText(find.byType(TextField).at(1), "Coastal quest");
      await tester.pumpAndSettle();
      expect(find.text("Coastal quest"), findsWidgets);
      expect(find.text("Quest tag"), findsNothing);
      await tester.enterText(find.byType(TextField).at(2), "Meet the Captain");
      await tester.pumpAndSettle();
      expect(find.text("Meet the Captain"), findsWidgets);
      await tester.tap(find.text("From this Page"));
      await tester.pumpAndSettle();
      final element = find.byWidgetPredicate(
        (widget) =>
            widget is AuthoredResourceSearchResult &&
            widget.resource.value == "rich:element",
      );
      expect(
        find.descendant(of: element, matching: find.text("Village")),
        findsNothing,
      );
      expect(
        find.descendant(of: element, matching: find.text("Meet the Captain")),
        findsNothing,
      );
      await tester.tapAt(tester.getCenter(find.text("Mayor greeting")));
      await tester.pumpAndSettle();
      expect(find.text("Selected resource: element"), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
