import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

part "nats_connection.freezed.dart";

/// Authentication and scope shared by the transports owned by one connection.
@Freezed(toStringOverride: false)
abstract class NatsConnectionSettings with _$NatsConnectionSettings {
  const factory NatsConnectionSettings({
    required String url,
    required String token,
    required UserInfo user,
    required skir.GetSentinelCredentialsResponse_Success sentinel,
    required skir.RecordId? organization,
  }) = _NatsConnectionSettings;

  const NatsConnectionSettings._();

  NatsClientConfiguration configuration(String session) {
    final qualifier = skir.EntityPermissionQualifier.createUser(
      organizationId: organization,
      connectionSession: session,
    );
    return NatsClientConfiguration(
      url: url,
      seed: sentinel.seed,
      jwt: sentinel.jwt,
      username: user.username ?? user.name ?? user.sub,
      password: token,
      actorId: user.sub,
      organizationId: organization?.id,
      connectionSession: session,
      connectNkey: base64.encode(
        skir.EntityPermissionQualifier.serializer.toBytes(qualifier),
      ),
      requestInboxPrefix: "_INBOX.${user.sub}.$session",
    );
  }
}

/// Owns the transport of one authenticated identity and organization.
///
/// The server grants every realm of the organization, so realms created after
/// connect are reachable without a new connection. Only [retry] replaces the
/// client: it opens a fresh session and hands it to dependents, so retained
/// watches rebind instead of being disposed mid session. Retries are
/// serialized, and closing this owner prevents any later replacement from
/// being published.
final class NatsConnectionOwner {
  NatsConnectionOwner({
    required this._settings,
    required this._clientFactory,
    required this._sessionFactory,
    required this._onReplacement,
  }) {
    _client = _connect();
  }

  final NatsConnectionSettings _settings;
  final NatsClientFactory _clientFactory;
  final NatsConnectionSessionFactory _sessionFactory;
  final void Function(NatsClient) _onReplacement;
  late NatsClient _client;
  Future<void> _operations = Future<void>.value();
  Future<void>? _closing;
  bool _closed = false;

  NatsClient get client => _client;

  /// Opens a fresh transport session and hands it to dependents.
  Future<void> retry() => _enqueue(() async {
    final previous = _client;
    _client = _connect();
    _onReplacement(_client);
    await _closeClient(previous);
  });

  Future<void> _enqueue(Future<void> Function() operation) {
    final result = _operations.then((_) {
      _checkOpen();
      return operation();
    });
    // A failed operation must not prevent subsequent recovery operations.
    _operations = result.catchError((Object _, StackTrace _) {});
    return result;
  }

  NatsClient _connect() {
    final configuration = _settings.configuration(_sessionFactory());
    debugPrint("nats: connecting to ${configuration.url}");
    return _clientFactory(configuration);
  }

  void _checkOpen() {
    if (_closed) {
      throw const NatsClientException(
        kind: NatsFailureKind.closed,
        message: "The authenticated connection scope ended",
      );
    }
  }

  Future<void> close() => _closing ??= _close();

  Future<void> _close() async {
    _closed = true;
    await _closeClient(_client);
  }

  Future<void> _closeClient(NatsClient client) async {
    try {
      await client.close();
    } on Object catch (error, stackTrace) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: "NATS connection",
          context: ErrorDescription("closing an owned transport"),
        ),
      );
    }
  }
}
