import "package:typewriter_panel/typewriter_panel.dart";

/// The NATS server side of a test world: every connection the panel opens.
///
/// Replaces the client factory, the one boundary between the panel and the
/// NATS package. Each connection is a [FakeNatsClient] that answers with the
/// handlers registered here; [disconnect] and [reconnect] move the current and
/// every later connection, so a test can take the backend away and give it
/// back the way a real outage does. It holds no service rules: what a subject
/// answers is up to the test.
final class FakeNats {
  final _handlers = <String, FutureOr<Uint8List> Function(Uint8List)>{};
  final _connections = <FakeNatsClient>[];
  NatsConnectionState _state = const NatsConnected();

  /// The connection the panel opened last.
  FakeNatsClient get connection => _connections.isEmpty
      ? throw StateError("The panel has not connected to NATS")
      : _connections.last;

  /// Whether the panel opened a connection yet.
  bool get connected => _connections.isNotEmpty;

  /// Replaces the client factory with connections to this server.
  Override get override =>
      natsClientFactoryProvider.overrideWithValue(_connect);

  FakeNatsClient _connect(NatsClientConfiguration configuration) {
    final client = FakeNatsClient(
      actorId: configuration.actorId,
      organizationId: configuration.organizationId,
      connectionSession: configuration.connectionSession,
    )..setConnectionState(_state);
    for (final MapEntry(:key, :value) in _handlers.entries) {
      client.registerHandler(key, value);
    }
    _connections.add(client);
    return client;
  }

  /// Answers every request on [subject] with [handler], on every connection.
  void registerHandler(
    String subject,
    FutureOr<Uint8List> Function(Uint8List requestData) handler,
  ) {
    _handlers[subject] = handler;
    for (final client in _connections) {
      client.registerHandler(subject, handler);
    }
  }

  /// Fails the connection the way an unreachable server does.
  void disconnect({
    NatsClientException failure = const NatsClientException(
      kind: NatsFailureKind.unavailable,
      message: "The test took the server away",
    ),
  }) => _move(NatsFailed(failure));

  /// Gives the connection back.
  void reconnect() => _move(const NatsConnected());

  void _move(NatsConnectionState state) {
    _state = state;
    for (final client in _connections) {
      if (client.connectionState is! NatsClosed) {
        client.setConnectionState(state);
      }
    }
  }

  /// Closes every connection still open.
  Future<void> close() async {
    for (final client in _connections) {
      await client.close();
    }
  }
}

/// A NATS notifier already connected to one client.
///
/// Application tests that drive a projection through raw NATS replies use it
/// to skip the signed in session. Widget tests use [FakeNats] through the
/// world instead, so the real connection owner runs.
class ConnectedNats extends Nats {
  ConnectedNats(this._initialClient);

  final NatsClient _initialClient;

  @override
  NatsClient build() => _initialClient;

  /// Replaces the connection the way a reconnect does.
  void replace(NatsClient client) => state = client;

  @override
  Future<void> retry() async {}
}

final class FakeNatsRequest {
  FakeNatsRequest({
    required this.subject,
    required Uint8List payload,
    required Map<String, String> headers,
    required this.timeout,
  }) : payload = Uint8List.fromList(payload).asUnmodifiableView(),
       headers = Map.unmodifiable(headers);

  final String subject;
  final Uint8List payload;
  final Map<String, String> headers;
  final Duration timeout;
}

final class FakeNatsPublication {
  FakeNatsPublication(this.subject, Uint8List payload)
    : payload = Uint8List.fromList(payload).asUnmodifiableView();

  final String subject;
  final Uint8List payload;
}

final class FakeNatsClient implements NatsClient {
  FakeNatsClient({
    this.actorId = "fixture-user",
    this.organizationId = "fixture-organization",
    this.connectionSession = "0123456789abcdef0123456789abcdef",
  });

  @override
  final String actorId;

  @override
  final String? organizationId;

  @override
  final String connectionSession;

  final Map<String, FutureOr<Uint8List> Function(Uint8List)> _handlers = {};
  final Map<int, FakeNatsSubscription> _subscriptions = {};
  final StreamController<NatsConnectionState> _connectionStateController =
      StreamController<NatsConnectionState>.broadcast(sync: true);

  NatsConnectionState _connectionState = const NatsConnected();
  int _subscriptionCounter = 0;
  bool _closed = false;

  final List<FakeNatsRequest> requests = [];
  final List<FakeNatsPublication> publications = [];

  Iterable<String> get subscriptionSubjects =>
      _subscriptions.values.map((subscription) => subscription.subject);

  @override
  NatsConnectionState get connectionState => _connectionState;

  @override
  Stream<NatsConnectionState> get connectionStateChanges =>
      _connectionStateController.stream;

  void setConnectionState(NatsConnectionState connectionState) {
    _connectionState = connectionState;
    if (!_connectionStateController.isClosed) {
      _connectionStateController.add(connectionState);
    }
  }

  void registerHandler(
    String subject,
    FutureOr<Uint8List> Function(Uint8List requestData) handler,
  ) {
    _handlers[subject] = handler;
  }

  /// Answers with the handler registered for [subject]; completing
  /// [cancelled] first fails the request with [TransferCancelled].
  @override
  Future<NatsMessage> request(
    String subject,
    Uint8List payload, {
    required TransportLimits limits,
    Map<String, String> headers = const {},
    Duration timeout = const Duration(seconds: 10),
    Future<void>? cancelled,
  }) async {
    requests.add(
      FakeNatsRequest(
        subject: subject,
        payload: payload,
        headers: headers,
        timeout: timeout,
      ),
    );
    if (_connectionState is! NatsConnected) {
      throw const NatsClientException(
        kind: NatsFailureKind.unavailable,
        message: "NATS client is not connected",
      );
    }
    final handler = _handlers[subject];
    if (handler == null) {
      throw TimeoutException("No handler for subject: $subject", timeout);
    }
    final reply = Future.sync(() => handler(Uint8List.fromList(payload)));
    final bytes = await switch (cancelled) {
      null => reply,
      final cancellation => Future.any([
        reply,
        cancellation.then<Uint8List>((_) => throw const TransferCancelled()),
      ]),
    };
    return NatsMessage(bytes, subject: subject);
  }

  @override
  Future<void> publish(
    String subject,
    Uint8List payload, {
    Map<String, String> headers = const {},
  }) async {
    if (_connectionState is! NatsConnected) {
      throw const NatsClientException(
        kind: NatsFailureKind.unavailable,
        message: "NATS client is not connected",
      );
    }
    publications.add(FakeNatsPublication(subject, payload));
  }

  @override
  Future<FakeNatsSubscription> subscribe(String subject) async {
    if (_connectionState is NatsClosed) {
      throw const NatsClientException(
        kind: NatsFailureKind.closed,
        message: "NATS client is closed",
      );
    }
    final subscription = FakeNatsSubscription(
      id: ++_subscriptionCounter,
      subject: subject,
      onUnsubscribe: _removeSubscription,
    );
    _subscriptions[subscription.id] = subscription;
    return subscription;
  }

  @override
  Future<FakeNatsSubscription> subscribePersistent(
    String stream,
    String consumer,
    String filterSubject,
  ) => subscribe(filterSubject);

  void emitMessage(int id, Uint8List payload) {
    _subscriptions[id]?.add(payload);
  }

  void emitMessageOnSubject(String subject, Uint8List payload) {
    for (final subscription in _subscriptions.values.toList()) {
      if (_subjectMatches(subscription.subject, subject)) {
        subscription.add(payload, subject: subject);
      }
    }
  }

  bool _subjectMatches(String pattern, String subject) {
    final patternTokens = pattern.split(".");
    final subjectTokens = subject.split(".");
    for (var index = 0; index < patternTokens.length; index++) {
      final token = patternTokens[index];
      if (token == ">") return true;
      if (index >= subjectTokens.length) return false;
      if (token != "*" && token != subjectTokens[index]) return false;
    }
    return patternTokens.length == subjectTokens.length;
  }

  void _removeSubscription(int id) {
    _subscriptions.remove(id);
  }

  @override
  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    _connectionState = const NatsClosed();
    // A real client reports closing after the call that closed it returns,
    // so a provider closing it while it disposes is not notified mid dispose.
    await Future<void>.value();
    _connectionStateController.add(const NatsClosed());
    final subscriptions = _subscriptions.values.toList();
    for (final subscription in subscriptions) {
      await subscription.unsubscribe();
    }
    await _connectionStateController.close();
  }

  Future<void> dispose() => close();
}

final class FakeNatsSubscription implements NatsSubscription {
  FakeNatsSubscription({
    required this.id,
    required this.subject,
    required this._onUnsubscribe,
  });

  final int id;
  final String subject;
  final void Function(int id) _onUnsubscribe;
  final StreamController<NatsMessage> _controller =
      StreamController<NatsMessage>.broadcast();
  bool _closed = false;

  @override
  Stream<NatsMessage> get messages => _controller.stream;

  @override
  Future<void> get done => _controller.done;

  void add(Uint8List payload, {String? subject}) {
    if (!_closed) {
      _controller.add(NatsMessage(payload, subject: subject ?? this.subject));
    }
  }

  @override
  Future<void> unsubscribe() async {
    if (_closed) return;
    _closed = true;
    _onUnsubscribe(id);
    await _controller.close();
  }
}
