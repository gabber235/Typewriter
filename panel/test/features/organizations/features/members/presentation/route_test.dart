import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/app/application/router/app_router.dart";
import "package:typewriter_panel/features/organizations/features/members/presentation/member_list_route.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";

import "../../../../../support/test_utils.dart";

void main() {
  test(
    "AppRouter collection keeps current members as the initial /members leaf",
    () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final organization = container
          .read(appRouterProvider)
          .routes
          .firstWhere((route) => route.path == "/organization/:organizationId");
      final members = organization.children!.firstWhere(
        (route) => route.path == "members",
      );
      final currentMembers = members.children!.firstWhere(
        (route) => route.path == "",
      );

      expect(currentMembers.page.name, MemberListRoute.name);
      expect(currentMembers.initial, isTrue);
    },
  );

  testWidgets("MemberListPage shows its focused heading without tabs", (
    tester,
  ) async {
    await tester.pumpTestApp(
      child: const MemberListPage(),
      overrides: organizationMembersProviderOverrides(
        state: DisplayState.noItems,
      ),
    );
    await tester.pump();

    expect(find.text("Members"), findsOneWidget);
    expect(find.text("Manage organization access and roles."), findsOneWidget);
    expect(find.byType(TabBar), findsNothing);
  });
}
