import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  for (final forwarded in [false, true]) {
    test("events received while paused apply in order after resume "
        "(forwarded: $forwarded)", () async {
      final world = testWorld([signedIn(ada)]);
      await world.initialized();
      world.nats.registerHandler("watch", (_) => counterBytes(1));
      final source = world.watchCounter(
        reduce: (current, event) => current * 10 + event,
      );
      Stream<int> forward(Stream<int> events) async* {
        yield* events;
      }

      final stream = forwarded ? forward(source) : source;
      final values = <int>[];
      final listener = stream.listen(values.add);
      addTearDown(listener.cancel);
      await eventually(() => expect(values, [1]));

      listener.pause();
      world.nats.connection
        ..emitMessageOnSubject("events", counterBytes(2))
        ..emitMessageOnSubject("events", counterBytes(3));
      await pumpEventQueue();
      expect(values, [1]);

      listener.resume();
      await eventually(() => expect(values, [1, 12, 123]));
      await listener.cancel();
      expect(world.nats.connection.subscriptionSubjects, isEmpty);
    });
  }

  test(
    "transformer errors preserve the last delivered reduction state",
    () async {
      final world = testWorld([signedIn(ada)]);
      await world.initialized();
      world.nats.registerHandler("watch", (_) => counterBytes(1));
      final values = <int>[];
      final errors = <Object>[];
      final listener = world
          .watchCounter(
            reduce: (previous, event) {
              if (event < 0) throw StateError("invalid update");
              return previous + event;
            },
          )
          .listen(values.add, onError: errors.add);
      addTearDown(listener.cancel);
      await eventually(() => expect(values, [1]));

      listener.pause();
      world.nats.connection
        ..emitMessageOnSubject("events", counterBytes(-1))
        ..emitMessageOnSubject("events", counterBytes(2));
      await pumpEventQueue();
      expect(errors, isEmpty);
      listener.resume();

      await eventually(() => expect(values, [1, 3]));
      expect(errors, [isA<StateError>()]);
      await listener.cancel();
      expect(world.nats.connection.subscriptionSubjects, isEmpty);
    },
  );

  test("confirmed facts and broker events apply in arrival order", () async {
    final world = testWorld([signedIn(ada)]);
    await world.initialized();
    final reply = Completer<Uint8List>();
    world.nats.registerHandler("watch", (_) => reply.future);
    final confirmations = StreamController<int>.broadcast(sync: true);
    addTearDown(confirmations.close);
    final values = <int>[];
    final listener = world
        .watchCounter(
          reduce: (current, event) => current + event,
          reduceConfirmed: (_, fact) => fact,
          confirmed: confirmations.stream,
          reconcileSnapshot: max,
          initialValue: 0,
        )
        .listen(values.add);
    addTearDown(listener.cancel);
    await eventually(
      () => expect(world.nats.connection.requests, hasLength(1)),
    );

    listener.pause();
    confirmations.add(4);
    reply.complete(counterBytes(1));
    world.nats.connection.emitMessageOnSubject("events", counterBytes(2));
    await pumpEventQueue();
    expect(values, isEmpty);
    listener.resume();

    await eventually(() => expect(values, [4, 4, 6]));
  });

  test("canceling a watch leaves the confirmed stream open", () async {
    final world = testWorld([signedIn(ada)]);
    await world.initialized();
    world.nats.registerHandler("watch", (_) => counterBytes(1));
    final confirmations = StreamController<int>.broadcast(sync: true);
    addTearDown(confirmations.close);
    final values = <int>[];
    final listener = world
        .watchCounter(confirmed: confirmations.stream, initialValue: 0)
        .listen(values.add);
    await eventually(() => expect(values, [1]));

    await listener.cancel();

    expect(confirmations.hasListener, isFalse);
    expect(confirmations.isClosed, isFalse);
    final borrowed = <int>[];
    final other = confirmations.stream.listen(borrowed.add);
    addTearDown(other.cancel);
    confirmations.add(9);
    expect(borrowed, [9]);
    expect(values, [1]);
  });

  test("canceling a paused watch discards queued reductions", () async {
    final world = testWorld([signedIn(ada)]);
    await world.initialized();
    world.nats.registerHandler("watch", (_) => counterBytes(1));
    var reductions = 0;
    final initial = Completer<void>();
    final listener = world
        .watchCounter(
          snapshot: (_) => ++reductions,
          reduce: (_, _) => ++reductions,
        )
        .listen((_) => initial.complete());
    addTearDown(listener.cancel);
    await initial.future;

    listener.pause();
    world.nats.connection.emitMessageOnSubject("events", counterBytes(1));
    await pumpEventQueue();
    expect(reductions, 1);
    await listener.cancel();
    await pumpEventQueue();

    expect(reductions, 1);
    expect(world.nats.connection.subscriptionSubjects, isEmpty);
  });

  test("paused sequenced watches preserve every accepted transition", () async {
    final world = testWorld([signedIn(ada)]);
    await world.initialized();
    world.nats.registerHandler("watch", (_) => counterBytes(1));
    final sequence = SequencedCollection<int>();
    final values = <int>[];
    final listener = world
        .watchCounter(persistent: true, sequence: sequence)
        .listen(values.add);
    addTearDown(listener.cancel);
    await eventually(() => expect(values, [1]));

    listener.pause();
    world.nats.connection
      ..emitMessageOnSubject("events", counterBytes(2))
      ..emitMessageOnSubject("events", counterBytes(3));
    await pumpEventQueue();
    expect(sequence.snapshot?.sequence, 3);
    expect(values, [1]);

    listener.resume();
    await eventually(() => expect(values, [1, 2, 3]));
  });

  test(
    "sequenced confirmations wait for snapshot and deduplicate broker delivery",
    () async {
      final world = testWorld([signedIn(ada)]);
      await world.initialized();
      final reply = Completer<Uint8List>();
      world.nats.registerHandler("watch", (_) => reply.future);
      final confirmations = StreamController<int>.broadcast(sync: true);
      addTearDown(confirmations.close);
      final sequence = SequencedCollection<int>();
      final values = <int>[];
      final listener = world
          .watchCounter(
            persistent: true,
            sequence: sequence,
            reduceConfirmed: (_, fact) => fact,
            confirmed: confirmations.stream,
          )
          .listen(values.add);
      addTearDown(listener.cancel);
      await eventually(
        () => expect(world.nats.connection.requests, hasLength(1)),
      );

      confirmations.add(2);
      world.nats.connection
        ..emitMessageOnSubject("events", counterBytes(2))
        ..emitMessageOnSubject("events", counterBytes(3));
      await pumpEventQueue();
      expect(values, isEmpty);

      reply.complete(counterBytes(1));
      await eventually(() => expect(values, [1, 2, 3]));
      expect(sequence.snapshot?.sequence, 3);
    },
  );

  test("failed snapshot rejects queued sequenced confirmations", () async {
    final world = testWorld([signedIn(ada)]);
    await world.initialized();
    final reply = Completer<Uint8List>();
    world.nats.registerHandler("watch", (_) => reply.future);
    final confirmations = StreamController<int>.broadcast(sync: true);
    addTearDown(confirmations.close);
    final failure = StateError("snapshot rejected");
    final values = <int>[];
    final errors = <Object>[];
    final done = Completer<void>();
    final listener = world
        .watchCounter(
          persistent: true,
          sequence: SequencedCollection<int>(),
          confirmed: confirmations.stream,
        )
        .listen(values.add, onError: errors.add, onDone: done.complete);
    addTearDown(listener.cancel);
    await eventually(
      () => expect(world.nats.connection.requests, hasLength(1)),
    );

    confirmations.add(2);
    reply.completeError(failure);
    await done.future;

    expect(errors, [same(failure)]);
    expect(values, isEmpty);
  });

  test(
    "sequenced projection ignores a confirmed fact older than its snapshot",
    () async {
      final world = testWorld([signedIn(ada)]);
      await world.initialized();
      world.nats.registerHandler("watch", (_) => counterBytes(2));
      final confirmations = StreamController<int>.broadcast(sync: true);
      addTearDown(confirmations.close);
      final values = <int>[];
      final listener = world
          .watchCounter(
            persistent: true,
            sequence: SequencedCollection<int>(),
            confirmed: confirmations.stream,
          )
          .listen(values.add);
      addTearDown(listener.cancel);
      await eventually(() => expect(values, [2]));

      confirmations.add(1);
      await pumpEventQueue();

      expect(values, [2]);
    },
  );
}
