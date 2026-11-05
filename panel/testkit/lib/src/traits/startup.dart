import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/src/core/trait.dart";
import "package:typewriter_testkit/src/core/world.dart";

/// A service the panel needs before it shows anything.
enum StartupDependency {
  /// The trace exporter.
  telemetry,

  /// The endpoint the NATS credentials come from.
  credentials,

  /// The identity provider that restores the session.
  identityProvider,
}

/// [dependency] is unreachable for the first [times] attempts the panel makes
/// to start, then answers.
Trait unreachableAtStartup(StartupDependency dependency, {int times = 1}) =>
    _UnreachableAtStartup(dependency, times);

final class _UnreachableAtStartup extends Trait {
  const _UnreachableAtStartup(this.dependency, this.times);

  final StartupDependency dependency;
  final int times;

  @override
  Slot get slot => const Slot("startup");

  @override
  String get description => "unreachableAtStartup($dependency, times: $times)";

  @override
  void applyTo(WorldBuilder world) {
    switch (dependency) {
      case StartupDependency.telemetry:
        var failures = times;
        world.overrides.add(
          panelTelemetryProvider.overrideWith((ref) async {
            if (failures > 0) {
              failures--;
              throw StateError("The trace exporter is unreachable");
            }
            return const NoopPanelTelemetry();
          }),
        );
      case StartupDependency.credentials:
        world.onStart((world) => world.session.credentialFailures = times);
      case StartupDependency.identityProvider:
        world.onStart(
          (world) => world.session.identityProviderFailures = times,
        );
    }
  }
}
