import "dart:async";

import "package:flutter_test/flutter_test.dart";
import "package:nats_core/nats_core.dart" as core;
import "package:typewriter_panel/typewriter_panel.dart";

void main() {
  test(
    "initial failure retains cause and stack without exposing its text",
    () async {
      final cause = StateError("super-secret-token");
      final causeStackTrace = StackTrace.current;
      final client = NatsCoreClient.fromConnectionFuture(
        Future<core.NatsConnection>.error(cause, causeStackTrace),
      );
      addTearDown(client.close);

      final failed =
          await client.connectionStateChanges.firstWhere(
                (connectionState) => connectionState is NatsFailed,
              )
              as NatsFailed;

      expect(failed.failure.kind, NatsFailureKind.unknown);
      expect(failed.failure.message, "Unexpected NATS client failure");
      expect(failed.failure.cause, same(cause));
      expect(failed.failure.causeStackTrace, same(causeStackTrace));
      expect(failed.failure.toString(), isNot(contains("super-secret-token")));
      expect(client.connectionState, same(failed));
    },
  );

  test("explicit close remains closed when initial connection fails", () async {
    final connection = Completer<core.NatsConnection>();
    final client = NatsCoreClient.fromConnectionFuture(connection.future);

    final close = client.close();
    connection.completeError(StateError("late failure"), StackTrace.current);
    await close;

    expect(client.connectionState, isA<NatsClosed>());
  });

  test("failure listener can close the client", () async {
    final connection = Completer<core.NatsConnection>();
    final client = NatsCoreClient.fromConnectionFuture(connection.future);
    final states = <NatsConnectionState>[];
    final closeCompleted = Completer<void>();
    final subscription = client.connectionStateChanges.listen((state) {
      states.add(state);
      if (state is NatsFailed) {
        client.close().then(
          closeCompleted.complete,
          onError: closeCompleted.completeError,
        );
      }
    });
    addTearDown(subscription.cancel);

    connection.completeError(StateError("rejected"), StackTrace.current);
    await closeCompleted.future;

    expect(states, [isA<NatsFailed>(), isA<NatsClosed>()]);
    expect(client.connectionState, isA<NatsClosed>());
  });
}
