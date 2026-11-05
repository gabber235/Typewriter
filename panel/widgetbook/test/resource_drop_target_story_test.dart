import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";
import "package:widgetbook_workspace/stories/authoring/presentation/resource_drop_target.stories.dart";

import "support/stories.dart";

const _entry = "Welcome to the village";
const _evening = "Village evening";

void main() {
  testWidgets("a dragged entry follows the pointer over the rail and offers "
      "Move here only above the page that accepts it", (tester) async {
    final panel = await tester.pumpStory(resourceDropTargetStory);

    final gesture = await tester.holdDrag(panel, _entry, onto: _evening);
    expect(find.text(_entry), findsNWidgets(2));
    expect(find.text("Move here"), findsOneWidget);
    final preview = tester.getRect(find.text(_entry).last);
    expect(preview.overlaps(panel.item(_evening).rect), isTrue);

    await gesture.moveTo(tester.getCenter(find.text(_entry).first));
    await tester.runStory();
    expect(find.text("Move here"), findsNothing);
    expect(find.text(_entry), findsOneWidget);

    await gesture.moveTo(panel.item(_evening).rect.center);
    await tester.runStory();
    expect(find.text("Move here"), findsOneWidget);
    await gesture.cancel();
    await tester.runStory();
    expect(find.text(_entry), findsOneWidget);
  });

  testWidgets("dropping an entry on the page moves it there and saves", (
    tester,
  ) async {
    final panel = await tester.pumpStory(resourceDropTargetStory);

    final gesture = await tester.holdDrag(panel, _entry, onto: _evening);
    await gesture.up();
    await tester.runStory();

    expect(
      panel.working.relations.ownerPath(compiledEntryFirstId).owners.first,
      compiledEntryDestinationId,
    );
    expect(
      panel.world.requireRealm.document.relations
          .ownerPath(compiledEntryFirstId)
          .owners
          .first,
      compiledEntryDestinationId,
    );
    expect(find.text(_entry), findsNothing);
    expect(find.text("Meet the village guide"), findsOneWidget);
  });

  testWidgets("the entry's context menu offers the same move", (tester) async {
    final panel = await tester.pumpStory(resourceDropTargetStory);

    final menu = await panel.item(_entry).contextMenu();
    expect(menu.entries, containsAll(["Open", "Inspect", "Move to"]));
    await menu.choose("Move to");
    await tester.runStory();

    expect(
      panel.working.relations.ownerPath(compiledEntryFirstId).owners.first,
      compiledEntryDestinationId,
    );
  });

  testWidgets("a page the Realm refuses takes no dropped entry", (
    tester,
  ) async {
    final panel = await tester.pumpStory(
      resourceDropTargetStory,
      knobs: {"Village evening": "Refuses the entries"},
    );

    final gesture = await tester.holdDrag(panel, _entry, onto: _evening);
    expect(find.text("Move here"), findsNothing);
    await gesture.up();
    await tester.runStory();

    expect(
      panel.working.relations.ownerPath(compiledEntryFirstId).owners.first,
      isNot(compiledEntryDestinationId),
    );
    expect(panel.world.requireRealm.saves, isEmpty);
  });

  testWidgets("a click selects only the clicked entry", (tester) async {
    final panel = await tester.pumpStory(resourceDropTargetStory);

    await panel.item(_entry).select();

    expect(
      panel.container.read(selectionProvider).map((selected) => selected.id),
      [compiledEntryFirstId.value],
    );
  });
}
