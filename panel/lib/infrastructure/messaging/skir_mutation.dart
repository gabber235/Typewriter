import "dart:async";
import "dart:typed_data";

import "package:riverpod/riverpod.dart";
import "package:skir_client/skir_client.dart";
import "package:typewriter_panel/typewriter_panel.dart";

/// Classification returned by a feature after decoding a mutation response.
///
/// The distinction controls whether the shared submission owner can mark the
/// attempt complete, surface a normal rejection, or protect against replaying
/// an operation whose outcome is not known.
enum MutationResponseDisposition { confirmed, rejected, uncertain }

/// Adapts a Riverpod scope to the shared mutation submission boundary.
///
/// These helpers keep Skir bytes and serializers at the messaging edge while
/// [PreparedCommit] owns submission identity, resource reservations, replay
/// policy, and integration. The originating scope is retained until the
/// prepared work is disposed, so deferred attempts cannot silently use a
/// different dependency graph.
extension RefSkirMutation on Ref {
  /// Freezes a mutation for deferred execution by the shared work owner.
  PreparedCommit<TResponse> prepareSkir<TResponse>(
    String subject,
    Uint8List requestBytes,
    Serializer<TResponse> serializer, {
    required String label,
    required MutationResponseDisposition Function(TResponse) classify,
    Future<void> Function(TResponse)? onResponse,
    String? submissionId,
    Set<Object> resources = const {},
    SubmissionReplay replay = SubmissionReplay.unsupported,
  }) {
    final retention = keepAlive();
    return SkirMutationClient(
          () => read(natsProvider),
          () => read(panelTelemetryProvider.future),
        )
        .prepare(
          subject,
          requestBytes,
          serializer,
          label: label,
          classify: classify,
          onResponse: onResponse,
          submissionId: submissionId,
          resources: resources,
          replay: replay,
        )
        .copyWith(dispose: retention.close);
  }

  /// Prepares and immediately submits one mutation through local work control.
  ///
  /// Unlike [prepareSkir], this operation transfers the prepared commit to the
  /// current work owner before returning its decoded response.
  Future<TResponse> mutateSkir<TResponse>(
    String subject,
    Uint8List requestBytes,
    Serializer<TResponse> serializer, {
    required String label,
    required MutationResponseDisposition Function(TResponse) classify,
    Future<void> Function(TResponse)? onResponse,
    String? submissionId,
    Set<Object> resources = const {},
    SubmissionReplay replay = SubmissionReplay.unsupported,
  }) => read(localWorkControllerProvider).execute(
    prepareSkir(
      subject,
      requestBytes,
      serializer,
      label: label,
      classify: classify,
      onResponse: onResponse,
      submissionId: submissionId,
      resources: resources,
      replay: replay,
    ),
  );
}

/// Bridges typed Skir mutations to the shared submission owner.
///
/// It resolves the current connection for each attempt, preserves captured
/// request bytes, and leaves reservation ownership and lifecycle decisions to
/// the mutation system. Dependencies belong to the originating scope and must
/// reject access after disposal.
final class SkirMutationClient {
  /// Provides late access to the current transport and to telemetry owned by
  /// the originating scope. Neither dependency is retained as a mutable global.
  const SkirMutationClient(this._client, this._telemetry);
  final NatsClient Function() _client;
  final Future<PanelTelemetry> Function() _telemetry;

  /// Returns the current transport for repositories that own subscriptions.
  NatsClient get client => _client();

  /// Performs one typed Skir request without creating a mutation submission.
  ///
  /// Request bytes cross the [NatsClient] boundary unchanged. The response is
  /// decoded here, where the Skir serializer belongs, while transport failures
  /// remain transport failures for the caller to handle.
  Future<T> request<T>(
    FutureOr<String> subject,
    Uint8List bytes,
    Serializer<T> serializer,
  ) async {
    final destination = await subject;
    final telemetry = await _telemetry();
    final client = _client();
    final response = await telemetry.traceNats(
      subject: destination,
      payloadSize: bytes.length,
      operationName: "request",
      operation: (headers) => client.request(
        destination,
        bytes,
        headers: headers,
        timeout: const Duration(seconds: 10),
      ),
    );
    return serializer.fromBytes(response.payload);
  }

  /// Captures a mutation attempt and returns a commit for the shared owner.
  ///
  /// The byte copy makes every send of this commit use the same request. The
  /// generated or supplied [submissionId] gives the attempt stable identity.
  /// [resources] describes the consistency scope that the mutation coordinator
  /// reserves outside this class. [replay] declares whether an uncertain
  /// result may send the identical captured request again. Preparation and
  /// reservation stay separate because preparation freezes intent, while the
  /// coordinator controls contention and lifetime.
  PreparedCommit<TResponse> prepare<TResponse>(
    FutureOr<String> subject,
    Uint8List requestBytes,
    Serializer<TResponse> serializer, {
    required String label,
    required MutationResponseDisposition Function(TResponse) classify,
    Future<void> Function(TResponse)? onResponse,
    String? submissionId,
    Set<Object> resources = const {},
    SubmissionReplay replay = SubmissionReplay.unsupported,
  }) {
    final bytes = Uint8List.fromList(requestBytes).asUnmodifiableView();

    return PreparedCommit<TResponse>(
      id: submissionId ?? uuid.v4(),
      label: label,
      replay: replay,
      resources: resources,
      integrate: (result) async {
        switch (result) {
          case SubmissionConfirmed(:final value):
            await onResponse?.call(value);
          case SubmissionRejected(response: final TResponse response):
            await onResponse?.call(response);
          case SubmissionRejected() ||
              SubmissionNotSubmitted() ||
              SubmissionUncertain():
        }
      },
      send: () async {
        // The returned closure is the only submission operation. Integration
        // observes its typed result and never sends the request a second time.
        final PanelTelemetry telemetry;
        final NatsClient client;
        final String destination;
        try {
          destination = await subject;
          telemetry = await _telemetry();
          client = _client();
        } on Object catch (error) {
          return SubmissionResult.notSubmitted(
            message: "The request could not be prepared",
            cause: error,
          );
        }
        final response = await telemetry.traceNats(
          subject: destination,
          payloadSize: bytes.length,
          operationName: "request",
          operation: (headers) => client.request(
            destination,
            bytes,
            headers: headers,
            timeout: const Duration(seconds: 10),
          ),
        );

        final value = serializer.fromBytes(response.payload);
        final disposition = classify(value);

        return switch (disposition) {
          MutationResponseDisposition.confirmed => SubmissionResult.confirmed(
            value,
          ),
          MutationResponseDisposition.rejected => SubmissionResult.rejected(
            message: "The operation was rejected",
            response: value,
          ),
          MutationResponseDisposition.uncertain => SubmissionResult.uncertain(
            message: "The server could not confirm the operation",
            cause: StateError("Unconfirmed mutation response"),
            stackTrace: StackTrace.current,
          ),
        };
      },
    );
  }
}
