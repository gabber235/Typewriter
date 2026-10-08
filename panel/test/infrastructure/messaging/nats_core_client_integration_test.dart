import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";

const _seed = "SUAKYRHVIOREXV7EUZTBHUHL7NUMHPMAS7QMDU3GTIUWEI5LDNOXD43IZY";
const _rejectedSeed =
    "SUAMZVERVLN7XWYTEVQ4JCSJODRGOYGIITJMJUOOVUEUOTRWAOET7LFU3Q";

Future<T> _waitForConnectionState<T extends NatsConnectionState>(
  NatsClient client,
) async {
  final completed = Completer<T>();
  final subscription = client.connectionStateChanges
      .where((state) => state is T)
      .cast<T>()
      .listen((state) {
        if (!completed.isCompleted) {
          completed.complete(state);
        }
      });
  final current = client.connectionState;
  if (current is T && !completed.isCompleted) {
    completed.complete(current);
  }
  try {
    return await completed.future;
  } finally {
    await subscription.cancel();
  }
}

void main() {
  final serverUrl = Platform.environment["NATS_ADAPTER_URL"];
  final skipReason = serverUrl == null ? "NATS_ADAPTER_URL is not set" : false;

  test(
    "adapter requests through a restricted caller inbox",
    () async {
      final responder = await NatsConnection.connect(
        NatsOptions(
          servers: [NatsServer.parse(serverUrl!)],
          authentication: NatsAuthentication.nkey(_seed),
        ),
      );
      addTearDown(responder.close);
      final client = NatsCoreClient.connect(
        NatsClientConfiguration(
          url: serverUrl,
          seed: _seed,
          requestInboxPrefix: "_INBOX.integration",
        ),
      );
      addTearDown(client.close);
      if (client.connectionState is! NatsConnected) {
        await _waitForConnectionState<NatsConnected>(client);
      }

      final received = Completer<CoreNatsMessage>();
      final responderSubscription = await responder.subscribe("allowed.echo");
      addTearDown(responderSubscription.unsubscribe);
      final listener = responderSubscription.messages.listen((message) {
        if (!received.isCompleted) received.complete(message);
        unawaited(responder.reply(message, message.payload));
      });
      addTearDown(listener.cancel);
      await responder.flush();

      final response = await client.request(
        "allowed.echo",
        Uint8List.fromList([1, 2, 3]),
        headers: const {"traceparent": "integration-trace"},
      );
      final request = await received.future;

      expect(response.payload, [1, 2, 3]);
      expect(request.headers?.first("traceparent"), "integration-trace");
      await expectLater(
        client.request("allowed.missing", Uint8List(0)),
        throwsA(
          isA<NatsClientException>().having(
            (error) => error.kind,
            "kind",
            NatsFailureKind.noResponders,
          ),
        ),
      );

      await client.close();
      expect(client.connectionState, isA<NatsClosed>());
    },
    skip: skipReason,
    timeout: const Timeout(Duration(seconds: 30)),
  );

  test(
    "adapter exposes rejected credentials as an authentication failure",
    () async {
      final client = NatsCoreClient.connect(
        NatsClientConfiguration(
          url: serverUrl!,
          seed: _rejectedSeed,
          requestInboxPrefix: "_INBOX.integration.rejected",
        ),
      );
      addTearDown(client.close);

      final failed = await _waitForConnectionState<NatsFailed>(client);

      expect(failed.failure.kind, NatsFailureKind.authentication);
      expect(failed.failure.cause, isA<NatsAuthenticationException>());
      final cause = failed.failure.cause! as NatsAuthenticationException;
      expect(failed.failure.message, cause.message);
      expect(failed.failure.toString(), isNot(contains(_rejectedSeed)));

      await client.close();
      expect(client.connectionState, isA<NatsClosed>());
    },
    skip: skipReason,
    timeout: const Timeout(Duration(seconds: 30)),
  );
}
