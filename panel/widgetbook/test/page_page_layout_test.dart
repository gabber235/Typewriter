import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook_workspace/stories/features/organizations/features/realms/features/books/features/pages/presentation/route.stories.dart";

void main() {
  testWidgets("sequence page stays within a narrow Widgetbook canvas", (
    tester,
  ) async {
    final previousErrorHandler = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.exception is NetworkImageLoadException) return;
      previousErrorHandler?.call(details);
    };
    addTearDown(() => FlutterError.onError = previousErrorHandler);

    await tester.binding.setSurfaceSize(const Size(1280, 720));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final story =
        pagePageStory(
              pageType: PageType.sequence,
              pagesState: DisplayState.manyItems,
              entriesState: DisplayState.fewItems,
              servicesState: DisplayState.manyItems,
            )
            as FakeApp;
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
    container
        .read(selectionProvider.notifier)
        .select(const EntryIdentifier("sequence_entry_0"));
    await tester.pumpAndSettle();

    FlutterError.onError = previousErrorHandler;
    expect(find.byType(PagePage), findsOneWidget);
    expect(find.byType(MobileInspector), findsOneWidget);
    expect(find.byType(DesktopInspector), findsNothing);
    expect(find.byType(TypedEditor), findsOneWidget);
  });
}
