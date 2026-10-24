import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:widgetbook_workspace/stories/shared/editors/presentation/configured_actions.stories.dart";

void main() {
  testWidgets(
    "configured action keeps keyboard activation and native defaults",
    (tester) async {
      await tester.pumpWidget(configuredActionsStory());
      await tester.pumpAndSettle();
      expect(find.byType(OutlinedButton), findsOneWidget);
      final reset = find.text("Reset");
      Focus.of(tester.element(reset)).requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(find.text("Executed 1 actions"), findsOneWidget);
      final defaultButton = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, "Native default"),
      );
      expect(defaultButton.style?.foregroundColor, isNull);
      expect(defaultButton.style?.backgroundColor, isNull);
      final icons = tester.widgetList<Icones>(find.byType(Icones));
      expect(icons.any((icon) => icon.icon == "mdi:content-save"), isTrue);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    "configured menu exposes reasons and executes an enabled keyboard action",
    (tester) async {
      await tester.pumpWidget(configuredActionsStory());
      await tester.pumpAndSettle();
      final trigger = find.text("Options");
      Focus.of(tester.element(trigger)).requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(find.text("Apply this action"), findsOneWidget);
      expect(find.text("A selection is required"), findsOneWidget);
      final blocked = tester.widget<MenuItemButton>(
        find.widgetWithText(MenuItemButton, "Unavailable"),
      );
      expect(blocked.onPressed, isNull);
      final menu = tester.widget<MenuAnchor>(find.byType(MenuAnchor));
      expect(menu.style?.minimumSize?.resolve({})?.width, 240);
      expect(menu.style?.maximumSize?.resolve({})?.width, 300);
      Focus.of(tester.element(find.text("Apply"))).requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(find.text("Executed 1 actions"), findsOneWidget);
      expect(find.text("Apply this action"), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets("read only action controls retain inspection without execution", (
    tester,
  ) async {
    await tester.pumpWidget(configuredActionsStory(readOnly: true));
    await tester.pumpAndSettle();
    expect(
      tester.widget<OutlinedButton>(find.byType(OutlinedButton)).onPressed,
      isNull,
    );
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
    await tester.tap(find.text("Reset"));
    await tester.pumpAndSettle();
    expect(find.text("Executed 0 actions"), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    "projection paint reaches the graph and timeline with native policies retained",
    (tester) async {
      await tester.pumpWidget(
        configuredActionsStory(projections: true, width: 700),
      );
      await tester.pumpAndSettle();
      final graph = tester.widget<Graph>(find.byType(Graph));
      expect(graph.data.cellSize, 60);
      expect(graph.data.edges.single.color, const Color(0xff7354bf));
      expect(graph.data.elements.map((element) => element.x), [0, 5]);
      final timeline = tester.widget<Timeline>(find.byType(Timeline));
      final style = timeline.style!;
      expect(style.rulerHeight, 44);
      expect(style.laneHeight, 40);
      expect(style.laneGap, 12);
      expect(style.palette.gridMajor, const Color(0xff7354bf));
      final native = TimelineStyle.fallback(
        Theme.of(tester.element(find.byType(Timeline))),
      );
      expect(style.minPixelsPerFrame, native.minPixelsPerFrame);
      expect(style.gridTickSteps, native.gridTickSteps);
      expect(style.edgeHandleWidth, native.edgeHandleWidth);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets("configured displays consume paint and keyboard navigation", (
    tester,
  ) async {
    await tester.pumpWidget(configuredActionsStory(displays: true));
    await tester.pumpAndSettle();
    final chip = tester.widget<Chip>(
      find.widgetWithText(Chip, "Configured chip"),
    );
    expect(chip.padding, const EdgeInsets.all(10));
    expect(chip.backgroundColor, const Color(0xffe5dcfa));
    expect(chip.side, BorderSide.none);
    final progress = tester.widget<LinearProgressIndicator>(
      find.byType(LinearProgressIndicator),
    );
    expect(progress.value, 0.3);
    expect(progress.minHeight, 12);
    expect(progress.color, const Color(0xff7354bf));
    final divider = tester.widget<Divider>(find.byType(Divider));
    expect(divider.thickness, 3);
    expect(divider.indent, 4);
    expect(divider.endIndent, 8);
    expect(find.text("Summary content"), findsOneWidget);
    final details = find.text("Details");
    Focus.of(tester.element(details)).requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.text("Detail content"), findsOneWidget);
    expect(find.text("Summary content"), findsNothing);
    final help = find.text("Focus for help");
    Focus.of(tester.element(help)).requestFocus();
    await tester.pumpAndSettle();
    expect(find.text("Configured help"), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
