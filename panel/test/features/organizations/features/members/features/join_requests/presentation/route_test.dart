import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/features/organizations/features/members/features/join_requests/presentation/route.dart";
import "package:typewriter_panel/shared/ui/components/page_heading.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";

import "../../../../../../../support/test_utils.dart";

void main() {
  testWidgets(
    "JoinRequestsPage separately shows its focused heading without tabs",
    (tester) async {
      await tester.pumpTestApp(
        child: const JoinRequestsPage(),
        overrides: [
          ...organizationMembersProviderOverrides(state: DisplayState.noItems),
          ...organizationJoinRequestsProviderOverrides(
            state: DisplayState.noItems,
          ),
        ],
      );
      await tester.pump(const Duration(seconds: 1));

      final heading = tester.widget<PageHeading>(find.byType(PageHeading));
      expect(heading.title, "Join Requests");
      expect(heading.subtext, isNotEmpty);
      expect(find.byType(TabBar), findsNothing);
    },
  );
}
