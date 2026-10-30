import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/src/drivers/panel_driver.dart";

/// The connection of the open Realm, as the panel decides what the author
/// may do with it.
extension RealmConnectionOnPanel on PanelDriver {
  /// The open Realm's connection state now.
  RealmConnectionState get realmConnection =>
      container.read(realmInteractionProvider).connectionState;

  /// Every connection state the open Realm passes through from now on,
  /// starting with the current one.
  List<RealmConnectionState> recordRealmConnection() {
    final states = <RealmConnectionState>[];
    final subscription = container.listen(
      realmInteractionProvider,
      (_, next) => states.add(next.connectionState),
      fireImmediately: true,
    );
    addTearDown(subscription.close);
    return states;
  }
}
