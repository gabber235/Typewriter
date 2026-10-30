import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/src/core/trait.dart";
import "package:typewriter_testkit/src/core/world.dart";
import "package:typewriter_testkit/src/doubles/nats.dart";

/// Every connection the panel opens to NATS stays in [state]: connecting,
/// reconnecting, failed for a reason, or closed by the server.
///
/// Unlike [offline], which takes a reachable server away, the connection
/// never leaves [state], so the screen it shows stays for inspection.
Trait natsConnection(NatsConnectionState state) => _NatsConnection(state);

final class _NatsConnection extends Trait {
  const _NatsConnection(this.state);

  final NatsConnectionState state;

  @override
  Slot get slot => Slot.connection;

  @override
  String get description => "natsConnection($state)";

  @override
  void applyTo(WorldBuilder world) => world.onStart(
    (started) => started.nats.connectWith = (configuration) => _PinnedClient(
      state,
      actorId: configuration.actorId,
      organizationId: configuration.organizationId,
      connectionSession: configuration.connectionSession,
    ),
  );
}

/// A connection that reports [_state] whatever the server moves it to.
final class _PinnedClient extends FakeNatsClient {
  _PinnedClient(
    this._state, {
    required super.actorId,
    required super.organizationId,
    required super.connectionSession,
  });

  final NatsConnectionState _state;

  @override
  void setConnectionState(NatsConnectionState connectionState) =>
      super.setConnectionState(_state);
}

/// The trace exporter never answers, so the panel stays on the screen it
/// shows while its startup dependencies resolve.
const Trait startupPending = _StartupPending();

final class _StartupPending extends Trait {
  const _StartupPending();

  @override
  Slot get slot => const Slot("startup");

  @override
  String get description => "startupPending";

  @override
  void applyTo(WorldBuilder world) => world.overrides.add(
    panelTelemetryProvider.overrideWith(
      (ref) => Completer<PanelTelemetry>().future,
    ),
  );
}
