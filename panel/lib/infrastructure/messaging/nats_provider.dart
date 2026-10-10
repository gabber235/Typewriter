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

/// Owns the authenticated NATS client for the current user and organization.
///
/// Credential providers and the organization qualifier are read when this
/// owner is built. Authorization refresh admits a connected candidate before
/// replacing the current client and closing its transport resources.
@Riverpod(keepAlive: true)
class Nats extends _$Nats {
  var _authorizationGeneration = 0;
  NatsClient? _ownedClient;
  Future<void> _authorizationTail = Future<void>.value();
  Set<skir.RecordId>? _acceptedRealmIds;
  Set<skir.RecordId>? _demandedRealmIds;
  var _demandedExact = false;
  late StreamController<AsyncValue<Set<skir.RecordId>>> _authorizationChanges;
  AsyncValue<Set<skir.RecordId>> _authorization = const AsyncLoading();

  AsyncValue<Set<skir.RecordId>> get authorization => _authorization;

  Stream<AsyncValue<Set<skir.RecordId>>> get authorizationChanges =>
      _authorizationChanges.stream;

  @override
  NatsClient build() {
    final client = _connectCandidate(watch: true);
    _authorizationGeneration++;
    _ownedClient = client;
    _acceptedRealmIds = null;
    _demandedRealmIds = null;
    _demandedExact = false;
    _authorization = const AsyncLoading();
    _authorizationChanges =
        StreamController<AsyncValue<Set<skir.RecordId>>>.broadcast();
    final changes = _authorizationChanges;
    ref.onDispose(() {
      _authorizationGeneration++;
      unawaited(_ownedClient?.close() ?? Future<void>.value());
      unawaited(changes.close());
    });
    return client;
  }

  NatsClient _connectCandidate({bool watch = false}) {
    final token = watch
        ? ref.watch(accessTokenProvider).value?.token
        : ref.read(accessTokenProvider).value?.token;
    if (token == null) {
      throw StateError("User must be authenticated before connecting to NATS");
    }
    final user = watch
        ? ref.watch(authUserInfoProvider).requireValue
        : ref.read(authUserInfoProvider).requireValue;
    final sentinel = watch
        ? ref.watch(sentinelCredentialsProvider).requireValue
        : ref.read(sentinelCredentialsProvider).requireValue;
    final organizationId = watch
        ? ref.watch(organizationIdProvider)
        : ref.read(organizationIdProvider);
    final sessionFactory = watch
        ? ref.watch(natsConnectionSessionFactoryProvider)
        : ref.read(natsConnectionSessionFactoryProvider);
    final connectionSession = sessionFactory();
    final qualifier = skir.EntityPermissionQualifier.createUser(
      organizationId: organizationId,
      connectionSession: connectionSession,
    );
    final configuration = NatsClientConfiguration(
      url: AppConfig.nats.url,
      seed: sentinel.seed,
      jwt: sentinel.jwt,
      username: user.username ?? user.name ?? user.sub,
      password: token,
      actorId: user.sub,
      organizationId: organizationId?.id,
      connectionSession: connectionSession,
      connectNkey: base64.encode(
        skir.EntityPermissionQualifier.serializer.toBytes(qualifier),
      ),
      requestInboxPrefix: "_INBOX.${user.sub}.$connectionSession",
    );

    debugPrint("nats: connecting to ${configuration.url}");
    final factory = watch
        ? ref.watch(natsClientFactoryProvider)
        : ref.read(natsClientFactoryProvider);
    return factory(configuration);
  }

  void _publishAuthorization(AsyncValue<Set<skir.RecordId>> value) {
    _authorization = value;
    _authorizationChanges.add(value);
  }

  Future<void> ensureRealmsAdmitted(Set<skir.RecordId> required) =>
      _admitRealms(required);

  Future<void> _admitRealms(
    Set<skir.RecordId> required, {
    bool exact = false,
    bool forceReplacement = false,
  }) {
    final generation = _authorizationGeneration;
    final demanded = Set<skir.RecordId>.unmodifiable(required);
    _demandedRealmIds = demanded;
    _demandedExact = exact;
    bool matches(Set<skir.RecordId> admitted) => exact
        ? const SetEquality<skir.RecordId>().equals(admitted, demanded)
        : admitted.containsAll(demanded);
    final operation = _authorizationTail.then((_) async {
      if (!ref.mounted || generation != _authorizationGeneration) return;
      _publishAuthorization(const AsyncLoading());
      NatsClient? candidate;
      try {
        final previous = state;
        if (!forceReplacement) {
          final current = (await previous.queryPermissions()).admittedRealms(
            previous,
          );
          if (!ref.mounted || generation != _authorizationGeneration) return;
          if (matches(current)) {
            _acceptedRealmIds = current;
            _publishAuthorization(AsyncData(current));
            return;
          }
        }
        candidate = _connectCandidate();
        final admitted = (await candidate.queryPermissions()).admittedRealms(
          candidate,
        );
        if (!matches(admitted)) {
          throw const NatsClientException(
            kind: NatsFailureKind.permission,
            message: "Required Realm grants were not admitted by the server",
          );
        }
        if (!ref.mounted || generation != _authorizationGeneration) return;
        _acceptedRealmIds = admitted;
        _ownedClient = candidate;
        state = candidate;
        candidate = null;
        _publishAuthorization(AsyncData(admitted));
        try {
          await previous.close();
        } on Object catch (error, stackTrace) {
          FlutterError.reportError(
            FlutterErrorDetails(
              exception: error,
              stack: stackTrace,
              library: "NATS authorization",
              context: ErrorDescription("closing the replaced connection"),
            ),
          );
        }
      } on Object catch (error, stackTrace) {
        if (ref.mounted && generation == _authorizationGeneration) {
          _publishAuthorization(AsyncError(error, stackTrace));
        }
        rethrow;
      } finally {
        await candidate?.close();
      }
    });
    _authorizationTail = operation.catchError((Object _, StackTrace _) {});
    return operation;
  }

  Future<void> refreshAuthorization(Set<skir.RecordId> observedRealms) {
    final known = _acceptedRealmIds;
    if (known != null &&
        const SetEquality<skir.RecordId>().equals(known, observedRealms)) {
      return Future<void>.value();
    }
    return _admitRealms(observedRealms, exact: true);
  }

  Future<void> retry() {
    final demanded =
        _demandedRealmIds ?? _acceptedRealmIds ?? const <skir.RecordId>{};
    return _admitRealms(
      demanded,
      exact: _demandedExact,
      forceReplacement: true,
    );
  }
}

@riverpod
Stream<AsyncValue<Set<skir.RecordId>>> natsAuthorization(Ref ref) async* {
  ref.watch(natsProvider);
  final owner = ref.read(natsProvider.notifier);
  yield owner.authorization;
  yield* owner.authorizationChanges;
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
