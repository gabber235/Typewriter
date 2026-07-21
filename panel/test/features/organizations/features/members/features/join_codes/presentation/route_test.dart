import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";

import "../../../../../../../support/test_utils.dart";
import "../application/support/join_codes_test_support.dart";

void main() {
  testWidgets("JoinCodesPage separately uses Join Code wording without tabs", (
    tester,
  ) async {
    await tester.pumpTestApp(
      child: const JoinCodesPage(),
      overrides: [
        ...organizationMembersProviderOverrides(state: DisplayState.noItems),
        ...organizationJoinCodesProviderOverrides(state: DisplayState.noItems),
      ],
    );
    await tester.pump();

    final heading = tester.widget<PageHeading>(find.byType(PageHeading));
    expect(heading.title, "Join Codes");
    expect(heading.subtext, isNotEmpty);
    expect(find.text("Join Code"), findsOneWidget);
    expect(find.text("Active Join Codes"), findsOneWidget);
    expect(find.textContaining("Active Links"), findsNothing);
    expect(find.textContaining("Invite Link"), findsNothing);
    expect(find.byType(TabBar), findsNothing);
  });

  for (final testCase in [
    ("mobile", Size(800, 1200), "joinCodesLoadingMobile"),
    ("desktop", Size(1440, 900), "joinCodesLoadingDesktop"),
  ]) {
    testWidgets("shows ${testCase.$1} loading shimmer", (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = testCase.$2;
      addTearDown(tester.view.reset);
      await tester.pumpTestApp(
        child: const JoinCodesPage(),
        overrides: [
          ...organizationMembersProviderOverrides(state: DisplayState.noItems),
          organizationJoinCodesProvider.overrideWith(
            LoadingJoinCodesNotifier.new,
          ),
        ],
        settle: false,
      );
      await tester.pump();

      expect(find.byKey(ValueKey(testCase.$3)), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(ValueKey(testCase.$3)),
          matching: find.byType(ShimmerBox),
        ),
        findsWidgets,
      );
      await tester.pump(const Duration(seconds: 1));
    });
  }
}
