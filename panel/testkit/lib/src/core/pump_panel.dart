import "package:flutter_test/flutter_test.dart";
import "package:typewriter_testkit/src/core/offline_network.dart";
import "package:typewriter_testkit/src/core/stage.dart";
import "package:typewriter_testkit/src/core/trait.dart";
import "package:typewriter_testkit/src/core/world.dart";
import "package:typewriter_testkit/src/drivers/panel_driver.dart";

/// Starts the panel in a widget test.
extension PumpPanel on WidgetTester {
  /// Pumps the real panel (router, guards, theme, shortcuts) over a world
  /// built from [traits], opened [at] a location or at the world's home.
  ///
  /// The world renders in the window its traits chose, never reaches the
  /// network (see [keepOffline]) and is disposed with the test. Returns once
  /// the panel finished its first navigation.
  Future<PanelDriver> pumpPanel(List<Trait> traits, {PanelLocation? at}) async {
    final world = World.build(traits);
    keepOffline();
    view
      ..physicalSize = world.window
      ..devicePixelRatio = 1;
    addTearDown(view.reset);
    addTearDown(world.dispose);
    await pumpWidget(PanelStage.world(world, at: at));
    final panel = PanelDriver(this, world);
    await panel.settle();
    return panel;
  }
}
