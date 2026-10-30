import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

const _configuration = NatsClientConfiguration(
  url: "nats://fixture:4222",
  seed: "fixture-seed",
  requestInboxPrefix: "_INBOX.fixture.session",
  actorId: "fixture-user",
  organizationId: "fixture-organization",
  connectionSession: "0123456789abcdef0123456789abcdef",
);

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
    final subscription = CountingNatsSubscription();
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

  final transportFailures = <(String, Object, NatsFailureKind)>[
    (
      "a denied permission",
      NatsPermissionException(
        serverMessage: "Permissions Violation for Publish",
        operation: NatsPermissionOperation.publish,
      ),
      NatsFailureKind.permission,
    ),
    (
      "no responders",
      const NatsNoRespondersException(),
      NatsFailureKind.noResponders,
    ),
    (
      "a closed connection",
      const NatsClosedException(),
      NatsFailureKind.closed,
    ),
    ("a timeout", NatsTimeoutException("connect"), NatsFailureKind.timeout),
    (
      "a protocol violation",
      const NatsProtocolException("unexpected frame"),
      NatsFailureKind.protocol,
    ),
  ];
  for (final (name, error, kind) in transportFailures) {
    test("$name fails the connection as ${kind.name}", () async {
      final client = NatsCoreClient.fromConnectionFuture(
        Future<NatsConnection>.error(error),
        configuration: _configuration,
      );

      final failed = await client.connectionStateChanges.firstWhere(
        (state) => state is NatsFailed,
      ) as NatsFailed;

      expect(failed.failure.kind, kind);
      expect(failed.failure.cause, same(error));
    });
  }

  test("a closed client refuses every operation as closed", () async {
    final client = NatsCoreClient.fromConnectionFuture(
      Future<NatsConnection>.error(StateError("no server in this test")),
      configuration: _configuration,
    );
    await client.close();
    final refusedAsClosed = throwsA(
      isA<NatsClientException>().having(
        (error) => error.kind,
        "kind",
        NatsFailureKind.closed,
      ),
    );

    await expectLater(
      client.request("subject", Uint8List(1), limits: transportLimits),
      refusedAsClosed,
    );
    await expectLater(client.publish("subject", Uint8List(1)), refusedAsClosed);
    await expectLater(client.subscribe("subject"), refusedAsClosed);
    await expectLater(
      client.subscribePersistent("TYPEWRITER_FIXTURE", "TW_fixture", "subject"),
      refusedAsClosed,
    );
  });

  group("a named consumer", () {
    test("has one subscription owner at a time", () async {
      var opened = 0;
      final client = NatsCoreClient.fromConnectionFuture(
        Future<NatsConnection>.error(StateError("no server in this test")),
        configuration: _configuration,
        persistentOpener: (stream, consumer, filter) async {
          opened++;
          return CountingNatsSubscription();
        },
      );
      addTearDown(client.close);
      await client.subscribePersistent(
        "TYPEWRITER_FIXTURE",
        "TW_fixture",
        "cloud.from.fixture.changed",
      );

      await expectLater(
        client.subscribePersistent(
          "TYPEWRITER_FIXTURE",
          "TW_fixture",
          "cloud.from.fixture.changed",
        ),
        throwsA(isA<StateError>()),
      );
      expect(opened, 1);
    });

    test("is free again after a failed acquisition", () async {
      const unavailable = NatsClientException(
        kind: NatsFailureKind.unavailable,
        message: "The stream is not reachable",
      );
      var attempts = 0;
      final subscription = CountingNatsSubscription();
      final client = NatsCoreClient.fromConnectionFuture(
        Future<NatsConnection>.error(StateError("no server in this test")),
        configuration: _configuration,
        persistentOpener: (stream, consumer, filter) async {
          attempts++;
          if (attempts == 1) throw unavailable;
          return subscription;
        },
      );
      addTearDown(client.close);

      await expectLater(
        client.subscribePersistent(
          "TYPEWRITER_FIXTURE",
          "TW_fixture",
          "cloud.from.fixture.changed",
        ),
        throwsA(same(unavailable)),
      );
      expect(
        await client.subscribePersistent(
          "TYPEWRITER_FIXTURE",
          "TW_fixture",
          "cloud.from.fixture.changed",
        ),
        same(subscription),
      );
    });
  });
}
