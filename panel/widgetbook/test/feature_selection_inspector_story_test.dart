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

import "support/network_images.dart";

void main() {
  testWidgetsWithNetworkImages("Book card story opens the Book inspector", (
    tester,
  ) async {
    await _prepareStory(tester);

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

    await _cancel(tester);
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
  });

  testWidgetsWithNetworkImages("Tag node story opens the Tag inspector", (
    tester,
  ) async {
    await _prepareStory(tester);

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

    await _cancel(tester);
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
  });

  testWidgetsWithNetworkImages(
    "Services page story opens the Service inspector",
    (tester) async {
      await _prepareStory(tester);
      await tester.pumpWidget(
        servicesPageStory(servicesState: DisplayState.fewItems),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(GridSelectableCard).first);
      await tester.pumpAndSettle();

      expect(find.text("Runs in"), findsOneWidget);
      expect(find.text("Expected a record"), findsNothing);
      final container = ProviderScope.containerOf(
        tester.element(find.byType(TypedEditor)),
      );
      final services = container.read(servicesProvider).requireValue;
      final editing = services.first;
      final realm = services.firstWhere((service) => service.isRealm);
      await _openSearch(tester);
      expect(find.text("No matching results"), findsNothing);
      expect(find.text("Standalone"), findsWidgets);
      expect(find.bySemanticsLabel(realm.displayName), findsOneWidget);
      await tester.tap(find.bySemanticsLabel(realm.displayName));
      await tester.pumpAndSettle();
      final updated = container
          .read(servicesProvider)
          .requireValue
          .singleWhere((service) => service.serviceId == editing.serviceId);
      expect(updated.runsIn, realm.serviceId);
      expect(find.text("Runs in"), findsOneWidget);
      expect(find.text("Expected a record"), findsNothing);
      expect(find.text("Realm"), findsOneWidget);
    },
  );

  testWidgetsWithNetworkImages("Tags page story opens the Tag inspector", (
    tester,
  ) async {
    await _prepareStory(tester);
    await tester.pumpWidget(tagsPageStory(tagsState: DisplayState.fewItems));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(TagNode).first);
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

    await tester.tap(find.byType(BookWidget).first);
    await tester.pumpAndSettle();

    expect(find.text("Direct Tags"), findsOneWidget);
  });

  testWidgetsWithNetworkImages(
    "sequence page story opens the Entry inspector",
    (tester) async {
      await _prepareStory(tester);
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

      expect(
        container.read(selectionProvider),
        contains(isA<EntryIdentifier>()),
      );
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
    },
  );

  testWidgetsWithNetworkImages("scene page story opens the Cue inspector", (
    tester,
  ) async {
    await _prepareStory(tester);
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

    expect(find.byType(TypedEditor), findsOneWidget);
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

Future<void> _openSearch(WidgetTester tester) async {
  await tester.tap(find.bySemanticsLabel("Activate search input"));
  await tester.pumpAndSettle();
}

Future<void> _cancel(WidgetTester tester) async {
  await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
  await tester.sendKeyEvent(LogicalKeyboardKey.escape);
  await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
}

RecordValue _editorRoot(WidgetTester tester) {
  final container = ProviderScope.containerOf(
    tester.element(find.byType(TypedEditor)),
  );
  final value = container.read(editorProvider)!.value(DataPath.root);
  return (value as ReadyEditorValue).value as RecordValue;
}
