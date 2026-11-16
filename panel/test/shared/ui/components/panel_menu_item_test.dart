import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  testWidgets(
    "Enter and a tap both choose an item; a disabled item does neither",
    (tester) async {
      final chosen = <String>[];
      await tester.pumpPanel(
        const [],
        at: PanelLocation.component(
          Scaffold(
            body: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                PanelMenuItem(
                  label: "Rename",
                  onPressed: () => chosen.add("Rename"),
                ),
                PanelMenuItem(
                  label: "Delete",
                  enabled: false,
                  onPressed: () => chosen.add("Delete"),
                ),
              ],
            ),
          ),
        ),
      );

      await tester.tap(find.text("Rename"));
      await tester.tap(find.text("Delete"), warnIfMissed: false);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();

      expect(chosen, ["Rename", "Rename"]);
      // Keyboard focus never reaches the disabled item.
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      final focused = FocusManager.instance.primaryFocus!.context!;
      expect(
        focused.findAncestorWidgetOfExactType<PanelMenuItem>()?.label,
        "Rename",
      );
    },
  );
}
