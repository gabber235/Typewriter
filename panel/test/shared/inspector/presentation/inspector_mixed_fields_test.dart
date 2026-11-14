import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  // Two members who differ in every field, and a third who agrees with the
  // first on all but the nickname.
  final kai = RecordSelectableIdentifier(
    id: "kai",
    fields: {
      RecordField.role: skir.DataValue.wrapStringValue("admin"),
      RecordField.online: skir.DataValue.wrapBoolean(true),
      RecordField.joined: skir.DataValue.wrapTimestamp(DateTime.utc(2024, 5)),
      RecordField.nickname: skir.DataValue.wrapStringValue("Kai"),
      RecordField.color: skir.DataValue.wrapInteger("4283215696"),
      RecordField.level: skir.DataValue.wrapInteger("3"),
      RecordField.title: recordTitle("Captain"),
      RecordField.reward: recordCoins(5),
      RecordField.perks: recordPerks(["build", "fly"]),
      RecordField.tags: recordTags(["red", "fast"]),
      RecordField.scores: recordScores({"pvp": 3}),
      RecordField.volume: skir.DataValue.wrapInteger("30"),
    },
  );
  final mira = RecordSelectableIdentifier(
    id: "mira",
    fields: {
      RecordField.team: skir.DataValue.wrapStringValue("blue"),
      RecordField.muted: skir.DataValue.wrapBoolean(true),
      RecordField.level: skir.DataValue.wrapInteger("40"),
      RecordField.joined: skir.DataValue.wrapTimestamp(DateTime.utc(2024, 11)),
      RecordField.color: skir.DataValue.wrapInteger("4288423856"),
      RecordField.nickname: skir.DataValue.wrapStringValue("Mira"),
      RecordField.spawn: recordSpawn(world: "arena", height: 80),
      RecordField.reward: recordCoins(9),
      RecordField.perks: recordPerks(["fly"]),
      RecordField.tags: recordTags(["slow"]),
      RecordField.scores: recordScores({"pvp": 4}),
      RecordField.volume: skir.DataValue.wrapInteger("70"),
    },
  );
  final lin = RecordSelectableIdentifier(
    id: "lin",
    fields: {
      ...kai.fields,
      RecordField.nickname: skir.DataValue.wrapStringValue("Lin"),
    },
  );
  // A member who agrees with the first on all but how high they spawn.
  final sol = RecordSelectableIdentifier(
    id: "sol",
    fields: {
      ...kai.fields,
      RecordField.spawn: recordSpawn(world: "lobby", height: 80),
    },
  );
  // A member rewarded with a badge where the first gets coins.
  final nova = RecordSelectableIdentifier(
    id: "nova",
    fields: {...kai.fields, RecordField.reward: recordBadge("Star")},
  );

  testWidgets("every field the selected items hold differently shows mixed", (
    tester,
  ) async {
    final panel = await tester.pumpDesktopInspector();
    await panel.selectAll([kai, mira]);

    for (final field in RecordField.values) {
      expect(panel.inspector.showsMixed(field.label), isTrue, reason: "$field");
    }
  });

  testWidgets("fields the selected items share show their shared value", (
    tester,
  ) async {
    final panel = await tester.pumpDesktopInspector();
    await panel.selectAll([kai, lin]);

    expect(panel.inspector.showsMixed(RecordField.nickname.label), isTrue);
    // Equal lists and maps edit as they do for one item, which needs value
    // locations a combined editor does not have, so they show no field here.
    final listed = {RecordField.tags, RecordField.scores};
    for (final field in RecordField.values.skip(1).whereNot(listed.contains)) {
      expect(
        panel.inspector.showsMixed(field.label),
        isFalse,
        reason: "$field",
      );
    }
  });

  testWidgets("the keyboard turns a mixed switch on for every item", (
    tester,
  ) async {
    final panel = await tester.pumpDesktopInspector();
    await panel.selectAll([kai, mira]);

    await panel.inspector.tabToField(RecordField.online.label);
    await panel.press(LogicalKeyboardKey.space);

    await panel.eventually(() {
      for (final item in [kai, mira]) {
        expect(
          panel.heldBy(item, RecordField.online),
          skir.DataValue.wrapBoolean(true),
        );
      }
    });
    expect(panel.inspector.showsMixed(RecordField.online.label), isFalse);
  });

  testWidgets("a click on a mixed check turns it on for every item", (
    tester,
  ) async {
    final panel = await tester.pumpDesktopInspector();
    await panel.selectAll([kai, mira]);

    await panel.inspector.click(RecordField.muted.label);

    await panel.eventually(() {
      for (final item in [kai, mira]) {
        expect(
          panel.heldBy(item, RecordField.muted),
          skir.DataValue.wrapBoolean(true),
        );
      }
    });
    expect(panel.inspector.showsMixed(RecordField.muted.label), isFalse);
  });

  testWidgets("choosing a segment of a mixed choice sets it for every item", (
    tester,
  ) async {
    final panel = await tester.pumpDesktopInspector();
    await panel.selectAll([kai, mira]);

    await panel.tapOn(panel.inspector.labeled("Blue"));

    await panel.eventually(() {
      for (final item in [kai, mira]) {
        expect(
          panel.heldBy(item, RecordField.team),
          skir.DataValue.wrapStringValue("blue"),
        );
      }
    });
    expect(panel.inspector.showsMixed(RecordField.team.label), isFalse);
  });

  testWidgets("typing in a mixed number sets it for every item", (
    tester,
  ) async {
    final panel = await tester.pumpDesktopInspector();
    await panel.selectAll([kai, mira]);

    await panel.field(RecordField.level.label).type("30");

    await panel.eventually(() {
      for (final item in [kai, mira]) {
        expect(
          panel.heldBy(item, RecordField.level),
          skir.DataValue.wrapInteger("30"),
        );
      }
    });
  });

  testWidgets("a nested record shows only the inner fields that differ", (
    tester,
  ) async {
    final panel = await tester.pumpDesktopInspector();
    await panel.selectAll([kai, sol]);

    expect(panel.inspector.showsMixed("World"), isFalse);
    expect(panel.inspector.showsMixed("Height"), isTrue);

    await panel.inspector.reveal("Height");
    await panel.field("Height").type("70");

    await panel.eventually(() {
      for (final item in [kai, sol]) {
        expect(
          panel.heldBy(item, RecordField.spawn),
          recordSpawn(world: "lobby", height: 70),
        );
      }
    });
  });

  testWidgets("a click on a title some members lack sets it for all", (
    tester,
  ) async {
    final panel = await tester.pumpDesktopInspector();
    await panel.selectAll([kai, mira]);
    expect(panel.inspector.showsMixed(RecordField.title.label), isTrue);

    await panel.inspector.click(RecordField.title.label);

    await panel.eventually(() {
      for (final item in [kai, mira]) {
        expect(panel.heldBy(item, RecordField.title), recordTitle("Captain"));
      }
    });
  });

  testWidgets("the keyboard sets a title some members lack for all", (
    tester,
  ) async {
    final panel = await tester.pumpDesktopInspector();
    await panel.selectAll([mira, kai]);

    await panel.inspector.tabToField(RecordField.title.label);
    await panel.press(LogicalKeyboardKey.space);

    await panel.eventually(() {
      for (final item in [kai, mira]) {
        expect(panel.heldBy(item, RecordField.title), recordTitle("Captain"));
      }
    });
  });

  testWidgets("a reward of one kind shows its inner fields as mixed", (
    tester,
  ) async {
    final panel = await tester.pumpDesktopInspector();
    await panel.selectAll([kai, mira]);
    expect(panel.inspector.showsMixed("Amount"), isTrue);

    await panel.inspector.reveal("Amount");
    await panel.field("Amount").type("12");

    await panel.eventually(() {
      for (final item in [kai, mira]) {
        expect(panel.heldBy(item, RecordField.reward), recordCoins(12));
      }
    });
  });

  testWidgets("rewards of different kinds show the kind as mixed", (
    tester,
  ) async {
    final panel = await tester.pumpDesktopInspector();
    await panel.selectAll([kai, nova]);

    expect(panel.inspector.showsMixed(RecordField.reward.label), isTrue);
    expect(panel.inspector.texts, isNot(contains("Amount")));
  });

  testWidgets("a perk some members hold says how many and cycles on click", (
    tester,
  ) async {
    final panel = await tester.pumpDesktopInspector();
    await panel.selectAll([kai, mira]);
    expect(panel.inspector.showsMixed("build"), isTrue);
    expect(panel.inspector.showsMixed("fly"), isFalse);
    expect(panel.inspector.texts, contains("build\n1 of 2"));

    await panel.inspector.click("build");
    await panel.eventually(() {
      expect(
        panel.heldBy(kai, RecordField.perks),
        recordPerks(["build", "fly"]),
      );
      expect(
        panel.heldBy(mira, RecordField.perks),
        recordPerks(["fly", "build"]),
      );
    });

    await panel.inspector.click("build");
    await panel.eventually(() {
      for (final item in [kai, mira]) {
        expect(panel.heldBy(item, RecordField.perks), recordPerks(["fly"]));
      }
    });

    await panel.inspector.click("build");
    await panel.eventually(() {
      expect(
        panel.heldBy(kai, RecordField.perks),
        recordPerks(["build", "fly"]),
      );
      expect(panel.heldBy(mira, RecordField.perks), recordPerks(["fly"]));
    });
    expect(panel.inspector.showsMixed("build"), isTrue);
  });

  testWidgets("the keyboard checks a perk for every member", (tester) async {
    final panel = await tester.pumpDesktopInspector();
    await panel.selectAll([kai, mira]);

    await panel.inspector.tabToField("build");
    await panel.press(LogicalKeyboardKey.space);

    await panel.eventually(() {
      expect(
        panel.heldBy(mira, RecordField.perks),
        recordPerks(["fly", "build"]),
      );
    });
  });

  testWidgets("one member's perks are the same checkable choices", (
    tester,
  ) async {
    final panel = await tester.pumpDesktopInspector();
    await panel.selectAll([kai]);

    await panel.inspector.click("chat");

    await panel.eventually(() {
      expect(
        panel.heldBy(kai, RecordField.perks),
        recordPerks(["build", "fly", "chat"]),
      );
    });
  });

  testWidgets("lists and maps that differ say how many there are", (
    tester,
  ) async {
    final panel = await tester.pumpDesktopInspector();
    await panel.selectAll([kai, mira, lin]);

    expect(
      panel.inspector.texts,
      contains(contains("Mixed: 2 different lists")),
    );
    expect(
      panel.inspector.texts,
      contains(contains("Mixed: 2 different maps")),
    );
    expect(panel.inspector.showsMixed(RecordField.tags.label), isTrue);
    expect(panel.inspector.showsMixed(RecordField.scores.label), isTrue);
  });

  testWidgets("editing differing lists starts from the first member's", (
    tester,
  ) async {
    final panel = await tester.pumpDesktopInspector();
    await panel.selectAll([kai, mira]);

    await panel.inspector.click(RecordField.tags.label);

    await panel.eventually(() {
      for (final item in [kai, mira]) {
        expect(
          panel.heldBy(item, RecordField.tags),
          recordTags(["red", "fast"]),
        );
      }
    });
  });

  testWidgets("the keyboard edits differing maps from the first member's", (
    tester,
  ) async {
    final panel = await tester.pumpDesktopInspector();
    await panel.selectAll([mira, kai]);

    await panel.inspector.tabToField(RecordField.scores.label);
    await panel.press(LogicalKeyboardKey.enter);

    await panel.eventually(() {
      for (final item in [kai, mira]) {
        expect(
          panel.heldBy(item, RecordField.scores),
          recordScores({"pvp": 4}),
        );
      }
    });
  });

  testWidgets("a click on a mixed slider sets that value for every member", (
    tester,
  ) async {
    final panel = await tester.pumpDesktopInspector();
    await panel.selectAll([kai, mira]);
    expect(panel.inspector.showsMixed(RecordField.volume.label), isTrue);

    await panel.inspector.click(RecordField.volume.label);

    await panel.eventually(() {
      for (final item in [kai, mira]) {
        expect(
          panel.heldBy(item, RecordField.volume),
          skir.DataValue.wrapInteger("50"),
        );
      }
    });
  });

  testWidgets("an arrow key on a mixed slider steps from the first member's", (
    tester,
  ) async {
    final panel = await tester.pumpDesktopInspector();
    await panel.selectAll([kai, mira]);

    await panel.inspector.tabToField(RecordField.volume.label);
    await panel.press(LogicalKeyboardKey.arrowRight);

    await panel.eventually(() {
      for (final item in [kai, mira]) {
        expect(
          panel.heldBy(item, RecordField.volume),
          skir.DataValue.wrapInteger("31"),
        );
      }
    });
  });
}
