import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";

import "../../../support/test_utils.dart";

void main() {
  testWidgets(
    "organization sidebar builds distinct member routes and positive badge",
    (tester) async {
      final links = OrganizationSidebarContent.organizationLinks(
        recordId("organization:org1"),
        3,
      );
      final sidebarLinks = links.whereType<SidebarLink>().toList();

      expect(sidebarLinks.map((link) => link.text), [
        "Services",
        "Members",
        "Join Requests",
        "Join Codes",
      ]);
      expect(_leafName(sidebarLinks[1]), MemberListRoute.name);
      expect(_leafName(sidebarLinks[2]), JoinRequestsRoute.name);
      expect(_leafName(sidebarLinks[3]), JoinCodesRoute.name);

      await tester.pumpTestApp(child: Column(children: links));
      final trailing = sidebarLinks[2].trailing! as Semantics;
      expect(trailing.properties.label, "3 pending join requests");
      expect(find.text("3"), findsOneWidget);
    },
  );

  testWidgets("organization sidebar hides pending badge when count is zero", (
    tester,
  ) async {
    final links = OrganizationSidebarContent.organizationLinks(
      recordId("organization:org1"),
      0,
    );

    await tester.pumpTestApp(child: Column(children: links));

    expect(
      find.bySemanticsLabel(RegExp("pending join requests")),
      findsNothing,
    );
    expect(
      links
          .whereType<SidebarLink>()
          .singleWhere((link) => link.text == "Join Requests")
          .trailing,
      isNull,
    );
  });
}

String _leafName(SidebarLink link) => link.route.flattened.last.routeName;
