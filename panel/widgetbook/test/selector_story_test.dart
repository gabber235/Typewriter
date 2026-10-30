import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:widgetbook_workspace/stories/shared/selectables/presentation/selector.stories.dart";

import "support/stories.dart";

void main() {
  testWidgets("clicking a card selects it and replaces the selection", (
    tester,
  ) async {
    final panel = (await tester.pumpStory(selectableUseCase))!;
    final mayor = panel.item("Meet The Mayor");
    final market = panel.item("Village Market");

    await mayor.select();
    expect(mayor.isMarkedSelected, isTrue);

    await market.select();
    expect(market.isMarkedSelected, isTrue);
    expect(mayor.isMarkedSelected, isFalse);
  });

  testWidgets("the add button adds a selectable card", (tester) async {
    final panel = (await tester.pumpStory(selectableUseCase))!;

    await panel.tapOn(find.byIcon(Icons.add));

    expect(panel.shows("Page 4"), isTrue);
  });
}
