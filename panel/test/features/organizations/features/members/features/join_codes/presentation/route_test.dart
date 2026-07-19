import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/features/organizations/features/members/features/join_codes/presentation/route.dart";
import "package:typewriter_panel/shared/ui/components/page_heading.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";

import "../../../../../../../support/test_utils.dart";

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
}
