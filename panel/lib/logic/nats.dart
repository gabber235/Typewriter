import "dart:async";

import "package:dart_nats/dart_nats.dart";
import "package:flutter/foundation.dart";
import "package:protobuf/protobuf.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";
import "package:typewriter_panel/logic/auth.dart";
import "package:typewriter_panel/logic/organization.dart";
import "package:typewriter_panel/utils/app_config.dart";

part "nats.g.dart";

// The sentinel JWT is just used to make sure the user gets into the correct account on the NATS server.
// It is not actually a valid credential nor allows the user to do anything.
// That is why its safe to store it in a constant.
// TODO: Remove when nats allows for the `default_sentinel` config option.
final _natsSentinelJwt = AppConfig.nats.sentinelJwt;
final _natsSentinelSeed = AppConfig.nats.sentinelSeed;
final _natsAcceptBadCert = AppConfig.nats.acceptBadCert;

@Riverpod(keepAlive: true)
class Nats extends _$Nats {
  @override
  Client build() {
    final token = ref.watch(accessTokenProvider).value?.token;
    if (token == null) {
      throw Exception("User must be authenticated before connecting to NATS");
    }

    final user = ref.watch(authUserInfoProvider).requireValue;

    final client = Client()..acceptBadCert = _natsAcceptBadCert;

    final url = AppConfig.nats.url;

    debugPrint(
      "nats: connecting to $url ${_natsAcceptBadCert ? "ignoring bad certificates" : ""}",
    );

    client
      ..seed = _natsSentinelSeed
      ..inboxPrefix = "_INBOX.${user.sub}";

    unawaited(
      client
          .connect(
            Uri.parse(url),
            connectOption: ConnectOption(
              jwt: _natsSentinelJwt,
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
