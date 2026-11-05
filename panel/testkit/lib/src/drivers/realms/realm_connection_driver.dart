import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/src/core/pump_panel.dart";
import "package:typewriter_testkit/src/core/stage.dart";
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

/// Content behind a Realm's suspension barrier.
extension PumpSuspendableContent on WidgetTester {
  /// Pumps [child] in an online Realm workspace of [size], behind its
  /// suspension barrier. Setting the returned connection's value moves the
  /// Realm online or offline.
  Future<({PanelDriver panel, ValueNotifier<RealmConnectionState> connection})>
  pumpSuspendable(Widget child, {required Size size}) async {
    final connection = ValueNotifier(RealmConnectionState.online);
    addTearDown(connection.dispose);
    final panel = await pumpPanel(
      const [],
      at: PanelLocation.component(
        SizedBox.fromSize(
          size: size,
          child: ValueListenableBuilder(
            valueListenable: connection,
            builder: (context, state, child) => RealmSuspensionBarrier(
              interaction: RealmInteractionState(connectionState: state),
              child: child!,
            ),
            child: child,
          ),
        ),
      ),
    );
    return (panel: panel, connection: connection);
  }
}
