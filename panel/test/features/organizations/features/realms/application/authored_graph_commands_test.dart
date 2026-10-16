import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

import "../../../../../support/authored_graph_fixture.dart";

void main() {
  test("node drop adds a reference from dragged source and toggles its exact occurrence", () async {
    final fixture = AuthoredGraphFixture();
    final commands = fixture.links;
    final first = commands.plan(fixture.group, fixture.target);
    final slot = first.slots.singleWhere((slot) => slot.label == "triggers");
    expect(slot.members.single.resource, fixture.source);
    expect(fixture.workspace.document.links, hasLength(2));
    final staged = await commands.apply(fixture.group, slot, {
      fixture.source: slot.members.single.choices.single,
    });
    expect(staged, isA<EditStaged>());
    final links = fixture.workspace.document.links.where(
      (link) => link.contract == fixture.triggerRelation,
    );
    expect(links, hasLength(1));
    expect(links.single.first, fixture.source);
    expect(links.single.second, fixture.target);
    final after = commands
        .plan(fixture.group, fixture.target)
        .slots
        .singleWhere((slot) => slot.label == "triggers");
    expect(after.members.single.choices.single.disconnect, isNotNull);
    expect(
      await commands.apply(fixture.group, after, {
        fixture.source: after.members.single.choices.single,
      }),
      isA<EditStaged>(),
    );
    expect(
      fixture.workspace.document.links.where(
        (link) => link.contract == fixture.triggerRelation,
      ),
      isEmpty,
    );
    expect(fixture.workspace.document.resource(fixture.source), isNotNull);
  });

  test("drop planning rejects self, another Realm, and stale membership", () {
    final fixture = AuthoredGraphFixture();
    expect(fixture.links.plan(fixture.group, fixture.source).slots, isEmpty);
    final other = fixture.group.copyWith(
      primary: fixture.group.primary.copyWith(
        realmId: skir.RecordId(
          table: "realm",
          key: skir.RecordIdKey.wrapString("another"),
        ),
      ),
      memberships: {
        fixture.group.primary.copyWith(
          realmId: skir.RecordId(
            table: "realm",
            key: skir.RecordIdKey.wrapString("another"),
          ),
        ): fixture.group.memberships.values.single,
      },
    );
    expect(
      fixture.links.plan(other, fixture.target).problem,
      contains("another Realm"),
    );
    final member = fixture.group.memberships.values.single;
    final stale = fixture.group.copyWith(
      memberships: {
        fixture.group.primary: skir.LinkOccurrence(
          id: member.id,
          source: member.source,
          target: skir.LinkTarget(
            resource: member.target.resource,
            opposite: editorRootPath.field("missing"),
          ),
        ),
      },
    );
    expect(fixture.links.plan(stale, fixture.target).slots, isEmpty);
  });

  test("stale chosen source value rejects a whole prepared drop", () async {
    final fixture = AuthoredGraphFixture();
    final slot = fixture.links
        .plan(fixture.group, fixture.target)
        .slots
        .singleWhere((slot) => slot.label == "triggers");
    final competing = await fixture.links.apply(fixture.group, slot, {
      fixture.source: slot.members.single.choices.single,
    });
    expect(competing, isA<EditStaged>());
    final previous = fixture.workspace.document;
    expect(
      await fixture.links.apply(fixture.group, slot, {
        fixture.source: slot.members.single.choices.single,
      }),
      isA<EditStageRejected>(),
    );
    expect(fixture.workspace.document, previous);
  });

  test("page transfer preserves identity and references and avoids destination obstacles", () async {
    final fixture = AuthoredGraphFixture();
    final linkSlot = fixture.links
        .plan(fixture.group, fixture.target)
        .slots
        .singleWhere((slot) => slot.label == "triggers");
    await fixture.links.apply(fixture.group, linkSlot, {
      fixture.source: linkSlot.members.single.choices.single,
    });
    final references = fixture.workspace.document.links
        .where((link) => link.contract == fixture.triggerRelation)
        .toList();
    final moved = await fixture.pages.move(fixture.group, fixture.destination);
    expect(moved, isA<EditStaged>());
    final document = fixture.workspace.document;
    expect(
      document
          .resource(fixture.source)!
          .authoredField("page")!
          .authoredLink!
          .target
          .resource,
      fixture.destination,
    );
    expect(
      document.resource(fixture.page)!.authoredField("elements")!.authoredItems,
      isEmpty,
    );
    expect(
      document
          .resource(fixture.destination)!
          .authoredField("elements")!
          .authoredItems,
      hasLength(2),
    );
    expect(
      document.links.where((link) => link.contract == fixture.triggerRelation),
      references,
    );
    expect(
      document
          .resource(fixture.source)!
          .graphGridRect!
          .overlaps(document.resource(fixture.target)!.graphGridRect!, gap: 1),
      isFalse,
    );
    expect(
      fixture.pages.plan(fixture.group, fixture.destination),
      contains("changed pages"),
    );
  });

  test("same page transfer is unchanged and mutation access is checked at invocation", () async {
    final fixture = AuthoredGraphFixture();
    expect(
      await fixture.pages.move(fixture.group, fixture.page),
      isA<EditUnchanged>(),
    );
    fixture.mutable = false;
    expect(
      await fixture.pages.move(fixture.group, fixture.destination),
      isA<EditStageRejected>(),
    );
    expect(fixture.links.plan(fixture.group, fixture.target).slots, isEmpty);
  });

  test("group transfer keeps relative geometry and stages one group before persistence", () async {
    final fixture = AuthoredGraphFixture(secondSource: true);
    final before = fixture.workspace.document
        .resource(fixture.source)!
        .graphGridRect!;
    final secondBefore = fixture.workspace.document
        .resource(fixture.second)!
        .graphGridRect!;
    expect(
      await fixture.pages.move(fixture.group, fixture.destination),
      isA<EditStaged>(),
    );
    final after = fixture.workspace.document
        .resource(fixture.source)!
        .graphGridRect!;
    final secondAfter = fixture.workspace.document
        .resource(fixture.second)!
        .graphGridRect!;
    expect(secondAfter.x - after.x, secondBefore.x - before.x);
    expect(secondAfter.y - after.y, secondBefore.y - before.y);
    expect(
      fixture.workspace.state.groups.values.where(
        (group) => group.operationCount > 0,
      ),
      hasLength(1),
    );
    expect(fixture.transport.requests, isEmpty);
    expect(
      fixture.workspace.document
          .resource(fixture.page)!
          .authoredField("elements")!
          .authoredItems,
      isEmpty,
    );
  });

  test(
    "mixed collection effects require confirmation and never partially apply",
    () async {
      final fixture = AuthoredGraphFixture(secondSource: true);
      final one = fixture.group.copyWith(
        memberships: {
          fixture.group.primary:
              fixture.group.memberships[fixture.group.primary]!,
        },
      );
      final first = fixture.links
          .plan(one, fixture.target)
          .slots
          .singleWhere((slot) => slot.label == "triggers");
      await fixture.links.apply(one, first, {
        fixture.source: first.members.single.choices.single,
      });
      final mixed = fixture.links
          .plan(fixture.group, fixture.target)
          .slots
          .singleWhere((slot) => slot.label == "triggers");
      final choices = {
        for (final member in mixed.members)
          member.resource: member.choices.single,
      };
      final previous = fixture.workspace.document;
      expect(
        await fixture.links.apply(fixture.group, mixed, choices),
        isA<EditStageRejected>(),
      );
      expect(fixture.workspace.document, previous);
      expect(
        await fixture.links.apply(
          fixture.group,
          mixed,
          choices,
          confirmedMixed: true,
        ),
        isA<EditStaged>(),
      );
      final references = fixture.workspace.document.links.where(
        (link) => link.contract == fixture.triggerRelation,
      );
      expect(references, hasLength(1));
      expect(references.single.first, fixture.second);
    },
  );

  test("group hover requires one common semantic field", () {
    final fixture = AuthoredGraphFixture(secondSource: true);
    final original = fixture.workspace.document;
    final entries = Map<skir.ResourceId, skir.AuthoringResource>.of(
      original.entries,
    );
    for (final pair in [
      (fixture.source, "incoming"),
      (fixture.second, "triggers"),
    ]) {
      final entry = entries[pair.$1]!;
      final changed = entry.content.toMutable()
        ..fields = entry.content.fields
            .where((field) => field.name != pair.$2)
            .toList();
      entries[pair.$1] = (entry.toMutable()..content = changed.toFrozen())
          .toFrozen();
    }
    final document = original.copyWith(entries: entries);
    final plan = document.planResourceLinks(
      group: fixture.group,
      target: fixture.target,
      scope: fixture.scope,
    );
    expect(plan.slots, isEmpty);
    expect(plan.problem, contains("no common compatible reference"));
  });

  test(
    "duplicate collection references require choosing the exact removal",
    () async {
      final fixture = AuthoredGraphFixture();
      final first = fixture.links
          .plan(fixture.group, fixture.target)
          .slots
          .singleWhere((slot) => slot.label == "triggers");
      await fixture.links.apply(fixture.group, first, {
        fixture.source: first.members.single.choices.single,
      });
      fixture.workspace
          .edit(
            label: "Add a distinct reference occurrence",
            apply: (edit) {
              final at = skir.ValueLocation(
                resource: fixture.source,
                path: skir.ValuePath(
                  segments: [
                    skir.PathSegment.createField(name: "triggers"),
                    skir.PathSegment.createItem(
                      id: skir.ItemId(value: "another-occurrence"),
                    ),
                  ],
                ),
              );
              final plan = (edit.linkPlans(
                catalog: fixture.workspace.document.catalog,
                source: at,
              ) as PortableLinkPlanReady).plans.single;
              final target = plan.targets.singleWhere(
                (target) => target.resource == fixture.target,
              );
              edit.applyResolvedReference(
                edit.resolveReference(
                  catalog: fixture.workspace.document.catalog,
                  plan: plan,
                  target: target,
                ),
              );
            },
          )
          .requireAccepted();
      final toggles = fixture.links
          .plan(fixture.group, fixture.target)
          .slots
          .singleWhere((slot) => slot.label == "triggers");
      expect(toggles.members.single.choices, hasLength(2));
      expect(
        toggles.members.single.choices.map((choice) => choice.key).toSet(),
        hasLength(2),
      );
      final chosen = toggles.members.single.choices.first;
      expect(
        await fixture.links.apply(fixture.group, toggles, {
          fixture.source: chosen,
        }),
        isA<EditStaged>(),
      );
      final remaining = fixture.workspace.document
          .resource(fixture.source)!
          .authoredField("triggers")!
          .authoredItems!
          .toList();
      expect(remaining, hasLength(1));
      expect(
        remaining.single.id,
        isNot(
          (chosen.disconnect!.id.location.path.segments.last
                  as skir.PathSegment_itemWrapper)
              .value
              .id,
        ),
      );
    },
  );

  test("lost interaction access discards all prepared group effects", () async {
    final fixture = AuthoredGraphFixture(secondSource: true);
    final before = fixture.workspace.document;
    var calls = 0;
    final result = await fixture.pages.move(
      fixture.group,
      fixture.destination,
      isCurrent: () => ++calls == 1,
    );
    expect(result, isA<EditStageRejected>());
    expect(fixture.workspace.document, before);
  });

  test(
    "group counterpart choices cannot overwrite one scalar inverse twice",
    () async {
      final fixture = AuthoredGraphFixture(
        secondSource: true,
        scalarIncoming: true,
        ambiguousIncoming: true,
      );
      final plan = fixture.links.plan(fixture.group, fixture.target);
      final slot = plan.slots.singleWhere((slot) => slot.label == "triggers");
      expect(
        slot.members.every((member) => member.choices.length == 2),
        isTrue,
      );
      final duplicate = {
        for (final member in slot.members)
          member.resource: member.choices.firstWhere(
            (choice) => choice.label.endsWith("to incoming"),
          ),
      };
      final previous = fixture.workspace.document;
      expect(
        await fixture.links.apply(fixture.group, slot, duplicate),
        isA<EditStageRejected>(),
      );
      expect(fixture.workspace.document, previous);
      final unique = {
        slot.members.first.resource: slot.members.first.choices.first,
        slot.members.last.resource: slot.members.last.choices.last,
      };
      expect(
        await fixture.links.apply(fixture.group, slot, unique),
        isA<EditStaged>(),
      );
      expect(
        fixture.workspace.document.links.where(
          (link) => link.contract == fixture.triggerRelation,
        ),
        hasLength(2),
      );
    },
  );

  test("group hover rejects a sole shared scalar counterpart", () {
    final fixture = AuthoredGraphFixture(
      secondSource: true,
      scalarIncoming: true,
    );
    expect(
      fixture.links
          .plan(fixture.group, fixture.target)
          .slots
          .where((slot) => slot.label == "triggers"),
      isEmpty,
    );
  });

  test("page move exposes exact counterpart choices and accepts selected collection atomically", () async {
    final fixture = AuthoredGraphFixture(
      secondSource: true,
      ambiguousPages: true,
    );
    final planned = fixture.pages.planChoices(
      fixture.group,
      fixture.destination,
    );
    expect(planned.problem, isNull);
    final members = planned.slots.single.members;
    expect(members.every((member) => member.choices.length == 2), isTrue);
    expect(
      await fixture.pages.move(fixture.group, fixture.destination),
      isA<EditStageRejected>(),
    );
    final choices = {
      for (final member in members)
        member.resource: member.choices.singleWhere(
          (choice) => choice.label.endsWith("into elementsOther"),
        ),
    };
    expect(
      await fixture.pages.move(
        fixture.group,
        fixture.destination,
        choices: choices,
      ),
      isA<EditStaged>(),
    );
    expect(
      fixture.workspace.document
          .resource(fixture.destination)!
          .authoredField("elementsOther")!
          .authoredItems,
      hasLength(2),
    );
    expect(
      fixture.workspace.document
          .resource(fixture.destination)!
          .authoredField("elements")!
          .authoredItems,
      hasLength(1),
    );
  });

  test("move rejects absent or incompatible destinations and revoked source access", () async {
    final fixture = AuthoredGraphFixture();
    expect(
      fixture.pages.plan(fixture.group, skir.ResourceId(value: "absent")),
      contains("unavailable"),
    );
    expect(
      fixture.pages.plan(fixture.group, fixture.target),
      contains("does not accept"),
    );
    final denied = fixture.group.copyWith(sourceCanMutate: () => false);
    expect(fixture.links.plan(denied, fixture.target).slots, isEmpty);
    expect(
      await fixture.pages.move(denied, fixture.destination),
      isA<EditStageRejected>(),
    );
    expect(await fixture.pages.disconnect(denied), isA<EditStageRejected>());
  });

  testWidgets(
    "staged page transfer remains visible through blocked and rejected persistence",
    (tester) async {
      final fixture = AuthoredGraphFixture();
      final result = await fixture.pages.move(
        fixture.group,
        fixture.destination,
      );
      expect(result, isA<EditStaged>());
      expect(
        fixture.workspace.document
            .resource(fixture.source)!
            .authoredField("page")!
            .authoredLink!
            .target
            .resource,
        fixture.destination,
      );
      await tester.pump(const Duration(milliseconds: 250));
      await tester.pump();
      expect(fixture.transport.requests, hasLength(1));
      expect(
        fixture.workspace.document
            .resource(fixture.source)!
            .authoredField("page")!
            .authoredLink!
            .target
            .resource,
        fixture.destination,
      );
      fixture.transport.reject(0, skir.CommitResult.wrapRejected(const []));
      await tester.pumpAndSettle();
      expect(
        fixture.workspace.state.groups.values.single.phase,
        isA<EditGroupRejected>(),
      );
      expect(
        fixture.workspace.document
            .resource(fixture.source)!
            .authoredField("page")!
            .authoredLink!
            .target
            .resource,
        fixture.destination,
      );
      expect(fixture.workspace.hasPendingWork, isTrue);
    },
  );

  test(
    "an occupied scalar inverse is not offered for another source",
    () async {
      final fixture = AuthoredGraphFixture(
        secondSource: true,
        scalarIncoming: true,
      );
      final firstGroup = fixture.group.copyWith(
        memberships: {
          fixture.group.primary:
              fixture.group.memberships[fixture.group.primary]!,
        },
      );
      final first = fixture.links
          .plan(firstGroup, fixture.target)
          .slots
          .singleWhere((slot) => slot.label == "triggers");
      expect(
        await fixture.links.apply(firstGroup, first, {
          fixture.source: first.members.single.choices.single,
        }),
        isA<EditStaged>(),
      );
      final secondIdentifier = AuthoringResourceIdentifier.inScope(
        fixture.scope,
        fixture.second,
      );
      final secondGroup = fixture.group.copyWith(
        primary: secondIdentifier,
        memberships: {
          secondIdentifier: fixture.group.memberships[secondIdentifier]!,
        },
      );
      expect(
        fixture.links
            .plan(secondGroup, fixture.target)
            .slots
            .where((slot) => slot.label == "triggers"),
        isEmpty,
      );
      expect(
        fixture.workspace.document
            .resource(fixture.target)!
            .authoredField("incoming")!
            .authoredLink!
            .target
            .resource,
        fixture.source,
      );
    },
  );

  test("page chooser retains its observation and rejects intervening destination geometry", () async {
    final fixture = AuthoredGraphFixture(ambiguousPages: true);
    final slot = fixture.pages
        .planChoices(fixture.group, fixture.destination)
        .slots
        .single;
    final choices = {fixture.source: slot.members.single.choices.last};
    fixture.workspace
        .edit(
          label: "Move destination node",
          apply: (edit) {
            edit.setPayload(
              skir.ValueLocation(
                resource: fixture.target,
                path: elementPlacementPath.field("x"),
              ),
              skir.DataValue.wrapInteger("9"),
            );
          },
        )
        .requireAccepted();
    final previous = fixture.workspace.document;
    expect(
      await fixture.pages.move(
        fixture.group,
        fixture.destination,
        plannedSlot: slot,
        choices: choices,
      ),
      isA<EditStageRejected>(),
    );
    expect(fixture.workspace.document, previous);
  });
}
