import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_test/flutter_test.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook_workspace/stories/features/organizations/features/realms/features/books/features/pages/presentation/route.stories.dart";
import "package:widgetbook_workspace/stories/features/organizations/features/realms/features/books/presentation/book.stories.dart";
import "package:widgetbook_workspace/stories/features/organizations/features/realms/features/books/presentation/library/route.stories.dart";
import "package:widgetbook_workspace/stories/features/organizations/features/realms/features/tags/presentation/route.stories.dart";
import "package:widgetbook_workspace/stories/features/organizations/features/realms/features/tags/presentation/tag_node.stories.dart";
import "package:widgetbook_workspace/stories/features/organizations/features/services/presentation/route.stories.dart";

void main() {
  testWidgets("Book card story opens the Book inspector", (tester) async {
    final errors = await _prepareStory(tester);

    await tester.pumpWidget(Builder(builder: bookUseCase));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(BookWidget));
    await tester.pumpAndSettle();

    expect(find.text("Direct Tags"), findsOneWidget);
    expect(find.text("direct_story"), findsWidgets);
    expect(find.text("inherited_lore"), findsOneWidget);

    final original = _editorRoot(tester);
    await _openSearch(tester);
    expect(find.text("Binding is not available"), findsNothing);
    await tester.tap(find.bySemanticsLabel("inherited_lore").first);
    await tester.pump();
    expect(_editorRoot(tester), isNot(original));

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(_editorRoot(tester), original);

    await _openSearch(tester);
    await tester.tap(find.bySemanticsLabel("inherited_lore").first);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();

    final committed = _editorRoot(tester);
    expect(committed.fields.keys, original.fields.keys);
    expect(committed.fields["title"], original.fields["title"]);
    expect(committed.fields["icon"], original.fields["icon"]);
    expect(committed.fields["color"], original.fields["color"]);
    expect((committed.fields["tags"]! as ListValue).values, hasLength(2));
    _expectNoFlutterErrors(errors);
  });

  testWidgets("Tag node story opens the Tag inspector", (tester) async {
    final errors = await _prepareStory(tester);

    await tester.pumpWidget(Builder(builder: tagNodeUseCase));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(TagNode));
    await tester.pumpAndSettle();

    expect(find.text("Direct Parents"), findsOneWidget);
    final original = _editorRoot(tester);
    await _openSearch(tester);
    expect(find.text("Binding is not available"), findsNothing);
    await tester.tap(find.bySemanticsLabel("candidate_parent").first);
    await tester.pump();
    expect(_editorRoot(tester), isNot(original));

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(_editorRoot(tester), original);

    await _openSearch(tester);
    await tester.tap(find.bySemanticsLabel("candidate_parent").first);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();

    final committed = _editorRoot(tester);
    expect(committed.fields.keys, original.fields.keys);
    expect(committed.fields["name"], original.fields["name"]);
    expect(committed.fields["color"], original.fields["color"]);
    expect(committed.fields["layout"], original.fields["layout"]);
    expect((committed.fields["parents"]! as ListValue).values, hasLength(1));
    _expectNoFlutterErrors(errors);
  });

  testWidgets("Services page story opens the Service inspector", (
    tester,
  ) async {
    final errors = await _prepareStory(tester);
    await tester.pumpWidget(
      servicesPageStory(servicesState: DisplayState.fewItems),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(GridSelectableCard).first);
    await tester.pumpAndSettle();

    expect(find.text("Runs in"), findsOneWidget);
    _expectNoFlutterErrors(errors);
  });

  testWidgets("Tags page story opens the Tag inspector", (tester) async {
    final errors = await _prepareStory(tester);
    await tester.pumpWidget(tagsPageStory(tagsState: DisplayState.fewItems));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(TagNode).first);
    await tester.pumpAndSettle();

    expect(find.text("Direct Parents"), findsOneWidget);
    _expectNoFlutterErrors(errors);
  });

  testWidgets("Library page story opens the Book inspector", (tester) async {
    final errors = await _prepareStory(tester);
    await tester.pumpWidget(
      libraryPageStory(
        displayState: DisplayState.fewItems,
        tagsState: DisplayState.noItems,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(BookWidget).first);
    await tester.pumpAndSettle();

    expect(find.text("Direct Tags"), findsOneWidget);
    _expectNoFlutterErrors(errors);
  });

  testWidgets("sequence page story opens the Entry inspector", (tester) async {
    final errors = await _prepareStory(tester);
    await tester.pumpWidget(
      pagePageStory(
        pageType: PageType.sequence,
        pagesState: DisplayState.manyItems,
        entriesState: DisplayState.manyItems,
        servicesState: DisplayState.manyItems,
      ),
    );
    await tester.pumpAndSettle();

    final entryTapTarget = find
        .descendant(
          of: find.byType(EntryNode).first,
          matching: find.byType(GestureDetector),
        )
        .hitTestable()
        .first;
    await tester.tap(entryTapTarget);
    await tester.pumpAndSettle();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(PagePage)),
    );
    final resolvedSelection = container.read(selectedProvider);

    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    _expectNoFlutterErrors(errors);
    expect(container.read(selectionProvider), contains(isA<EntryIdentifier>()));
    expect(
      resolvedSelection.hasError,
      isFalse,
      reason: "${resolvedSelection.error}",
    );
    expect(resolvedSelection.value, hasLength(1));
    expect(find.byType(TypedEditor), findsOneWidget);
    expect(find.byType(EntryHeader), findsOneWidget);
    expect(find.text("Priority"), findsOneWidget);
    expect(find.text("Weight"), findsOneWidget);
  });

  testWidgets("scene page story opens the Cue inspector", (tester) async {
    final errors = await _prepareStory(tester);
    await tester.pumpWidget(
      pagePageStory(
        pageType: PageType.scene,
        pagesState: DisplayState.manyItems,
        entriesState: DisplayState.manyItems,
        servicesState: DisplayState.manyItems,
        overwriteElements: pagePageSceneElements(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(TimelineSegmentSurface).first);
    await tester.pumpAndSettle();

    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    _expectNoFlutterErrors(errors);
    expect(find.byType(TypedEditor), findsOneWidget);
    expect(find.byType(CueHeader), findsOneWidget);
  });
}

typedef _StoryErrorCapture = ({
  List<FlutterErrorDetails> errors,
  void Function(FlutterErrorDetails)? previousHandler,
});

Future<_StoryErrorCapture> _prepareStory(
  WidgetTester tester, {
  Size size = const Size(1600, 1000),
}) async {
  final errors = <FlutterErrorDetails>[];
  final previousErrorHandler = FlutterError.onError;
  FlutterError.onError = (details) {
    if (details.exception is NetworkImageLoadException) return;
    errors.add(details);
  };
  addTearDown(() => FlutterError.onError = previousErrorHandler);
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  addTearDown(() {
    FlutterError.onError = previousErrorHandler;
    final firstError = errors.firstOrNull;
    if (firstError == null) return;
    fail("${firstError.exceptionAsString()}\n${firstError.stack}");
  });
  return (errors: errors, previousHandler: previousErrorHandler);
}

void _expectNoFlutterErrors(_StoryErrorCapture capture) {
  FlutterError.onError = capture.previousHandler;
}

Future<void> _openSearch(WidgetTester tester) async {
  await tester.tap(find.bySemanticsLabel("Activate search input"));
  await tester.pumpAndSettle();
}

RecordValue _editorRoot(WidgetTester tester) {
  final container = ProviderScope.containerOf(
    tester.element(find.byType(TypedEditor)),
  );
  final value = container.read(editorProvider)!.value(DataPath.root);
  return (value as ReadyEditorValue).value as RecordValue;
}
