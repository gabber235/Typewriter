import "dart:async";
import "dart:typed_data";

import "package:dart_nats/dart_nats.dart";
import "package:flutter_test/flutter_test.dart";
import "package:http/http.dart" as http;
import "package:http/testing.dart";
import "package:riverpod/riverpod.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart" hide Header;
import "package:typewriter_testkit/typewriter_testkit.dart";

final _testRefProvider = Provider<Ref>((ref) => ref);

final class _FakeTelemetry implements PanelTelemetry {
  @override
  Future<T> traceNats<T>({
    required String subject,
    required int payloadSize,
    required String operationName,
    required Future<T> Function(Header? header) operation,
  }) => operation(
    Header(
      headers: {
        "traceparent":
            "00-4bf92f3577b34da6a3ce929d0e0e4736-00f067aa0ba902b7-01",
        "tracestate": "vendor=value",
      },
    ),
  );

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
    late MockNatsClient mockClient;
    late ProviderContainer container;

    setUp(() {
      mockClient = MockNatsClient();
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
        mockClient.requests.single.header?.get("traceparent"),
        startsWith("00-4bf92f"),
      );
      expect(
        mockClient.requests.single.header?.get("tracestate"),
        "vendor=value",
      );
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
      mockClient.setStatus(Status.disconnected);

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
        throwsA(isA<NatsException>()),
      );
    });
  });

  group("RefNatsExtension.watchRequest", () {
    late MockNatsClient mockClient;
    late ProviderContainer container;

    setUp(() {
      mockClient = MockNatsClient();
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

    test("injects trace headers on the initial Skir publication", () async {
      const listenSubject = "test.responses";
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

      while (mockClient.publications.isEmpty) {
        await Future<void>.delayed(Duration.zero);
      }

      final publication = mockClient.publications.single;
      expect(publication.subject, "test.watch");
      expect(publication.replyTo, listenSubject);
      expect(publication.header?.get("traceparent"), startsWith("00-4bf92f"));
      expect(publication.header?.get("tracestate"), "vendor=value");

      mockClient.emitMessageOnSubject(
        listenSubject,
        skir.GetSentinelCredentialsResponse.serializer.toBytes(
          skir.GetSentinelCredentialsResponse.createSuccess(
            jwt: "test-jwt",
            seed: "test-seed",
          ),
        ),
      );

      expect(await firstResponse, isA<skir.GetSentinelCredentialsResponse>());
    });
  });

  group("NatsStatus", () {
    late MockNatsClient mockClient;

    setUp(() {
      mockClient = MockNatsClient();
    });

    tearDown(() {
      mockClient.dispose();
    });

    test("initial status matches client status", () {
      expect(mockClient.status, equals(Status.connected));
    });

    test("status updates when client status changes", () async {
      final statuses = <Status>[];
      final subscription = mockClient.statusStream.listen(statuses.add);

      mockClient
        ..setStatus(Status.disconnected)
        ..setStatus(Status.reconnecting)
        ..setStatus(Status.connected);

      await Future<void>.delayed(Duration.zero);

      expect(statuses, contains(Status.disconnected));
      expect(statuses, contains(Status.reconnecting));
      expect(statuses, contains(Status.connected));

      await subscription.cancel();
    });
  });

  group("MockNatsClient subscription", () {
    late MockNatsClient mockClient;

    setUp(() {
      mockClient = MockNatsClient();
    });

    tearDown(() {
      mockClient.dispose();
    });

    test("sub creates subscription that receives emitted messages", () async {
      final subscription = mockClient.sub<dynamic>("test.subject");
      final messages = <Message>[];
      final streamSub = subscription.stream.listen(messages.add);

      final testData = Uint8List.fromList([1, 2, 3, 4]);
      mockClient.emitMessage(subscription.sid, testData);

      await Future<void>.delayed(Duration.zero);

      expect(messages.length, equals(1));
      expect(messages.first.data, equals(testData));

      await streamSub.cancel();
    });

    test("unSub closes subscription stream", () async {
      final subscription = mockClient.sub<dynamic>("test.subject");
      var streamClosed = false;
      subscription.stream.listen(null, onDone: () => streamClosed = true);

      mockClient.unSub(subscription);

      await Future<void>.delayed(Duration.zero);

      expect(streamClosed, isTrue);
    });

    test("close disposes all subscriptions", () async {
      final sub1 = mockClient.sub<dynamic>("subject1");
      final sub2 = mockClient.sub<dynamic>("subject2");

      var stream1Closed = false;
      var stream2Closed = false;

      sub1.stream.listen(null, onDone: () => stream1Closed = true);
      sub2.stream.listen(null, onDone: () => stream2Closed = true);

      await mockClient.close();

      await Future<void>.delayed(Duration.zero);

      expect(stream1Closed, isTrue);
      expect(stream2Closed, isTrue);
      expect(mockClient.status, equals(Status.closed));
    });
  });
}
