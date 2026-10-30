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

/// What one connection input holds: its value once it loaded, its failure
/// when it never loaded, or neither while it first loads. A reload keeps the
/// loaded value, so it does not replace the connection.
typedef _ConnectionInput<T> = ({
  T? value,
  Object? error,
  StackTrace? stackTrace,
});

_ConnectionInput<T> _connectionInput<T>(AsyncValue<T> state) => (
  value: state.value,
  error: state.hasValue ? null : state.error,
  stackTrace: state.hasValue ? null : state.stackTrace,
);

/// Publishes the active client owned by the authenticated connection scope.
///
/// The connection opens once its inputs exist: the identity provider session
/// and the sentinel credentials. Until then, and while nobody is signed in,
/// it stays pending, so a consumer waiting for it opens nothing and resumes
/// once the inputs arrive. Only a changed session, credentials or
/// organization disposes the previous connection. [retry] publishes a fresh
/// session of the same scope.
@Riverpod(keepAlive: true)
class Nats extends _$Nats {
  late NatsConnectionOwner _connection;

  @override
  FutureOr<NatsClient> build() {
    final organization = ref.watch(organizationIdProvider);
    final clientFactory = ref.watch(natsClientFactoryProvider);
    final sessionFactory = ref.watch(natsConnectionSessionFactoryProvider);
    final session = ref.watch(authSessionProvider.select(_connectionInput));
    final sentinel = ref.watch(
      sentinelCredentialsProvider.select(_connectionInput),
    );
    for (final input in [session, sentinel]) {
      if (input.error case final error?) {
        Error.throwWithStackTrace(error, input.stackTrace!);
      }
    }
    final (signedIn, credentials) = (session.value, sentinel.value);
    if (signedIn == null || credentials == null) {
      // The change that brings the missing input rebuilds this provider.
      return Completer<NatsClient>().future;
    }
    final connection = NatsConnectionOwner(
      settings: NatsConnectionSettings(
        url: AppConfig.nats.url,
        token: signedIn.token.token,
        user: signedIn.user,
        sentinel: credentials,
        organization: organization,
      ),
      clientFactory: clientFactory,
      sessionFactory: sessionFactory,
      onReplacement: (client) => state = AsyncData(client),
    );
    _connection = connection;
    ref.onDispose(() => unawaited(connection.close()));
    return connection.client;
  }

  /// Opens a fresh session of the current connection once it exists.
  Future<void> retry() async {
    await future;
    await _connection.retry();
  }
}

/// Projects transport lifecycle into Riverpod for connection status UI.
///
/// The connection reads as connecting until it opens. Its synchronous client
/// state is emitted first, then later transport events update the provider.
/// This provider observes lifecycle only and does not own the client or
/// decide whether a failure is recoverable.
@riverpod
class NatsLifecycle extends _$NatsLifecycle {
  @override
  NatsConnectionState build() {
    final client = switch (ref.watch(natsProvider)) {
      AsyncData(:final value) => value,
      AsyncError(:final error, :final stackTrace) => Error.throwWithStackTrace(
        error,
        stackTrace,
      ),
      AsyncLoading() => null,
    };
    if (client == null) return const NatsConnecting();
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
