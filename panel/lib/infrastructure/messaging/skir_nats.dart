import "dart:async";
import "dart:typed_data";

import "package:riverpod/riverpod.dart";
import "package:skir_client/skir_client.dart";
import "package:typewriter_panel/infrastructure/messaging/nats_client.dart";
import "package:typewriter_panel/infrastructure/messaging/nats_provider.dart";
import "package:typewriter_panel/infrastructure/observability/telemetry.dart";

const _requestTimeout = Duration(seconds: 10);
const _membershipStream = "TYPEWRITER_MEMBERSHIP";

/// A value paired with the server sequence that produced it.
///
/// Sequencing is application consistency state, not transport state. The
/// snapshot lets a watcher distinguish a duplicate event from a missing event
/// and recover from a gap without asking the NATS adapter to understand Skir.
final class SequencedSnapshot<T> {
  const SequencedSnapshot({required this.sequence, required this.value});

  /// Server sequence represented by [value].
  final int sequence;

  /// Snapshot or projection at [sequence].
  final T value;
}

/// Outcome of applying one event against the current authoritative sequence.
enum SequencedEventResult { duplicate, applied, gap }

/// Applies ordered events to one authoritative snapshot.
///
/// Historical events are ignored. A future event reports a gap so its owner can
/// reload a snapshot before continuing. The reducer remains supplied by the
/// feature because this boundary owns sequence safety, not resource policy or
/// domain merging.
final class SequencedCollection<T> {
  SequencedSnapshot<T>? _current;

  /// Current value. Throws until [snapshot] has been assigned.
  T get value => _current!.value;

  /// The latest accepted snapshot, or null before the first load.
  SequencedSnapshot<T>? get snapshot => _current;

  /// Replaces the authoritative baseline after a snapshot reload.
  set snapshot(SequencedSnapshot<T> value) => _current = value;

  /// Applies [sequence] only when it is the immediate successor.
  ///
  /// An older or equal sequence is a duplicate. A future sequence is a gap and
  /// leaves the current value unchanged. [reduce] runs only for an applied
  /// event, so callers can safely retry gap recovery without double applying.
  SequencedEventResult apply({
    required int sequence,
    required T Function(T current) reduce,
  }) {
    final current = _current;
    if (current == null || sequence != current.sequence + 1) {
      if (current != null && sequence <= current.sequence) {
        return SequencedEventResult.duplicate;
      }
      return SequencedEventResult.gap;
    }
    _current = SequencedSnapshot(
      sequence: sequence,
      value: reduce(current.value),
    );
    return SequencedEventResult.applied;
  }
}

/// Reports an event that remained ahead of the reloaded snapshot.
final class CollectionSequenceGap implements Exception {
  const CollectionSequenceGap({required this.expected, required this.received});

  /// Sequence required to continue from the reloaded snapshot.
  final int expected;

  /// Sequence carried by the event that could not be applied.
  final int received;
}

/// Provides typed Skir request and watch adapters for a Riverpod scope.
///
/// This is the protocol boundary above [NatsClient]. It performs serialization,
/// initial snapshot loading, event reduction, and cancellation cleanup, while
/// the transport abstraction retains ownership of NATS readiness, failures,
/// subscriptions, and connection lifetime.
extension RefNatsExtension on Ref {
  /// Sends one Skir request through the current transport and decodes its
  /// typed response. Request adaptation stays here so callers never couple
  /// feature code to payload bytes or NATS package types.
  Future<TResponse> requestSkir<TResponse>(
    String subject,
    Uint8List requestBytes,
    Serializer<TResponse> serializer,
  ) async {
    final telemetry = await read(panelTelemetryProvider.future);
    final client = read(natsProvider);
    final response = await telemetry.traceNats(
      subject: subject,
      payloadSize: requestBytes.length,
      operationName: "request",
      operation: (headers) => client.request(
        subject,
        requestBytes,
        headers: headers,
        timeout: _requestTimeout,
      ),
    );
    return serializer.fromBytes(response.payload);
  }

  /// Combines an initial typed response with subsequent subscription messages.
  ///
  /// Reduction happens at delivery, so each result reaches its listener before
  /// the next reduction. Cancellation unsubscribes even when subscription
  /// setup is still pending, which keeps the Riverpod scope from retaining a
  /// transport resource after its consumer leaves.
  Stream<TData> watchRequest<TData, TResponse>({
    required String subject,
    required String listenSubject,
    required Uint8List requestBytes,
    required Serializer<TResponse> serializer,
    required TData Function(TData?, TResponse) transformer,
  }) {
    final client = watch(natsProvider);
    final responses = Stream<TResponse>.multi((controller) async {
      NatsSubscription? subscription;
      var active = true;
      Future<void>? unsubscribeOperation;

      Future<void> unsubscribe() => unsubscribeOperation ??= () async {
        active = false;
        await subscription?.unsubscribe();
      }();

      controller.onCancel = unsubscribe;
      onDispose(() => unawaited(unsubscribe()));

      try {
        subscription = await client.subscribe(listenSubject);
        if (!active) {
          await subscription.unsubscribe();
          return;
        }
        final telemetry = await read(panelTelemetryProvider.future);
        final initial = await telemetry.traceNats(
          subject: subject,
          payloadSize: requestBytes.length,
          operationName: "request",
          operation: (headers) => client.request(
            subject,
            requestBytes,
            headers: headers,
            timeout: _requestTimeout,
          ),
        );
        if (!active) return;

        controller.add(serializer.fromBytes(initial.payload));

        await for (final message in subscription.messages) {
          if (!active) return;
          controller.add(serializer.fromBytes(message.payload));
        }
      } on Object catch (error, stackTrace) {
        if (active) controller.addError(error, stackTrace);
      } finally {
        await unsubscribe();
        if (!controller.isClosed) {
          await controller.close();
        }
      }
    });
    return responses.transform(
      StreamTransformer<TResponse, TData>((stream, cancelOnError) {
        TData? previous;
        return stream
            .transform(
              StreamTransformer<TResponse, TData>.fromHandlers(
                handleData: (response, sink) {
                  try {
                    final next = transformer(previous, response);
                    previous = next;
                    sink.add(next);
                  } on Object catch (error, stackTrace) {
                    sink
                      ..addError(error, stackTrace)
                      ..close();
                  }
                },
              ),
            )
            .listen(null, cancelOnError: cancelOnError);
      }),
    );
  }

  /// Watches a sequenced snapshot and its ordered event stream.
  ///
  /// The snapshot is loaded before events are reduced. Duplicates are ignored;
  /// a gap triggers one snapshot reload, after which an irreconcilable gap is
  /// surfaced as [CollectionSequenceGap]. Cancellation owns the subscription
  /// cleanup, while feature supplied functions own Skir decoding and merging.
  Stream<TData> watchSequencedRequest<TData, TResponse, TEvent>({
    required String subject,
    required String eventSubject,
    required Uint8List requestBytes,
    required Serializer<TResponse> responseSerializer,
    required Serializer<TEvent> eventSerializer,
    required SequencedSnapshot<TData> Function(TResponse) snapshot,
    required int Function(TEvent) eventSequence,
    required TData Function(TData, TEvent) reduce,
    required SequencedCollection<TData> sequenceState,
  }) {
    final client = watch(natsProvider);
    return Stream<TData>.multi((controller) async {
      NatsSubscription? subscription;
      var active = true;
      Future<void>? unsubscribeOperation;

      Future<void> unsubscribe() => unsubscribeOperation ??= () async {
        active = false;
        await subscription?.unsubscribe();
      }();

      Future<void> cancel() async {
        try {
          await unsubscribe();
        } on Object {
          // Cancellation is already terminal for this watcher. The shared
          // connection retains final ownership when local cleanup has failed.
        }
      }

      Future<SequencedSnapshot<TData>> loadSnapshot() async {
        final telemetry = await read(panelTelemetryProvider.future);
        final response = await telemetry.traceNats(
          subject: subject,
          payloadSize: requestBytes.length,
          operationName: "request",
          operation: (headers) => client.request(
            subject,
            requestBytes,
            headers: headers,
            timeout: _requestTimeout,
          ),
        );
        return snapshot(responseSerializer.fromBytes(response.payload));
      }

      controller.onCancel = cancel;
      onDispose(() => unawaited(cancel()));

      Object? failure;
      StackTrace? failureStackTrace;

      try {
        subscription = await client.subscribeOrdered(
          _membershipStream,
          eventSubject,
        );
        if (!active) {
          await subscription.unsubscribe();
          return;
        }

        var current = await loadSnapshot();
        if (!active) return;
        sequenceState.snapshot = current;
        controller.add(current.value);

        await for (final message in subscription.messages) {
          if (!active) return;
          final event = eventSerializer.fromBytes(message.payload);
          final sequence = eventSequence(event);
          var result = sequenceState.apply(
            sequence: sequence,
            reduce: (value) => reduce(value, event),
          );
          if (result == SequencedEventResult.duplicate) continue;

          if (result == SequencedEventResult.gap) {
            current = await loadSnapshot();
            if (!active) return;
            sequenceState.snapshot = current;
            controller.add(current.value);
            result = sequenceState.apply(
              sequence: sequence,
              reduce: (value) => reduce(value, event),
            );
            if (result == SequencedEventResult.duplicate) continue;
            if (result == SequencedEventResult.gap) {
              throw CollectionSequenceGap(
                expected: current.sequence + 1,
                received: sequence,
              );
            }
          }
          controller.add(sequenceState.value);
        }
      } on Object catch (error, stackTrace) {
        if (active) {
          failure = error;
          failureStackTrace = stackTrace;
        }
      } finally {
        final reportCleanupFailure = active;
        try {
          await unsubscribe();
        } on Object catch (error, stackTrace) {
          if (failure == null && reportCleanupFailure) {
            failure = error;
            failureStackTrace = stackTrace;
          }
        }
        if (failure != null && !controller.isClosed) {
          controller.addError(failure, failureStackTrace);
        }
        if (!controller.isClosed) await controller.close();
      }
    });
  }
}
