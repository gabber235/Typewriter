import "package:flutter/gestures.dart";
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
import "package:widgetbook_workspace/stories/shared/inspector/presentation/inspector.stories.dart";

import "support/network_images.dart";

void main() {
  testWidgetsWithNetworkImages("Book card story opens the Book inspector", (
    tester,
  ) async {
    await _prepareStory(tester);

    await tester.pumpWidget(Builder(builder: bookUseCase));
    await tester.pumpAndSettle();

    await _tapSelectable(tester, find.byType(BookWidget));
    await tester.pump(kDoubleTapTimeout);
    await tester.pumpAndSettle();

    expect(find.text("Direct Tags"), findsOneWidget);
    expect(find.text("direct_story"), findsWidgets);
    expect(find.text("inherited_lore"), findsOneWidget);

    final original = _editorRoot(tester);
    await _openSearch(tester, last: true);
    expect(find.text("Binding is not available"), findsNothing);
    await tester.tap(find.bySemanticsLabel("inherited_lore").first);
    await tester.pump();
    expect(_editorRoot(tester), isNot(original));

    await _cancel(tester);
    await tester.pumpAndSettle();
    expect(_editorRoot(tester), original);
  });

  testWidgetsWithNetworkImages("Tag node story opens the Tag inspector", (
    tester,
  ) async {
    await _prepareStory(tester);

    await tester.pumpWidget(Builder(builder: tagNodeUseCase));
    await tester.pumpAndSettle();

    await _tapSelectable(tester, find.byType(TagNode));
    await tester.pumpAndSettle();

    expect(find.text("Direct Parents"), findsOneWidget);
    final original = _editorRoot(tester);
    await _openSearch(tester);
    expect(find.text("Binding is not available"), findsNothing);
    await tester.tap(find.bySemanticsLabel("candidate_parent").first);
    await tester.pump();
    expect(_editorRoot(tester), isNot(original));

    await _cancel(tester);
    await tester.pumpAndSettle();
    expect(_editorRoot(tester), original);
  });

  testWidgetsWithNetworkImages(
    "Book mixed selection resolves both cards through the Book inspector",
    (tester) async {
      await _prepareStory(tester);
      await tester.pumpWidget(mixedBookSelectionStory());
      await tester.pumpAndSettle();

      final container = _inspectorContainer(tester);
      expect(container.read(selectionProvider), hasLength(2));
      expect(find.byType(ComposedEditor), findsOneWidget);
      expect(
        find.text("Title"),
        findsOneWidget,
        reason: tester
            .widgetList<Text>(find.byType(Text))
            .map((text) => text.data)
            .join(" | "),
      );
      expect(find.text("Icon"), findsOneWidget);
      expect(find.text("Color"), findsOneWidget);
      expect(find.text("Direct Tags"), findsOneWidget);
      expect(find.text("Binding is not available"), findsNothing);
    },
  );

  testWidgetsWithNetworkImages(
    "Tag mixed selection resolves both nodes through the Tag inspector",
    (tester) async {
      await _prepareStory(tester);
      await tester.pumpWidget(mixedTagSelectionStory(initiallySelected: false));
      await tester.pumpAndSettle();

      final tags = find.byType(TagNode);
      await _tapSelectable(tester, tags.at(2));
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await _tapSelectable(tester, tags.at(3));
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await tester.pumpAndSettle();

      final container = _inspectorContainer(tester);
      expect(container.read(selectionProvider), hasLength(2));
      expect(find.byType(ComposedEditor), findsOneWidget);
      expect(find.text("Name"), findsOneWidget);
      expect(find.text("Color"), findsOneWidget);
      expect(find.text("Direct Parents"), findsOneWidget);
      expect(find.text("Binding is not available"), findsNothing);
    },
  );

  for (final sharedColor in [false, true]) {
    testWidgetsWithNetworkImages(
      "heterogeneous selection exposes only the shared color field when "
      "sharedColor is $sharedColor",
      (tester) async {
        await _prepareStory(tester);
        await tester.pumpWidget(
          bookAndTagSelectionStory(sharedColor: sharedColor),
        );
        await tester.pumpAndSettle();

        final container = _inspectorContainer(tester);
        expect(container.read(selectionProvider), hasLength(2));
        expect(find.byType(ComposedEditor), findsOneWidget);
        expect(find.text("Color"), findsOneWidget);
        expect(find.text("Title"), findsNothing);
        expect(find.text("Icon"), findsNothing);
        expect(find.text("Direct Tags"), findsNothing);
        expect(find.text("Name"), findsNothing);
        expect(find.text("Direct Parents"), findsNothing);
        expect(find.text("Binding is not available"), findsNothing);
      },
    );
  }

  testWidgetsWithNetworkImages(
    "Services page story opens the Service inspector",
    (tester) async {
      await _prepareStory(tester);
      await tester.pumpWidget(servicesPageStory());
      await tester.pumpAndSettle();

      await tester.tap(find.byType(GridSelectableCard).first);
      await tester.pumpAndSettle();

      expect(find.text("Name"), findsOneWidget);
      expect(find.text("Version"), findsOneWidget);
      expect(find.text("Service"), findsOneWidget);
      expect(find.text("CONNECTION"), findsOneWidget);
      expect(find.text("Connected"), findsWidgets);
      expect(find.text("Expected a record"), findsNothing);
      expect(find.text("Last seen"), findsOneWidget);
    },
  );

  testWidgetsWithNetworkImages("Tags page story opens the Tag inspector", (
    tester,
  ) async {
    await _prepareStory(tester);
    await tester.pumpWidget(tagsPageStory(tagsState: DisplayState.fewItems));
    await tester.pumpAndSettle();

    await _tapSelectable(tester, find.byType(TagNode).first);
    await tester.pumpAndSettle();

    expect(find.text("Direct Parents"), findsOneWidget);
  });

  testWidgetsWithNetworkImages("Library page story opens the Book inspector", (
    tester,
  ) async {
    await _prepareStory(tester);
    await tester.pumpWidget(
      libraryPageStory(
        displayState: DisplayState.fewItems,
        tagsState: DisplayState.noItems,
      ),
    );
    await tester.pumpAndSettle();

    _selectFirst<BookIdentifier>(tester);
    await tester.pumpAndSettle();

    expect(find.text("Direct Tags"), findsOneWidget);
  });

  testWidgetsWithNetworkImages("graph page story opens the Entry inspector", (
    tester,
  ) async {
    await _prepareStory(tester);
    final elements = graphPageStoryElements(
      count: 12,
      direction: GraphDirection.leftToRight,
    );
    await tester.pumpWidget(
      pagePageStory(
        definition: graphPageStoryDefinition(
          GraphDirection.leftToRight,
          elements,
        ),
        elements: elements,
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

    expect(container.read(selectionProvider), contains(isA<EntryIdentifier>()));
    expect(
      resolvedSelection.hasError,
      isFalse,
      reason: "${resolvedSelection.error}",
    );
    expect(resolvedSelection.value, hasLength(1));
    final entryHeader = find.byType(EntryInspectorHeader);
    expect(entryHeader, findsOneWidget);
    expect(
      find.descendant(of: entryHeader, matching: find.byType(ComposedEditor)),
      findsOneWidget,
    );
    expect(find.text("Name"), findsOneWidget);
    expect(find.text("Priority"), findsOneWidget);
    expect(find.text("Weight"), findsOneWidget);
  });

  testWidgetsWithNetworkImages("timeline page story opens the Cue inspector", (
    tester,
  ) async {
    await _prepareStory(tester);
    final elements = generateTimelinePageElements(
      trackCount: 4,
      segmentsPerTrack: 2,
      keyframesPerSegment: 2,
      nestingDepth: 1,
    );
    await tester.pumpWidget(
      pagePageStory(
        definition: timelinePageStoryDefinition(elements),
        elements: elements,
        pagesState: DisplayState.manyItems,
        entriesState: DisplayState.manyItems,
        servicesState: DisplayState.manyItems,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(TimelineSegmentSurface).first);
    await tester.pumpAndSettle();

    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    expect(
      find.byWidgetPredicate(
        (widget) => widget is ComposedEditor && widget.key != null,
      ),
      findsOneWidget,
    );
    expect(find.byType(CueHeader), findsOneWidget);
  });
}

Future<void> _prepareStory(
  WidgetTester tester, {
  Size size = const Size(1600, 1000),
}) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
}

Future<void> _openSearch(WidgetTester tester, {bool last = false}) async {
  final search = find.byWidgetPredicate(
    (widget) =>
        widget is Semantics &&
        widget.properties.label == "Activate search input",
    skipOffstage: false,
  );
  final target = last ? search.last : search.first;
  await tester.ensureVisible(target);
  await tester.tap(target);
  await tester.pumpAndSettle();
}

void _selectFirst<T extends SelectableIdentifier>(WidgetTester tester) {
  final selector = tester
      .widgetList<Selector>(find.byType(Selector))
      .firstWhere((selector) => selector.selectableId is T);
  final container = ProviderScope.containerOf(
    tester.element(find.byType(Selector).first),
  );
  container.read(selectionProvider.notifier).select(selector.selectableId);
}

Future<void> _tapSelectable(WidgetTester tester, Finder surface) async {
  final target = find
      .descendant(of: surface, matching: find.byType(GestureDetector))
      .hitTestable();
  expect(target, findsWidgets);
  await tester.tap(target.first);
}

Future<void> _cancel(WidgetTester tester) async {
  await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
  await tester.sendKeyEvent(LogicalKeyboardKey.escape);
  await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
}

RecordValue _editorRoot(WidgetTester tester) {
  final container = ProviderScope.containerOf(
    tester.element(find.byType(ComposedEditor)),
  );
  final model = container.read(inspectionSessionProvider).model!;
  final owner = (model.inputs.values.single as PresentationEditInput).owner;
  final value = owner.value(DataPath.root);
  return (value as ReadyEditorValue).value as RecordValue;
}

ProviderContainer _inspectorContainer(WidgetTester tester) =>
    ProviderScope.containerOf(tester.element(find.byType(InspectorScaffold)));
