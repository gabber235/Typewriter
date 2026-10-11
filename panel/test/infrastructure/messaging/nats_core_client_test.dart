import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";

const _configuration = NatsClientConfiguration(
  url: "nats://fixture:4222",
  seed: "fixture-seed",
  requestInboxPrefix: "_INBOX.fixture.session",
  actorId: "fixture-user",
  organizationId: "fixture-organization",
  connectionSession: "0123456789abcdef0123456789abcdef",
);

final class _PendingCloseSubscription implements NatsSubscription {
  final StreamController<NatsMessage> _messages =
      StreamController<NatsMessage>.broadcast();
  int unsubscribeCount = 0;

  @override
  Stream<NatsMessage> get messages => _messages.stream;

  @override
  Future<void> get done => _messages.done;

  @override
  Future<void> unsubscribe() async {
    unsubscribeCount++;
    await _messages.close();
  }
}

void main() {
  test(
    "initial failure retains cause and stack without exposing its text",
    () async {
      final cause = StateError("super-secret-token");
      final causeStackTrace = StackTrace.current;
      final client = NatsCoreClient.fromConnectionFuture(
        Future<NatsConnection>.error(cause, causeStackTrace),
        configuration: _configuration,
      );
      addTearDown(client.close);

      final failed = await client.connectionStateChanges.firstWhere(
        (connectionState) => connectionState is NatsFailed,
      ) as NatsFailed;

      expect(failed.failure.kind, NatsFailureKind.unknown);
      expect(failed.failure.message, "Unexpected NATS client failure");
      expect(failed.failure.cause, same(cause));
      expect(failed.failure.causeStackTrace, same(causeStackTrace));
      expect(failed.failure.toString(), isNot(contains("super-secret-token")));
      expect(client.connectionState, same(failed));
    },
  );

  test(
    "connection failure remains unavailable and preserves its cause and stack",
    () async {
      const error = NatsConnectionException("Transport closed");
      final stackTrace = StackTrace.current;
      final client = NatsCoreClient.fromConnectionFuture(
        Future<NatsConnection>.error(error, stackTrace),
        configuration: _configuration,
      );
      addTearDown(client.close);

      final failed = await client.connectionStateChanges.firstWhere(
        (state) => state is NatsFailed,
      ) as NatsFailed;

      expect(failed.failure.kind, NatsFailureKind.unavailable);
      expect(failed.failure.cause, same(error));
      expect(failed.failure.causeStackTrace, same(stackTrace));
    },
  );

  test("nonstandard cause stack cannot prevent failure state", () async {
    final error = NatsAuthenticationException(
      "authentication rejected",
      causeStackTrace: StackTrace.fromString("<asynchronous suspension>"),
    );
    final client = NatsCoreClient.fromConnectionFuture(
      Future<NatsConnection>.error(error, StackTrace.current),
      configuration: _configuration,
    );
    addTearDown(client.close);

    await pumpEventQueue();

    expect(client.connectionState, isA<NatsFailed>());
    final failed = client.connectionState as NatsFailed;
    expect(failed.failure.kind, NatsFailureKind.authentication);
    expect(failed.failure.cause, same(error));
  });

  test("explicit close remains closed when initial connection fails", () async {
    final connection = Completer<NatsConnection>();
    final client = NatsCoreClient.fromConnectionFuture(
      connection.future,
      configuration: _configuration,
    );

    final close = client.close();
    connection.completeError(StateError("late failure"), StackTrace.current);
    await close;

    expect(client.connectionState, isA<NatsClosed>());
  });

  test("failure listener can close the client", () async {
    final connection = Completer<NatsConnection>();
    final client = NatsCoreClient.fromConnectionFuture(
      connection.future,
      configuration: _configuration,
    );
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

  test("close waits for an acquiring persistent subscription", () async {
    final connection = Completer<NatsConnection>();
    final acquisition = Completer<NatsSubscription>();
    final subscription = _PendingCloseSubscription();
    final client = NatsCoreClient.fromConnectionFuture(
      connection.future,
      configuration: _configuration,
      persistentOpener: (stream, consumer, filter) => acquisition.future,
    );

    final acquiring = client.subscribePersistent(
      "TYPEWRITER_FIXTURE",
      "TW_fixture",
      "cloud.from.fixture.changed",
    );
    final closing = client.close();
    acquisition.complete(subscription);
    expect(await acquiring, same(subscription));
    connection.completeError(StateError("fixture connection ended"));
    await closing;

    expect(subscription.unsubscribeCount, 1);
    expect(client.connectionState, isA<NatsClosed>());
  });
}
