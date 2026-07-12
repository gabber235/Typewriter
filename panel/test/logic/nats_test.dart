import "dart:async";
import "dart:typed_data";

import "package:dart_nats/dart_nats.dart";
import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/logic/nats.dart";
import "package:typewriter_panel/skir.dart" as skir;
import "package:typewriter_testkit/typewriter_testkit.dart";

void main() {
  group("ClientProtoExtension.requestSkir", () {
    late MockNatsClient mockClient;

    setUp(() {
      mockClient = MockNatsClient();
    });

    tearDown(() {
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

      final response = await mockClient.requestSkir(
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

      await mockClient.requestSkir(
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
        () => mockClient.requestSkir(
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
        () => mockClient.requestSkir(
          "test.subject",
          skir.GetSentinelCredentialsRequest.serializer.toBytes(
            skir.GetSentinelCredentialsRequest(),
          ),
          skir.GetSentinelCredentialsResponse.serializer,
        ),
        throwsA(isA<NatsException>()),
      );
    });

    test("handles empty response data", () async {
      mockClient.registerHandler("test.subject", (requestData) => Uint8List(0));

      final response = await mockClient.requestSkir(
        "test.subject",
        skir.GetSentinelCredentialsRequest.serializer.toBytes(
          skir.GetSentinelCredentialsRequest(),
        ),
        skir.GetSentinelCredentialsResponse.serializer,
      );

      expect(response, isA<skir.GetSentinelCredentialsResponse_unknown>());
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
