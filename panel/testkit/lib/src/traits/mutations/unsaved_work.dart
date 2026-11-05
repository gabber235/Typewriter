import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/src/core/trait.dart";
import "package:typewriter_testkit/src/core/world.dart";
import "package:typewriter_testkit/src/doubles/unsaved_work.dart";

/// The user holds [UnsavedWork] in every organization the panel opens, so
/// leaving that organization or signing out asks first.
///
/// Work belongs to the organization it was made in and ends with it; the
/// trait makes the edit again each time the panel enters an organization.
const Trait unsavedWork = _UnsavedWorkTrait();

final class _UnsavedWorkTrait extends Trait {
  const _UnsavedWorkTrait();

  @override
  Slot get slot => const Slot("local work");

  @override
  String get description => "unsavedWork";

  @override
  void applyTo(WorldBuilder world) => world.onStart(_editInEveryOrganization);

  static void _editInEveryOrganization(World world) {
    LocalWorkScope? edited;
    final subscription = world.container.listen(localWorkScopeProvider, (
      _,
      scope,
    ) {
      if (scope.organizationId == null || scope == edited) return;
      edited = scope;
      // The work session of a new scope starts once the current notification
      // finished; the edit belongs to that session.
      scheduleMicrotask(() {
        if (world.container.read(localWorkScopeProvider) != scope) return;
        world.container
            .read(localWorkProvider.notifier)
            .register(UnsavedWork());
      });
    }, fireImmediately: true);
    world.addCleanup(subscription.close);
  }
}
