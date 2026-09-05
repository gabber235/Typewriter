import "dart:async";
import "dart:typed_data";

import "package:typewriter_panel/typewriter_panel.dart";

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

  @override
  Future<NatsMessage> request(
    String subject,
    Uint8List payload, {
    Map<String, String> headers = const {},
    Duration timeout = const Duration(seconds: 10),
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
    return NatsMessage(
      await handler(Uint8List.fromList(payload)),
      subject: subject,
    );
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
    setConnectionState(const NatsClosed());
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
    required void Function(int id) onUnsubscribe,
  }) : _onUnsubscribe = onUnsubscribe;

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
