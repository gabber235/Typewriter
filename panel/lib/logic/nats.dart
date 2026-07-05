import "dart:async";

import "package:dart_nats/dart_nats.dart";
import "package:flutter/foundation.dart";
import "package:http/http.dart" as http;
import "package:protobuf/protobuf.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";
import "package:typewriter_panel/logic/auth.dart";
import "package:typewriter_panel/logic/organization.dart";
import "package:typewriter_panel/skirout/access/v1/sentinel.dart";
import "package:typewriter_panel/utils/app_config.dart";

part "nats.g.dart";

/// Fetches the sentinel credentials from the API.
@Riverpod(keepAlive: true)
Future<GetSentinelCredentialsResponse_Success> sentinelCredentials(
  Ref ref,
) async {
  final url = Uri.parse("${AppConfig.api.baseUrl}/auth/sentinel");
  final response = await http.get(url);

  if (response.statusCode != 200) {
    throw Exception(
      "Failed to fetch sentinel credentials: ${response.statusCode}",
    );
  }

  final data = GetSentinelCredentialsResponse.serializer.fromBytes(
    response.bodyBytes,
  );

  return switch (data) {
    GetSentinelCredentialsResponse_configurationErrorWrapper() =>
      throw Exception("Configuration error"),
    GetSentinelCredentialsResponse_invalidCredentialsWrapper() =>
      throw Exception("Invalid credentials"),
    GetSentinelCredentialsResponse_successWrapper(:final value) => value,
    GetSentinelCredentialsResponse_unknown() => throw Exception(
      "Unknown response",
    ),
  };
}

@Riverpod(keepAlive: true)
class Nats extends _$Nats {
  @override
  Client build() {
    final token = ref.watch(accessTokenProvider).value?.token;
    if (token == null) {
      throw Exception("User must be authenticated before connecting to NATS");
    }

    final user = ref.watch(authUserInfoProvider).requireValue;
    final sentinelCredentials = ref
        .watch(sentinelCredentialsProvider)
        .requireValue;

    final client = Client();

    final url = AppConfig.nats.url;

    debugPrint("nats: connecting to $url");

    client
      ..seed = sentinelCredentials.seed
      ..inboxPrefix = "_INBOX.${user.sub}";

    unawaited(
      client
          .connect(
            Uri.parse(url),
            connectOption: ConnectOption(
              jwt: sentinelCredentials.jwt,
              user: user.username ?? user.name ?? user.sub,
              pass: token,
              // ignore: only_use_keep_alive_inside_keep_alive
              nkey: ref.watch(organizationIdProvider),
            ),
          )
          .onError((error, stackTrace) {
            debugPrint("nats: error connecting to $url: $error");
            client.close();
          }),
    );

    ref.onDispose(client.close);

    return client;
  }
}

@riverpod
class NatsStatus extends _$NatsStatus {
  @override
  Status build() {
    final client = ref.watch(natsProvider);
    debugPrint("nats: status ${client.status}");
    final sub = client.statusStream.listen((status) {
      debugPrint("nats: status $status");
      state = status;
    });
    ref.onDispose(sub.cancel);
    return client.status;
  }
}

/// Extension on Client to add protobuf request/response methods
extension ClientProtoExtension on Client {
  /// Send a protobuf request and receive a protobuf response
  @Deprecated("migrate to skir")
  Future<TResponse> requestProto<
    TRequest extends GeneratedMessage,
    TResponse extends GeneratedMessage
  >(
    String subject,
    TRequest request,
    TResponse Function() responseBuilder,
  ) async {
    final requestBytes = request.writeToBuffer();
    final response = await this.request(subject, requestBytes);

    return responseBuilder()..mergeFromBuffer(response.data);
  }
}

/// Extension on Ref to allow for listening to Nats topics while sending an initial request
extension RefNatsExtension on Ref {
  /// Send a protobuf request and receive a protobuf response while listening to a topic
  @Deprecated("migrate to skir")
  Stream<TResponse> requestProtoThenListen<
    TRequest extends GeneratedMessage,
    TResponse extends GeneratedMessage
  >({
    required String subject,
    required String listenSubject,
    required TRequest request,
    required TResponse Function() responseBuilder,
  }) async* {
    final status = watch(natsStatusProvider);
    if (status != Status.connected) {
      throw Exception("NATS is not connected");
    }
    final client = watch(natsProvider);
    final sub = client.sub(listenSubject);
    onDispose(() => client.unSub(sub));

    await client.pub(subject, request.writeToBuffer(), replyTo: listenSubject);

    await for (final msg in sub.stream) {
      final response = responseBuilder()..mergeFromBuffer(msg.data);
      yield response;
    }
  }
}
