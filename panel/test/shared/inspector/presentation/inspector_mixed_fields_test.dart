import "package:flutter/services.dart";
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
    },
  );
  final lin = RecordSelectableIdentifier(
    id: "lin",
    fields: {
      ...kai.fields,
      RecordField.nickname: skir.DataValue.wrapStringValue("Lin"),
    },
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
    for (final field in RecordField.values.skip(1)) {
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
}
