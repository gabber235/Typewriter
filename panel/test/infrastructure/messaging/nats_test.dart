import "dart:async";
import "dart:typed_data";

import "package:flutter_test/flutter_test.dart";
import "package:http/http.dart" as http;
import "package:http/testing.dart";
import "package:riverpod/riverpod.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";

final _testRefProvider = Provider<Ref>((ref) => ref);

final class _PendingSubscribeNatsClient implements NatsClient {
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

final class _ControlledCloseNatsClient implements NatsClient {
  final Completer<void> closeStarted = Completer<void>();
  final Completer<void> allowClose = Completer<void>();

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
  }) => throw UnsupportedError("Not used by this test");

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
  Future<void> close() async {
    if (!closeStarted.isCompleted) closeStarted.complete();
    await allowClose.future;
  }
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
  Future<http.Response> traceHttp({
    required String method,
    required Uri uri,
    required Future<http.Response> Function(Map<String, String> headers)
    operation,
  }) => operation({
    "traceparent": "00-4bf92f3577b34da6a3ce929d0e0e4736-00f067aa0ba902b7-01",
    "tracestate": "vendor=value",
  });
}

void main() {
  group("sentinelCredentials", () {
    test("forwards trace headers and decodes a successful response", () async {
      late http.Request capturedRequest;
      final responseBytes = skir.GetSentinelCredentialsResponse.serializer
          .toBytes(
            skir.GetSentinelCredentialsResponse.createSuccess(
              jwt: "test-jwt",
              seed: "test-seed",
            ),
          );
      final client = MockClient((request) async {
        capturedRequest = request;
        return http.Response.bytes(responseBytes, 200);
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
            MockClient((_) async => http.Response("unavailable", 503)),
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
            MockClient((_) => Future<http.Response>.error(error)),
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
            "test.subject",
            skir.GetSentinelCredentialsRequest.serializer.toBytes(
              skir.GetSentinelCredentialsRequest(),
            ),
            skir.GetSentinelCredentialsResponse.serializer,
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
            "test.subject",
            skir.GetSentinelCredentialsRequest.serializer.toBytes(request),
            skir.GetSentinelCredentialsResponse.serializer,
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
              "unregistered.subject",
              skir.GetSentinelCredentialsRequest.serializer.toBytes(
                skir.GetSentinelCredentialsRequest(),
              ),
              skir.GetSentinelCredentialsResponse.serializer,
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
              "test.subject",
              skir.GetSentinelCredentialsRequest.serializer.toBytes(
                skir.GetSentinelCredentialsRequest(),
              ),
              skir.GetSentinelCredentialsResponse.serializer,
            ),
        throwsA(isA<NatsClientException>()),
      );
    });
  });

  group("RefNatsExtension.watchRequest", () {
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

    test("injects trace headers on the initial Skir request", () async {
      const listenSubject = "test.responses";
      mockClient.registerHandler(
        "test.watch",
        (_) => skir.GetSentinelCredentialsResponse.serializer.toBytes(
          skir.GetSentinelCredentialsResponse.createSuccess(
            jwt: "test-jwt",
            seed: "test-seed",
          ),
        ),
      );
      final stream = container
          .read(_testRefProvider)
          .watchRequest(
            subject: "test.watch",
            listenSubject: listenSubject,
            requestBytes: Uint8List.fromList([1, 2, 3]),
            serializer: skir.GetSentinelCredentialsResponse.serializer,
            transformer: (_, response) => response,
          );
      final firstResponse = stream.first;

      while (mockClient.requests.isEmpty) {
        await Future<void>.delayed(Duration.zero);
      }

      final request = mockClient.requests.single;
      expect(request.subject, "test.watch");
      expect(request.headers["traceparent"], startsWith("00-4bf92f"));
      expect(request.headers["tracestate"], "vendor=value");

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
          .watchRequest(
            subject: "test.cancel",
            listenSubject: listenSubject,
            requestBytes: Uint8List.fromList([1, 2, 3]),
            serializer: skir.GetSentinelCredentialsResponse.serializer,
            transformer: (_, response) => response,
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
          .watchRequest(
            subject: "test.pending",
            listenSubject: "test.pending.responses",
            requestBytes: Uint8List(0),
            serializer: skir.GetSentinelCredentialsResponse.serializer,
            transformer: (_, response) => response,
          );
      final listener = stream.listen(null);
      await Future<void>.delayed(Duration.zero);

      await listener.cancel();
      client.completeSubscription();
      await pumpEventQueue();

      expect(client.subscription.unsubscribed, isTrue);
      expect(client.requests, isZero);
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
    test("closes the current client before creating its replacement", () async {
      final firstClient = _ControlledCloseNatsClient();
      final secondClient = FakeNatsClient();
      final createdClients = <NatsClient>[];
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
            recordId("organization:test"),
          ),
          natsClientFactoryProvider.overrideWithValue((_) {
            final client = createdClients.isEmpty ? firstClient : secondClient;
            createdClients.add(client);
            return client;
          }),
        ],
      );
      addTearDown(() async {
        if (!firstClient.allowClose.isCompleted) {
          firstClient.allowClose.complete();
        }
        container.dispose();
        await secondClient.dispose();
      });
      expect(container.read(natsProvider), same(firstClient));

      final retry = container.read(natsProvider.notifier).retry();
      await firstClient.closeStarted.future;

      expect(createdClients, [same(firstClient)]);

      firstClient.allowClose.complete();
      await retry;
      expect(container.read(natsProvider), same(secondClient));
      expect(createdClients, [same(firstClient), same(secondClient)]);
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
