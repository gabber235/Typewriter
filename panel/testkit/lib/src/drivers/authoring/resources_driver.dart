import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/src/core/world.dart";
import "package:typewriter_testkit/src/drivers/component_driver.dart";
import "package:typewriter_testkit/src/drivers/shared/selectable_driver.dart";

/// The resources a Realm surface lists, such as the Books of the Library.
final class ResourcesDriver extends ComponentDriver {
  ResourcesDriver(super.tester, this.world);

  final World world;

  /// The resource the surface shows as [label].
  ResourceRowDriver row(String label) => ResourceRowDriver(tester, label);

  /// Whether the surface shows a resource as [label].
  bool showing(String label) => labeled(label).evaluate().isNotEmpty;

  /// The resources selected for the inspector and for operations.
  ///
  /// Selection has no semantics of its own yet, so this reads the panel's
  /// selection instead of the screen.
  List<skir.ResourceId> get selected => [
    for (final identifier in world.container.read(selectionProvider))
      if (identifier case AuthoringResourceIdentifier(:final resourceId))
        resourceId,
  ];

  /// Selects exactly [resources], the way another part of the panel does.
  Future<void> selectOnly(List<skir.ResourceId> resources) async {
    final scope = world.requireRealm.scope;
    world.container.read(selectionProvider.notifier).selectAll([
      for (final resource in resources)
        AuthoringResourceIdentifier.inScope(scope, resource),
    ]);
    await settle();
  }
}

/// One resource of a surface, found by the label the user reads on it.
final class ResourceRowDriver extends SelectableDriver {
  ResourceRowDriver(super.tester, super.label);

  /// The resource's operations, through its context menu.
  ResourceOperationsDriver get operations => ResourceOperationsDriver(this);
}

/// The operations a resource offers in its context menu.
final class ResourceOperationsDriver {
  ResourceOperationsDriver(this._row);

  final ResourceRowDriver _row;

  /// Opens the context menu and returns its entries.
  Future<List<String>> open() async => (await _row.contextMenu()).entries;

  /// Opens the context menu and chooses [label].
  Future<void> choose(String label) async {
    final menu = await _row.contextMenu();
    await menu.choose(label);
  }
}
