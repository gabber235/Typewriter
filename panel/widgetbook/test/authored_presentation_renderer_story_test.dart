import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook_workspace/stories/features/organizations/features/realms/presentation/authored_presentation_renderer.stories.dart";

void main() {
  testWidgets(
    "heading gallery fits and hides resource identity for multiple selection",
    (tester) async {
      await tester.pumpWidget(
        const FakeApp(
          child: Scaffold(
            body: Center(
              child: SizedBox(width: 200, child: ResourceHeadingGallery()),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(AutoSizeText), findsNWidgets(2));
      expect(
        find.text("book:019d1c2a8f7b7cc18c2a4a7b2fd1e281"),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(
        const FakeApp(
          child: Scaffold(
            body: Center(
              child: SizedBox(
                width: 200,
                child: ResourceHeadingGallery(multiple: true),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(AutoSizeText), findsOneWidget);
      expect(find.text("book:019d1c2a8f7b7cc18c2a4a7b2fd1e281"), findsNothing);
      expect(
        find.text("Normal fields and section labels remain visible"),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets("the canonical scalar gallery renders and edits real controls", (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(900, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const FakeApp(
        child: Scaffold(
          body: SingleChildScrollView(child: AuthoredScalarGallery()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(PortablePresentationNodeRenderer), findsWidgets);
    expect(find.text("Title"), findsOneWidget);
    expect(find.text("Count"), findsOneWidget);
    expect(find.text("Enabled"), findsOneWidget);
    expect(find.text("Intensity"), findsOneWidget);
    expect(find.text("Starts at"), findsOneWidget);
    expect(find.text("Duration in milliseconds"), findsOneWidget);
    expect(find.text("Color"), findsOneWidget);
    expect(find.text("Binary payload"), findsOneWidget);
    expect(find.byType(DateTimePickerField), findsOneWidget);
    expect(find.byType(ColorPickerField), findsOneWidget);

    await tester.tap(find.byType(Switch));
    await tester.pump();
    expect(tester.widget<Switch>(find.byType(Switch)).value, isFalse);

    final count = find.byType(TextFormField).at(1);
    await tester.enterText(count, "12");
    await tester.pumpAndSettle();
    expect(find.text("12"), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets("canonical layouts and actions preserve interactive behavior", (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(700, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const FakeApp(
        child: Scaffold(
          body: SingleChildScrollView(child: AuthoredInteractionGallery()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text("Details are visible"), findsOneWidget);
    expect(find.byType(DepthBox), findsWidgets);
    expect(find.text("Quest actions"), findsOneWidget);
    final actionHeader = find.widgetWithText(InkWell, "Quest actions");
    expect(actionHeader, findsOneWidget);
    Finder headerAction(String label) => find.descendant(
      of: actionHeader,
      matching: find.widgetWithText(TextButton, label),
    );
    expect(
      find.text("Portable header actions use the current draft"),
      findsOneWidget,
    );
    expect(
      find.byTooltip("The presentation value is unavailable"),
      findsOneWidget,
    );
    expect(
      tester.getCenter(headerAction("Archive")).dx,
      greaterThan(tester.getCenter(headerAction("Duplicate")).dx),
    );
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(find.text("Details are hidden"), findsOneWidget);

    expect(find.text("General settings"), findsOneWidget);
    await tester.tap(find.text("Advanced"));
    await tester.pumpAndSettle();
    expect(find.text("Advanced settings"), findsOneWidget);
    await tester.tap(find.widgetWithText(ChoiceChip, "History"));
    await tester.pumpAndSettle();
    expect(find.text("Change history"), findsOneWidget);

    await tester.tap(
      find.descendant(
        of: find.byKey(const ValueKey("authored.scalar.interaction.add_item")),
        matching: find.widgetWithText(FilledButton, "Add item"),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text("Item 4"), findsOneWidget);
    expect(find.byTooltip("Remove item"), findsNWidgets(4));

    final firstItem = find.text("Item 1");
    final secondItem = find.text("Item 2");
    expect(
      tester.getTopLeft(firstItem).dy,
      lessThan(tester.getTopLeft(secondItem).dy),
    );
    final firstRow = find.descendant(
      of: find.byKey(const ValueKey("authored.scalar.interaction.list")),
      matching: find.byWidgetPredicate(
        (widget) =>
            widget is KeyedSubtree && widget.key == const ValueKey("one"),
      ),
    );
    expect(firstRow, findsOneWidget);
    await tester.tap(
      find.descendant(of: firstRow, matching: find.byTooltip("Reorder item")),
    );
    await tester.sendKeyDownEvent(LogicalKeyboardKey.altLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.altLeft);
    await tester.pumpAndSettle();
    expect(
      tester.getTopLeft(firstItem).dy,
      greaterThan(tester.getTopLeft(secondItem).dy),
    );

    expect(find.text("intro"), findsOneWidget);
    expect(find.text("Welcome"), findsOneWidget);
    expect(find.text("outro"), findsOneWidget);
    expect(find.text("Farewell"), findsOneWidget);
    await tester.tap(
      find.descendant(
        of: find.byKey(const ValueKey("authored.scalar.interaction.add_row")),
        matching: find.widgetWithText(FilledButton, "Add entry"),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text("chapter"), findsOneWidget);
    expect(find.text("Arrival"), findsOneWidget);
    expect(find.byTooltip("Remove row"), findsNWidgets(3));
    expect(find.text("No default presentation is available"), findsNothing);

    final rootRenderer = tester
        .widgetList<PortablePresentationNodeRenderer>(
          find.byType(PortablePresentationNodeRenderer),
        )
        .firstWhere(
          (renderer) => renderer.node.nodeId == "authored.interaction.gallery",
        );
    final host = rootRenderer.scope.host! as AuthoredPresentationHost;
    Iterable<skir.MapRow> rows() => switch (host.authored
        .resource(host.resource)!
        .authoredField("metadata")!
        .authoredPayload) {
      skir.DataValue_mapValueWrapper(:final value) => value.rows,
      _ => throw StateError("The interaction metadata is no longer a map"),
    };
    final added = rows().singleWhere(
      (row) => row.key == skir.DataValue.wrapStringValue("chapter"),
    );
    final rowOrder = rows().map((row) => row.id).toList();
    final otherRows = rows().where((row) => row.id != added.id).toList();
    skir.DataValue at(skir.PathSegment branch) => switch (host.authored.read(
      skir.ValueLocation(
        resource: host.resource,
        path: skir.ValuePath(
          segments: [
            skir.PathSegment.createField(name: "metadata"),
            skir.PathSegment.createItem(id: added.id),
            branch,
          ],
        ),
      ),
    )) {
      PortablePathValue(:final value) => value,
      _ => throw StateError("The inserted map branch is unavailable"),
    };
    Finder editor(String text) => find.byWidgetPredicate(
      (widget) => widget is TextFormField && widget.controller?.text == text,
    );

    await tester.enterText(editor("chapter"), "chapter_two");
    await tester.pumpAndSettle();
    expect(
      at(skir.PathSegment.mapKey),
      skir.DataValue.wrapStringValue("chapter_two"),
    );
    expect(
      at(skir.PathSegment.mapValue),
      skir.DataValue.wrapStringValue("Arrival"),
    );
    expect(rows().where((row) => row.id != added.id).toList(), otherRows);
    expect(rows().map((row) => row.id).toList(), rowOrder);
    await tester.enterText(editor("Arrival"), "Departure");
    await tester.pumpAndSettle();
    expect(
      at(skir.PathSegment.mapKey),
      skir.DataValue.wrapStringValue("chapter_two"),
    );
    expect(
      at(skir.PathSegment.mapValue),
      skir.DataValue.wrapStringValue("Departure"),
    );
    expect(rows().where((row) => row.id != added.id).toList(), otherRows);
    expect(rows().map((row) => row.id).toList(), rowOrder);

    await tester.tap(headerAction("Archive"));
    await tester.pumpAndSettle();
    expect(find.text("Archive quest?"), findsOneWidget);
    expect(
      find.text("The quest will no longer be available to players."),
      findsOneWidget,
    );
    await tester.tap(find.widgetWithText(FilledButton, "Archive"));
    await tester.pumpAndSettle();
    expect(find.text("Archived quest"), findsOneWidget);

    await tester.tap(
      find.descendant(of: actionHeader, matching: find.byTooltip("Collapse")),
    );
    await tester.pumpAndSettle();
    expect(find.text("Archived quest"), findsNothing);
    await tester.tap(
      find.descendant(of: actionHeader, matching: find.byTooltip("Expand")),
    );
    await tester.pumpAndSettle();
    expect(find.text("Archived quest"), findsOneWidget);

    final reload = find.descendant(
      of: find.byKey(const ValueKey("authored.scalar.interaction.reload")),
      matching: find.widgetWithText(FilledButton, "Reload from Realm"),
    );
    final status = find.byKey(const ValueKey("authored.action.status"));
    expect(host.capabilities.reload, isNull);
    expect(tester.widget<FilledButton>(reload).onPressed, isNotNull);
    expect(status, findsNothing);
    await tester.ensureVisible(reload);
    await tester.pumpAndSettle();
    await tester.tap(reload);
    await tester.pumpAndSettle();
    const reloadFailure =
        "The editor action did not complete: Bad state: Reload is unavailable";
    final reloadOutcome =
        rootRenderer
            .scope
            .operations
            .value
            .outcomes[PortableOperationKey.execute(
          skir.EditorAction.wrapRealm(skir.RealmEditorAction.createReload()),
        )];
    expect(reloadOutcome, isNotNull);
    expect(reloadOutcome!.pending, isFalse);
    expect(reloadOutcome.diagnostics.single.message, reloadFailure);
    expect(reloadOutcome.diagnostics.single.targets, isEmpty);
    expect(status, findsOneWidget);
    expect(tester.widget<Text>(status).data, reloadFailure);
    expect(tester.takeException(), isNull);
  });
}
