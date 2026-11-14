import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  testWidgets(
    "selecting a resource row fades its fill in with ink, not at once",
    (tester) async {
      Widget row({required bool selected}) => SizedBox(
        width: 260,
        child: PresentationInteractionScope(
          value: PresentationInteraction(selected: selected),
          child: ResourceItemChrome(
            appearance: skir.ResourceAppearance(
              label: "Realm",
              accent: Colors.blue.toSkirColor(),
              icon: skir.Icon.wrapIconify("material-symbols:book"),
            ),
          ),
        ),
      );

      final panel = await tester.showComponent(row(selected: false));
      final before = await panel.fillAt(find.text("Realm"));

      await tester.showComponent(row(selected: true), settle: false);
      await tester.pump(tester.settleTimeOf(MotionToken.ink) ~/ 3);
      final during = await panel.fillAt(find.text("Realm"));

      await panel.settle();
      final after = await panel.fillAt(find.text("Realm"));
      expect(during, isNot(before));
      expect(during, isNot(after));
    },
  );

  testWidgets("hovering a resource row raises it and leaves its fill alone", (
    tester,
  ) async {
    Widget row({required bool hovered}) => SizedBox(
      width: 260,
      child: PresentationInteractionScope(
        value: PresentationInteraction(hovered: hovered),
        child: ResourceItemChrome(
          appearance: skir.ResourceAppearance(
            label: "Realm",
            accent: Colors.blue.toSkirColor(),
            icon: skir.Icon.wrapIconify("material-symbols:book"),
          ),
        ),
      ),
    );

    final panel = await tester.showComponent(row(hovered: false));
    final before = await panel.fillAt(find.text("Realm"));
    final top = tester.getRect(find.text("Realm")).top;

    await tester.showComponent(row(hovered: true));

    expect(tester.getRect(find.text("Realm")).top, lessThan(top));
    expect(await panel.fillAt(find.text("Realm")), before);
  });
}
