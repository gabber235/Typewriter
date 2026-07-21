import "dart:async";
import "dart:convert";

import "package:dart_nats/dart_nats.dart";
import "package:flutter/foundation.dart";
import "package:http/http.dart" as http;
import "package:protobuf/protobuf.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";
import "package:skir_client/skir_client.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart" hide Header;

part "nats.g.dart";

const _requestTimeout = Duration(seconds: 10);

@Riverpod(keepAlive: true)
http.Client panelHttpClient(Ref ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return client;
}

/// Fetches the sentinel credentials from the API.
@Riverpod(keepAlive: true)
Future<skir.GetSentinelCredentialsResponse_Success> sentinelCredentials(
  Ref ref,
) async {
  final url = Uri.parse("${AppConfig.api.baseUrl}/auth/sentinel");
  final telemetry = await ref.watch(panelTelemetryProvider.future);
  final client = ref.watch(panelHttpClientProvider);
  final response = await telemetry.traceHttp(
    method: "GET",
    uri: url,
    operation: (headers) => client.get(url, headers: headers),
  );

  if (response.statusCode != 200) {
    throw ApiException(
      code: response.statusCode,
      message: "Failed to fetch sentinel credentials",
    );
  }

  final data = skir.GetSentinelCredentialsResponse.serializer.fromBytes(
    response.bodyBytes,
  );

  return switch (data) {
    skir.GetSentinelCredentialsResponse_unknown() =>
      throw ApiException.unknownResponseMessage(),
    skir.GetSentinelCredentialsResponse_internalErrorWrapper() =>
      throw ApiException.internalServerError(),
    skir.GetSentinelCredentialsResponse_successWrapper(:final value) => value,
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

    final qualifier = skir.EntityPermissionQualifier.createUser(
      organizationId: ref.watch(organizationIdProvider),
    );

    unawaited(
      client
          .connect(
            Uri.parse(url),
            connectOption: ConnectOption(
              jwt: sentinelCredentials.jwt,
              user: user.username ?? user.name ?? user.sub,
              pass: token,
              // ignore: only_use_keep_alive_inside_keep_alive
              nkey: base64.encode(
                skir.EntityPermissionQualifier.serializer.toBytes(qualifier),
              ),
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
  Future<TResponse> requestSkir<TResponse>(
    String subject,
    Uint8List requestBytes,
    Serializer<TResponse> serializer,
  ) async {
    final telemetry = await read(panelTelemetryProvider.future);
    final client = read(natsProvider);
    final response = await telemetry.traceNats(
      subject: subject,
      payloadSize: requestBytes.length,
      operationName: "request",
      operation: (header) =>
          client.request(subject, requestBytes, header: header),
    );
    return serializer.fromBytes(response.data);
  }

  Stream<TData> watchRequest<TData, TResponse>({
    required String subject,
    required String listenSubject,
    required Uint8List requestBytes,
    required Serializer<TResponse> serializer,
    required TData Function(TData?, TResponse) transformer,
  }) async* {
    final status = watch(natsStatusProvider);
    if (status != Status.connected) {
      throw Exception("NATS is not connected");
    }
    final client = watch(natsProvider);
    final sub = client.sub(listenSubject);
    onDispose(() => client.unSub(sub));

    debugPrint("requesting: $subject");
    final telemetry = await read(panelTelemetryProvider.future);
    await telemetry.traceNats(
      subject: subject,
      payloadSize: requestBytes.length,
      operationName: "publish",
      operation: (header) => client.pub(
        subject,
        requestBytes,
        replyTo: listenSubject,
        header: header,
      ),
    );

    TData? lastData;

    await for (final msg in sub.stream.timeoutFirstValue(
      _requestTimeout,
      message: "No response received for '$subject' within $_requestTimeout",
    )) {
      final response = transformer(lastData, serializer.fromBytes(msg.data));
      yield response;
      lastData = response;
    }
  }

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
