import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
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

  /// The requests the panel sent to [subject] over its last connection,
  /// oldest first; none before it connected.
  Iterable<FakeNatsRequest> requestsTo(String subject) =>
      connected ? connection.requestsTo(subject) : const [];

  /// Whether the panel opened a connection yet.
  bool get connected => _connections.isNotEmpty;

  /// Replaces the client factory with connections to this server.
  Override get override =>
      natsClientFactoryProvider.overrideWithValue(_connect);

  /// Decides when the server admits each subscription the panel asks for,
  /// on every connection: the subscription waits for the future it returns,
  /// so a test holds one pending until it completes that future. [persistent]
  /// tells a named consumer from a core subscription. Null, or a null
  /// result, admits at once.
  Future<void>? Function(String subject, {required bool persistent})?
  admitSubscription;

  /// Every connection the panel opened, oldest first.
  List<FakeNatsClient> get connections => List.unmodifiable(_connections);

  /// Opens a connection to this server, the way the client factory the
  /// [override] installs does; for code that takes the factory directly.
  FakeNatsClient connect(NatsClientConfiguration configuration) =>
      _connect(configuration);

  FakeNatsClient _connect(NatsClientConfiguration configuration) {
    final client = FakeNatsClient(
      actorId: configuration.actorId,
      organizationId: configuration.organizationId,
      connectionSession: configuration.connectionSession,
    );
    client.admitSubscription = (subject, {required persistent}) =>
        admitSubscription?.call(subject, persistent: persistent);
    client.setConnectionState(_state);
    for (final MapEntry(:key, :value) in _handlers.entries) {
      client.registerHandler(key, value);
    }
    _connections.add(client);
    return client;
  }

  /// Answers every request on [subject] with [handler], on every connection.
  /// The commands this double answers, each after [latency] and failing
  /// with what [failure] reads when it reads anything.
  FakeNatsCommands commands({
    required Duration latency,
    required Object? Function() failure,
  }) => FakeNatsCommands._(this, latency, failure);

  /// What the handler registered for [operation]'s subject answers its
  /// request, decoded, the way a backend client would read it.
  Future<TResponse> answer<TResponse>(
    SkirRouteOperation<TResponse> operation,
  ) async {
    final handler =
        _handlers[operation.subject] ??
        (throw StateError("Nothing answers ${operation.subject}"));
    return operation.responseSerializer.fromBytes(
      await handler(operation.requestBytes),
    );
  }

  void registerHandler(
    String subject,
    FutureOr<Uint8List> Function(Uint8List requestData) handler,
  ) {
    _handlers[subject] = handler;
    for (final client in _connections) {
      client.registerHandler(subject, handler);
    }
  }

  /// Holds every later request on [subject], on every connection, until the
  /// test answers it; returns the held requests, oldest first.
  List<Completer<Uint8List>> holdRequests(String subject) {
    final held = <Completer<Uint8List>>[];
    registerHandler(subject, (_) {
      final request = Completer<Uint8List>();
      held.add(request);
      return request.future;
    });
    return held;
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

  /// Keeps the current and every later connection in [state], whatever
  /// [disconnect] and [reconnect] ask for afterwards, so the screen it shows
  /// stays for inspection.
  void hold(NatsConnectionState state) {
    _move(state);
    _held = true;
  }

  var _held = false;

  void _move(NatsConnectionState state) {
    if (_held) return;
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

/// One panel connection to [FakeNats], or a lone connection for code that
/// takes a client directly.
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

  /// What unsubscribing fails with once the subscription closed, the way a
  /// broker that cannot confirm the cleanup does; null lets it succeed.
  Object? unsubscribeFailure;

  /// Decides when this connection admits each subscription, as
  /// [FakeNats.admitSubscription] does for every connection.
  Future<void>? Function(String subject, {required bool persistent})?
  admitSubscription;

  /// The requests sent to [subject] over this connection, oldest first.
  Iterable<FakeNatsRequest> requestsTo(String subject) =>
      requests.where((request) => request.subject == subject);

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
    await admitSubscription?.call(subject, persistent: false);
    return _open(subject);
  }

  @override
  Future<FakeNatsSubscription> subscribePersistent(
    String stream,
    String consumer,
    String filterSubject,
  ) async {
    await admitSubscription?.call(filterSubject, persistent: true);
    return _open(filterSubject);
  }

  FakeNatsSubscription _open(String subject) {
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
      unsubscribeFailure: () => unsubscribeFailure,
    );
    _subscriptions[subscription.id] = subscription;
    return subscription;
  }

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

  /// Ends every subscription matching [subject] with [error], the way a lost
  /// reader or a broken stream does.
  void failOnSubject(String subject, Object error) {
    for (final subscription in _subscriptions.values.toList()) {
      if (_subjectMatches(subscription.subject, subject)) {
        subscription.fail(error);
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
      try {
        await subscription.unsubscribe();
      } on Object {
        // A failing cleanup the test chose still ends the subscription.
      }
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
    this._unsubscribeFailure,
  });

  final int id;
  final String subject;
  final void Function(int id) _onUnsubscribe;
  final Object? Function()? _unsubscribeFailure;
  // One reader, as on a real subscription. Cancelling it answers with a
  // future of the test's own zone: the already completed future Dart returns
  // otherwise resumes its awaiter only on the real event loop, which a widget
  // test's fake clock never reaches, so a watch closing its subscription
  // would never finish.
  late final StreamController<NatsMessage> _controller =
      StreamController<NatsMessage>(onCancel: () => Future<void>.value());
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

  /// Ends delivery with [error]; the subscription stays registered until
  /// its owner unsubscribes, as a lost server side reader does.
  void fail(Object error) {
    if (_closed || _controller.isClosed) return;
    _controller.addError(error);
    unawaited(_controller.close());
  }

  /// How often the owner asked to end the subscription.
  var unsubscribes = 0;

  @override
  Future<void> unsubscribe() async {
    unsubscribes++;
    if (_closed) return;
    _closed = true;
    _onUnsubscribe(id);
    // A server forgets the interest at once; it does not wait for the
    // subscriber's listeners to see the end, so neither does the double.
    unawaited(_controller.close());
    if (_unsubscribeFailure?.call() case final failure?) throw failure;
  }
}

/// Registers command handlers on a [FakeNats] that answer each decoded
/// request after a latency, unless a failure is set.
final class FakeNatsCommands {
  FakeNatsCommands._(this._nats, this._latency, this._failure);

  final FakeNats _nats;
  final Duration _latency;
  final Object? Function() _failure;

  /// Answers [operation] with what [reply] makes of each request decoded by
  /// [requests].
  void call<TRequest, TResponse>(
    SkirRouteOperation<TResponse> operation,
    skir.Serializer<TRequest> requests,
    TResponse Function(TRequest request) reply,
  ) => _nats.registerHandler(operation.subject, (bytes) async {
    await Future<void>.delayed(_latency);
    if (_failure() case final error?) throw error;
    return operation.responseSerializer.toBytes(
      reply(requests.fromBytes(bytes)),
    );
  });
}
