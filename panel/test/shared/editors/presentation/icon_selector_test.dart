import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_test/flutter_test.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";

import "../../../support/test_utils.dart";

void main() {
  testWidgets("opens from the keyboard and limits the result viewport", (
    tester,
  ) async {
    await _pumpIconApp(tester, child: const _IconHarness());

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), "");
    await tester.pumpAndSettle();

    expect(find.text("Search icons"), findsOneWidget);
    expect(find.bySemanticsLabel("7 icon results"), findsOneWidget);
    final viewport = tester.getSize(find.byType(CustomScrollView));
    expect(viewport.height, 240);
  });

  testWidgets("arrow navigation previews and Escape restores the value", (
    tester,
  ) async {
    await _pumpIconApp(tester, child: const _IconHarness());
    await _openWithKeyboard(tester);
    await tester.enterText(find.byType(TextField), "");
    await tester.pumpAndSettle();

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    expect(_value(tester), "mdi:home");

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    expect(_value(tester), "mdi:account");

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(_value(tester), "mdi:star");
    expect(find.text("Search icons"), findsNothing);
  });

  testWidgets("submission selects the active search result", (tester) async {
    await _pumpIconApp(tester, child: const _IconHarness());
    await _openWithKeyboard(tester);

    await tester.enterText(find.byType(TextField), "account");
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(QueryBar)),
    );
    expect(container.read(searchProvider)?.currentPreview?.id, "mdi:account");
    tester.widget<QueryBar>(find.byType(QueryBar)).onSubmitted!("lucide:wand");
    await tester.pumpAndSettle();

    expect(_value(tester), "lucide:wand");
    expect(find.byKey(const ValueKey("icon_selector_query")), findsNothing);
    expect(find.byKey(const ValueKey("icon_selector_query")), findsNothing);
  });

  testWidgets("Tab accepts a direct identifier and exits edit mode", (
    tester,
  ) async {
    await _pumpIconApp(
      tester,
      child: FocusTraversalGroup(
        child: const Row(
          children: [
            Expanded(child: _IconHarness()),
            Expanded(child: TextField(key: ValueKey("next_field"))),
          ],
        ),
      ),
    );
    await _openWithKeyboard(tester);
    await tester.enterText(find.byType(TextField).first, "lucide:wand");

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();

    expect(_value(tester), "lucide:wand");
    expect(find.byKey(const ValueKey("icon_selector_query")), findsNothing);
    expect(FocusManager.instance.primaryFocus?.debugLabel, "Icon selector");
  });

  testWidgets("read only and disabled fields do not enter edit mode", (
    tester,
  ) async {
    await _pumpIconApp(tester, child: const _IconHarness(readOnly: true));
    await tester.tap(find.byType(TextField));
    await tester.pumpAndSettle();
    expect(find.text("Search icons"), findsNothing);

    await _pumpIconApp(tester, child: const _IconHarness(enabled: false));
    await tester.tap(find.byType(TextField));
    await tester.pumpAndSettle();
    expect(find.text("Search icons"), findsNothing);
  });
}

Future<void> _pumpIconApp(WidgetTester tester, {required Widget child}) {
  return tester.pumpTestApp(
    child: child,
    overrides: [
      iconSelectorIconBuilderProvider.overrideWithValue(
        (context, icon, size, color) => SizedBox.square(dimension: size),
      ),
    ],
  );
}

Future<void> _openWithKeyboard(WidgetTester tester) async {
  await tester.sendKeyEvent(LogicalKeyboardKey.tab);
  await tester.sendKeyEvent(LogicalKeyboardKey.enter);
  await tester.pumpAndSettle();
}

String _value(WidgetTester tester) =>
    tester.state<_IconHarnessState>(find.byType(_IconHarness)).value;

class _IconHarness extends StatefulWidget {
  const _IconHarness({this.enabled = true, this.readOnly = false});

  final bool enabled;
  final bool readOnly;

  @override
  State<_IconHarness> createState() => _IconHarnessState();
}

class _IconHarnessState extends State<_IconHarness> {
  String value = "mdi:star";

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 420,
    child: IconSelector(
      value: value,
      enabled: widget.enabled,
      readOnly: widget.readOnly,
      onChanged: (next) => setState(() => value = next),
      sourceBuilder: (ref, onSelected) {
        return MockSearchSource(
          nodes: _results,
          actions: {SelectIconSearchAction: SelectIconSearchAction(onSelected)},
        );
      },
    ),
  );
}

final _results =
    [
          "mdi:home",
          "mdi:account",
          "mdi:star",
          "lucide:wand",
          "tabler:map",
          "ph:heart",
          "carbon:settings",
        ]
        .map((identifier) {
          final parts = identifier.split(":");
          return SearchNode.result(
            result: SearchResult(
              id: identifier,
              type: iconSearchResultType,
              payload: IconSearchResultPayload(
                identifier: identifier,
                name: parts.last,
                collection: parts.first,
              ),
              actions: const [SelectIconSearchAction],
              title: parts.last,
              subtitle: parts.first,
            ),
          );
        })
        .toList(growable: false);
