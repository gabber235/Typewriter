import "package:typewriter_testkit/src/core/trait.dart";
import "package:typewriter_testkit/src/core/world.dart";

/// The backend goes away [after] the panel opened; with no delay the panel
/// opens without it.
Trait offline({Duration after = Duration.zero}) => _Offline(after);

final class _Offline extends Trait {
  const _Offline(this.after);

  final Duration after;

  @override
  Slot get slot => Slot.connection;

  @override
  String get description => "offline(after: $after)";

  @override
  void applyTo(WorldBuilder world) => world.offlineAfter = after;
}

/// Every backend double takes [delay] to answer.
Trait latency(Duration delay) => _Latency(delay);

final class _Latency extends Trait {
  const _Latency(this.delay);

  final Duration delay;

  @override
  Slot get slot => Slot.latency;

  @override
  String get description => "latency($delay)";

  @override
  void applyTo(WorldBuilder world) => world.latency = delay;
}
