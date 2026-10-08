import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

part "nats_provider.g.dart";

/// Creates a transport owner from credentials and connection settings.
///
/// Kept as a provider so tests can replace the concrete NATS package boundary
/// without changing feature code or authentication assembly.
typedef NatsClientFactory = NatsClient Function(
  NatsClientConfiguration configuration,
);

/// Provides the concrete NATS owner factory used after authentication.
@Riverpod(keepAlive: true)
NatsClientFactory natsClientFactory(Ref ref) => NatsCoreClient.connect;

/// Owns the HTTP client used by panel infrastructure requests.
@Riverpod(keepAlive: true)
Client panelHttpClient(Ref ref) {
  final client = Client();
  ref.onDispose(client.close);
  return client;
}

/// Fetches the short lived credentials required to open the user's NATS session.
///
/// HTTP status and unknown Skir variants are translated here, at the boundary
/// that still understands both the HTTP response and the generated contract.
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

/// Owns the authenticated NATS client for the current user and organization.
///
/// Credential providers and the organization qualifier are read when this
/// owner is built. Invalidating it closes the old client before a fresh
/// connection is created, which makes retry an ownership operation rather than
/// a second connection layered over the first.
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

  /// Replaces a failed client after its transport resources have been closed.
  Future<void> retry() async {
    final client = state;
    await client.close();
    if (!ref.mounted) return;
    ref.invalidateSelf();
  }
}

/// Projects transport lifecycle into Riverpod for connection status UI.
///
/// The synchronous client state is emitted first, then later transport events
/// update the provider. This provider observes lifecycle only and does not own
/// the client or decide whether a failure is recoverable.
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
