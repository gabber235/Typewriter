import "dart:async";
import "dart:convert";

import "package:flutter/foundation.dart";
import "package:http/http.dart" as http;
import "package:riverpod_annotation/riverpod_annotation.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

part "nats_provider.g.dart";

typedef NatsClientFactory =
    NatsClient Function(NatsClientConfiguration configuration);

@Riverpod(keepAlive: true)
NatsClientFactory natsClientFactory(Ref ref) => NatsCoreClient.connect;

@Riverpod(keepAlive: true)
http.Client panelHttpClient(Ref ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return client;
}

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
  NatsClient build() {
    final token = ref.watch(accessTokenProvider).value?.token;
    if (token == null) {
      throw StateError("User must be authenticated before connecting to NATS");
    }
    final user = ref.watch(authUserInfoProvider).requireValue;
    final sentinel = ref.watch(sentinelCredentialsProvider).requireValue;
    final qualifier = skir.EntityPermissionQualifier.createUser(
      organizationId: ref.watch(organizationIdProvider),
    );
    final configuration = NatsClientConfiguration(
      url: AppConfig.nats.url,
      seed: sentinel.seed,
      jwt: sentinel.jwt,
      username: user.username ?? user.name ?? user.sub,
      password: token,
      connectNkey: base64.encode(
        skir.EntityPermissionQualifier.serializer.toBytes(qualifier),
      ),
      requestInboxPrefix: "_INBOX.${user.sub}",
    );
    debugPrint("nats: connecting to ${configuration.url}");
    final client = ref.watch(natsClientFactoryProvider)(configuration);
    ref.onDispose(() => unawaited(client.close()));
    return client;
  }

  Future<void> retry() async {
    final client = state;
    await client.close();
    if (!ref.mounted) return;
    ref.invalidateSelf();
  }
}

@riverpod
class NatsLifecycle extends _$NatsLifecycle {
  @override
  NatsConnectionState build() {
    final client = ref.watch(natsProvider);
    final subscription = client.connectionStateChanges.listen((connection) {
      _logConnectionState(connection);
      state = connection;
    });
    ref.onDispose(subscription.cancel);
    _logConnectionState(client.connectionState);
    return client.connectionState;
  }
}

void _logConnectionState(NatsConnectionState connectionState) {
  final message = switch (connectionState) {
    NatsReconnecting(:final failure) || NatsFailed(:final failure) =>
      "${connectionState.runtimeType}: ${failure.kind}: ${failure.safeDescription}",
    _ => "${connectionState.runtimeType}",
  };
  debugPrint("nats: state $message");
}
