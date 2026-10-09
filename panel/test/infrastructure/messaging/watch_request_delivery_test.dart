import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";

final _refProvider = Provider<Ref>((ref) => ref);

Stream<T> _forward<T>(Stream<T> source) async* {
  yield* source;
}

void main() {
  for (final forwarded in [false, true]) {
    test(
      "paused watches reduce against listener state with forwarding $forwarded",
      () async {
        final payload = skir.GetSentinelCredentialsResponse.serializer.toBytes(
          skir.GetSentinelCredentialsResponse.createSuccess(
            jwt: "jwt",
            seed: "seed",
          ),
        );
        final nats = FakeNatsClient()..registerHandler("watch", (_) => payload);
        final container = ProviderContainer.test(
          overrides: [
            natsProvider.overrideWithValue(nats),
            panelTelemetryProvider.overrideWithValue(
              const AsyncData(NoopPanelTelemetry()),
            ),
          ],
        );
        addTearDown(nats.dispose);
        addTearDown(container.dispose);
        var current = 0;

        final values = <int>[];
        final initial = Completer<void>();
        final completed = Completer<void>();
        final source = container
            .read(_refProvider)
            .watchProjection<
              int,
              skir.GetSentinelCredentialsResponse,
              skir.GetSentinelCredentialsResponse
            >(
              subject: "watch",
              eventSubject: "events",
              requestBytes: Uint8List(0),
              responseSerializer:
                  skir.GetSentinelCredentialsResponse.serializer,
              eventSerializer: skir.GetSentinelCredentialsResponse.serializer,
              snapshot: (_) => current + 1,
              reduce: (_, _) => current + 1,
              delivery: const ProjectionDelivery.ephemeral(),
              reconciliation: const ProjectionReconciliation.latest(),
            );
        final stream = forwarded ? _forward(source) : source;
        final listener = stream.listen((value) {
          current = value;
          values.add(value);
          if (values.length == 1) initial.complete();
          if (values.length == 3) completed.complete();
        });
        addTearDown(listener.cancel);

        await initial.future.timeout(const Duration(seconds: 2));
        listener.pause();
        nats
          ..emitMessageOnSubject("events", payload)
          ..emitMessageOnSubject("events", payload);
        await pumpEventQueue();
        expect(values, [1]);
        listener.resume();

        await completed.future.timeout(const Duration(seconds: 2));
        expect(values, [1, 2, 3]);
        await listener.cancel();
        expect(nats.subscriptionSubjects, isEmpty);
      },
    );
  }

  test(
    "transformer errors preserve the last delivered reduction state",
    () async {
      final nats = FakeNatsClient()
        ..registerHandler(
          "watch",
          (_) =>
              skir.Duration.serializer.toBytes(skir.Duration(milliseconds: 1)),
        );
      final container = ProviderContainer.test(
        overrides: [
          natsProvider.overrideWithValue(nats),
          panelTelemetryProvider.overrideWithValue(
            const AsyncData(NoopPanelTelemetry()),
          ),
        ],
      );
      addTearDown(nats.dispose);
      addTearDown(container.dispose);
      final values = <int>[];
      final errors = <Object>[];
      final initial = Completer<void>();
      final completed = Completer<void>();
      final listener = container
          .read(_refProvider)
          .watchProjection<int, skir.Duration, skir.Duration>(
            subject: "watch",
            eventSubject: "events",
            requestBytes: Uint8List(0),
            responseSerializer: skir.Duration.serializer,
            eventSerializer: skir.Duration.serializer,
            snapshot: (response) => response.milliseconds,
            reduce: (previous, event) {
              if (event.milliseconds < 0) throw StateError("invalid update");
              return previous + event.milliseconds;
            },
            delivery: const ProjectionDelivery.ephemeral(),
            reconciliation: const ProjectionReconciliation.latest(),
          )
          .listen((value) {
            values.add(value);
            if (values.length == 1) initial.complete();
            if (values.length == 2) completed.complete();
          }, onError: errors.add);
      addTearDown(listener.cancel);
      await initial.future.timeout(const Duration(seconds: 2));
      listener.pause();
      nats
        ..emitMessageOnSubject(
          "events",
          skir.Duration.serializer.toBytes(skir.Duration(milliseconds: -1)),
        )
        ..emitMessageOnSubject(
          "events",
          skir.Duration.serializer.toBytes(skir.Duration(milliseconds: 2)),
        );
      await pumpEventQueue();
      expect(errors, isEmpty);
      listener.resume();
      await completed.future.timeout(const Duration(seconds: 2));
      expect(values, [1, 3]);
      expect(errors, [isA<StateError>()]);
      await listener.cancel();
      expect(nats.subscriptionSubjects, isEmpty);
    },
  );

  test("confirmed facts snapshots and broker events share one paused queue and borrowed lifetime", () async {
    final reply = Completer<Uint8List>();
    final confirmations = StreamController<skir.Duration>.broadcast(sync: true);
    final nats = FakeNatsClient()
      ..registerHandler("watch", (_) => reply.future);
    final container = ProviderContainer.test(
      overrides: [
        natsProvider.overrideWithValue(nats),
        panelTelemetryProvider.overrideWithValue(
          const AsyncData(NoopPanelTelemetry()),
        ),
      ],
    );
    addTearDown(nats.dispose);
    addTearDown(container.dispose);
    addTearDown(confirmations.close);
    final values = <int>[];
    final listener = container
        .read(_refProvider)
        .watchProjection<int, skir.Duration, skir.Duration>(
          subject: "watch",
          eventSubject: "events",
          requestBytes: Uint8List(0),
          responseSerializer: skir.Duration.serializer,
          eventSerializer: skir.Duration.serializer,
          snapshot: (response) => response.milliseconds,
          reduce: (current, event) => current + event.milliseconds,
          reduceConfirmed: (_, event) => event.milliseconds,
          confirmedEvents: confirmations.stream,
          reconcileSnapshot: max,
          initialValue: 0,
          delivery: const ProjectionDelivery.ephemeral(),
          reconciliation: const ProjectionReconciliation.latest(),
        )
        .listen(values.add);
    addTearDown(listener.cancel);
    await pumpEventQueue();
    expect(nats.requests, hasLength(1));
    listener.pause();
    confirmations.add(skir.Duration(milliseconds: 4));
    reply.complete(
      skir.Duration.serializer.toBytes(skir.Duration(milliseconds: 1)),
    );
    nats.emitMessageOnSubject(
      "events",
      skir.Duration.serializer.toBytes(skir.Duration(milliseconds: 2)),
    );
    await pumpEventQueue();
    expect(values, isEmpty);
    listener.resume();
    await pumpEventQueue();
    expect(values, [4, 4, 6]);
    await listener.cancel();
    expect(confirmations.hasListener, isFalse);
    expect(confirmations.isClosed, isFalse);
    final borrowed = <skir.Duration>[];
    final other = confirmations.stream.listen(borrowed.add);
    confirmations.add(skir.Duration(milliseconds: 9));
    expect(borrowed.single.milliseconds, 9);
    expect(values, [4, 4, 6]);
    await other.cancel();
  });

  test("canceling a paused watch discards queued reductions", () async {
    final payload = skir.Duration.serializer.toBytes(
      skir.Duration(milliseconds: 1),
    );
    final nats = FakeNatsClient()..registerHandler("watch", (_) => payload);
    final container = ProviderContainer.test(
      overrides: [
        natsProvider.overrideWithValue(nats),
        panelTelemetryProvider.overrideWithValue(
          const AsyncData(NoopPanelTelemetry()),
        ),
      ],
    );
    addTearDown(nats.dispose);
    addTearDown(container.dispose);
    var reductions = 0;
    final initial = Completer<void>();
    final listener = container
        .read(_refProvider)
        .watchProjection<int, skir.Duration, skir.Duration>(
          subject: "watch",
          eventSubject: "events",
          requestBytes: Uint8List(0),
          responseSerializer: skir.Duration.serializer,
          eventSerializer: skir.Duration.serializer,
          snapshot: (_) => ++reductions,
          reduce: (_, _) => ++reductions,
          delivery: const ProjectionDelivery.ephemeral(),
          reconciliation: const ProjectionReconciliation.latest(),
        )
        .listen((_) => initial.complete());
    addTearDown(listener.cancel);
    await initial.future.timeout(const Duration(seconds: 2));
    listener.pause();
    nats.emitMessageOnSubject("events", payload);
    await pumpEventQueue();
    expect(reductions, 1);
    await listener.cancel();
    await pumpEventQueue();
    expect(reductions, 1);
    expect(nats.subscriptionSubjects, isEmpty);
  });

  test("paused sequenced watches preserve every accepted transition", () async {
    final nats = FakeNatsClient()
      ..registerHandler(
        "watch",
        (_) => skir.Duration.serializer.toBytes(skir.Duration(milliseconds: 1)),
      );
    final container = ProviderContainer.test(
      overrides: [
        natsProvider.overrideWithValue(nats),
        panelTelemetryProvider.overrideWithValue(
          const AsyncData(NoopPanelTelemetry()),
        ),
      ],
    );
    addTearDown(nats.dispose);
    addTearDown(container.dispose);
    final sequenceState = SequencedCollection<int>();
    final values = <int>[];
    final initial = Completer<void>();
    final completed = Completer<void>();
    final listener = container
        .read(_refProvider)
        .watchProjection<int, skir.Duration, skir.Duration>(
          subject: "watch",
          eventSubject: "events",
          requestBytes: Uint8List(0),
          responseSerializer: skir.Duration.serializer,
          eventSerializer: skir.Duration.serializer,
          snapshot: (response) => response.milliseconds,
          reduce: (_, event) => event.milliseconds,
          delivery: const ProjectionDelivery.ordered(
            stream: "TYPEWRITER_MEMBERSHIP",
          ),
          reconciliation: ProjectionReconciliation.sequenced(
            snapshotSequence: (response) => response.milliseconds,
            eventSequence: (event) => event.milliseconds,
            sequenceState: sequenceState,
          ),
        )
        .listen((value) {
          values.add(value);
          if (values.length == 1) initial.complete();
          if (values.length == 3) completed.complete();
        });
    addTearDown(listener.cancel);

    await initial.future.timeout(const Duration(seconds: 2));
    listener.pause();
    nats
      ..emitMessageOnSubject(
        "events",
        skir.Duration.serializer.toBytes(skir.Duration(milliseconds: 2)),
      )
      ..emitMessageOnSubject(
        "events",
        skir.Duration.serializer.toBytes(skir.Duration(milliseconds: 3)),
      );
    await pumpEventQueue();
    expect(sequenceState.snapshot?.sequence, 3);
    expect(values, [1]);

    listener.resume();
    await completed.future.timeout(const Duration(seconds: 2));
    expect(values, [1, 2, 3]);
  });
}
