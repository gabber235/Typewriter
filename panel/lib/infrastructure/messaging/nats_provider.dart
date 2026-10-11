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

typedef NatsConnectionSessionFactory = String Function();

/// Provides the concrete NATS owner factory used after authentication.
@Riverpod(keepAlive: true)
NatsClientFactory natsClientFactory(Ref ref) => NatsCoreClient.connect;

@Riverpod(keepAlive: true)
NatsConnectionSessionFactory natsConnectionSessionFactory(Ref ref) =>
    () => uuid.v4().replaceAll("-", "").toLowerCase();

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

/// Publishes the active client owned by the authenticated connection scope.
///
/// Credential and organization changes dispose the entire previous connection.
/// Permission refresh and retry retain the current client until a replacement
/// has been admitted by the server.
@Riverpod(keepAlive: true)
class Nats extends _$Nats {
  late NatsConnectionOwner _connection;

  NatsClient get client => state;

  @override
  NatsClient build() {
    final token = ref.watch(accessTokenProvider).value?.token;
    if (token == null) {
      throw StateError("User must be authenticated before connecting to NATS");
    }
    final connection = NatsConnectionOwner(
      settings: NatsConnectionSettings(
        url: AppConfig.nats.url,
        token: token,
        user: ref.watch(authUserInfoProvider).requireValue,
        sentinel: ref.watch(sentinelCredentialsProvider).requireValue,
        organization: ref.watch(organizationIdProvider),
      ),
      clientFactory: ref.watch(natsClientFactoryProvider),
      sessionFactory: ref.watch(natsConnectionSessionFactoryProvider),
      onReplacement: (client) => state = client,
    );
    _connection = connection;
    ref.onDispose(() => unawaited(connection.close()));
    return connection.client;
  }

  Future<void> ensureRealmsAdmitted(Set<skir.RecordId> required) =>
      _connection.ensureRealmsAdmitted(required);

  Future<void> refreshAuthorization(Set<skir.RecordId> observedRealms) =>
      _connection.refreshAuthorization(observedRealms);

  Future<void> retry() => _connection.retry();
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
