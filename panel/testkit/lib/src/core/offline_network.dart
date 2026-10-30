import "dart:io";

import "package:flutter_test/flutter_test.dart";
import "package:typewriter_testkit/src/doubles/images.dart";

/// Keeps the current test off the network until it ends.
///
/// Every socket the test opens fails with a [StateError] naming the address,
/// so code that forgot to go through a double fails loudly instead of
/// reaching the address the panel is built against. HTTP answers come from
/// [FakeImageHosts]. [PumpPanel.pumpPanel] and [testWorld] call it, so every
/// test world is offline.
void keepOffline() {
  final previous = IOOverrides.current;
  IOOverrides.global = _Offline();
  addTearDown(() => IOOverrides.global = previous);
  FakeImageHosts.install();
}

final class _Offline extends IOOverrides {
  @override
  Future<Socket> socketConnect(
    dynamic host,
    int port, {
    dynamic sourceAddress,
    int sourcePort = 0,
    Duration? timeout,
  }) => Future.error(_refused(host, port));

  @override
  Future<ConnectionTask<Socket>> socketStartConnect(
    dynamic host,
    int port, {
    dynamic sourceAddress,
    int sourcePort = 0,
  }) => Future.error(_refused(host, port));

  StateError _refused(Object? host, int port) => StateError(
    "A test world reaches no network, but something connected to "
    "$host:$port; give that seam a double instead",
  );
}
