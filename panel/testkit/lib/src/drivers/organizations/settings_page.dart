import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/src/core/stage.dart";
import "package:typewriter_testkit/src/traits/session.dart";

/// The settings page of [organization], [acme] unless a test names another.
PanelLocation organizationSettingsPage([skir.Organization? organization]) =>
    PanelLocation.route(
      OrganizationRoute(
        organizationId: (organization ?? acme).organizationId.id,
        children: [const OrganizationSettingsRoute()],
      ),
    );
