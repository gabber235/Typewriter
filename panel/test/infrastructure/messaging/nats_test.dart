import "package:flutter_test/flutter_test.dart";
import "package:http/testing.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

/// The trace context an enabled trace exporter adds to every request.
const _traceHeaders = {
  "traceparent": "00-4bf92f3577b34da6a3ce929d0e0e4736-00f067aa0ba902b7-01",
  "tracestate": "vendor=value",
};

/// The scope a request is sent from, as a feature provider would.
final _scope = Provider<Ref>((ref) => ref);

const _lost = NatsClientException(
  kind: NatsFailureKind.unavailable,
  message: "The test took the reader away",
);

void main() {
  group("sentinelCredentials", () {
    test("forwards trace headers and decodes a successful response", () async {
      late Request sent;

      final container = ProviderContainer(
        retry: (retryCount, error) => null,
        overrides: [
          panelHttpClientProvider.overrideWithValue(
            MockClient((request) async {
              sent = request;
              return Response.bytes(
                skir.GetSentinelCredentialsResponse.serializer.toBytes(
                  skir.GetSentinelCredentialsResponse.createSuccess(
                    jwt: "test-jwt",
                    seed: "test-seed",
                  ),
                ),
                200,
              );
            }),
          ),
          panelTelemetryProvider.overrideWithValue(
            const AsyncData(FakeTelemetry(_traceHeaders)),
          ),
        ],
      );
      addTearDown(container.dispose);
      final credentials = await container.read(
        sentinelCredentialsProvider.future,
      );

      expect(credentials.jwt, "test-jwt");
      expect(credentials.seed, "test-seed");
      expect(sent.method, "GET");
      expect(
        sent.headers,
        containsPair("traceparent", startsWith("00-4bf92f")),
      );
      expect(sent.headers, containsPair("tracestate", "vendor=value"));
    });

    final failures = [
      (
        "a non success HTTP status keeps its status",
        Response("unavailable", 503),
        503,
      ),
      (
        "an unknown response variant fails as unprocessable",
        Response.bytes(
          skir.GetSentinelCredentialsResponse.serializer.toBytes(
            skir.GetSentinelCredentialsResponse.unknown,
          ),
          200,
        ),
        422,
      ),
      (
        "an internal error fails as a server error",
        Response.bytes(
          skir.GetSentinelCredentialsResponse.serializer.toBytes(
            skir.GetSentinelCredentialsResponse.createInternalError(),
          ),
          200,
        ),
        500,
      ),
    ];
    for (final (name, reply, code) in failures) {
      test(name, () async {
        final container = ProviderContainer(
          retry: (retryCount, error) => null,
          overrides: [
            panelHttpClientProvider.overrideWithValue(
              MockClient((_) async => reply),
            ),
            panelTelemetryProvider.overrideWithValue(
              const AsyncData(FakeTelemetry(_traceHeaders)),
            ),
          ],
        );
        addTearDown(container.dispose);
        await expectLater(
          container.read(sentinelCredentialsProvider.future),
          throwsA(
            isA<ApiException>().having((error) => error.code, "code", code),
          ),
        );
      });
    }

    test("rethrows the original HTTP transport exception", () async {
      final error = StateError("network failed");

      final container = ProviderContainer(
        retry: (retryCount, error) => null,
        overrides: [
          panelHttpClientProvider.overrideWithValue(
            MockClient((_) => Future<Response>.error(error)),
          ),
          panelTelemetryProvider.overrideWithValue(
            const AsyncData(FakeTelemetry(_traceHeaders)),
          ),
        ],
      );
      addTearDown(container.dispose);
      await expectLater(
        container.read(sentinelCredentialsProvider.future),
        throwsA(same(error)),
      );
    });
  });

  group("Nats", () {
    test("refuses to connect without a signed in user", () async {
      final world = testWorld(const []);
      await world.initialized();

      expect(
        () => world.container.read(natsProvider),
        throwsA(
          isA<ProviderException>().having(
            (error) => error.exception,
            "exception",
            isA<StateError>().having(
              (error) => error.message,
              "message",
              "User must be authenticated before connecting to NATS",
            ),
          ),
        ),
      );
      expect(world.nats.connected, isFalse);
    });

    test("signing out closes the connection", () async {
      final world = testWorld([signedIn(ada)]);
      await world.initialized();
      final connection = world.container.listen(natsProvider, (_, _) {});
      addTearDown(connection.close);
      final signedInConnection = world.nats.connection;

      await world.container.read(authProvider.notifier).signOut();
      await eventually(
        () => expect(signedInConnection.connectionState, isA<NatsClosed>()),
      );
    });

    test("a session that has just signed in reaches its organizations "
        "before anything else read its token", () async {
      final world = testWorld([
        signedIn(ada, organization: acme),
        userBackend(),
      ]);
      // The panel fetches these before anyone signs in.
      await world.container.read(sentinelCredentialsProvider.future);

      final organizations = await world
          .watch(organizationsProvider.future)
          .read();

      expect(organizations.map((it) => it.name), [acme.name]);
    });

    testWidgets("an organization change reconnects to the new organization", (
      tester,
    ) async {
      final globex = organization("Globex");
      final panel = await tester.pumpPanel([
        signedIn(ada, organization: acme, others: [globex]),
      ]);
      final connection = panel.container.listen(natsProvider, (_, _) {});
      addTearDown(connection.close);
      final acmeConnection = panel.world.nats.connection;
      expect(acmeConnection.organizationId, acme.organizationId.id);

      unawaited(
        panel.container
            .read(appRouterProvider)
            .navigate(
              OrganizationRoute(organizationId: globex.organizationId.id),
            ),
      );
      await panel.settle();

      expect(
        panel.world.nats.connection.organizationId,
        globex.organizationId.id,
      );
      expect(acmeConnection.connectionState, isA<NatsClosed>());
    });
  });

  group("NatsLifecycle", () {
    test("reports outages and follows a replaced connection", () async {
      final world = testWorld([signedIn(ada)]);
      await world.initialized();
      final lifecycle = world.container.listen(
        natsLifecycleProvider,
        (_, _) {},
      );
      addTearDown(lifecycle.close);
      expect(lifecycle.read(), isA<NatsConnected>());

      world.nats.disconnect(failure: _lost);
      expect(
        lifecycle.read(),
        isA<NatsFailed>().having((state) => state.failure, "failure", _lost),
      );
      world.nats.reconnect();
      expect(lifecycle.read(), isA<NatsConnected>());

      final replaced = world.nats.connection;
      await world.container.read(natsProvider.notifier).retry();
      expect(world.nats.connection, isNot(same(replaced)));
      world.nats.connection.setConnectionState(const NatsReconnecting(_lost));
      expect(
        lifecycle.read(),
        isA<NatsReconnecting>().having(
          (state) => state.failure,
          "failure",
          _lost,
        ),
      );
    });
  });

  group("RefNatsExtension.requestSkir", () {
    test("decodes the reply and carries the trace headers", () async {
      final world = testWorld([signedIn(ada), traced(_traceHeaders)]);
      await world.initialized();
      world.nats.registerHandler(
        "test.subject",
        (_) => skir.GetSentinelCredentialsResponse.serializer.toBytes(
          skir.GetSentinelCredentialsResponse.createSuccess(
            jwt: "test-jwt",
            seed: "test-seed",
          ),
        ),
      );

      final response = await world.container
          .read(_scope)
          .requestSkir(
            SkirRouteOperation(
              subject: "test.subject",
              requestBytes: skir.GetSentinelCredentialsRequest.serializer
                  .toBytes(skir.GetSentinelCredentialsRequest()),
              responseSerializer:
                  skir.GetSentinelCredentialsResponse.serializer,
              outcome: (_) => ResponseOutcome.success,
              limits: transportLimits,
            ),
          );

      expect(
        response,
        isA<skir.GetSentinelCredentialsResponse_successWrapper>()
            .having((it) => it.value.jwt, "jwt", "test-jwt")
            .having((it) => it.value.seed, "seed", "test-seed"),
      );
      final headers = world.nats.connection.requests.single.headers;
      expect(headers, containsPair("traceparent", startsWith("00-4bf92f")));
      expect(headers, containsPair("tracestate", "vendor=value"));
    });

    test("sends the request bytes unchanged", () async {
      final world = testWorld([signedIn(ada)]);
      await world.initialized();
      final request = counterBytes(42);
      Uint8List? received;
      world.nats.registerHandler("test.subject", (bytes) {
        received = bytes;
        return counterBytes(0);
      });

      await world.container
          .read(_scope)
          .requestSkir(
            SkirRouteOperation(
              subject: "test.subject",
              requestBytes: request,
              responseSerializer: skir.Duration.serializer,
              outcome: (_) => ResponseOutcome.success,
              limits: transportLimits,
            ),
          );

      expect(received, request);
    });
  });

  group("RefNatsExtension.watchProjection", () {
    test("subscribes before the traced initial Skir request", () async {
      final world = testWorld([signedIn(ada), traced(_traceHeaders)]);
      await world.initialized();
      var subscribedBeforeSnapshot = false;
      world.nats.registerHandler("watch", (_) {
        subscribedBeforeSnapshot = world.nats.connection.subscriptionSubjects
            .contains("events");
        return counterBytes(1);
      });

      expect(await world.watchCounter().first, 1);

      final request = world.nats.connection.requests.single;
      expect(request.subject, "watch");
      expect(
        request.headers,
        containsPair("traceparent", startsWith("00-4bf92f")),
      );
      expect(request.headers, containsPair("tracestate", "vendor=value"));
      expect(subscribedBeforeSnapshot, isTrue);
    });

    test("unsubscribes when the response stream is canceled", () async {
      final world = testWorld([signedIn(ada)]);
      await world.initialized();
      world.nats.registerHandler("watch", (_) => counterBytes(1));
      final values = <int>[];
      final listener = world.watchCounter().listen(values.add);
      await eventually(() => expect(values, [1]));
      expect(world.nats.connection.subscriptionSubjects, ["events"]);

      await listener.cancel();

      expect(world.nats.connection.subscriptionSubjects, isEmpty);
    });

    test("cancellation remains safe while subscribe is pending", () async {
      final world = testWorld([signedIn(ada)]);
      await world.initialized();
      world.nats.connectWith = HeldSubscriptionsNatsClient.new;
      final listener = world.watchCounter().listen(null);
      final server = world.nats.connection as HeldSubscriptionsNatsClient;
      await pumpEventQueue();

      final cancellation = listener.cancel();
      server.admission.complete();
      await cancellation;
      await pumpEventQueue();

      expect(server.subscriptionSubjects, isEmpty);
      expect(server.requests, isEmpty);
    });

    test("reconnect serializes a pending persistent acquisition", () async {
      final world = testWorld([signedIn(ada)]);
      await world.initialized();
      world.nats.connectWith = HeldAcquisitionsNatsClient.new;
      var snapshots = 0;
      world.nats.registerHandler("watch", (_) => counterBytes(++snapshots));
      final values = <int>[];
      final listener = world.watchCounter(persistent: true).listen(values.add);
      addTearDown(listener.cancel);
      final server = world.nats.connection as HeldAcquisitionsNatsClient;
      await eventually(() => expect(server.admissions, hasLength(1)));

      world.nats
        ..disconnect()
        ..reconnect();
      await pumpEventQueue();
      expect(server.admissions, hasLength(1));

      server.admissions[0].complete();
      await eventually(() => expect(server.admissions, hasLength(2)));
      expect(server.subscriptionSubjects, isEmpty);
      server.admissions[1].complete();
      await eventually(() => expect(values, [1]));

      expect(server.mostAcquiringAtOnce, 1);
      expect(server.subscriptionSubjects, ["events"]);
    });

    test(
      "reconnect replaces the subscription and reloads its baseline",
      () async {
        final world = testWorld([signedIn(ada)]);
        await world.initialized();
        var snapshot = 1;
        world.nats.registerHandler("watch", (_) => counterBytes(snapshot));
        final values = <int>[];
        final listener = world.watchCounter().listen(values.add);
        addTearDown(listener.cancel);
        await eventually(() => expect(values, [1]));
        world.nats.connection.emitMessageOnSubject("events", counterBytes(2));
        await eventually(() => expect(values, [1, 2]));

        world.nats.disconnect();
        await eventually(
          () => expect(world.nats.connection.subscriptionSubjects, isEmpty),
        );
        snapshot = 4;
        world.nats.connection.emitMessageOnSubject("events", counterBytes(3));
        world.nats.reconnect();
        await eventually(() => expect(values, [1, 2, 4]));

        expect(world.nats.connection.requests, hasLength(2));
        expect(world.nats.connection.subscriptionSubjects, ["events"]);
      },
    );

    test("a stale reconnect generation cannot publish its snapshot", () async {
      final world = testWorld([signedIn(ada)]);
      await world.initialized();
      final firstSnapshot = Completer<Uint8List>();
      var requests = 0;
      world.nats.registerHandler("watch", (_) {
        requests++;
        return requests == 1 ? firstSnapshot.future : counterBytes(2);
      });
      final values = <int>[];
      final listener = world.watchCounter().listen(values.add);
      addTearDown(listener.cancel);
      await eventually(() => expect(requests, 1));

      world.nats
        ..disconnect()
        ..reconnect();
      await eventually(() => expect(values, [2]));
      firstSnapshot.complete(counterBytes(1));
      await pumpEventQueue();

      expect(values, [2]);
      expect(requests, 2);
    });

    test(
      "cancellation closes a subscription while its refresh is pending",
      () async {
        final world = testWorld([signedIn(ada)]);
        await world.initialized();
        final refresh = Completer<Uint8List>();
        var requests = 0;
        world.nats.registerHandler("watch", (_) {
          requests++;
          return requests == 1 ? counterBytes(1) : refresh.future;
        });
        final values = <int>[];
        final listener = world.watchCounter().listen(values.add);
        await eventually(() => expect(values, [1]));

        world.nats.disconnect();
        await eventually(
          () => expect(world.nats.connection.subscriptionSubjects, isEmpty),
        );
        world.nats.reconnect();
        await eventually(() => expect(requests, 2));

        await listener.cancel();
        expect(world.nats.connection.subscriptionSubjects, isEmpty);
        refresh.complete(counterBytes(2));
        await pumpEventQueue();

        expect(values, [1]);
        expect(world.nats.connection.subscriptionSubjects, isEmpty);
      },
    );

    test("sequenced watch ignores duplicates and refreshes one gap", () async {
      final world = testWorld([signedIn(ada)]);
      await world.initialized();
      var snapshot = 1;
      world.nats.registerHandler("watch", (_) => counterBytes(snapshot));
      final values = <int>[];
      final listener = world
          .watchCounter(persistent: true, sequence: SequencedCollection<int>())
          .listen(values.add);
      addTearDown(listener.cancel);
      await eventually(() => expect(values, [1]));

      world.nats.connection
        ..emitMessageOnSubject("events", counterBytes(1))
        ..emitMessageOnSubject("events", counterBytes(2));
      await eventually(() => expect(values, [1, 2]));
      snapshot = 4;
      world.nats.connection.emitMessageOnSubject("events", counterBytes(4));
      await eventually(() => expect(values, [1, 2, 4]));
      world.nats.connection.emitMessageOnSubject("events", counterBytes(5));
      await eventually(() => expect(values, [1, 2, 4, 5]));

      expect(world.nats.connection.requests, hasLength(2));
    });

    test(
      "a delayed snapshot cannot rewind accepted sequence progress",
      () async {
        final world = testWorld([signedIn(ada)]);
        await world.initialized();
        final delayedSnapshot = Completer<Uint8List>();
        world.nats.registerHandler("watch", (_) => delayedSnapshot.future);
        final sequence = SequencedCollection<int>()
          ..snapshot = const SequencedSnapshot(sequence: 1, value: 10);
        final values = <int>[];
        final listener = world
            .watchCounter(
              persistent: true,
              sequence: sequence,
              snapshot: (value) => value * 10,
              reduce: (_, event) => event * 10,
            )
            .listen(values.add);
        addTearDown(listener.cancel);
        await eventually(
          () => expect(world.nats.connection.requests, isNotEmpty),
        );

        expect(
          sequence.apply(sequence: 2, reduce: (_) => 20),
          SequencedEventResult.applied,
        );
        delayedSnapshot.complete(counterBytes(1));
        await eventually(() => expect(values, isNotEmpty));

        expect(sequence.snapshot?.sequence, 2);
        expect(values, [20]);
      },
    );

    test("a lost persistent reader reacquires its subscription and reloads "
        "the snapshot", () async {
      final world = testWorld([signedIn(ada)]);
      await world.initialized();
      var snapshots = 0;
      world.nats.registerHandler("watch", (_) => counterBytes(++snapshots));
      final values = <int>[];
      final listener = world.watchCounter(persistent: true).listen(values.add);
      await eventually(() => expect(values, [1]));

      world.nats.connection.failOnSubject("events", _lost);

      // Recovery backs off before it reacquires; a second is ample.
      await eventually(
        () => expect(values, [1, 2]),
        timeout: const Duration(seconds: 1),
      );
      expect(world.nats.connection.subscriptionSubjects, ["events"]);
      await listener.cancel();
      expect(world.nats.connection.subscriptionSubjects, isEmpty);
    });

    test(
      "sequenced watch preserves stream failure when cleanup also fails",
      () async {
        final world = testWorld([signedIn(ada)]);
        await world.initialized();
        world.nats.registerHandler("watch", (_) => counterBytes(1));
        final primaryFailure = StateError("primary stream failure");
        final values = <int>[];
        final errors = <Object>[];
        final done = Completer<void>();
        world
            .watchCounter(
              persistent: true,
              sequence: SequencedCollection<int>(),
            )
            .listen(values.add, onError: errors.add, onDone: done.complete);
        await eventually(() => expect(values, [1]));

        world.nats.connection
          ..unsubscribeFailure = Exception("cleanup failure")
          ..failOnSubject("events", primaryFailure);
        await done.future;

        expect(errors, [same(primaryFailure)]);
        expect(world.nats.connection.subscriptionSubjects, isEmpty);
      },
    );

    test("sequenced watch cancellation suppresses cleanup failure", () async {
      final world = testWorld([signedIn(ada)]);
      await world.initialized();
      world.nats.registerHandler("watch", (_) => counterBytes(1));
      final errors = <Object>[];
      final listener = world
          .watchCounter(persistent: true, sequence: SequencedCollection<int>())
          .listen(null, onError: errors.add);
      await eventually(
        () => expect(world.nats.connection.subscriptionSubjects, ["events"]),
      );
      world.nats.connection.unsubscribeFailure = Exception("cleanup failure");

      await listener.cancel();

      expect(errors, isEmpty);
      expect(world.nats.connection.subscriptionSubjects, isEmpty);
    });
  });
}
