import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";

import "../../../../../../../../../../../support/test_utils.dart";

void main() {
  testWidgets("empty graph keeps the graph surface and floating add action", (
    tester,
  ) async {
    await tester.pumpTestApp(
      settle: false,
      overrides: _emptyPageOverrides(),
      child: const SizedBox(
        width: 800,
        height: 600,
        child: EntryGraph(pageId: "page"),
      ),
    );
    await tester.pump(const Duration(milliseconds: 150));
    await tester.pumpAndSettle();

    expect(find.byType(Graph), findsOneWidget);
    expect(find.byType(FloatingButton), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsOneWidget);
    expect(find.byType(EmptyScreen), findsNothing);

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(SearchModal<void>), findsOneWidget);

    Navigator.of(tester.element(find.byType(SearchModal<void>))).pop();
    await tester.pumpAndSettle();
  });

  testWidgets(
    "empty timeline keeps the timeline surface and floating add action",
    (tester) async {
      await tester.pumpTestApp(
        settle: false,
        overrides: _emptyPageOverrides(),
        child: const SizedBox(
          width: 800,
          height: 600,
          child: EntryTimelineEditor(pageId: "page"),
        ),
      );
      await tester.pump(const Duration(milliseconds: 150));
      await tester.pumpAndSettle();

      expect(find.byType(Timeline), findsOneWidget);
      expect(find.byType(FloatingButton), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.byType(EmptyScreen), findsNothing);
    },
  );
}

final _organizationId = recordId("organization:test");
final _realmId = recordId("service:test");

List<Override> _emptyPageOverrides() => [
  organizationIdProvider.overrideWithValue(_organizationId),
  realmIdProvider.overrideWithValue(_realmId),
  ...pageElementsProviderOverrides(state: DisplayState.noItems),
  decodedRealmDocumentValuesProvider(
    _organizationId,
    _realmId,
  ).overrideWithValue(
    const AsyncData(AuthoringValue(value: {"page": []}, revision: 1)),
  ),
  pageDocumentHealthProvider(
    _organizationId,
    _realmId,
    recordId("page:page"),
  ).overrideWithValue(null),
];
