import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/src/core/eventually.dart";
import "package:typewriter_testkit/src/core/world.dart";
import "package:typewriter_testkit/src/drivers/authoring/resources_driver.dart";
import "package:typewriter_testkit/src/drivers/component_driver.dart";
import "package:typewriter_testkit/src/drivers/dialog_driver.dart";
import "package:typewriter_testkit/src/drivers/graph/graph_driver.dart";
import "package:typewriter_testkit/src/drivers/inspector_driver.dart";
import "package:typewriter_testkit/src/drivers/semantics.dart";
import "package:typewriter_testkit/src/drivers/shared/field_driver.dart";
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

  /// The text field the user reads as [label].
  FieldDriver field(String label) => FieldDriver(tester, label);

  /// The text field at [index] in reading order, for fields without a label.
  FieldDriver fieldAt(int index) => FieldDriver.at(tester, index);

  /// The graph canvas in the middle of the window.
  GraphDriver get graph => GraphDriver(tester);

  /// The inspector beside the open surface.
  InspectorDriver get inspector => InspectorDriver(tester);

  /// The context menu the user opened.
  ContextMenuDriver get menu => ContextMenuDriver(tester);

  /// The dialog in front of the panel.
  DialogDriver get dialog => DialogDriver(tester);

  /// What assistive technology reads for the control that has keyboard
  /// focus, or null.
  String? get focused {
    final nodes = find.semantics
        .byPredicate(
          (node) =>
              // A node merged into its parent is read as that parent.
              !node.isMergedIntoParent &&
              node.getSemanticsData().flagsCollection.isFocused ==
                  Tristate.isTrue,
        )
        .evaluate();
    // The label assistive technology reads, with what merged into it.
    return nodes.isEmpty ? null : nodes.last.spoken;
  }

  /// Whether keyboard focus is on the control [label] or on the unlabeled
  /// control around it, such as a field that holds focus before editing.
  /// An icon button named only by its tooltip counts as labeled by it.
  bool hasFocusOn(String label) {
    final nodes = find.semantics
        .byPredicate((node) => node.isFocused)
        .evaluate();
    if (nodes.isEmpty) return false;
    final node = nodes.last;
    return node.spoken == label ||
        node.spoken.isEmpty && node.getSemanticsData().tooltip == label ||
        node.spoken.isEmpty &&
            node.descendants.any((child) => child.spoken == label);
  }

  /// Whether the control [target] shows holds the keyboard focus.
  bool holdsFocus(Finder target) => tester.getSemantics(target).isFocused;

  /// Presses Tab until the control [target] shows holds the keyboard focus,
  /// then presses Enter on it. Each key pumps a single frame, so work the
  /// activation starts stays pending for the test to observe.
  Future<void> activateWithKeyboard(Finder target, {int limit = 30}) async {
    for (var step = 0; step < limit && !holdsFocus(target); step++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
    }
    expect(holdsFocus(target), isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
  }

  /// Makes [selection] the selection, the way choosing those items does,
  /// and lets the panel react.
  Future<void> selectAll(List<SelectableIdentifier> selection) async {
    container.read(selectionProvider.notifier).selectAll(selection);
    await settle();
  }

  /// Presses Tab until the control [label] has keyboard focus; fails when
  /// [limit] presses never reach it, since then no keyboard user can.
  Future<void> tabTo(String label, {int limit = 10}) async {
    for (var tabs = 0; tabs < limit && !hasFocusOn(label); tabs++) {
      await press(LogicalKeyboardKey.tab);
    }
    expect(hasFocusOn(label), isTrue, reason: "Tab reaches $label");
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

  /// Presses [key] while Shift is held.
  Future<void> pressShifted(LogicalKeyboardKey key) async {
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyEvent(key);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await settle();
  }

  /// Waits until [check] passes; see [Eventually.eventually].
  Future<void> eventually(
    FutureOr<void> Function() check, {
    Duration timeout = eventuallyTimeout,
  }) => tester.eventually(check, timeout: timeout);

  /// Keeps [provider] watched until the test ends, the way a page showing
  /// it does, and returns the subscription that reads it.
  ///
  /// For state the panel shows no other way yet; prefer a driver that reads
  /// what the user sees.
  ProviderSubscription<T> watch<T>(ProviderListenable<T> provider) {
    final subscription = container.listen(provider, (_, _) {});
    addTearDown(subscription.close);
    return subscription;
  }

  /// Watches [provider] until the test ends and returns it once it stopped
  /// loading, holding a value or an error.
  Future<AsyncValue<T>> loaded<T>(
    ProviderListenable<AsyncValue<T>> provider,
  ) async {
    final subscription = watch(provider);
    await eventually(() => expect(subscription.read().isLoading, isFalse));
    return subscription.read();
  }
}
