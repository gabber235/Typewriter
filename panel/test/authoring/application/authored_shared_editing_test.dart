import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  final first = sharedNoteFirst;
  final second = sharedNoteSecond;
  final title = editorRootPath.field("title");

  testWidgets("selected resources show what they agree on and leave the rest "
      "unfilled", (tester) async {
    final editing = SharedAuthoredEditing(
      sharedNotes(),
      resources: [first, second],
    );

    final shared = editing.shared;
    expect(
      shared.value.editorValueAt(editorRootPath.field("body")),
      textValue("Shared"),
    );
    expect(shared.value.editorValueAt(title), skir.DataValue.unfilled);
    expect(shared.itemValues.map((item) => item.editorValueAt(title)), [
      textValue("Morning"),
      textValue("Evening"),
    ]);
  });

  testWidgets("one resource alone has no item values", (tester) async {
    final editing = SharedAuthoredEditing(sharedNotes(), resources: [first]);

    expect(editing.shared.value.editorValueAt(title), textValue("Morning"));
    expect(editing.shared.itemValues, isEmpty);
  });

  testWidgets("a change reaches every selected resource in one save", (
    tester,
  ) async {
    final editing = SharedAuthoredEditing(
      sharedNotes(),
      resources: [first, second],
    );

    final result = await editing.host.write(
      editing.at(["title"]),
      textValue("Noon"),
      context: editing.context,
    );
    expect(result, isA<PortablePresentationWriteApplied>());

    final saved = await editing.save(tester);
    expect(
      [
        for (final intent in saved.intents)
          if (intent case skir.EditIntent_setValueWrapper(:final value))
            (value.at.resource, value.value),
      ],
      unorderedEquals([
        (first, textValue("Noon")),
        (second, textValue("Noon")),
      ]),
    );
  });

  testWidgets("choosing a form prepares it once and gives it to every "
      "selected resource", (tester) async {
    final requests = <skir.ValuePreparationRequest>[];
    final editing = SharedAuthoredEditing(
      sharedNotes(),
      resources: [first, second],
      prepareValue: (request) async {
        requests.add(request);
        return preparedRecord(request, [
          skir.FieldValue(name: "amount", value: textValue("5")),
        ]);
      },
    );

    final result = await editing.host.execute(
      skir.EditorAction.wrapLocal(
        skir.LocalEditorAction.createChooseForm(
          target: editing.at(["reward"]),
          type: skir.TypeUse.wrapNamed(typeUse("Coins")),
        ),
      ),
      context: editing.context,
    );
    expect(result, isA<PortablePresentationWriteApplied>());

    expect(requests, hasLength(1));
    final document = editing.binding.document;
    for (final resource in [first, second]) {
      final reward = document.valueAt(valueAt(resource, ["reward"]));
      expect(
        switch (reward) {
          skir.DataValue_namedWrapper(:final value) => value.actualType,
          _ => null,
        },
        typeUse("Coins"),
        reason: "$resource",
      );
    }
    await editing.save(tester);
  });

  testWidgets("adding a row adds it to every selected resource", (
    tester,
  ) async {
    final document = authoredDoc(
      [
        for (final resource in [first, second])
          authoredRecord(resource, {
            "lines": skir.DataValue.createListValue(items: const []),
          }, type: typeUse("Script")),
      ],
      catalog: authoredCatalog([
        declaredCollection("Lines", skir.ScalarKind.text),
        declaredRecord("Script", fields: {"lines": "Lines"}),
      ]),
    ).document;
    final editing = SharedAuthoredEditing(document, resources: [first, second]);

    final result = await editing.host.addCollectionItem(
      editing.at(["lines"]),
      context: editing.context,
    );
    expect(result, isA<PortablePresentationWriteApplied>());

    for (final resource in [first, second]) {
      final lines = editing.binding.document.valueAt(
        valueAt(resource, ["lines"]),
      );
      expect(lines?.authoredItems, hasLength(1), reason: "$resource");
    }
  });

  group("links", () {
    testWidgets("only targets every selected resource may link are offered", (
      tester,
    ) async {
      final fixture = LinkChoicesFixture(directCollection: true);
      final editing = SharedAuthoredEditing(
        fixture.draft.toDocument(),
        resources: [fixture.source.resource, fixture.emptyTarget],
      );

      final plans = editing.host.planLink(
        editing.location(["source"]),
        context: editing.context,
      );

      final targets = (plans as PortableLinkPlanReady).plans.single.targets;
      final alone = (fixture.draft.linkPlans(
        catalog: fixture.catalog,
        source: fixture.source,
      ) as PortableLinkPlanReady).plans.single.targets;
      final elsewhere = (fixture.draft.linkPlans(
        catalog: fixture.catalog,
        source: valueAt(fixture.emptyTarget, ["source"]),
      ) as PortableLinkPlanReady).plans.single.targets;
      expect(
        targets.map((target) => target.resource).toSet(),
        alone
            .map((target) => target.resource)
            .toSet()
            .intersection(elsewhere.map((target) => target.resource).toSet()),
      );
      expect(
        targets.map((target) => target.resource),
        contains(fixture.existingTarget),
      );
    });

    testWidgets("a link one target may hold for one source only is not "
        "offered to several", (tester) async {
      final fixture = LinkChoicesFixture();
      final editing = SharedAuthoredEditing(
        fixture.draft.toDocument(),
        resources: [fixture.source.resource, fixture.emptyTarget],
      );

      final plans = editing.host.planLink(
        editing.location(["source"]),
        context: editing.context,
      );

      final targets = (plans as PortableLinkPlanReady).plans.single.targets;
      expect(targets, isNotEmpty);
      for (final target in targets) {
        expect(target.disabledReason, isNotNull, reason: "${target.resource}");
      }
    });

    testWidgets("choosing a target links every selected resource and its "
        "counterpart in one save", (tester) async {
      final fixture = LinkChoicesFixture(directCollection: true);
      final editing = SharedAuthoredEditing(
        fixture.draft.toDocument(),
        resources: [fixture.source.resource, fixture.emptyTarget],
      );
      final plan = (editing.host.planLink(
        editing.location(["source"]),
        context: editing.context,
      ) as PortableLinkPlanReady).plans.single;

      final result = await editing.host.connectLink(
        plan: plan,
        target: plan.targets.singleWhere(
          (target) => target.resource == fixture.existingTarget,
        ),
        counterpart: const PortableLinkCounterpartRequest.automatic(),
        context: editing.context,
      );
      expect(result, isA<PortablePresentationWriteApplied>());

      final saved = await editing.saved(tester);
      expect(editing.realm.saves, hasLength(1));
      expect([
        for (final link in saved.links)
          if (link.second == fixture.existingTarget) link.first,
      ], unorderedEquals([fixture.source.resource, fixture.emptyTarget]));
      final back = saved.valueAt(valueAt(fixture.existingTarget, ["wrapper"]));
      expect(
        back?.authoredItems?.map(
          (item) => item.value.authoredLink?.target.resource,
        ),
        unorderedEquals([fixture.source.resource, fixture.emptyTarget]),
      );
    });

    testWidgets("a link the selected resources hold differently shows mixed "
        "until one target links them all", (tester) async {
      final fixture = LinkChoicesFixture(directCollection: true);
      final draft = fixture.draft;
      draft.applyResolvedReference(
        draft.resolveSingleLink(
          fixture.existingTarget,
          "source",
          fixture.source.resource,
        ),
      );
      final chooser = await LinkChooserDriver.show(
        tester,
        draft.toDocument(),
        source: valueAt(fixture.existingTarget, ["source"]),
        editedWith: [fixture.emptyTarget],
      );
      expect(find.text(mixedValueLabel), findsOneWidget);

      await chooser.open(tooltip: "Change linked resource");
      await chooser.choose(
        fixture.source.resource,
        "Use the declared counterpart",
      );
      final saved = await chooser.save();

      expect([
        for (final link in saved.links)
          if (link.second == fixture.source.resource) link.first,
      ], unorderedEquals([fixture.existingTarget, fixture.emptyTarget]));
    });

    testWidgets("clearing a link clears it on every selected resource", (
      tester,
    ) async {
      final fixture = LinkChoicesFixture(directCollection: true);
      final draft = fixture.draft;
      for (final source in [fixture.source.resource, fixture.emptyTarget]) {
        draft.applyResolvedReference(
          draft.resolveSingleLink(source, "source", fixture.existingTarget),
        );
      }
      final editing = SharedAuthoredEditing(
        draft.toDocument(),
        resources: [fixture.source.resource, fixture.emptyTarget],
      );
      final location = editing.location(["source"]);
      final link = editing.binding.document.valueAt(location)!.authoredLink!;

      final result = editing.host.disconnectLink(
        skir.LinkOccurrence(
          id: skir.LinkOccurrenceId(
            endpoint: link.endpoint,
            location: location,
          ),
          source: location.resource,
          target: link.target,
        ),
        context: editing.context,
      );
      expect(result, isA<PortablePresentationWriteApplied>());

      final saved = await editing.saved(tester);
      expect(editing.realm.saves, hasLength(1));
      expect(
        saved.links.where((link) => link.second == fixture.existingTarget),
        isEmpty,
      );
    });
  });
}
