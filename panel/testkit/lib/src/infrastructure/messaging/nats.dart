import "dart:async";
import "dart:typed_data";

import "package:dart_nats/dart_nats.dart";
import "package:mocktail/mocktail.dart";

class MockNatsPublication {
  MockNatsPublication({
    required this.subject,
    required Uint8List data,
    required this.replyTo,
    required this.header,
  }) : data = Uint8List.fromList(data);

  final String? subject;
  final Uint8List data;
  final String? replyTo;
  final Header? header;
}

class MockNatsRequest {
  MockNatsRequest({
    required this.subject,
    required Uint8List data,
    required this.header,
  }) : data = Uint8List.fromList(data);

  final String subject;
  final Uint8List data;
  final Header? header;
}

class MockNatsClient extends Mock implements Client {
  final Map<String, Uint8List Function(Uint8List)> _handlers = {};
  final Map<int, MockSubscription<dynamic>> _subscriptions = {};
  Status _status = Status.connected;
  final StreamController<Status> _statusController =
      StreamController<Status>.broadcast();

  int _sidCounter = 0;

  final List<MockNatsPublication> publications = [];
  final List<MockNatsRequest> requests = [];

  Iterable<String> get subscriptionSubjects =>
      _subscriptions.values.map((subscription) => subscription.subject);

  @override
  Status get status => _status;

  @override
  Stream<Status> get statusStream => _statusController.stream;

  @override
  bool get connected => _status == Status.connected;

  void setStatus(Status newStatus) {
    _status = newStatus;
    _statusController.add(newStatus);
  }

  void registerHandler(
    String subject,
    Uint8List Function(Uint8List requestData) handler,
  ) {
    _handlers[subject] = handler;
  }

  void emitMessage(int sid, Uint8List data) {
    if (_subscriptions.containsKey(sid)) {
      final sub = _subscriptions[sid]!;
      final message = Message(sub.subject, sid, data, this);
      sub.addMessage(message);
    }
  }

  void emitMessageOnSubject(String subject, Uint8List data) {
    for (final sub in _subscriptions.values.where(
      (subscription) => subscription.subject == subject,
    )) {
      final message = Message(sub.subject, sub.sid, data, this);
      sub.addMessage(message);
    }
  }

  @override
  Future<Message<T>> request<T>(
    String subj,
    Uint8List data, {
    Duration timeout = const Duration(seconds: 2),
    T Function(String)? jsonDecoder,
    Header? header,
  }) async {
    requests.add(MockNatsRequest(subject: subj, data: data, header: header));
    if (_status != Status.connected) {
      throw NatsException("request error: client not connected");
    }

    if (!_handlers.containsKey(subj)) {
      throw TimeoutException("No handler for subject: $subj", timeout);
    }

    final responseData = _handlers[subj]!(data);
    return Message<T>(subj, 0, responseData, this, jsonDecoder: jsonDecoder);
  }

  @override
  Future<bool> pub(
    String? subject,
    Uint8List data, {
    String? replyTo,
    bool? buffer,
    Header? header,
  }) async {
    if (_status != Status.connected && !(buffer ?? true)) {
      return false;
    }
    publications.add(
      MockNatsPublication(
        subject: subject,
        data: data,
        replyTo: replyTo,
        header: header,
      ),
    );
    return true;
  }

  @override
  Subscription<T> sub<T>(
    String subject, {
    String? queueGroup,
    T Function(String)? jsonDecoder,
  }) {
    _sidCounter++;
    final sub = MockSubscription<T>(_sidCounter, subject);
    _subscriptions[_sidCounter] = sub;
    return sub;
  }

  @override
  bool unSub(Subscription<dynamic> s) {
    if (_subscriptions.containsKey(s.sid)) {
      _subscriptions[s.sid]!.closeStream();
      _subscriptions.remove(s.sid);
      return true;
    }
    return false;
  }

  bool _disposed = false;

  @override
  Future<void> close() async {
    if (_disposed) return;
    _status = Status.closed;
    if (!_statusController.isClosed) {
      _statusController.add(Status.closed);
    }
    for (final sub in _subscriptions.values) {
      sub.closeStream();
    }
    _subscriptions.clear();
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    close();
    _statusController.close();
  }
}

class MockSubscription<T> implements Subscription<T> {
  @override
  final int sid;

  @override
  final String subject;

  final StreamController<Message<T>> _controller =
      StreamController<Message<T>>.broadcast();

  MockSubscription(this.sid, this.subject);

  @override
  Stream<Message<T>> get stream => _controller.stream;

  @override
  String? get queueGroup => null;

  @override
  void add(Message<dynamic> msg) {
    _controller.add(msg as Message<T>);
  }

  void addMessage(Message<dynamic> msg) {
    _controller.add(msg as Message<T>);
  }

  @override
  Future<void> close() async {
    if (!_controller.isClosed) {
      await _controller.close();
    }
  }

  @override
  Future<void> drain() async {
    await close();
  }

  void closeStream() {
    if (!_controller.isClosed) {
      _controller.close();
    }
  }

  @override
  bool unSub() => true;

  @override
  T Function(String)? jsonDecoder;
}
