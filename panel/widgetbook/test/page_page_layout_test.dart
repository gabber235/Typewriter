import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook_workspace/stories/features/organizations/features/realms/features/books/features/pages/presentation/route.stories.dart";

import "support/network_images.dart";

void main() {
  testWidgetsWithNetworkImages(
    "graph page stays within a narrow Widgetbook canvas",
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 720));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final elements = graphPageStoryElements(
        count: 6,
        direction: GraphDirection.leftToRight,
      );
      final story = pagePageStory(
        definition: graphPageStoryDefinition(
          GraphDirection.leftToRight,
          elements,
        ),
        elements: elements,
        pagesState: DisplayState.manyItems,
        entriesState: DisplayState.fewItems,
        servicesState: DisplayState.manyItems,
      ) as FakeApp;
      await tester.pumpWidget(
        FakeApp(
          overrides: story.overrides,
          child: MediaQuery(
            data: const MediaQueryData(size: Size(1280, 720)),
            child: SizedBox(width: 550, height: 720, child: story.child),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final container = ProviderScope.containerOf(
        tester.element(find.byType(PagePage)),
      );
      final entry = tester
          .widget<EntryNode>(find.byType(EntryNode).first)
          .entry;
      container
          .read(selectionProvider.notifier)
          .select(EntryIdentifier(entry.id));
      await tester.pumpAndSettle();

      expect(find.byType(PagePage), findsOneWidget);
      expect(find.byType(MobileInspector), findsOneWidget);
      expect(find.byType(DesktopInspector), findsNothing);
      final inspectorBodyEditor = find.descendant(
        of: find.byType(MobileInspector),
        matching: find.byWidgetPredicate(
          (widget) => widget is ComposedEditor && widget.key != null,
        ),
      );
      expect(inspectorBodyEditor, findsOneWidget);
    },
  );
}
