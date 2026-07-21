import "dart:async";

import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/typewriter_panel.dart";
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

    final heading = tester.widget<PageHeading>(find.byType(PageHeading));
    expect(heading.title, "Members");
    expect(heading.subtext, isNotEmpty);
    expect(find.byType(TabBar), findsNothing);
  });

  testWidgets("MemberListPage shows mobile member shimmers while loading", (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(400, 900);
    addTearDown(tester.view.reset);

    await tester.pumpTestApp(
      child: const MemberListPage(),
      overrides: [
        organizationMembersProvider.overrideWith(
          _LoadingOrganizationMembers.new,
        ),
      ],
      settle: false,
    );
    await tester.pump();

    expect(find.byKey(const ValueKey("membersLoadingMobile")), findsOneWidget);
    expect(find.byKey(const ValueKey("membersLoadingDesktop")), findsNothing);
    expect(find.byType(ShimmerBox), findsWidgets);
  });

  testWidgets("MemberListPage shows desktop member shimmers while loading", (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1200, 900);
    addTearDown(tester.view.reset);

    await tester.pumpTestApp(
      child: const MemberListPage(),
      overrides: [
        organizationMembersProvider.overrideWith(
          _LoadingOrganizationMembers.new,
        ),
      ],
      settle: false,
    );
    await tester.pump();

    expect(find.byKey(const ValueKey("membersLoadingDesktop")), findsOneWidget);
    expect(find.byKey(const ValueKey("membersLoadingMobile")), findsNothing);
    expect(find.byType(ShimmerBox), findsWidgets);
  });
}

class _LoadingOrganizationMembers extends OrganizationMembers {
  @override
  Stream<List<OrganizationMember>> build() {
    final controller = StreamController<List<OrganizationMember>>();
    ref.onDispose(controller.close);
    return controller.stream;
  }
}
