import "package:flutter_test/flutter_test.dart";
import "package:http/testing.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";

final _testRefProvider = Provider<Ref>((ref) => ref);

mixin _FixtureNatsIdentity implements NatsClient {
  @override
  String get actorId => "fixture-user";

  @override
  String? get organizationId => "fixture-organization";

  @override
  String get connectionSession => "0123456789abcdef0123456789abcdef";

  @override
  Future<NatsSubscription> subscribePersistent(
    String stream,
    String consumer,
    String filterSubject,
  ) => subscribe(filterSubject);
}

Future<void> _waitFor(bool Function() condition) async {
  await Future.doWhile(() async {
    if (condition()) return false;
    await Future<void>.delayed(Duration.zero);
    return true;
  }).timeout(const Duration(seconds: 2));
}

final class _PendingSubscribeNatsClient
    with _FixtureNatsIdentity
    implements NatsClient {
  final Completer<NatsSubscription> _pendingSubscription = Completer();
  final _TrackingNatsSubscription subscription = _TrackingNatsSubscription();
  int requests = 0;

  @override
  NatsConnectionState get connectionState => const NatsConnected();

  @override
  Stream<NatsConnectionState> get connectionStateChanges =>
      const Stream.empty();

  @override
  Future<NatsMessage> request(
    String subject,
    Uint8List payload, {
    Map<String, String> headers = const {},
    Duration timeout = const Duration(seconds: 10),
  }) {
    requests++;
    throw StateError("Request must not run after cancellation");
  }

  @override
  Future<void> publish(
    String subject,
    Uint8List payload, {
    Map<String, String> headers = const {},
  }) => throw UnsupportedError("Not used by this test");

  @override
  Future<NatsSubscription> subscribe(String subject) =>
      _pendingSubscription.future;

  void completeSubscription() => _pendingSubscription.complete(subscription);

  @override
  Future<void> close() async {}
}

final class _TrackingNatsSubscription implements NatsSubscription {
  final StreamController<NatsMessage> _messages = StreamController.broadcast();
  bool unsubscribed = false;

  @override
  Stream<NatsMessage> get messages => _messages.stream;

  @override
  Future<void> get done => _messages.done;

  @override
  Future<void> unsubscribe() async {
    if (unsubscribed) return;
    unsubscribed = true;
    await _messages.close();
  }
}

final class _PendingReconnectNatsClient
    with _FixtureNatsIdentity
    implements NatsClient {
  final _lifecycle = StreamController<NatsConnectionState>.broadcast(
    sync: true,
  );
  final acquisitions = <Completer<NatsSubscription>>[];
  final subscriptions = <_TrackingNatsSubscription>[];
  NatsConnectionState _state = const NatsConnected();
  int activeAcquisitions = 0;
  int maximumActiveAcquisitions = 0;
  int requests = 0;

  @override
  NatsConnectionState get connectionState => _state;

  @override
  Stream<NatsConnectionState> get connectionStateChanges => _lifecycle.stream;

  void setConnectionState(NatsConnectionState value) {
    _state = value;
    _lifecycle.add(value);
  }

  @override
  Future<NatsSubscription> subscribePersistent(
    String stream,
    String consumer,
    String filterSubject,
  ) {
    activeAcquisitions++;
    maximumActiveAcquisitions = max(
      maximumActiveAcquisitions,
      activeAcquisitions,
    );
    final acquisition = Completer<NatsSubscription>();
    acquisitions.add(acquisition);
    return acquisition.future.whenComplete(() => activeAcquisitions--);
  }

  void completeAcquisition(int index) {
    final subscription = _TrackingNatsSubscription();
    subscriptions.add(subscription);
    acquisitions[index].complete(subscription);
  }

  @override
  Future<NatsMessage> request(
    String subject,
    Uint8List payload, {
    Map<String, String> headers = const {},
    Duration timeout = const Duration(seconds: 10),
  }) async {
    requests++;
    return NatsMessage(
      skir.Duration.serializer.toBytes(skir.Duration(milliseconds: requests)),
    );
  }

  @override
  Future<void> publish(
    String subject,
    Uint8List payload, {
    Map<String, String> headers = const {},
  }) => throw UnsupportedError("Not used by this test");

  @override
  Future<NatsSubscription> subscribe(String subject) =>
      throw UnsupportedError("Not used by this test");

  @override
  Future<void> close() => _lifecycle.close();
}

final class _FailingOrderedNatsClient
    with _FixtureNatsIdentity
    implements NatsClient {
  _FailingOrderedNatsClient({required this.unsubscribeError});

  final Exception unsubscribeError;
  late final _FailingOrderedNatsSubscription subscription =
      _FailingOrderedNatsSubscription(unsubscribeError);
  int requests = 0;

  @override
  NatsConnectionState get connectionState => const NatsConnected();

  @override
  Stream<NatsConnectionState> get connectionStateChanges =>
      const Stream.empty();

  @override
  Future<NatsMessage> request(
    String subject,
    Uint8List payload, {
    Map<String, String> headers = const {},
    Duration timeout = const Duration(seconds: 10),
  }) async {
    requests++;
    return NatsMessage(
      skir.Duration.serializer.toBytes(skir.Duration(milliseconds: 1)),
    );
  }

  @override
  Future<void> publish(
    String subject,
    Uint8List payload, {
    Map<String, String> headers = const {},
  }) => throw UnsupportedError("Not used by this test");

  @override
  Future<NatsSubscription> subscribe(String subject) =>
      throw UnsupportedError("Not used by this test");

  @override
  Future<NatsSubscription> subscribePersistent(
    String stream,
    String consumer,
    String filterSubject,
  ) async => subscription;

  @override
  Future<void> close() async {}
}

final class _FailingOrderedNatsSubscription implements NatsSubscription {
  _FailingOrderedNatsSubscription(this.unsubscribeError);

  final Exception unsubscribeError;
  final StreamController<NatsMessage> _messages = StreamController();
  int unsubscribeCount = 0;

  @override
  Stream<NatsMessage> get messages => _messages.stream;

  @override
  Future<void> get done => _messages.done;

  void fail(Object error, StackTrace stackTrace) {
    _messages.addError(error, stackTrace);
    unawaited(_messages.close());
  }

  @override
  Future<void> unsubscribe() async {
    unsubscribeCount++;
    await _messages.close();
    throw unsubscribeError;
  }
}

final class _RecoveringPersistentNatsClient
    with _FixtureNatsIdentity
    implements NatsClient {
  final List<_RecoverableSubscription> subscriptions = [];
  int requests = 0;

  @override
  NatsConnectionState get connectionState => const NatsConnected();

  @override
  Stream<NatsConnectionState> get connectionStateChanges =>
      const Stream.empty();

  @override
  Future<NatsMessage> request(
    String subject,
    Uint8List payload, {
    Map<String, String> headers = const {},
    Duration? timeout,
  }) async {
    requests++;
    return NatsMessage(
      skir.Duration.serializer.toBytes(skir.Duration(milliseconds: requests)),
    );
  }

  @override
  Future<NatsSubscription> subscribePersistent(
    String stream,
    String consumer,
    String filterSubject,
  ) async {
    final subscription = _RecoverableSubscription();
    subscriptions.add(subscription);
    return subscription;
  }

  @override
  Future<void> publish(
    String subject,
    Uint8List payload, {
    Map<String, String> headers = const {},
  }) => throw UnsupportedError("Not used by this test");

  @override
  Future<NatsSubscription> subscribe(String subject) =>
      throw UnsupportedError("Not used by this test");

  @override
  Future<void> close() async {}
}

final class _RecoverableSubscription implements NatsSubscription {
  final StreamController<NatsMessage> _messages = StreamController();
  int unsubscribeCount = 0;

  @override
  Stream<NatsMessage> get messages => _messages.stream;

  @override
  Future<void> get done => _messages.done;

  void lose() {
    _messages.addError(
      const NatsClientException(
        kind: NatsFailureKind.unavailable,
        message: "Named consumer was lost",
      ),
    );
    unawaited(_messages.close());
  }

  @override
  Future<void> unsubscribe() async {
    unsubscribeCount++;
    await _messages.close();
  }
}

void _admitPermissions(
  FakeNatsClient client,
  Iterable<skir.RecordId> realms, {
  VoidCallback? onQuery,
}) {
  final organization = client.organizationId;
  final grant = panelTransportPermissions(
    actorId: client.actorId,
    organizationId: organization == null
        ? null
        : skir.recordId("organization:$organization"),
    connectionSession: client.connectionSession,
    realmIds: realms,
  );
  client.registerHandler(r"$SYS.REQ.USER.INFO", (_) {
    onQuery?.call();
    return Uint8List.fromList(
      utf8.encode(
        jsonEncode({
          "data": {
            "permissions": {
              "publish": {"allow": grant.publish.toList()},
              "subscribe": {"allow": grant.subscribe.toList()},
            },
          },
        }),
      ),
    );
  });
}

final class _FakeTelemetry implements PanelTelemetry {
  @override
  Future<T> traceNats<T>({
    required String subject,
    required int payloadSize,
    required String operationName,
    required Future<T> Function(Map<String, String> headers) operation,
  }) => operation({
    "traceparent": "00-4bf92f3577b34da6a3ce929d0e0e4736-00f067aa0ba902b7-01",
    "tracestate": "vendor=value",
  });

  @override
  Future<Response> traceHttp({
    required String method,
    required Uri uri,
    required Future<Response> Function(Map<String, String> headers) operation,
  }) => operation({
    "traceparent": "00-4bf92f3577b34da6a3ce929d0e0e4736-00f067aa0ba902b7-01",
    "tracestate": "vendor=value",
  });
}

void main() {
  group("sentinelCredentials", () {
    test("forwards trace headers and decodes a successful response", () async {
      late Request capturedRequest;
      final responseBytes = skir.GetSentinelCredentialsResponse.serializer
          .toBytes(
            skir.GetSentinelCredentialsResponse.createSuccess(
              jwt: "test-jwt",
              seed: "test-seed",
            ),
          );
      final client = MockClient((request) async {
        capturedRequest = request;
        return Response.bytes(responseBytes, 200);
      });
      final container = ProviderContainer(
        retry: (retryCount, error) => null,
        overrides: [
          panelHttpClientProvider.overrideWithValue(client),
          panelTelemetryProvider.overrideWithValue(AsyncData(_FakeTelemetry())),
        ],
      );
      addTearDown(container.dispose);

      final result = await container.read(sentinelCredentialsProvider.future);

      expect(result.jwt, "test-jwt");
      expect(capturedRequest.method, "GET");
      expect(capturedRequest.headers["traceparent"], startsWith("00-4bf92f"));
      expect(capturedRequest.headers["tracestate"], "vendor=value");
    });

    test("preserves a non-success HTTP status", () async {
      final container = ProviderContainer(
        retry: (retryCount, error) => null,
        overrides: [
          panelHttpClientProvider.overrideWithValue(
            MockClient((_) async => Response("unavailable", 503)),
          ),
          panelTelemetryProvider.overrideWithValue(AsyncData(_FakeTelemetry())),
        ],
      );
      addTearDown(container.dispose);

      await expectLater(
        container.read(sentinelCredentialsProvider.future),
        throwsA(
          isA<ApiException>()
              .having((error) => error.code, "code", 503)
              .having(
                (error) => error.message,
                "message",
                "Failed to fetch sentinel credentials",
              ),
        ),
      );
    });

    test("rethrows the original HTTP transport exception", () async {
      final error = StateError("network failed");
      final container = ProviderContainer(
        retry: (retryCount, error) => null,
        overrides: [
          panelHttpClientProvider.overrideWithValue(
            MockClient((_) => Future<Response>.error(error)),
          ),
          panelTelemetryProvider.overrideWithValue(AsyncData(_FakeTelemetry())),
        ],
      );
      addTearDown(container.dispose);

      await expectLater(
        container.read(sentinelCredentialsProvider.future),
        throwsA(same(error)),
      );
    });
  });

  group("RefNatsExtension.requestSkir", () {
    late FakeNatsClient mockClient;
    late ProviderContainer container;

    setUp(() {
      mockClient = FakeNatsClient();
      container = ProviderContainer(
        overrides: [
          natsProvider.overrideWithValue(mockClient),
          panelTelemetryProvider.overrideWithValue(AsyncData(_FakeTelemetry())),
        ],
      );
    });

    tearDown(() {
      container.dispose();
      mockClient.dispose();
    });

    test("returns deserialized response on successful request", () async {
      final responseProto = skir.GetSentinelCredentialsResponse.createSuccess(
        jwt: "test-jwt",
        seed: "test-seed",
      );

      mockClient.registerHandler(
        "test.subject",
        (requestData) => skir.GetSentinelCredentialsResponse.serializer.toBytes(
          responseProto,
        ),
      );

      final response = await container
          .read(_testRefProvider)
          .requestSkir(
            SkirRouteOperation(
              subject: "test.subject",
              requestBytes: skir.GetSentinelCredentialsRequest.serializer
                  .toBytes(skir.GetSentinelCredentialsRequest()),
              responseSerializer:
                  skir.GetSentinelCredentialsResponse.serializer,
            ),
          );

      expect(
        response,
        isA<skir.GetSentinelCredentialsResponse_successWrapper>(),
      );
      final success =
          (response as skir.GetSentinelCredentialsResponse_successWrapper)
              .value;
      expect(success.jwt, equals("test-jwt"));
      expect(success.seed, equals("test-seed"));
      expect(
        mockClient.requests.single.headers["traceparent"],
        startsWith("00-4bf92f"),
      );
      expect(mockClient.requests.single.headers["tracestate"], "vendor=value");
    });

    test("sends request bytes correctly", () async {
      final request = skir.GetSentinelCredentialsRequest();

      Uint8List? capturedRequestData;
      mockClient.registerHandler("test.subject", (requestData) {
        capturedRequestData = Uint8List.fromList(requestData);
        return skir.GetSentinelCredentialsResponse.serializer.toBytes(
          skir.GetSentinelCredentialsResponse.createSuccess(jwt: "", seed: ""),
        );
      });

      await container
          .read(_testRefProvider)
          .requestSkir(
            SkirRouteOperation(
              subject: "test.subject",
              requestBytes: skir.GetSentinelCredentialsRequest.serializer
                  .toBytes(request),
              responseSerializer:
                  skir.GetSentinelCredentialsResponse.serializer,
            ),
          );

      expect(capturedRequestData, isNotNull);

      final decodedRequest = skir.GetSentinelCredentialsRequest.serializer
          .fromBytes(capturedRequestData!);
      expect(decodedRequest, isA<skir.GetSentinelCredentialsRequest>());
    });

    test("throws timeout when no handler registered", () async {
      expect(
        () => container
            .read(_testRefProvider)
            .requestSkir(
              SkirRouteOperation(
                subject: "unregistered.subject",
                requestBytes: skir.GetSentinelCredentialsRequest.serializer
                    .toBytes(skir.GetSentinelCredentialsRequest()),
                responseSerializer:
                    skir.GetSentinelCredentialsResponse.serializer,
              ),
            ),
        throwsA(isA<TimeoutException>()),
      );
    });

    test("throws exception when client not connected", () async {
      mockClient.setConnectionState(
        const NatsReconnecting(
          NatsClientException(
            kind: NatsFailureKind.unavailable,
            message: "NATS service is unavailable",
          ),
        ),
      );

      expect(
        () => container
            .read(_testRefProvider)
            .requestSkir(
              SkirRouteOperation(
                subject: "test.subject",
                requestBytes: skir.GetSentinelCredentialsRequest.serializer
                    .toBytes(skir.GetSentinelCredentialsRequest()),
                responseSerializer:
                    skir.GetSentinelCredentialsResponse.serializer,
              ),
            ),
        throwsA(isA<NatsClientException>()),
      );
    });
  });

  group("RefNatsExtension.watchProjection", () {
    late FakeNatsClient mockClient;
    late ProviderContainer container;

    setUp(() {
      mockClient = FakeNatsClient();
      container = ProviderContainer(
        overrides: [
          natsProvider.overrideWithValue(mockClient),
          panelTelemetryProvider.overrideWithValue(AsyncData(_FakeTelemetry())),
        ],
      );
    });

    tearDown(() {
      container.dispose();
      mockClient.dispose();
    });

    test("subscribes before the traced initial Skir request", () async {
      const listenSubject = "test.responses";
      var subscribedBeforeSnapshot = false;
      mockClient.registerHandler("test.watch", (_) {
        subscribedBeforeSnapshot = mockClient.subscriptionSubjects.contains(
          listenSubject,
        );
        return skir.GetSentinelCredentialsResponse.serializer.toBytes(
          skir.GetSentinelCredentialsResponse.createSuccess(
            jwt: "test-jwt",
            seed: "test-seed",
          ),
        );
      });
      final stream = container
          .read(_testRefProvider)
          .watchProjection<
            skir.GetSentinelCredentialsResponse,
            skir.GetSentinelCredentialsResponse,
            skir.GetSentinelCredentialsResponse
          >(
            subject: "test.watch",
            eventSubject: listenSubject,
            requestBytes: Uint8List.fromList([1, 2, 3]),
            responseSerializer: skir.GetSentinelCredentialsResponse.serializer,
            eventSerializer: skir.GetSentinelCredentialsResponse.serializer,
            snapshot: (response) => response,
            reduce: (_, event) => event,
            delivery: const ProjectionDelivery.ephemeral(),
            reconciliation: const ProjectionReconciliation.latest(),
          );
      final firstResponse = stream.first;

      while (mockClient.requests.isEmpty) {
        await Future<void>.delayed(Duration.zero);
      }

      final request = mockClient.requests.single;
      expect(request.subject, "test.watch");
      expect(request.headers["traceparent"], startsWith("00-4bf92f"));
      expect(request.headers["tracestate"], "vendor=value");
      expect(subscribedBeforeSnapshot, isTrue);

      expect(await firstResponse, isA<skir.GetSentinelCredentialsResponse>());
    });

    test("unsubscribes when the response stream is canceled", () async {
      const listenSubject = "test.cancel.responses";
      mockClient.registerHandler(
        "test.cancel",
        (_) => skir.GetSentinelCredentialsResponse.serializer.toBytes(
          skir.GetSentinelCredentialsResponse.createSuccess(
            jwt: "test-jwt",
            seed: "test-seed",
          ),
        ),
      );
      final stream = container
          .read(_testRefProvider)
          .watchProjection<
            skir.GetSentinelCredentialsResponse,
            skir.GetSentinelCredentialsResponse,
            skir.GetSentinelCredentialsResponse
          >(
            subject: "test.cancel",
            eventSubject: listenSubject,
            requestBytes: Uint8List.fromList([1, 2, 3]),
            responseSerializer: skir.GetSentinelCredentialsResponse.serializer,
            eventSerializer: skir.GetSentinelCredentialsResponse.serializer,
            snapshot: (response) => response,
            reduce: (_, event) => event,
            delivery: const ProjectionDelivery.ephemeral(),
            reconciliation: const ProjectionReconciliation.latest(),
          );
      final subscription = stream.listen(null);

      while (mockClient.requests.isEmpty) {
        await Future<void>.delayed(Duration.zero);
      }

      expect(mockClient.subscriptionSubjects, contains(listenSubject));

      await subscription.cancel();

      expect(mockClient.subscriptionSubjects, isEmpty);
    });

    test("cancellation remains safe while subscribe is pending", () async {
      final client = _PendingSubscribeNatsClient();
      final pendingContainer = ProviderContainer(
        overrides: [
          natsProvider.overrideWithValue(client),
          panelTelemetryProvider.overrideWithValue(AsyncData(_FakeTelemetry())),
        ],
      );
      addTearDown(pendingContainer.dispose);
      final stream = pendingContainer
          .read(_testRefProvider)
          .watchProjection<
            skir.GetSentinelCredentialsResponse,
            skir.GetSentinelCredentialsResponse,
            skir.GetSentinelCredentialsResponse
          >(
            subject: "test.pending",
            eventSubject: "test.pending.responses",
            requestBytes: Uint8List(0),
            responseSerializer: skir.GetSentinelCredentialsResponse.serializer,
            eventSerializer: skir.GetSentinelCredentialsResponse.serializer,
            snapshot: (response) => response,
            reduce: (_, event) => event,
            delivery: const ProjectionDelivery.ephemeral(),
            reconciliation: const ProjectionReconciliation.latest(),
          );
      final listener = stream.listen(null);
      await Future<void>.delayed(Duration.zero);

      final cancellation = listener.cancel();
      client.completeSubscription();
      await cancellation;
      await pumpEventQueue();

      expect(client.subscription.unsubscribed, isTrue);
      expect(client.requests, isZero);
    });

    test("reconnect serializes a pending persistent acquisition", () async {
      final client = _PendingReconnectNatsClient();
      final pendingContainer = ProviderContainer(
        overrides: [
          natsProvider.overrideWithValue(client),
          panelTelemetryProvider.overrideWithValue(AsyncData(_FakeTelemetry())),
        ],
      );
      addTearDown(pendingContainer.dispose);
      addTearDown(client.close);
      final values = <int>[];
      final listener = pendingContainer
          .read(_testRefProvider)
          .watchProjection<int, skir.Duration, skir.Duration>(
            subject: "test.pending.reconnect",
            eventSubject: "test.pending.reconnect.changed",
            requestBytes: Uint8List(0),
            responseSerializer: skir.Duration.serializer,
            eventSerializer: skir.Duration.serializer,
            snapshot: (response) => response.milliseconds,
            reduce: (_, event) => event.milliseconds,
            delivery: const ProjectionDelivery.persistent(
              stream: "TYPEWRITER_FIXTURE",
              consumer: "TW_fixture",
            ),
            reconciliation: const ProjectionReconciliation.latest(),
          )
          .listen(values.add);
      await _waitFor(() => client.acquisitions.length == 1);

      client
        ..setConnectionState(
          const NatsReconnecting(
            NatsClientException(
              kind: NatsFailureKind.unavailable,
              message: "Connection interrupted",
            ),
          ),
        )
        ..setConnectionState(const NatsConnected());
      await pumpEventQueue();
      expect(client.acquisitions, hasLength(1));

      client.completeAcquisition(0);
      await _waitFor(() => client.acquisitions.length == 2);
      expect(client.subscriptions.single.unsubscribed, isTrue);
      client.completeAcquisition(1);
      await _waitFor(() => values.isNotEmpty);

      expect(client.maximumActiveAcquisitions, 1);
      expect(values, [1]);
      await listener.cancel();
    });

    test(
      "reconnect replaces the subscription and reloads its baseline",
      () async {
        var snapshot = 1;
        mockClient.registerHandler(
          "test.reconnect",
          (_) => skir.Duration.serializer.toBytes(
            skir.Duration(milliseconds: snapshot),
          ),
        );
        final values = <int>[];
        final listener = container
            .read(_testRefProvider)
            .watchProjection<int, skir.Duration, skir.Duration>(
              subject: "test.reconnect",
              eventSubject: "test.reconnect.changed",
              requestBytes: Uint8List(0),
              responseSerializer: skir.Duration.serializer,
              eventSerializer: skir.Duration.serializer,
              snapshot: (response) => response.milliseconds,
              reduce: (_, event) => event.milliseconds,
              delivery: const ProjectionDelivery.ephemeral(),
              reconciliation: const ProjectionReconciliation.latest(),
            )
            .listen(values.add);

        await _waitFor(() => values.length == 1);
        mockClient.emitMessageOnSubject(
          "test.reconnect.changed",
          skir.Duration.serializer.toBytes(skir.Duration(milliseconds: 2)),
        );
        await _waitFor(() => values.length == 2);

        mockClient.setConnectionState(
          const NatsReconnecting(
            NatsClientException(
              kind: NatsFailureKind.unavailable,
              message: "Connection interrupted",
            ),
          ),
        );
        await _waitFor(() => mockClient.subscriptionSubjects.isEmpty);
        snapshot = 4;
        mockClient
          ..emitMessageOnSubject(
            "test.reconnect.changed",
            skir.Duration.serializer.toBytes(skir.Duration(milliseconds: 3)),
          )
          ..setConnectionState(const NatsConnected());
        await _waitFor(() => values.length == 3);

        expect(values, [1, 2, 4]);
        expect(mockClient.requests, hasLength(2));
        expect(mockClient.subscriptionSubjects, ["test.reconnect.changed"]);
        await listener.cancel();
      },
    );

    test("a stale reconnect generation cannot publish its snapshot", () async {
      final firstSnapshot = Completer<Uint8List>();
      var requests = 0;
      mockClient.registerHandler("test.stale.generation", (_) {
        requests++;
        if (requests == 1) return firstSnapshot.future;
        return skir.Duration.serializer.toBytes(skir.Duration(milliseconds: 2));
      });
      final values = <int>[];
      final listener = container
          .read(_testRefProvider)
          .watchProjection<int, skir.Duration, skir.Duration>(
            subject: "test.stale.generation",
            eventSubject: "test.stale.generation.changed",
            requestBytes: Uint8List(0),
            responseSerializer: skir.Duration.serializer,
            eventSerializer: skir.Duration.serializer,
            snapshot: (response) => response.milliseconds,
            reduce: (_, event) => event.milliseconds,
            delivery: const ProjectionDelivery.ephemeral(),
            reconciliation: const ProjectionReconciliation.latest(),
          )
          .listen(values.add);

      await _waitFor(() => requests == 1);
      mockClient
        ..setConnectionState(
          const NatsReconnecting(
            NatsClientException(
              kind: NatsFailureKind.unavailable,
              message: "Connection interrupted",
            ),
          ),
        )
        ..setConnectionState(const NatsConnected());
      await _waitFor(() => values.length == 1);

      firstSnapshot.complete(
        skir.Duration.serializer.toBytes(skir.Duration(milliseconds: 1)),
      );
      await pumpEventQueue();

      expect(values, [2]);
      expect(requests, 2);
      await listener.cancel();
    });

    test(
      "cancellation closes a subscription while its refresh is pending",
      () async {
        final refresh = Completer<Uint8List>();
        var requests = 0;
        mockClient.registerHandler("test.refresh.cancel", (_) {
          requests++;
          if (requests == 1) {
            return skir.Duration.serializer.toBytes(
              skir.Duration(milliseconds: 1),
            );
          }
          return refresh.future;
        });
        final values = <int>[];
        final listener = container
            .read(_testRefProvider)
            .watchProjection<int, skir.Duration, skir.Duration>(
              subject: "test.refresh.cancel",
              eventSubject: "test.refresh.cancel.changed",
              requestBytes: Uint8List(0),
              responseSerializer: skir.Duration.serializer,
              eventSerializer: skir.Duration.serializer,
              snapshot: (response) => response.milliseconds,
              reduce: (_, event) => event.milliseconds,
              delivery: const ProjectionDelivery.ephemeral(),
              reconciliation: const ProjectionReconciliation.latest(),
            )
            .listen(values.add);
        await _waitFor(() => values.isNotEmpty);

        mockClient.setConnectionState(
          const NatsReconnecting(
            NatsClientException(
              kind: NatsFailureKind.unavailable,
              message: "Connection interrupted",
            ),
          ),
        );
        await _waitFor(() => mockClient.subscriptionSubjects.isEmpty);
        mockClient.setConnectionState(const NatsConnected());
        await _waitFor(() => requests == 2);

        await listener.cancel();
        expect(mockClient.subscriptionSubjects, isEmpty);
        refresh.complete(
          skir.Duration.serializer.toBytes(skir.Duration(milliseconds: 2)),
        );
        await pumpEventQueue();

        expect(values, [1]);
        expect(mockClient.subscriptionSubjects, isEmpty);
      },
    );

    test("sequenced watch ignores duplicates and refreshes one gap", () async {
      var snapshotSequence = 1;
      final sequenceState = SequencedCollection<int>();
      mockClient.registerHandler(
        "test.sequenced.watch",
        (_) => skir.Duration.serializer.toBytes(
          skir.Duration(milliseconds: snapshotSequence),
        ),
      );
      final values = <int>[];
      final subscription = container
          .read(_testRefProvider)
          .watchProjection<int, skir.Duration, skir.Duration>(
            subject: "test.sequenced.watch",
            eventSubject: "test.sequenced.changed",
            requestBytes: Uint8List(0),
            responseSerializer: skir.Duration.serializer,
            eventSerializer: skir.Duration.serializer,
            snapshot: (response) => response.milliseconds,
            reduce: (_, event) => event.milliseconds,
            delivery: const ProjectionDelivery.persistent(
              stream: "TYPEWRITER_MEMBERSHIP",
              consumer: "TW_nats_test_one",
            ),
            reconciliation: ProjectionReconciliation.sequenced(
              snapshotSequence: (response) => response.milliseconds,
              eventSequence: (event) => event.milliseconds,
              sequenceState: sequenceState,
            ),
          )
          .listen(values.add);

      while (values.isEmpty) {
        await Future<void>.delayed(Duration.zero);
      }
      mockClient
        ..emitMessageOnSubject(
          "test.sequenced.changed",
          skir.Duration.serializer.toBytes(skir.Duration(milliseconds: 1)),
        )
        ..emitMessageOnSubject(
          "test.sequenced.changed",
          skir.Duration.serializer.toBytes(skir.Duration(milliseconds: 2)),
        );
      while (values.length < 2) {
        await Future<void>.delayed(Duration.zero);
      }

      snapshotSequence = 4;
      mockClient.emitMessageOnSubject(
        "test.sequenced.changed",
        skir.Duration.serializer.toBytes(skir.Duration(milliseconds: 4)),
      );
      while (values.length < 3) {
        await Future<void>.delayed(Duration.zero);
      }
      mockClient.emitMessageOnSubject(
        "test.sequenced.changed",
        skir.Duration.serializer.toBytes(skir.Duration(milliseconds: 5)),
      );
      while (values.length < 4) {
        await Future<void>.delayed(Duration.zero);
      }

      expect(values, [1, 2, 4, 5]);
      expect(mockClient.requests, hasLength(2));
      await subscription.cancel();
    });

    test(
      "a delayed snapshot cannot rewind accepted sequence progress",
      () async {
        final delayedSnapshot = Completer<Uint8List>();
        final sequenceState = SequencedCollection<int>()
          ..snapshot = const SequencedSnapshot(sequence: 1, value: 10);
        mockClient.registerHandler(
          "test.sequenced.delayed",
          (_) => delayedSnapshot.future,
        );
        final values = <int>[];
        final listener = container
            .read(_testRefProvider)
            .watchProjection<int, skir.Duration, skir.Duration>(
              subject: "test.sequenced.delayed",
              eventSubject: "test.sequenced.delayed.changed",
              requestBytes: Uint8List(0),
              responseSerializer: skir.Duration.serializer,
              eventSerializer: skir.Duration.serializer,
              snapshot: (response) => response.milliseconds * 10,
              reduce: (_, event) => event.milliseconds * 10,
              delivery: const ProjectionDelivery.persistent(
                stream: "TYPEWRITER_MEMBERSHIP",
                consumer: "TW_nats_test_two",
              ),
              reconciliation: ProjectionReconciliation.sequenced(
                snapshotSequence: (response) => response.milliseconds,
                eventSequence: (event) => event.milliseconds,
                sequenceState: sequenceState,
              ),
            )
            .listen(values.add);

        await _waitFor(() => mockClient.requests.isNotEmpty);
        expect(
          sequenceState.apply(sequence: 2, reduce: (_) => 20),
          SequencedEventResult.applied,
        );
        delayedSnapshot.complete(
          skir.Duration.serializer.toBytes(skir.Duration(milliseconds: 1)),
        );
        await _waitFor(() => values.isNotEmpty);

        expect(sequenceState.snapshot?.sequence, 2);
        expect(values, [20]);
        await listener.cancel();
      },
    );

    test("lost persistent reader reacquires lease and snapshot", () async {
      final client = _RecoveringPersistentNatsClient();
      final recoveringContainer = ProviderContainer(
        overrides: [
          natsProvider.overrideWithValue(client),
          panelTelemetryProvider.overrideWithValue(AsyncData(_FakeTelemetry())),
        ],
      );
      addTearDown(recoveringContainer.dispose);
      final values = <int>[];
      final subscription = recoveringContainer
          .read(_testRefProvider)
          .watchProjection<int, skir.Duration, skir.Duration>(
            subject: "test.recovery",
            eventSubject: "test.recovery.changed",
            requestBytes: Uint8List(0),
            responseSerializer: skir.Duration.serializer,
            eventSerializer: skir.Duration.serializer,
            snapshot: (response) => response.milliseconds,
            reduce: (_, event) => event.milliseconds,
            delivery: const ProjectionDelivery.persistent(
              stream: "TYPEWRITER_MEMBERSHIP",
              consumer: "TW_nats_reader_recovery",
            ),
            reconciliation: const ProjectionReconciliation.latest(),
          )
          .listen(values.add);

      while (values.isEmpty) {
        await Future<void>.delayed(Duration.zero);
      }
      client.subscriptions.single.lose();
      while (client.subscriptions.length < 2 || values.length < 2) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }

      expect(values, [1, 2]);
      expect(client.requests, 2);
      expect(client.subscriptions.first.unsubscribeCount, 1);
      await subscription.cancel();
      expect(client.subscriptions.last.unsubscribeCount, 1);
    });

    test(
      "sequenced watch preserves stream failure when cleanup also fails",
      () async {
        final primaryFailure = StateError("primary stream failure");
        final cleanupFailure = Exception("cleanup failure");
        final client = _FailingOrderedNatsClient(
          unsubscribeError: cleanupFailure,
        );
        final failingContainer = ProviderContainer(
          overrides: [
            natsProvider.overrideWithValue(client),
            panelTelemetryProvider.overrideWithValue(
              AsyncData(_FakeTelemetry()),
            ),
          ],
        );
        addTearDown(failingContainer.dispose);
        final values = <int>[];
        final errors = <Object>[];
        final completed = Completer<void>();
        failingContainer
            .read(_testRefProvider)
            .watchProjection<int, skir.Duration, skir.Duration>(
              subject: "test.sequenced.failure",
              eventSubject: "test.sequenced.failure.changed",
              requestBytes: Uint8List(0),
              responseSerializer: skir.Duration.serializer,
              eventSerializer: skir.Duration.serializer,
              snapshot: (response) => response.milliseconds,
              reduce: (_, event) => event.milliseconds,
              delivery: const ProjectionDelivery.persistent(
                stream: "TYPEWRITER_MEMBERSHIP",
                consumer: "TW_nats_test_three",
              ),
              reconciliation: ProjectionReconciliation.sequenced(
                snapshotSequence: (response) => response.milliseconds,
                eventSequence: (event) => event.milliseconds,
                sequenceState: SequencedCollection<int>(),
              ),
            )
            .listen(
              values.add,
              onError: (Object error, StackTrace _) => errors.add(error),
              onDone: completed.complete,
            );

        while (values.isEmpty) {
          await Future<void>.delayed(Duration.zero);
        }
        client.subscription.fail(primaryFailure, StackTrace.current);
        await completed.future;

        expect(errors, [same(primaryFailure)]);
        expect(client.subscription.unsubscribeCount, 1);
      },
    );

    test("sequenced watch cancellation suppresses cleanup failure", () async {
      final client = _FailingOrderedNatsClient(
        unsubscribeError: Exception("cleanup failure"),
      );
      final failingContainer = ProviderContainer(
        overrides: [
          natsProvider.overrideWithValue(client),
          panelTelemetryProvider.overrideWithValue(AsyncData(_FakeTelemetry())),
        ],
      );
      addTearDown(failingContainer.dispose);
      final errors = <Object>[];
      final listener = failingContainer
          .read(_testRefProvider)
          .watchProjection<int, skir.Duration, skir.Duration>(
            subject: "test.sequenced.cancel",
            eventSubject: "test.sequenced.cancel.changed",
            requestBytes: Uint8List(0),
            responseSerializer: skir.Duration.serializer,
            eventSerializer: skir.Duration.serializer,
            snapshot: (response) => response.milliseconds,
            reduce: (_, event) => event.milliseconds,
            delivery: const ProjectionDelivery.persistent(
              stream: "TYPEWRITER_MEMBERSHIP",
              consumer: "TW_nats_test_four",
            ),
            reconciliation: ProjectionReconciliation.sequenced(
              snapshotSequence: (response) => response.milliseconds,
              eventSequence: (event) => event.milliseconds,
              sequenceState: SequencedCollection<int>(),
            ),
          )
          .listen(
            null,
            onError: (Object error, StackTrace _) => errors.add(error),
          );

      while (client.requests == 0) {
        await Future<void>.delayed(Duration.zero);
      }
      await listener.cancel();

      expect(errors, isEmpty);
      expect(client.subscription.unsubscribeCount, 1);
    });

    test("sequenced collection rejects historical mutation responses", () {
      final sequenceState = SequencedCollection<int>()
        ..snapshot = const SequencedSnapshot(sequence: 3, value: 30);

      expect(
        sequenceState.apply(sequence: 2, reduce: (_) => 20),
        SequencedEventResult.duplicate,
      );
      expect(sequenceState.value, 30);
      expect(
        sequenceState.apply(sequence: 5, reduce: (_) => 50),
        SequencedEventResult.gap,
      );
      expect(sequenceState.value, 30);
      expect(
        sequenceState.apply(sequence: 4, reduce: (_) => 40),
        SequencedEventResult.applied,
      );
      expect(sequenceState.value, 40);
    });
  });

  group("NatsLifecycle", () {
    late FakeNatsClient mockClient;

    setUp(() {
      mockClient = FakeNatsClient();
    });

    tearDown(() {
      mockClient.dispose();
    });

    test("initial state matches client state", () {
      expect(mockClient.connectionState, isA<NatsConnected>());
    });

    test("state updates retain reconnect failure", () async {
      const failure = NatsClientException(
        kind: NatsFailureKind.timeout,
        message: "NATS operation timed out",
      );
      final states = <NatsConnectionState>[];
      final subscription = mockClient.connectionStateChanges.listen(states.add);

      mockClient
        ..setConnectionState(const NatsFailed(failure))
        ..setConnectionState(const NatsReconnecting(failure))
        ..setConnectionState(const NatsConnected());

      await Future<void>.delayed(Duration.zero);

      expect(states[0], isA<NatsFailed>());
      expect((states[0] as NatsFailed).failure, same(failure));
      expect(states[1], isA<NatsReconnecting>());
      expect((states[1] as NatsReconnecting).failure, same(failure));
      expect(states[2], isA<NatsConnected>());

      await subscription.cancel();
    });
  });

  group("Nats retry", () {
    test("rejects insufficient grants before replacing the client", () async {
      final existingRealm = skir.recordId("realm_instance:realm1");
      final demandedRealm = skir.recordId("realm_instance:realm2");
      final clients = <FakeNatsClient>[];
      final sessions = [
        "00000000000000000000000000000000",
        "11111111111111111111111111111111",
        "22222222222222222222222222222222",
      ];
      final container = ProviderContainer(
        overrides: [
          accessTokenProvider.overrideWithValue(
            const AsyncData(AccessToken(token: "access-token")),
          ),
          authUserInfoProvider.overrideWithValue(
            const AsyncData(UserInfo(sub: "user-id")),
          ),
          sentinelCredentialsProvider.overrideWithValue(
            AsyncData(
              skir.GetSentinelCredentialsResponse_Success(
                jwt: "sentinel-jwt",
                seed: "sentinel-seed",
              ),
            ),
          ),
          organizationIdProvider.overrideWithValue(
            skir.recordId("organization:test"),
          ),
          natsConnectionSessionFactoryProvider.overrideWithValue(
            () => sessions[clients.length],
          ),
          natsClientFactoryProvider.overrideWithValue((configuration) {
            final client = FakeNatsClient(
              actorId: configuration.actorId,
              organizationId: configuration.organizationId,
              connectionSession: configuration.connectionSession,
            );
            final index = clients.length;
            _admitPermissions(
              client,
              index == 2 ? [existingRealm, demandedRealm] : [existingRealm],
              onQuery: index == 1
                  ? () => expect(
                      clients.first.connectionState,
                      isA<NatsConnected>(),
                    )
                  : null,
            );
            clients.add(client);
            return client;
          }),
        ],
      );
      addTearDown(() async {
        container.dispose();
        for (final client in clients) {
          await client.dispose();
        }
      });
      final firstClient = container.read(natsProvider);
      expect(container.read(natsProvider), same(firstClient));
      await container.read(natsProvider.notifier).ensureRealmsAdmitted({
        existingRealm,
      });

      await expectLater(
        container.read(natsProvider.notifier).ensureRealmsAdmitted({
          existingRealm,
          demandedRealm,
        }),
        throwsA(
          isA<NatsClientException>().having(
            (error) => error.kind,
            "kind",
            NatsFailureKind.permission,
          ),
        ),
      );
      expect(container.read(natsProvider), same(firstClient));
      expect(firstClient.connectionState, isA<NatsConnected>());
      expect(clients[1].connectionState, isA<NatsClosed>());

      await container.read(natsProvider.notifier).retry();
      expect(container.read(natsProvider), same(clients[2]));
      expect((await clients[2].queryPermissions()).admittedRealms(clients[2]), {
        existingRealm,
        demandedRealm,
      });
      expect(firstClient.connectionState, isA<NatsClosed>());
    });
  });

  group("FakeNatsClient subscription", () {
    late FakeNatsClient mockClient;

    setUp(() {
      mockClient = FakeNatsClient();
    });

    tearDown(() {
      mockClient.dispose();
    });

    test("sub creates subscription that receives emitted messages", () async {
      final subscription = await mockClient.subscribe("test.subject");
      final messages = <NatsMessage>[];
      final streamSub = subscription.messages.listen(messages.add);

      final testData = Uint8List.fromList([1, 2, 3, 4]);
      mockClient.emitMessage(subscription.id, testData);

      await Future<void>.delayed(Duration.zero);

      expect(messages.length, equals(1));
      expect(messages.first.payload, equals(testData));

      await streamSub.cancel();
    });

    test("unSub closes subscription stream", () async {
      final subscription = await mockClient.subscribe("test.subject");
      var streamClosed = false;
      subscription.messages.listen(null, onDone: () => streamClosed = true);

      await subscription.unsubscribe();

      await Future<void>.delayed(Duration.zero);

      expect(streamClosed, isTrue);
    });

    test("close disposes all subscriptions", () async {
      final sub1 = await mockClient.subscribe("subject1");
      final sub2 = await mockClient.subscribe("subject2");

      var stream1Closed = false;
      var stream2Closed = false;

      sub1.messages.listen(null, onDone: () => stream1Closed = true);
      sub2.messages.listen(null, onDone: () => stream2Closed = true);

      await mockClient.close();

      await Future<void>.delayed(Duration.zero);

      expect(stream1Closed, isTrue);
      expect(stream2Closed, isTrue);
      expect(mockClient.connectionState, isA<NatsClosed>());
    });
  });
}
