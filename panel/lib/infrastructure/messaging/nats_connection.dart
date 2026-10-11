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

@freezed
sealed class _RealmAccess with _$RealmAccess {
  const factory _RealmAccess.required(Set<skir.RecordId> realms) =
      _RequiredRealmAccess;
  const factory _RealmAccess.exact(Set<skir.RecordId> realms) =
      _ExactRealmAccess;

  const _RealmAccess._();

  bool accepts(Set<skir.RecordId> admitted) => switch (this) {
    _RequiredRealmAccess(:final realms) => admitted.containsAll(realms),
    _ExactRealmAccess(:final realms) =>
      const SetEquality<skir.RecordId>().equals(admitted, realms),
  };
}

/// Owns transports for one authenticated identity and organization.
///
/// Grant changes and retries are serialized. A replacement becomes visible only
/// after the server admits the expected grants. Failed candidates are closed
/// while the active client remains available. Closing this owner also closes an
/// in flight candidate and prevents any later replacement from being published.
final class NatsConnectionOwner {
  NatsConnectionOwner({
    required this._settings,
    required this._clientFactory,
    required this._sessionFactory,
    required this._onReplacement,
  }) {
    _client = _connect();
    _observeClient(_client);
  }

  final NatsConnectionSettings _settings;
  final NatsClientFactory _clientFactory;
  final NatsConnectionSessionFactory _sessionFactory;
  final void Function(NatsClient) _onReplacement;
  late NatsClient _client;
  NatsClient? _candidate;
  StreamSubscription<NatsConnectionState>? _lifecycle;
  Set<skir.RecordId>? _admitted;
  _RealmAccess _expected = const _RealmAccess.required({});
  Future<void> _operations = Future<void>.value();
  Future<void>? _closing;
  bool _closed = false;

  NatsClient get client => _client;

  Future<void> ensureRealmsAdmitted(Set<skir.RecordId> required) {
    final expected = _RealmAccess.required(Set.unmodifiable(required));
    return _enqueue(() => _admit(expected));
  }

  Future<void> refreshAuthorization(Set<skir.RecordId> observed) {
    final expected = _RealmAccess.exact(Set.unmodifiable(observed));
    return _enqueue(() => _admit(expected));
  }

  /// Repeats the last requested grant requirement with a fresh transport session.
  Future<void> retry() => _enqueue(() => _replace(_expected));

  Future<void> _enqueue(Future<void> Function() operation) {
    final result = _operations.then((_) {
      _checkOpen();
      return operation();
    });
    // A failed operation must not prevent subsequent recovery operations.
    _operations = result.catchError((Object _, StackTrace _) {});
    return result;
  }

  Future<void> _admit(_RealmAccess expected) async {
    _expected = expected;
    final known = _admitted;
    if (expected is _ExactRealmAccess &&
        _client.connectionState is NatsConnected &&
        known != null &&
        expected.accepts(known)) {
      return;
    }
    final admitted = (await _client.queryPermissions()).admittedRealms(_client);
    _checkOpen();
    if (expected.accepts(admitted)) {
      _admitted = admitted;
      return;
    }
    await _replace(expected);
  }

  Future<void> _replace(_RealmAccess expected) async {
    final candidate = _connect();
    _candidate = candidate;
    try {
      final admitted = (await candidate.queryPermissions()).admittedRealms(
        candidate,
      );
      _checkOpen();
      if (!expected.accepts(admitted)) {
        throw const NatsClientException(
          kind: NatsFailureKind.permission,
          message: "Required Realm grants were not admitted by the server",
        );
      }
      final previous = _client;
      _client = candidate;
      _observeClient(candidate);
      _admitted = admitted;
      _candidate = null;
      _onReplacement(candidate);
      await _closeClient(previous);
    } finally {
      if (identical(_candidate, candidate)) {
        _candidate = null;
        await _closeClient(candidate);
      }
    }
  }

  NatsClient _connect() {
    final configuration = _settings.configuration(_sessionFactory());
    debugPrint("nats: connecting to ${configuration.url}");
    return _clientFactory(configuration);
  }

  void _observeClient(NatsClient client) {
    final previous = _lifecycle;
    if (previous != null) unawaited(previous.cancel());
    _lifecycle = client.connectionStateChanges.listen((state) {
      if (identical(client, _client) && state is! NatsConnected) {
        _admitted = null;
      }
    });
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
    await Future.wait([
      if (_lifecycle case final lifecycle?) lifecycle.cancel(),
      _closeClient(_client),
      if (_candidate case final candidate?) _closeClient(candidate),
    ]);
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
