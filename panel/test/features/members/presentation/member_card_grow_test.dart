import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

final _ada = member("Ada", joinedAt: DateTime.utc(2024));

void main() {
  testWidgets("Esc on a grown card returns focus to it at row size", (
    tester,
  ) async {
    final panel = await tester.pumpPanel(
      [
        signedIn(ada, organization: acme),
        membership(members: [_ada]),
      ],
      at: PanelLocation.component(
        SizedBox(
          width: 400,
          child: MemberTabletCard(
            member: _ada,
            isSelected: false,
            onSelectionChanged: (_) {},
            onSelectAll: () {},
            onClearSelection: () {},
            hasSelection: false,
            onRemoveSelection: () async {},
          ),
        ),
      ),
    );
    final card = find.byType(MemberTabletCard);
    final rowHeight = tester.getSize(card).height;

    // The control holding keyboard focus, by its label.
    String? focused() => FocusManager.instance.primaryFocus?.context
        ?.findAncestorWidgetOfExactType<Button>()
        ?.label;
    Future<void> tabTo(String label) async {
      for (var tabs = 0; tabs < 10 && focused() != label; tabs++) {
        await panel.press(LogicalKeyboardKey.tab);
      }
      expect(focused(), label);
    }

    await tabTo("Show member details");
    await panel.press(LogicalKeyboardKey.space);
    expect(tester.getSize(card).height, greaterThan(rowHeight));
    await tabTo("Remove Member");
    await panel.press(LogicalKeyboardKey.escape);

    expect(tester.getSize(card).height, rowHeight);
    expect(focused(), "Show member details");
  });
}
