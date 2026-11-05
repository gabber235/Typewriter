import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/src/core/stage.dart";
import "package:typewriter_testkit/src/traits/session.dart";

/// The members section of [organization] opened at [page], such as
/// `membersPage(const JoinCodesRoute())`; the current members list unless a
/// page is named.
PanelLocation membersPage([
  PageRouteInfo page = const MemberListRoute(),
  skir.Organization? organization,
]) => PanelLocation.route(
  OrganizationRoute(
    organizationId: (organization ?? acme).organizationId.id,
    children: [
      MembersRoute(children: [page]),
    ],
  ),
);
