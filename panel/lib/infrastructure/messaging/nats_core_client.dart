import "package:typewriter_panel/typewriter_panel.dart";

/// Owns the concrete NATS connection for the panel transport boundary.
///
/// The connection is created once and remains private to this adapter. This
/// class translates package errors, maps package events to the panel lifecycle,
/// and closes the connection and its event stream together. Higher layers only
/// see [NatsClient], which keeps Skir serialization, mutation identity, and
/// resource coordination independent from transport implementation details.
final class NatsCoreClient implements NatsClient {
  /// Starts a client whose connection and subscriptions are owned by this instance.
  factory NatsCoreClient.connect(NatsClientConfiguration configuration) {
    try {
      return NatsCoreClient._(
        NatsConnection.connect(
          NatsOptions(
            servers: [NatsServer.parse(configuration.url)],
            name: "typewriter-panel",
            authentication: NatsAuthentication.nkey(
              configuration.seed,
              jwt: configuration.jwt,
              username: configuration.username,
              password: configuration.password,
              connectNkey: configuration.connectNkey,
            ),
            requestInboxPrefix: configuration.requestInboxPrefix,
          ),
        ),
        configuration,
      );
    } on Object catch (error, stackTrace) {
      Error.throwWithStackTrace(_translate(error, stackTrace), stackTrace);
    }
  }

  NatsCoreClient._(
    this._connection,
    this._configuration, {
    this._persistentOpener,
  }) {
    unawaited(_initialize());
  }

  /// Injects a connection future so lifecycle and failure behavior can be
  /// tested without a live server.
  @visibleForTesting
  factory NatsCoreClient.fromConnectionFuture(
    Future<NatsConnection> connection, {
    required NatsClientConfiguration configuration,
    Future<NatsSubscription> Function(
      String stream,
      String consumerName,
      String filterSubject,
    )?
    persistentOpener,
  }) => NatsCoreClient._(
    connection,
    configuration,
    persistentOpener: persistentOpener,
  );

  final Future<NatsConnection> _connection;
  final NatsClientConfiguration _configuration;
  final Future<NatsSubscription> Function(
    String stream,
    String consumerName,
    String filterSubject,
  )?
  _persistentOpener;
  final StreamController<NatsConnectionState> _connectionStateController =
      StreamController<NatsConnectionState>.broadcast();

  NatsConnectionState _connectionState = const NatsConnecting();
  StreamSubscription<NatsConnectionEvent>? _events;
  bool _closed = false;
  Future<void>? _closeOperation;
  final Map<String, Future<NatsSubscription>> _projectionSubscriptions = {};

  @override
  String get actorId => _configuration.actorId;

  @override
  String? get organizationId => _configuration.organizationId;

  @override
  String get connectionSession => _configuration.connectionSession;

  @override
  NatsConnectionState get connectionState => _connectionState;

  @override
  Stream<NatsConnectionState> get connectionStateChanges =>
      _connectionStateController.stream;

  /// Attaches one event listener and publishes the initial connection result.
  ///
  /// A close racing with connection establishment still closes the eventual
  /// connection. That keeps this object as the sole owner of transport
  /// lifetime, including a connection that completes after local shutdown.
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
      _setConnectionState(NatsFailed(_translate(error, stackTrace)));
      debugPrint("nats: connection error ${_diagnostic(error)}");
      if (kDebugMode) {
        if (error case NatsException(:final causeStackTrace?)) {
          debugPrint("nats: connection error cause\n$causeStackTrace");
        }
      }
    }
  }

  void _onEvent(NatsConnectionEvent event) {
    if (_closed) return;

    switch (event) {
      case CoreNatsConnected():
        _setConnectionState(const NatsConnected());
      case CoreNatsConnecting() || CoreNatsReconnecting():
        break;
      case NatsDisconnected(:final error, :final willReconnect):
        final failure = _translate(
          error,
          error.causeStackTrace ?? StackTrace.current,
        );
        _setConnectionState(
          willReconnect ? NatsReconnecting(failure) : NatsFailed(failure),
        );
      case NatsDraining():
        break;
      case CoreNatsClosed(:final error):
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
      case NatsServerError() || NatsLameDuckMode():
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

  Future<NatsConnection> _readyConnection() async {
    if (_closed) {
      throw const NatsClientException(
        kind: NatsFailureKind.closed,
        message: "NATS client is closed",
      );
    }
    try {
      final connection = await _connection;
      if (_closed) {
        throw const NatsClientException(
          kind: NatsFailureKind.closed,
          message: "NATS client is closed",
        );
      }
      return connection;
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
        headers: headers.isEmpty ? null : NatsHeaders(entries: headers.entries),
        timeout: timeout,
      );
      return NatsMessage(response.payload, subject: response.subject);
    } on NatsClientException {
      rethrow;
    } on Object catch (error, stackTrace) {
      Error.throwWithStackTrace(_translate(error, stackTrace), stackTrace);
    }
  }

  @override
  Future<void> publish(
    String subject,
    Uint8List payload, {
    Map<String, String> headers = const {},
  }) async {
    try {
      final connection = await _readyConnection();
      await connection.publish(
        subject,
        payload,
        headers: headers.isEmpty ? null : NatsHeaders(entries: headers.entries),
      );
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
      final subscription = await connection.subscribe(subject);
      try {
        await connection.flush();
      } on Object catch (error, stackTrace) {
        try {
          await subscription.unsubscribe();
        } on Object {
          // The admission failure remains the cause owned by this operation.
        }
        Error.throwWithStackTrace(error, stackTrace);
      }
      return _NatsCoreSubscription(subscription);
    } on NatsClientException {
      rethrow;
    } on Object catch (error, stackTrace) {
      Error.throwWithStackTrace(_translate(error, stackTrace), stackTrace);
    }
  }

  @override
  Future<NatsSubscription> subscribePersistent(
    String stream,
    String consumerName,
    String filterSubject,
  ) async {
    if (_closed) {
      throw const NatsClientException(
        kind: NatsFailureKind.closed,
        message: "NATS client is closed",
      );
    }
    if (_projectionSubscriptions.containsKey(consumerName)) {
      throw StateError("This projection already has a subscription owner");
    }
    final acquisition =
        _persistentOpener?.call(stream, consumerName, filterSubject) ??
        _openPersistent(stream, consumerName, filterSubject);
    _projectionSubscriptions[consumerName] = acquisition;
    try {
      return await acquisition;
    } on NatsClientException {
      final _ = _projectionSubscriptions.remove(consumerName);
      rethrow;
    } on Object catch (error, stackTrace) {
      final _ = _projectionSubscriptions.remove(consumerName);
      Error.throwWithStackTrace(_translate(error, stackTrace), stackTrace);
    }
  }

  Future<_NatsNativeProjectionSubscription> _openPersistent(
    String stream,
    String consumerName,
    String filterSubject,
  ) async {
    final connection = await _readyConnection();
    final manager = JetStreamContext(connection).consumers;
    await _deleteNamedConsumer(manager, stream, consumerName);
    final config = JetStreamPullConsumerConfig(
      name: consumerName,
      durable: false,
      filters: JetStreamConsumerFilters.single(filterSubject),
      ackPolicy: JetStreamConsumerAckPolicy.none,
      start: const JetStreamConsumerStart.all(),
      inactiveThreshold: JetStreamNanoseconds.fromDuration(
        const Duration(minutes: 2),
      ),
    );
    late final JetStreamConsumerInfo info;
    try {
      info = await manager.createPull(stream, config);
    } on NatsTimeoutException {
      info = await manager.info(stream, consumerName);
    } on NatsConnectionException {
      info = await manager.info(stream, consumerName);
    }
    _requireNamedConsumer(info, config);
    final consumer = await manager.pull(stream, consumerName);
    return _NatsNativeProjectionSubscription(
      consumer.consume(),
      cleanup: () async {
        if (connection.isConnected) {
          await _deleteNamedConsumer(manager, stream, consumerName);
        }
      },
      release: () => _projectionSubscriptions.remove(consumerName),
    );
  }

  void _requireNamedConsumer(
    JetStreamConsumerInfo info,
    JetStreamPullConsumerConfig expected,
  ) {
    final actual = info.config;
    if (info.name != expected.name ||
        actual.kind != JetStreamConsumerKind.pull ||
        actual.durableName != null ||
        actual.ackPolicy != JetStreamConsumerAckPolicy.none ||
        !const ListEquality<String>().equals(
          actual.filterSubjects,
          expected.filters.subjects,
        )) {
      throw StateError("Named projection consumer definition differs");
    }
  }

  Future<void> _deleteNamedConsumer(
    JetStreamConsumerManager manager,
    String stream,
    String consumer,
  ) async {
    try {
      await manager.delete(stream, consumer);
    } on JetStreamApiException catch (error) {
      if (error.code != 404) rethrow;
    } on NatsTimeoutException {
      await _reconcileDeletion(manager, stream, consumer);
    } on NatsConnectionException {
      await _reconcileDeletion(manager, stream, consumer);
    }
  }

  Future<void> _reconcileDeletion(
    JetStreamConsumerManager manager,
    String stream,
    String consumer,
  ) async {
    try {
      await manager.info(stream, consumer);
    } on JetStreamApiException catch (error) {
      if (error.code == 404) return;
      rethrow;
    }
    await manager.delete(stream, consumer);
  }

  /// Closes the transport exactly once and completes after owned resources are
  /// released. A failed initial connection remains a terminal transport event;
  /// it does not prevent explicit local closure from becoming [NatsClosed].
  @override
  Future<void> close() => _closeOperation ??= _close();

  Future<void> _close() async {
    if (_closed) return;
    _closed = true;

    _setConnectionState(const NatsClosed());

    final acquisitions = _projectionSubscriptions.values.toList(
      growable: false,
    );
    Object? failure;
    StackTrace? failureStackTrace;
    try {
      try {
        await Future.wait(
          acquisitions.map(
            (acquisition) => acquisition.then(
              (subscription) => subscription.unsubscribe(),
              onError: (Object _, StackTrace _) {},
            ),
          ),
        );
      } on Object catch (error, stackTrace) {
        failure = error;
        failureStackTrace = stackTrace;
      }

      NatsConnection? connection;
      try {
        connection = await _connection;
      } on Object {
        // A connection that never opened has no transport left to close.
      }
      if (connection != null) {
        try {
          await connection.close();
        } on Object catch (error, stackTrace) {
          failure ??= error;
          failureStackTrace ??= stackTrace;
        }
      }
    } finally {
      await _events?.cancel();
      await _connectionStateController.close();
    }
    if (failure != null) {
      Error.throwWithStackTrace(failure, failureStackTrace!);
    }
  }
}

String _diagnostic(Object error) => switch (error) {
  NatsException(:final message, :final cause) =>
    "${error.runtimeType}: $message${cause == null ? "" : " (${cause.runtimeType})"}",
  _ => error.runtimeType.toString(),
};

final class _NatsCoreSubscription implements NatsSubscription {
  const _NatsCoreSubscription(this._subscription);

  final CoreNatsSubscription _subscription;

  @override
  Stream<NatsMessage> get messages => _subscription.messages.transform(
    StreamTransformer.fromHandlers(
      handleData: (message, sink) =>
          sink.add(NatsMessage(message.payload, subject: message.subject)),
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

final class _NatsNativeProjectionSubscription implements NatsSubscription {
  _NatsNativeProjectionSubscription(
    this.operation, {
    required this.cleanup,
    required this.release,
  });

  final JetStreamConsumerStream operation;
  final Future<void> Function() cleanup;
  final VoidCallback release;
  Future<void>? _unsubscribing;

  @override
  Stream<NatsMessage> get messages => operation.messages.transform(
    StreamTransformer.fromHandlers(
      handleData: (delivery, sink) => sink.add(
        NatsMessage(
          delivery.message.payload,
          subject: delivery.message.subject,
        ),
      ),
      handleError: (error, stackTrace, sink) =>
          sink.addError(_translate(error, stackTrace), stackTrace),
    ),
  );

  @override
  Future<void> get done async {
    try {
      await operation.done;
    } on Object catch (error, stackTrace) {
      Error.throwWithStackTrace(_translate(error, stackTrace), stackTrace);
    }
  }

  @override
  Future<void> unsubscribe() => _unsubscribing ??= () async {
    try {
      try {
        try {
          await operation.stop();
        } on Object {
          // The native stream and done retain the terminal delivery failure.
        }
        try {
          await operation.done;
        } on Object {
          // Delivery failure remains observable through messages and done.
        }
        await cleanup();
      } on Object catch (error, stackTrace) {
        Error.throwWithStackTrace(_translate(error, stackTrace), stackTrace);
      }
    } finally {
      release();
    }
  }();
}

NatsClientException _translate(Object error, StackTrace stackTrace) {
  if (error is NatsClientException) return error;
  final kind = switch (error) {
    JetStreamConsumerHeartbeatException() => NatsFailureKind.timeout,
    JetStreamApiException(:final code) when code == 404 =>
      NatsFailureKind.unavailable,
    JetStreamConsumerStatusException(:final code) when code == 404 =>
      NatsFailureKind.unavailable,
    JetStreamConsumerStatusException(code: 409, :final description)
        when _lostConsumerStatus(description) =>
      NatsFailureKind.unavailable,
    JetStreamApiException(:final code) when code == 403 =>
      NatsFailureKind.permission,
    JetStreamApiException() ||
    JetStreamProtocolException() ||
    JetStreamConsumerStatusException() => NatsFailureKind.protocol,
    NatsAuthenticationException() => NatsFailureKind.authentication,
    NatsPermissionException() => NatsFailureKind.permission,
    NatsTimeoutException() ||
    NatsDrainTimeoutException() => NatsFailureKind.timeout,
    NatsNoRespondersException() => NatsFailureKind.noResponders,
    NatsClosedException() || NatsDrainingException() => NatsFailureKind.closed,
    NatsProtocolException() ||
    NatsSubjectException() ||
    NatsHeaderException() ||
    NatsMaxPayloadException() ||
    NatsMissingReplySubjectException() ||
    NatsSlowConsumerException() => NatsFailureKind.protocol,
    NatsConnectionException() ||
    NatsDnsException() ||
    NatsConnectCandidatesException() ||
    NatsReconnectBufferException() ||
    NatsMaximumSubscriptionsException() ||
    NatsConnectionLimitException() ||
    NatsStaleConnectionException() ||
    NatsUnsupportedRuntimeException() => NatsFailureKind.unavailable,
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

bool _lostConsumerStatus(String description) {
  final normalized = description.toLowerCase();
  return normalized.contains("consumer deleted") ||
      normalized.contains("leadership change");
}

String _translatedMessage(Object error, NatsFailureKind kind) =>
    switch (error) {
      NatsUnknownServerException() => "NATS server rejected the operation",
      NatsException(:final message) => message,
      ArgumentError() ||
      FormatException() => "Invalid NATS client configuration",
      _ => kind.safeDescription,
    };
