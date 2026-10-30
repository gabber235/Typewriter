import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/src/core/trait.dart";
import "package:typewriter_testkit/src/core/world.dart";
import "package:typewriter_testkit/src/doubles/telemetry.dart";

/// Tracing is enabled, so every request the panel sends carries the trace
/// context [headers]; see [FakeTelemetry].
Trait traced(Map<String, String> headers) => _Traced(headers);

final class _Traced extends Trait {
  const _Traced(this.headers);

  final Map<String, String> headers;

  @override
  Slot get slot => const Slot("telemetry");

  @override
  String get description => "traced";

  @override
  void applyTo(WorldBuilder world) => world.overrides.add(
    panelTelemetryProvider.overrideWithValue(AsyncData(FakeTelemetry(headers))),
  );
}
