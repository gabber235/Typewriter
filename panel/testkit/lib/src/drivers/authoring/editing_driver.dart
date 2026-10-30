import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/src/authoring/realm_world.dart";
import "package:typewriter_testkit/src/drivers/authoring/surface_driver.dart";
import "package:typewriter_testkit/src/drivers/panel_driver.dart";

/// Editing the seeded Realm through components shown above its surface.
extension EditingDrivers on PanelDriver {
  /// The panel's editing of the seeded Realm, the one every surface of the
  /// open Realm edits through.
  Future<RealmEditing> openEditing() async {
    final editing = await world.openRealmEditing();
    await settle();
    return editing;
  }

  /// Closes the component [AboveSurfaceDrivers.showAbove] showed last, the
  /// way closing a pane unmounts it, and leaves the Realm open.
  Future<void> closeAbove() async {
    container.read(appRouterProvider).navigatorKey.currentState!.pop();
    await settle();
  }
}
