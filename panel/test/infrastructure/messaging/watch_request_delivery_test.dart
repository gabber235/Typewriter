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
            .watchRequest(
              subject: "watch",
              listenSubject: "events",
              requestBytes: Uint8List(0),
              serializer: skir.GetSentinelCredentialsResponse.serializer,
              transformer: (_, _) => current + 1,
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
          .watchRequest<int, skir.Duration>(
            subject: "watch",
            listenSubject: "events",
            requestBytes: Uint8List(0),
            serializer: skir.Duration.serializer,
            transformer: (previous, response) {
              if (response.milliseconds < 0) throw StateError("invalid update");
              return (previous ?? 0) + response.milliseconds;
            },
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
        .watchRequest<int, skir.Duration>(
          subject: "watch",
          listenSubject: "events",
          requestBytes: Uint8List(0),
          serializer: skir.Duration.serializer,
          transformer: (_, _) => ++reductions,
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
}
