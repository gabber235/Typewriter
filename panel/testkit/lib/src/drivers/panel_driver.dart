import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/src/core/eventually.dart";
import "package:typewriter_testkit/src/core/world.dart";
import "package:typewriter_testkit/src/drivers/authoring/resources_driver.dart";
import "package:typewriter_testkit/src/drivers/component_driver.dart";
import "package:typewriter_testkit/src/drivers/dialog_driver.dart";
import "package:typewriter_testkit/src/drivers/inspector_driver.dart";
import "package:typewriter_testkit/src/drivers/shared/selectable_driver.dart";

/// The whole panel as its user sees it, over the [world] it runs against.
final class PanelDriver extends ComponentDriver {
  PanelDriver(super.tester, this.world);

  /// The doubles and container the panel runs against.
  final World world;

  /// The provider container of the panel.
  ///
  /// For state the panel shows no other way yet, such as which resources are
  /// selected; prefer a driver that reads what the user sees.
  ProviderContainer get container => world.container;

  /// The address the panel shows, such as `/organization/acme/realm/main`.
  String get path => container.read(appRouterProvider).currentPath;

  /// The resources of the open Realm surface.
  ResourcesDriver get resources => ResourcesDriver(tester, world);

  /// The selectable item the user reads as [label].
  SelectableDriver item(String label) => SelectableDriver(tester, label);

  /// The inspector beside the open surface.
  InspectorDriver get inspector => InspectorDriver(tester);

  /// The context menu the user opened.
  ContextMenuDriver get menu => ContextMenuDriver(tester);

  /// The dialog in front of the panel.
  DialogDriver get dialog => DialogDriver(tester);

  /// The label of the control that has keyboard focus, or null.
  String? get focused {
    final nodes = find.semantics
        .byPredicate(
          (node) =>
              node.getSemanticsData().flagsCollection.isFocused ==
              Tristate.isTrue,
        )
        .evaluate();
    return nodes.isEmpty ? null : nodes.last.label;
  }

  /// Presses [key] on the keyboard.
  Future<void> press(LogicalKeyboardKey key) async {
    await tester.sendKeyEvent(key);
    await settle();
  }

  /// Presses [key] with the platform's primary modifier: Command on Apple
  /// platforms, Control elsewhere.
  Future<void> pressPrimary(LogicalKeyboardKey key) async {
    final modifier = switch (defaultTargetPlatform) {
      TargetPlatform.macOS || TargetPlatform.iOS => LogicalKeyboardKey.metaLeft,
      _ => LogicalKeyboardKey.controlLeft,
    };
    await tester.sendKeyDownEvent(modifier);
    await tester.sendKeyEvent(key);
    await tester.sendKeyUpEvent(modifier);
    await settle();
  }

  /// Waits until [check] passes; see [Eventually.eventually].
  Future<void> eventually(
    FutureOr<void> Function() check, {
    Duration timeout = eventuallyTimeout,
  }) => tester.eventually(check, timeout: timeout);
}
