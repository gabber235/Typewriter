import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

const _requestTimeout = Duration(seconds: 10);

/// One fully resolved Skir request at the messaging boundary.
///
/// Generated route adapters own subject construction and serialization. This
/// value snapshots their result so deferred submissions cannot observe later
/// request mutation while application owners retain classification, replay,
/// reservation, and integration policy.
final class SkirRouteOperation<TResponse> {
  SkirRouteOperation({
    required this.subject,
    required Uint8List requestBytes,
    required this.responseSerializer,
  }) : requestBytes = Uint8List.fromList(requestBytes).asUnmodifiableView();

  final String subject;
  final Uint8List requestBytes;
  final skir.Serializer<TResponse> responseSerializer;
}

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

/// Serializes sequenced broker and confirmed facts behind one snapshot gate.
final class _SequencedAdmissionQueue<Value> {
  _SequencedAdmissionQueue(this.apply);

  final Future<void> Function(Value, int) apply;
  Future<void> _tail = Future<void>.value();
  Completer<void> _ready = Completer<void>();
  var _generation = 0;
  var _installed = false;
  var _closed = false;
  Object? _failure;
  StackTrace? _failureStack;

  void beginGeneration(int generation) {
    if (_closed) return;
    if (!_ready.isCompleted) _ready.complete();
    _generation = generation;
    _installed = false;
    _failure = null;
    _failureStack = null;
    _ready = Completer<void>();
  }

  void snapshotInstalled(int generation) {
    if (_closed || generation != _generation) return;
    _installed = true;
    if (!_ready.isCompleted) _ready.complete();
  }

  void snapshotFailed(int generation, Object error, StackTrace stackTrace) {
    if (_closed || generation != _generation) return;
    _failure = error;
    _failureStack = stackTrace;
    if (!_ready.isCompleted) _ready.complete();
  }

  Future<void> enqueue(Value event, {int? brokerGeneration}) {
    final job = _tail.then((_) async {
      while (!_closed && !_installed && _failure == null) {
        await _ready.future;
      }
      if (_closed) return;
      final failure = _failure;
      if (failure != null) {
        Error.throwWithStackTrace(failure, _failureStack!);
      }
      final generation = _generation;
      if (brokerGeneration != null && brokerGeneration != generation) return;
      await apply(event, generation);
    });
    _tail = job.catchError((Object _, StackTrace _) {});
    return job;
  }

  void close() {
    if (_closed) return;
    _closed = true;
    if (!_ready.isCompleted) _ready.complete();
  }
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
    SkirRouteOperation<TResponse> operation,
  ) async {
    final telemetry = await read(panelTelemetryProvider.future);
    final client = read(natsProvider);
    final response = await telemetry.traceNats(
      subject: operation.subject,
      payloadSize: operation.requestBytes.length,
      operationName: "request",
      operation: (headers) => client.request(
        operation.subject,
        operation.requestBytes,
        headers: headers,
        timeout: _requestTimeout,
      ),
    );
    return operation.responseSerializer.fromBytes(response.payload);
  }

  /// Watches one typed snapshot and event projection through a shared lifetime.
  ///
  /// Latest projections can observe [confirmedEvents] alongside broker events.
  /// Both reduce against the same accepted value, starting at [initialValue].
  /// [reduceConfirmed] distinguishes confirmed command facts from observations.
  /// [reconcileSnapshot] applies feature policy when a replacement arrives,
  /// such as preserving newer facts only for members of the incoming snapshot.
  Stream<TData> watchProjection<TData, TResponse, TEvent>({
    required String subject,
    required String eventSubject,
    required Uint8List requestBytes,
    required skir.Serializer<TResponse> responseSerializer,
    required skir.Serializer<TEvent> eventSerializer,
    required TData Function(TResponse) snapshot,
    required TData Function(TData, TEvent) reduce,
    required ProjectionDelivery delivery,
    required ProjectionReconciliation<TData, TResponse, TEvent> reconciliation,
    Stream<TEvent>? confirmedEvents,
    TData Function(TData, TEvent)? reduceConfirmed,
    TData Function(TData, TData)? reconcileSnapshot,
    TData? initialValue,
  }) => ProjectionWatcher<TData, TResponse, TEvent>(
    client: watch(natsProvider),
    requestSnapshot: () async {
      final telemetry = await read(panelTelemetryProvider.future);
      return telemetry.traceNats(
        subject: subject,
        payloadSize: requestBytes.length,
        operationName: "request",
        operation: (headers) => read(natsProvider).request(
          subject,
          requestBytes,
          headers: headers,
          timeout: _requestTimeout,
        ),
      );
    },
    responseSerializer: responseSerializer,
    eventSerializer: eventSerializer,
    snapshot: snapshot,
    reduce: reduce,
    confirmedEvents: confirmedEvents,
    reduceConfirmed: reduceConfirmed,
    reconcileSnapshot: reconcileSnapshot,
    initialValue: initialValue,
    delivery: delivery,
    reconciliation: reconciliation,
    registerDisposal: onDispose,
  ).watch(eventSubject: eventSubject);
}

/// Owns one projection subscription across connection generations.
final class ProjectionWatcher<TData, TResponse, TEvent> {
  const ProjectionWatcher({
    required this.client,
    required this.requestSnapshot,
    required this.responseSerializer,
    required this.eventSerializer,
    required this.snapshot,
    required this.reduce,
    required this.delivery,
    required this.reconciliation,
    required this.registerDisposal,
    this.confirmedEvents,
    this.reduceConfirmed,
    this.reconcileSnapshot,
    this.initialValue,
  });

  final NatsClient client;
  final Future<NatsMessage> Function() requestSnapshot;
  final skir.Serializer<TResponse> responseSerializer;
  final skir.Serializer<TEvent> eventSerializer;
  final TData Function(TResponse) snapshot;
  final TData Function(TData, TEvent) reduce;

  /// Confirmed command facts observed through this subscription lifetime.
  final Stream<TEvent>? confirmedEvents;
  final TData Function(TData, TEvent)? reduceConfirmed;

  /// Reconciles replacement membership with accepted facts for surviving items.
  final TData Function(TData, TData)? reconcileSnapshot;

  /// Baseline for confirmed facts accepted before the first snapshot.
  final TData? initialValue;
  final ProjectionDelivery delivery;
  final ProjectionReconciliation<TData, TResponse, TEvent> reconciliation;
  final void Function(void Function()) registerDisposal;

  Stream<TData> watch({required String eventSubject}) =>
      Stream<_ProjectionEmission<TData> Function()>.multi((controller) {
            NatsSubscription? subscription;
            StreamSubscription<NatsMessage>? messages;
            StreamSubscription<NatsConnectionState>? lifecycle;
            var latest = initialValue;
            StreamSubscription<TEvent>? confirmations;
            var active = true;
            var connected = false;
            var generation = 0;
            var cleanup = Future<void>.value();
            var replacement = Future<void>.value();
            final sequencedPolicy = switch (reconciliation) {
              final ProjectionSequenced<TData, TResponse, TEvent> policy =>
                policy,
              ProjectionLatest() => null,
            };
            late final _SequencedAdmissionQueue<TEvent>? admissions;

            Future<void> closeSubscription() {
              final currentMessages = messages;
              final currentSubscription = subscription;
              messages = null;
              subscription = null;
              return cleanup = cleanup.then((_) async {
                await currentMessages?.cancel();
                await currentSubscription?.unsubscribe();
              });
            }

            void terminate(Object error, StackTrace stackTrace) {
              if (!active) return;
              controller.addError(error, stackTrace);
              active = false;
              admissions?.close();
              generation++;
              unawaited(() async {
                await lifecycle?.cancel();
                await confirmations?.cancel();
                try {
                  await replacement;
                } on Object {
                  // The delivery failure remains the primary terminal error.
                }
                try {
                  await closeSubscription();
                } on Object {
                  // The delivery failure remains the primary terminal error.
                }
                if (!controller.isClosed) await controller.close();
              }());
            }

            late void Function(
              Object error,
              StackTrace stackTrace,
              int failedGeneration,
            )
            recoverDelivery;

            Future<NatsSubscription> subscribe() => switch (delivery) {
              ProjectionDeliveryEphemeral() => client.subscribe(eventSubject),
              ProjectionDeliveryPersistent(:final stream, :final consumer) =>
                client.subscribePersistent(stream, consumer, eventSubject),
            };

            Future<void> installSnapshot(int expectedGeneration) async {
              final responseMessage = await requestSnapshot();
              if (!active || !connected || generation != expectedGeneration) {
                return;
              }
              final response = responseSerializer.fromBytes(
                responseMessage.payload,
              );
              final value = snapshot(response);
              switch (reconciliation) {
                case ProjectionLatest():
                  controller.add(() {
                    if (!active || generation != expectedGeneration) {
                      return _ProjectionEmission.discarded();
                    }
                    final current = latest;
                    final installed = current == null
                        ? value
                        : reconcileSnapshot?.call(current, value) ?? value;
                    latest = installed;
                    return _ProjectionEmission.delivered(installed);
                  });
                case final ProjectionSequenced<TData, TResponse, TEvent> policy:
                  policy.installSnapshot(response, value);
                  admissions?.snapshotInstalled(expectedGeneration);
                  final installed = policy.current;
                  controller.add(
                    () => active && generation == expectedGeneration
                        ? _ProjectionEmission.delivered(installed)
                        : _ProjectionEmission.discarded(),
                  );
              }
            }

            Future<void> applySequencedEvent(
              ProjectionSequenced<TData, TResponse, TEvent> policy,
              TEvent event,
              int expectedGeneration,
            ) async {
              var result = policy.applyEvent(event, reduce);
              if (result == SequencedEventResult.duplicate) return;
              if (result == SequencedEventResult.gap) {
                await installSnapshot(expectedGeneration);
                if (!active || !connected || generation != expectedGeneration) {
                  return;
                }
                result = policy.applyEvent(event, reduce);
                if (result == SequencedEventResult.duplicate) return;
                if (result == SequencedEventResult.gap) {
                  throw CollectionSequenceGap(
                    expected: policy.sequenceState.snapshot!.sequence + 1,
                    received: policy.eventSequence(event),
                  );
                }
              }
              final applied = policy.current;
              controller.add(
                () => active && generation == expectedGeneration
                    ? _ProjectionEmission.delivered(applied)
                    : _ProjectionEmission.discarded(),
              );
            }

            Future<NatsSubscription?> acquireSubscription(
              int expectedGeneration,
            ) async {
              await closeSubscription();
              if (!active || !connected || generation != expectedGeneration) {
                return null;
              }

              final next = await subscribe();
              if (!active || !connected || generation != expectedGeneration) {
                await next.unsubscribe();
                return null;
              }
              return next;
            }

            admissions = sequencedPolicy == null
                ? null
                : _SequencedAdmissionQueue<TEvent>(
                    (event, epoch) =>
                        applySequencedEvent(sequencedPolicy, event, epoch),
                  );

            Future<NatsSubscription?> scheduleAcquisition(
              int expectedGeneration,
            ) {
              final operation = replacement.then(
                (_) => acquireSubscription(expectedGeneration),
              );
              replacement = operation.then<void>(
                (_) {},
                onError: (Object _, StackTrace _) {},
              );
              return operation;
            }

            Future<void> replaceSubscription(int expectedGeneration) async {
              final next = await scheduleAcquisition(expectedGeneration);
              if (next == null) return;
              subscription = next;
              var events = Future<void>.value();
              final snapshotReady = Completer<void>();
              final nextMessages = next.messages.listen(
                (message) {
                  if (!active || generation != expectedGeneration) return;
                  if (admissions != null) {
                    final TEvent event;
                    try {
                      event = eventSerializer.fromBytes(message.payload);
                    } on Object catch (error, stackTrace) {
                      controller.addError(error, stackTrace);
                      return;
                    }
                    unawaited(
                      admissions
                          .enqueue(event, brokerGeneration: expectedGeneration)
                          .catchError((Object error, StackTrace stackTrace) {
                            if (active && generation == expectedGeneration) {
                              controller.addError(error, stackTrace);
                            }
                          }),
                    );
                    return;
                  }
                  events = events
                      .then((_) async {
                        await snapshotReady.future;
                        if (!active || generation != expectedGeneration) return;
                        final event = eventSerializer.fromBytes(
                          message.payload,
                        );
                        switch (reconciliation) {
                          case ProjectionLatest():
                            controller.add(() {
                              if (!active || generation != expectedGeneration) {
                                return _ProjectionEmission.discarded();
                              }
                              final current = latest;
                              if (current == null) {
                                throw StateError(
                                  "Projection event arrived before its snapshot",
                                );
                              }
                              return _ProjectionEmission.delivered(
                                latest = reduce(current, event),
                              );
                            });
                          case final ProjectionSequenced<
                            TData,
                            TResponse,
                            TEvent
                          >
                          policy:
                            await applySequencedEvent(
                              policy,
                              event,
                              expectedGeneration,
                            );
                        }
                      })
                      .catchError((Object error, StackTrace stackTrace) {
                        if (active && generation == expectedGeneration) {
                          controller.addError(error, stackTrace);
                        }
                      });
                },
                onError: (Object error, StackTrace stackTrace) {
                  if (active && generation == expectedGeneration) {
                    recoverDelivery(error, stackTrace, expectedGeneration);
                  }
                },
              );
              messages = nextMessages;

              try {
                await installSnapshot(expectedGeneration);
                snapshotReady.complete();
              } on Object {
                snapshotReady.complete();
                if (identical(subscription, next)) subscription = null;
                if (identical(messages, nextMessages)) messages = null;
                await nextMessages.cancel();
                await next.unsubscribe();
                rethrow;
              }
            }

            recoverDelivery = (error, stackTrace, failedGeneration) {
              if (!active || generation != failedGeneration) return;
              if (error case NatsClientException(
                kind: NatsFailureKind.timeout || NatsFailureKind.unavailable,
              )) {
                final recoveryGeneration = ++generation;
                admissions?.beginGeneration(recoveryGeneration);
                unawaited(
                  Future<void>.delayed(const Duration(milliseconds: 250))
                      .then((_) => replaceSubscription(recoveryGeneration))
                      .catchError((Object next, StackTrace nextStackTrace) {
                        admissions?.snapshotFailed(
                          recoveryGeneration,
                          next,
                          nextStackTrace,
                        );
                        recoverDelivery(
                          next,
                          nextStackTrace,
                          recoveryGeneration,
                        );
                      }),
                );
                return;
              }
              terminate(error, stackTrace);
            };

            void observeLifecycle(NatsConnectionState state) {
              final nextConnected = state is NatsConnected;
              if (connected == nextConnected) return;
              connected = nextConnected;
              final nextGeneration = ++generation;
              admissions?.beginGeneration(nextGeneration);
              unawaited(
                replaceSubscription(nextGeneration).catchError((
                  Object error,
                  StackTrace stackTrace,
                ) {
                  admissions?.snapshotFailed(nextGeneration, error, stackTrace);
                  recoverDelivery(error, stackTrace, nextGeneration);
                }),
              );
            }

            confirmations = confirmedEvents?.listen(
              (event) {
                if (admissions != null) {
                  unawaited(
                    admissions.enqueue(event).catchError((
                      Object error,
                      StackTrace stackTrace,
                    ) {
                      if (active) controller.addError(error, stackTrace);
                    }),
                  );
                  return;
                }
                controller.add(() {
                  if (!active) return _ProjectionEmission.discarded();
                  final current = latest;
                  if (current == null) {
                    throw StateError(
                      "Confirmed facts require an initial value",
                    );
                  }
                  latest = (reduceConfirmed ?? reduce)(current, event);
                  return _ProjectionEmission.delivered(latest);
                });
              },
              onError: (Object error, StackTrace stackTrace) {
                if (active) controller.addError(error, stackTrace);
              },
            );

            lifecycle = client.connectionStateChanges.listen(
              observeLifecycle,
              onError: (Object error, StackTrace stackTrace) {
                if (active) controller.addError(error, stackTrace);
              },
            );
            observeLifecycle(client.connectionState);

            Future<void> cancel() async {
              if (!active) return;
              active = false;
              admissions?.close();
              generation++;
              await lifecycle?.cancel();
              await confirmations?.cancel();
              try {
                await replacement;
              } on Object {
                // Cancellation has no listener that can receive replacement errors.
              }
              try {
                await closeSubscription();
              } on Object {
                // Cancellation has no listener that can receive cleanup errors.
              }
            }

            controller.onCancel = cancel;
            registerDisposal(() => unawaited(cancel()));
          })
          .map((value) => value())
          .where((value) => value.deliver)
          .map((value) => value.value as TData);
}

final class _ProjectionEmission<T> {
  const _ProjectionEmission.delivered(this.value) : deliver = true;

  const _ProjectionEmission.discarded() : deliver = false, value = null;

  final bool deliver;
  final T? value;
}
