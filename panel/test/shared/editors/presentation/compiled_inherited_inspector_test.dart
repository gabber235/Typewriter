import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

final compiledSdkInheritedInspectorValue = skir.DataValue.serializer.fromBytes(
  base64Decode(
    "c2tpcvgO+Pf4/PjzB2ZpeHR1cmXzEEluc3BlY3Rvck1lc3NhZ2UB+A33+gX48wdtZXNzYWdl+AjzDEhlbGxvIHBsYXllcvjzBG5h"
    "bWX4CPMHV2VsY29tZfjzBW5vdGVz+AjzC1NoYXJlZCBub3Rl+PMFb3RoZXL4CPMIQ29vbGRvd2748wlwbGFjZW1lbnT4Dvj3+Pv3"
    "8yA1NzhmMGQ0MmJjOTY0YjFmYWI1MmM4ZGU1ZTAyZjljNQH4Dff6BPjzBmhlaWdodPgF8wEx+PMFd2lkdGj4BfMBMfjzAXj4BfMB"
    "MPjzAXn4BfMBMA==",
  ),
);

void main() {
  final coordinates = [
    for (final field in ["x", "y", "width", "height"])
      compiledSdkPlacementValue
          .authoredField(field)!
          .authoredInteger!
          .toString(),
  ];

  testWidgets(
    "compiled inherited fields render with their parts and placement in order",
    (tester) async {
      final inspector = ValueInspector(
        compiledSdkInheritedInspectorValue,
        catalog: CheckedEditorCatalog(compiledSdkControlCatalog),
      );

      final panel = await inspector.show(tester);

      expect(visibleFieldValues(), [
        "Welcome",
        "Hello player",
        "Shared note",
        "Cooldown",
        ...coordinates,
      ]);
      final fields = visibleTextFields();
      final heading = tester.getRect(panel.labeled("Entry heading"));
      final details = tester.getRect(panel.labeled("Shared details"));
      expect(heading.top, greaterThan(fields[0].screenRect.top));
      expect(heading.top, lessThan(fields[1].screenRect.top));
      expect(details.top, greaterThan(fields[1].screenRect.top));
      expect(details.top, lessThan(fields[2].screenRect.top));
    },
  );

  testWidgets("an edit to an inherited field writes its trimmed value", (
    tester,
  ) async {
    final inspector = ValueInspector(
      compiledSdkInheritedInspectorValue,
      catalog: CheckedEditorCatalog(compiledSdkControlCatalog),
    );
    final panel = await inspector.show(tester);

    await panel.field("name").enter("  Renamed  ");

    expect(inspector.value.authoredField("name")?.authoredString, "Renamed");
  });

  testWidgets("an edit to a shared part writes the part's field", (
    tester,
  ) async {
    final inspector = ValueInspector(
      compiledSdkInheritedInspectorValue,
      catalog: CheckedEditorCatalog(compiledSdkControlCatalog),
    );
    final panel = await inspector.show(tester);

    await panel.field("Notes").submit("Changed note");

    expect(
      inspector.value.authoredField("notes")?.authoredString,
      "Changed note",
    );
  });

  testWidgets("an edit to a placement coordinate writes the coordinate", (
    tester,
  ) async {
    final inspector = ValueInspector(
      compiledSdkInheritedInspectorValue,
      catalog: CheckedEditorCatalog(compiledSdkControlCatalog),
    );
    final panel = await inspector.show(tester);

    await panel.field("X coordinate").enter("37");

    expect(
      inspector.value
          .authoredField("placement")
          ?.authoredField("x")
          ?.authoredInteger,
      BigInt.from(37),
    );
  });

  testWidgets("edited values and layout survive a serialized reload", (
    tester,
  ) async {
    final edited = ValueInspector(
      compiledSdkInheritedInspectorValue,
      catalog: CheckedEditorCatalog(compiledSdkControlCatalog),
    );
    final panel = await edited.show(tester);
    await panel.field("name").enter("Renamed");
    await panel.field("Notes").submit("Changed note");
    await panel.field("X coordinate").enter("37");
    await tester.pumpWidget(const SizedBox.shrink());

    final reloaded = ValueInspector(
      skir.DataValue.serializer.fromBytes(
        skir.DataValue.serializer.toBytes(edited.value),
      ),
      catalog: CheckedEditorCatalog(
        skir.EditorCatalog.serializer.fromBytes(
          skir.EditorCatalog.serializer.toBytes(compiledSdkControlCatalog),
        ),
      ),
    );
    final reopened = await reloaded.show(tester);

    expect(visibleFieldValues(), [
      "Renamed",
      "Hello player",
      "Changed note",
      "Cooldown",
      "37",
      ...coordinates.skip(1),
    ]);
    final fields = visibleTextFields();
    final heading = tester.getRect(reopened.labeled("Entry heading"));
    final details = tester.getRect(reopened.labeled("Shared details"));
    expect(heading.top, greaterThan(fields[0].screenRect.top));
    expect(heading.top, lessThan(fields[1].screenRect.top));
    expect(details.top, greaterThan(fields[1].screenRect.top));
    expect(details.top, lessThan(fields[2].screenRect.top));
  });
}
