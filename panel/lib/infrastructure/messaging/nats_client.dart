import "package:typewriter_panel/typewriter_panel.dart";

/// Stable failure categories exposed by the panel transport boundary.
///
/// The category is safe to use in UI and recovery policy. The original cause
/// remains available on [NatsClientException] for diagnostics without exposing
/// its potentially sensitive text through normal presentation paths.
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

  /// Fixed text suitable for user facing recovery or status presentation.
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

/// The connection attempt has started but is not usable yet.
final class NatsConnecting extends NatsConnectionState {
  const NatsConnecting();
}

/// The transport has an active connection and accepts operations.
final class NatsConnected extends NatsConnectionState {
  const NatsConnected();
}

/// The connection was lost, but the underlying client will try to recover.
final class NatsReconnecting extends NatsConnectionState {
  const NatsReconnecting(this.failure);

  /// The translated reason for the disconnect.
  final NatsClientException failure;
}

/// The transport cannot recover without a new client or explicit retry.
final class NatsFailed extends NatsConnectionState {
  const NatsFailed(this.failure);

  /// The translated terminal failure.
  final NatsClientException failure;
}

/// Local shutdown completed. No further operations are accepted.
final class NatsClosed extends NatsConnectionState {
  const NatsClosed();
}

/// Transport failure with a safe message and an optional diagnostic cause.
///
/// Callers should branch on [kind] or [safeDescription]. [message] may contain
/// package or server context for controlled handling, while [toString] omits
/// both it and the original cause to avoid leaking credentials or wire data.
final class NatsClientException implements Exception {
  const NatsClientException({
    required this.kind,
    required this.message,
    this.cause,
    this.causeStackTrace,
  });

  /// The stable category used for recovery and presentation decisions.
  final NatsFailureKind kind;

  /// Context retained for controlled diagnostics, but not included by [toString].
  final String message;

  /// The original package or server error, when one exists.
  final Object? cause;

  /// The original error stack, when one exists.
  final StackTrace? causeStackTrace;

  /// A fixed description safe to show outside diagnostic tooling.
  String get safeDescription => kind.safeDescription;

  @override
  String toString() => "NatsClientException($kind): $safeDescription";
}

/// Credentials and protocol settings needed to create one NATS transport owner.
///
/// Authentication material is kept at this boundary because it configures the
/// connection, not a Skir request or a mutation. [requestInboxPrefix] scopes
/// request replies to the authenticated panel session.
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

  /// NATS server URL.
  final String url;

  /// NKey seed used by the connection authenticator.
  final String seed;

  /// Optional JWT paired with [seed].
  final String? jwt;

  /// Optional username presented during connection authentication.
  final String? username;

  /// Optional password presented during connection authentication.
  final String? password;

  /// Optional connect NKey used to qualify the authenticated session.
  final String? connectNkey;

  /// Prefix used to isolate request replies for this authenticated session.
  final String requestInboxPrefix;
}

/// Immutable transport data crossing the NATS boundary.
///
/// The payload is copied and exposed read only, preventing a caller from
/// changing bytes while a serializer, retry, or replay still uses them.
final class NatsMessage {
  NatsMessage(Uint8List payload, {this.subject = ""})
    : payload = Uint8List.fromList(payload).asUnmodifiableView();

  /// Subject from which the message was received, when the transport provides it.
  final String subject;

  /// Read only copy of the wire payload.
  final Uint8List payload;
}

/// A subscription owned by the transport boundary.
///
/// The message stream and [done] retain transport failures as stream or future
/// errors. [unsubscribe] is idempotent from the caller's perspective and ends
/// delivery without transferring ownership of the underlying connection.
abstract interface class NatsSubscription {
  /// Messages delivered until unsubscribe or connection shutdown.
  Stream<NatsMessage> get messages;

  /// Completes when delivery ends, or with the transport failure that ended it.
  Future<void> get done;

  /// Stops delivery without closing the shared NATS connection.
  Future<void> unsubscribe();
}

/// The panel's transport boundary for request, publish, and subscription work.
///
/// Implementations own connection readiness, transport error translation,
/// subscription cleanup, and connection shutdown. Callers depend on this
/// contract instead of the NATS packages, so typed Skir adapters and mutation
/// orchestration cannot accidentally acquire or close the shared connection.
abstract interface class NatsClient {
  /// Current lifecycle state, available synchronously to new consumers.
  NatsConnectionState get connectionState;

  /// Emits lifecycle changes after the synchronous [connectionState] value.
  /// Terminal failure values retain their typed cause for recovery decisions.
  Stream<NatsConnectionState> get connectionStateChanges;

  /// Sends a request and waits for the matching reply or [timeout].
  /// Headers are transport metadata and are not part of the payload contract.
  Future<NatsMessage> request(
    String subject,
    Uint8List payload, {
    Map<String, String> headers = const {},
    Duration timeout = const Duration(seconds: 10),
  });

  /// Publishes bytes without waiting for an application response.
  /// The returned future covers transport acceptance, not feature integration.
  Future<void> publish(
    String subject,
    Uint8List payload, {
    Map<String, String> headers = const {},
  });

  /// Subscribes to a subject. The returned subscription owns delivery until
  /// [NatsSubscription.unsubscribe] or connection shutdown.
  Future<NatsSubscription> subscribe(String subject);

  /// Creates an ordered JetStream subscription for one stream filter.
  /// Sequence recovery remains the responsibility of the protocol adapter.
  Future<NatsSubscription> subscribeOrdered(
    String stream,
    String filterSubject,
  );

  /// Ends the shared transport and all owned subscriptions. Calls are safe to
  /// repeat and complete only after connection cleanup finishes.
  Future<void> close();
}
