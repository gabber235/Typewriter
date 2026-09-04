import "dart:typed_data";

enum NatsFailureKind {
  unavailable("NATS service is unavailable"),
  timeout("NATS operation timed out"),
  noResponders("No NATS responder is available"),
  permission("NATS permission was denied"),
  authentication("NATS authentication failed"),
  protocol("NATS protocol operation failed"),
  closed("NATS client is closed"),
  unknown("Unexpected NATS client failure");

  const NatsFailureKind(this.safeDescription);

  final String safeDescription;
}

/// Observable lifecycle of a [NatsClient].
///
/// Terminal failures retain their typed cause. [NatsClosed] is reserved for an
/// explicit local close, so consumers never need to infer failure from a bare
/// status value.
sealed class NatsConnectionState {
  const NatsConnectionState();
}

final class NatsConnecting extends NatsConnectionState {
  const NatsConnecting();
}

final class NatsConnected extends NatsConnectionState {
  const NatsConnected();
}

final class NatsReconnecting extends NatsConnectionState {
  const NatsReconnecting(this.failure);

  final NatsClientException failure;
}

final class NatsFailed extends NatsConnectionState {
  const NatsFailed(this.failure);

  final NatsClientException failure;
}

final class NatsClosed extends NatsConnectionState {
  const NatsClosed();
}

final class NatsClientException implements Exception {
  const NatsClientException({
    required this.kind,
    required this.message,
    this.cause,
    this.causeStackTrace,
  });

  final NatsFailureKind kind;
  final String message;
  final Object? cause;
  final StackTrace? causeStackTrace;

  String get safeDescription => kind.safeDescription;

  @override
  String toString() => "NatsClientException($kind): $safeDescription";
}

final class NatsClientConfiguration {
  const NatsClientConfiguration({
    required this.url,
    required this.seed,
    required this.requestInboxPrefix,
    this.jwt,
    this.username,
    this.password,
    this.connectNkey,
  });

  final String url;
  final String seed;
  final String? jwt;
  final String? username;
  final String? password;
  final String? connectNkey;
  final String requestInboxPrefix;
}

final class NatsMessage {
  NatsMessage(Uint8List payload)
    : payload = Uint8List.fromList(payload).asUnmodifiableView();

  final Uint8List payload;
}

abstract interface class NatsSubscription {
  Stream<NatsMessage> get messages;

  Future<void> get done;

  Future<void> unsubscribe();
}

abstract interface class NatsClient {
  NatsConnectionState get connectionState;

  Stream<NatsConnectionState> get connectionStateChanges;

  Future<NatsMessage> request(
    String subject,
    Uint8List payload, {
    Map<String, String> headers = const {},
    Duration timeout = const Duration(seconds: 10),
  });

  Future<NatsSubscription> subscribe(String subject);

  Future<void> close();
}
