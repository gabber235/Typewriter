import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  testWidgets(
    "a drag resolves its candidates once and hovering costs no round trip",
    (tester) async {
      final fixture = AuthoredGraphFixture();
      await fixture.showDropTarget(tester);
      final target = tester.getCenter(_target);
      final gesture = await fixture.startSourceDrag(tester);
      await gesture.moveTo(target);
      await tester.pumpAndSettle();
      expect(find.text("accepted: Move here"), findsOneWidget);
      await gesture.moveTo(const Offset(10, 10));
      await tester.pumpAndSettle();
      expect(find.text("neutral"), findsOneWidget);
      await gesture.moveTo(target);
      await tester.pumpAndSettle();
      expect(find.text("accepted: Move here"), findsOneWidget);
      expect(fixture.dropResolutions, hasLength(1));
      expect(fixture.preparations, isEmpty);
      await gesture.up();
      await tester.pumpAndSettle();
      expect(fixture.dropResolutions, hasLength(1));
      expect(
        fixture.workspace.document.relations.children[fixture.destination],
        contains(fixture.source),
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets("a destination without offers rejects the drag", (tester) async {
    final fixture = AuthoredGraphFixture();
    await fixture.showDropTarget(tester, destination: fixture.page);
    final gesture = await fixture.startSourceDrag(tester);
    await gesture.moveTo(tester.getCenter(_target));
    await tester.pumpAndSettle();
    expect(find.text("rejected"), findsOneWidget);
    await gesture.up();
    await tester.pumpAndSettle();
    expect(fixture.preparations, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    "accepted drop survives pointer retirement while candidates are pending",
    (tester) async {
      final fixture = AuthoredGraphFixture();
      final release = Completer<void>();
      final resolve = fixture.recording(
        resolve: (request) async {
          await release.future;
          return fixture.dropCandidates(request);
        },
      );
      await fixture.showDropTarget(tester, resolve: resolve);
      final gesture = await fixture.startSourceDrag(tester);
      final offered = tester
          .widget<GraphDrag>(find.byType(GraphDrag))
          .controller
          .value!
          .payload;
      await gesture.moveTo(tester.getCenter(_target));
      await tester.pump();
      expect(find.text("neutral"), findsOneWidget);
      await gesture.up();
      await tester.pump();
      expect(offered.phase, GraphDragPhase.retired);
      expect(
        fixture.workspace.document.relations.children[fixture.destination],
        isNot(contains(fixture.source)),
      );
      release.complete();
      await tester.pumpAndSettle();
      expect(
        fixture.workspace.document.relations.children[fixture.destination],
        contains(fixture.source),
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    "a drop accepted while candidates load reaches the enclosing target when "
    "the inner target turns out to offer nothing",
    (tester) async {
      final fixture = AuthoredGraphFixture();
      final release = Completer<void>();
      final resolve = fixture.recording(
        resolve: (request) async {
          await release.future;
          return fixture.dropCandidates(request);
        },
      );
      await fixture.showDropTarget(
        tester,
        resolve: resolve,
        destination: fixture.page,
        enclosing: fixture.destination,
      );
      final gesture = await fixture.startSourceDrag(tester);
      await gesture.moveTo(tester.getCenter(_target));
      await tester.pump();
      expect(find.text("neutral"), findsOneWidget);
      await gesture.up();
      await tester.pump();
      release.complete();
      await tester.pumpAndSettle();
      expect(
        fixture.workspace.document.relations.children[fixture.destination],
        contains(fixture.source),
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    "a target that can offer nothing refuses while candidates load, so the "
    "enclosing target receives the drag",
    (tester) async {
      final fixture = AuthoredGraphFixture();
      final release = Completer<void>();
      final resolve = fixture.recording(
        resolve: (request) async {
          await release.future;
          return fixture.dropCandidates(request);
        },
      );
      await fixture.showDropTarget(
        tester,
        resolve: resolve,
        // A dragged resource is never its own destination.
        destination: fixture.source,
        enclosing: fixture.destination,
      );
      final gesture = await fixture.startSourceDrag(tester);
      await gesture.moveTo(tester.getCenter(_target));
      await tester.pump();
      expect(find.text("rejected"), findsOneWidget);
      expect(find.text("enclosing neutral"), findsOneWidget);
      release.complete();
      await tester.pumpAndSettle();
      expect(find.text("enclosing accepted: Move here"), findsOneWidget);
      await gesture.up();
      await tester.pumpAndSettle();
      expect(
        fixture.workspace.document.relations.children[fixture.destination],
        contains(fixture.source),
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    "several offers open the drop chooser, and Escape cancels the drop",
    (tester) async {
      final fixture = AuthoredGraphFixture();
      final resolve = fixture.recording(
        resolve: (request) async =>
            skir.ResolveDropCandidatesResult.wrapResolved([
              for (final operation in ["linkWith", "moveToOwner"])
                skir.DropCandidates(
                  operation: fixtureOperationId(operation),
                  destinations: [fixture.destination],
                  complete: true,
                ),
            ]),
      );
      await fixture.showDropTarget(tester, resolve: resolve);
      final target = tester.getCenter(_target);
      var gesture = await fixture.startSourceDrag(tester);
      await gesture.moveTo(target);
      await tester.pumpAndSettle();
      expect(find.text("accepted: 2 options"), findsOneWidget);
      await gesture.up();
      await tester.pumpAndSettle();
      expect(find.byType(DropChooser), findsOneWidget);
      final labels = tester
          .widgetList<MenuItemButton>(
            find.descendant(
              of: find.byType(DropChooser),
              matching: find.byType(MenuItemButton),
            ),
          )
          .map((button) => (button.child! as Text).data)
          .toList();
      expect(labels, ["Move to", "Link with"]);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.byType(DropChooser), findsNothing);
      expect(fixture.preparations, isEmpty);

      gesture = await fixture.startSourceDrag(tester, pointer: 2);
      await gesture.moveTo(target);
      await tester.pumpAndSettle();
      await gesture.up();
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(DropChooser),
          matching: find.text("Move to"),
        ),
      );
      await tester.pumpAndSettle();
      expect(fixture.preparations.single.capability.value, "moveToOwner");
      expect(
        fixture.workspace.document.relations.children[fixture.destination],
        contains(fixture.source),
      );
    },
  );

  testWidgets(
    "removing source ProviderScope hides root feedback and retires the hover",
    (tester) async {
      final fixture = AuthoredGraphFixture();
      final visible = ValueNotifier(true);
      addTearDown(visible.dispose);
      await fixture.showDropTarget(tester, visible: visible);
      final gesture = await fixture.startSourceDrag(tester);
      final offered = tester
          .widget<GraphDrag>(find.byType(GraphDrag))
          .controller
          .value!
          .payload;
      await gesture.moveTo(tester.getCenter(_target));
      await tester.pumpAndSettle();
      expect(find.text("Source"), findsNWidgets(2));
      expect(find.text("accepted: Move here"), findsOneWidget);
      visible.value = false;
      await tester.pump();
      await tester.pump();
      expect(offered.phase, GraphDragPhase.retired);
      expect(find.text("Source"), findsNothing);
      expect(find.text("accepted: Move here"), findsNothing);
      expect(find.text("rejected"), findsNothing);
      await gesture.up();
      await tester.pumpAndSettle();
      expect(
        fixture.workspace.document.relations.children[fixture.destination],
        isNot(contains(fixture.source)),
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    "old resource avatar leave and drop preserve the replacement hover",
    (tester) async {
      final fixture = AuthoredGraphFixture();
      final generation = ValueNotifier(0);
      addTearDown(generation.dispose);
      await fixture.showDropTarget(tester, generation: generation);
      final old = await fixture.startSourceDrag(tester, pointer: 1);
      final target = tester.getCenter(_target);
      await old.moveTo(target);
      await tester.pumpAndSettle();
      generation.value++;
      await tester.pump();
      await tester.pump();
      final next = await fixture.startSourceDrag(tester, pointer: 2);
      await next.moveTo(target);
      await tester.pumpAndSettle();
      expect(find.text("accepted: Move here"), findsOneWidget);
      await old.moveTo(const Offset(10, 10));
      await tester.pump();
      expect(find.text("accepted: Move here"), findsOneWidget);
      await old.moveTo(target);
      await tester.pump();
      await old.up();
      await tester.pump();
      expect(find.text("accepted: Move here"), findsOneWidget);
      expect(
        fixture.workspace.document.relations.children[fixture.destination],
        isNot(contains(fixture.source)),
      );
      await next.up();
      await tester.pumpAndSettle();
      expect(
        fixture.workspace.document.relations.children[fixture.destination],
        contains(fixture.source),
      );
      expect(tester.takeException(), isNull);
    },
  );
}

/// The drop target the dragged resource is moved onto.
final _target = find.bySemanticsLabel(RegExp("^Operation target"));
