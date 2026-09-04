import "dart:async";

import "package:flutter/foundation.dart";
import "package:nats_core/nats_core.dart" as core;
import "package:typewriter_panel/infrastructure/messaging/nats_client.dart";

final class NatsCoreClient implements NatsClient {
  factory NatsCoreClient.connect(NatsClientConfiguration configuration) {
    try {
      return NatsCoreClient._(
        core.NatsConnection.connect(
          core.NatsOptions(
            servers: [core.NatsServer.parse(configuration.url)],
            name: "typewriter-panel",
            authentication: core.NatsAuthentication.nkey(
              configuration.seed,
              jwt: configuration.jwt,
              username: configuration.username,
              password: configuration.password,
              connectNkey: configuration.connectNkey,
            ),
            requestInboxPrefix: configuration.requestInboxPrefix,
          ),
        ),
      );
    } on Object catch (error, stackTrace) {
      Error.throwWithStackTrace(_translate(error, stackTrace), stackTrace);
    }
  }

  NatsCoreClient._(this._connection) {
    unawaited(_initialize());
  }

  @visibleForTesting
  factory NatsCoreClient.fromConnectionFuture(
    Future<core.NatsConnection> connection,
  ) => NatsCoreClient._(connection);

  final Future<core.NatsConnection> _connection;
  final StreamController<NatsConnectionState> _connectionStateController =
      StreamController<NatsConnectionState>.broadcast();

  NatsConnectionState _connectionState = const NatsConnecting();
  StreamSubscription<core.NatsConnectionEvent>? _events;
  bool _closed = false;
  Future<void>? _closeOperation;

  @override
  NatsConnectionState get connectionState => _connectionState;

  @override
  Stream<NatsConnectionState> get connectionStateChanges =>
      _connectionStateController.stream;

  Future<void> _initialize() async {
    try {
      final connection = await _connection;
      if (_closed) {
        await connection.close();
        return;
      }
      _events = connection.events.listen(_onEvent);
      _setConnectionState(const NatsConnected());
    } on Object catch (error, stackTrace) {
      if (_closed) return;
      debugPrint("nats: connection error ${_diagnostic(error)}");
      if (kDebugMode) {
        if (error case core.NatsException(:final causeStackTrace?)) {
          debugPrintStack(
            label: "nats: connection error cause",
            stackTrace: causeStackTrace,
          );
        }
      }
      _setConnectionState(NatsFailed(_translate(error, stackTrace)));
    }
  }

  void _onEvent(core.NatsConnectionEvent event) {
    if (_closed) return;

    switch (event) {
      case core.NatsConnected():
        _setConnectionState(const NatsConnected());
      case core.NatsConnecting() || core.NatsReconnecting():
        break;
      case core.NatsDisconnected(:final error, :final willReconnect):
        final failure = _translate(
          error,
          error.causeStackTrace ?? StackTrace.current,
        );
        _setConnectionState(
          willReconnect ? NatsReconnecting(failure) : NatsFailed(failure),
        );
      case core.NatsDraining():
        break;
      case core.NatsClosed(:final error):
        _setConnectionState(
          error == null
              ? const NatsClosed()
              : NatsFailed(
                  _translate(
                    error,
                    error.causeStackTrace ?? StackTrace.current,
                  ),
                ),
        );
      case core.NatsServerError() || core.NatsLameDuckMode():
        break;
    }
  }

  void _setConnectionState(NatsConnectionState connectionState) {
    if (_connectionState.runtimeType == connectionState.runtimeType &&
        connectionState is! NatsReconnecting &&
        connectionState is! NatsFailed) {
      return;
    }
    _connectionState = connectionState;
    if (!_connectionStateController.isClosed) {
      _connectionStateController.add(connectionState);
    }
  }

  Future<core.NatsConnection> _readyConnection() async {
    if (_closed) {
      throw const NatsClientException(
        kind: NatsFailureKind.closed,
        message: "NATS client is closed",
      );
    }
    try {
      return await _connection;
    } on Object catch (error, stackTrace) {
      Error.throwWithStackTrace(_translate(error, stackTrace), stackTrace);
    }
  }

  @override
  Future<NatsMessage> request(
    String subject,
    Uint8List payload, {
    Map<String, String> headers = const {},
    Duration timeout = const Duration(seconds: 10),
  }) async {
    try {
      final connection = await _readyConnection();
      final response = await connection.request(
        subject,
        payload,
        headers: headers.isEmpty
            ? null
            : core.NatsHeaders(entries: headers.entries),
        timeout: timeout,
      );
      return NatsMessage(response.payload);
    } on NatsClientException {
      rethrow;
    } on Object catch (error, stackTrace) {
      Error.throwWithStackTrace(_translate(error, stackTrace), stackTrace);
    }
  }

  @override
  Future<NatsSubscription> subscribe(String subject) async {
    try {
      final connection = await _readyConnection();
      return _NatsCoreSubscription(await connection.subscribe(subject));
    } on NatsClientException {
      rethrow;
    } on Object catch (error, stackTrace) {
      Error.throwWithStackTrace(_translate(error, stackTrace), stackTrace);
    }
  }

  @override
  Future<void> close() => _closeOperation ??= _close();

  Future<void> _close() async {
    if (_closed) return;
    _closed = true;
    _setConnectionState(const NatsClosed());
    try {
      final connection = await _connection;
      await connection.close();
    } on Object {
      // Initial connection failure already owns its transport cleanup.
    } finally {
      await _events?.cancel();
      await _connectionStateController.close();
    }
  }
}

String _diagnostic(Object error) => switch (error) {
  core.NatsException(:final message, :final cause) =>
    "${error.runtimeType}: $message${cause == null ? "" : " (${cause.runtimeType})"}",
  _ => error.runtimeType.toString(),
};

final class _NatsCoreSubscription implements NatsSubscription {
  const _NatsCoreSubscription(this._subscription);

  final core.NatsSubscription _subscription;

  @override
  Stream<NatsMessage> get messages => _subscription.messages.transform(
    StreamTransformer.fromHandlers(
      handleData: (message, sink) => sink.add(NatsMessage(message.payload)),
      handleError: (error, stackTrace, sink) =>
          sink.addError(_translate(error, stackTrace), stackTrace),
    ),
  );

  @override
  Future<void> get done async {
    try {
      await _subscription.done;
    } on Object catch (error, stackTrace) {
      Error.throwWithStackTrace(_translate(error, stackTrace), stackTrace);
    }
  }

  @override
  Future<void> unsubscribe() async {
    try {
      await _subscription.unsubscribe();
    } on Object catch (error, stackTrace) {
      Error.throwWithStackTrace(_translate(error, stackTrace), stackTrace);
    }
  }
}

NatsClientException _translate(Object error, StackTrace stackTrace) {
  if (error is NatsClientException) return error;
  final kind = switch (error) {
    core.NatsAuthenticationException() => NatsFailureKind.authentication,
    core.NatsPermissionException() => NatsFailureKind.permission,
    core.NatsTimeoutException() ||
    core.NatsDrainTimeoutException() => NatsFailureKind.timeout,
    core.NatsNoRespondersException() => NatsFailureKind.noResponders,
    core.NatsClosedException() ||
    core.NatsDrainingException() => NatsFailureKind.closed,
    core.NatsProtocolException() ||
    core.NatsSubjectException() ||
    core.NatsHeaderException() ||
    core.NatsMaxPayloadException() ||
    core.NatsMissingReplySubjectException() ||
    core.NatsSlowConsumerException() => NatsFailureKind.protocol,
    core.NatsConnectionException() ||
    core.NatsDnsException() ||
    core.NatsConnectCandidatesException() ||
    core.NatsReconnectBufferException() ||
    core.NatsMaximumSubscriptionsException() ||
    core.NatsConnectionLimitException() ||
    core.NatsStaleConnectionException() ||
    core.NatsUnsupportedRuntimeException() => NatsFailureKind.unavailable,
    ArgumentError() || FormatException() => NatsFailureKind.protocol,
    _ => NatsFailureKind.unknown,
  };
  return NatsClientException(
    kind: kind,
    message: _translatedMessage(error, kind),
    cause: error,
    causeStackTrace: stackTrace,
  );
}

String _translatedMessage(Object error, NatsFailureKind kind) =>
    switch (error) {
      core.NatsUnknownServerException() => "NATS server rejected the operation",
      core.NatsException(:final message) => message,
      ArgumentError() ||
      FormatException() => "Invalid NATS client configuration",
      _ => kind.safeDescription,
    };
