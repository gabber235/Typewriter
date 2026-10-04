import "dart:async";
import "dart:typed_data";

import "package:crypto/crypto.dart";
import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/messaging/bounded_transfer_assembler.dart";

void main() {
  test("assembles verified chunks and releases retained bytes", () {
    final pool = BoundedTransferPool(
      assemblerFactory: () =>
          BoundedTransferAssembler(maximumChunkBytes: 3, maximumChunks: 3),
    );
    final parts = _parts([1, 2, 3, 4, 5], chunkSize: 3);

    expect(pool.accept(parts.first), isA<BoundedTransferPoolPending>());
    expect(pool.retainedBytes, 3);
    final completed = pool.accept(parts.last) as BoundedTransferPoolComplete;

    expect(completed.transferId, "transfer");
    expect(completed.bytes, [1, 2, 3, 4, 5]);
    expect(pool.retainedBytes, 0);
    expect(() => completed.bytes[0] = 9, throwsUnsupportedError);
  });

  test("copies incoming bytes before retaining a chunk", () {
    final payload = Uint8List.fromList([1, 2]);
    final part = BoundedTransferPart(
      transferId: "transfer",
      index: 0,
      chunkCount: 1,
      encodedSize: 2,
      sha256: sha256.convert(payload).toString(),
      payload: payload,
    );

    payload[0] = 9;

    final state = BoundedTransferAssembler().accept(part);
    expect((state as BoundedTransferComplete).bytes, [1, 2]);
  });

  test("rejects noncanonical digests and releases retained bytes", () {
    final pool = BoundedTransferPool(
      assemblerFactory: () =>
          BoundedTransferAssembler(maximumChunkBytes: 3, maximumChunks: 3),
    );
    final parts = _parts([1, 2, 3, 4], chunkSize: 3);
    pool.accept(parts.first);

    expect(
      () => pool.accept(
        BoundedTransferPart(
          transferId: "transfer",
          index: 1,
          chunkCount: 2,
          encodedSize: 4,
          sha256: parts.last.sha256.toUpperCase(),
          payload: [4],
        ),
      ),
      throwsA(isA<BoundedTransferRejected>()),
    );
    expect(pool.retainedBytes, 0);
  });

  test("rejects a payload that does not match its digest", () {
    final parts = _parts([1, 2, 3, 4], chunkSize: 3);
    final assembler = BoundedTransferAssembler(
      maximumChunkBytes: 3,
      maximumChunks: 3,
    )..accept(parts.first);

    expect(
      () => assembler.accept(
        BoundedTransferPart(
          transferId: "transfer",
          index: 1,
          chunkCount: 2,
          encodedSize: 4,
          sha256: parts.last.sha256,
          payload: [9],
        ),
      ),
      throwsA(isA<BoundedTransferRejected>()),
    );
    expect(assembler.retainedBytes, 0);
  });

  test("rejects duplicate chunks and invalid chunk shapes", () {
    final part = _parts([1, 2, 3, 4], chunkSize: 3).first;
    final assembler = BoundedTransferAssembler(
      maximumChunkBytes: 3,
      maximumChunks: 3,
    )..accept(part);

    expect(
      () => assembler.accept(part),
      throwsA(isA<BoundedTransferRejected>()),
    );
    expect(
      () => BoundedTransferAssembler().accept(
        BoundedTransferPart(
          transferId: "transfer",
          index: 1,
          chunkCount: 1,
          encodedSize: 1,
          sha256: sha256.convert([1]).toString(),
          payload: [1],
        ),
      ),
      throwsA(isA<BoundedTransferRejected>()),
    );
  });

  test("bounds active transfer count and aggregate retained bytes", () {
    final countPool = BoundedTransferPool(
      maximumActiveTransfers: 1,
      assemblerFactory: () =>
          BoundedTransferAssembler(maximumChunkBytes: 2, maximumChunks: 2),
    )..accept(_parts([1, 2, 3], chunkSize: 2).first);
    expect(
      () => countPool.accept(
        _parts([4, 5, 6], chunkSize: 2, transferId: "second").first,
      ),
      throwsA(isA<BoundedTransferRejected>()),
    );

    final bytePool = BoundedTransferPool(
      maximumRetainedBytes: 1,
      assemblerFactory: () =>
          BoundedTransferAssembler(maximumChunkBytes: 2, maximumChunks: 2),
    );
    expect(
      () => bytePool.accept(_parts([1, 2, 3], chunkSize: 2).first),
      throwsA(isA<BoundedTransferRejected>()),
    );
    expect(bytePool.retainedBytes, 0);
  });

  test("round trips a multimegabyte transfer", () {
    final bytes = Uint8List(3 * 1024 * 1024 + 7);
    for (var index = 0; index < bytes.length; index++) {
      bytes[index] = index % 251;
    }
    final pool = BoundedTransferPool();
    BoundedTransferPoolState state = const BoundedTransferPoolPending();

    for (final part in _parts(
      bytes,
      chunkSize: defaultMaximumTransferChunkBytes,
    )) {
      state = pool.accept(part);
    }

    expect((state as BoundedTransferPoolComplete).bytes, bytes);
    expect(pool.retainedBytes, 0);
  });

  testWidgets("expires an idle incomplete transfer without another message", (
    tester,
  ) async {
    final expired = <String>[];
    final pool = BoundedTransferPool(
      idleTimeout: const Duration(seconds: 2),
      onExpired: expired.add,
      assemblerFactory: () =>
          BoundedTransferAssembler(maximumChunkBytes: 3, maximumChunks: 3),
    )..accept(_parts([1, 2, 3, 4], chunkSize: 3).first);

    await tester.pump(const Duration(seconds: 2));

    expect(expired, ["transfer"]);
    expect(pool.retainedBytes, 0);
  });

  testWidgets("cancels the source subscription after an assembly timeout", (
    tester,
  ) async {
    var cancelled = false;
    final controller = StreamController<BoundedTransferPart>(
      onCancel: () => cancelled = true,
    );
    Object? failure;
    final assembly = BoundedTransferAssembler()
        .assemble(controller.stream, timeout: const Duration(seconds: 2))
        .catchError((Object error) {
          failure = error;
          return Uint8List(0);
        });

    await tester.pump(const Duration(seconds: 1));
    controller.add(_parts([1, 2], chunkSize: 1).first);
    await tester.pump(const Duration(milliseconds: 999));
    expect(failure, isNull);

    await tester.pump(const Duration(milliseconds: 2));
    await tester.pump();

    expect(failure, isA<TimeoutException>());
    expect(cancelled, isTrue);
    await assembly;
  });

  testWidgets("reports a cancellation failure without extending the deadline", (
    tester,
  ) async {
    final cleanupFailures = <Object>[];
    final controller = StreamController<BoundedTransferPart>(
      onCancel: () => Future<void>.error(StateError("cleanup failed")),
    );
    Object? transferFailure;
    final assembly =
        BoundedTransferAssembler(
              onCleanupFailure: (error, _) => cleanupFailures.add(error),
            )
            .assemble(controller.stream, timeout: const Duration(seconds: 2))
            .catchError((Object error) {
              transferFailure = error;
              return Uint8List(0);
            });

    await tester.pump(const Duration(seconds: 2));
    await tester.pump();

    expect(transferFailure, isA<TimeoutException>());
    expect(cleanupFailures.single, isA<StateError>());
    await assembly;
  });

  test(
    "explicit cancellation releases the source subscription immediately",
    () async {
      var cancelled = false;
      final source = StreamController<BoundedTransferPart>(
        onCancel: () => cancelled = true,
      );
      final dispose = Completer<void>();
      final assembly = BoundedTransferAssembler().assemble(
        source.stream,
        cancelled: dispose.future,
      );

      source.add(_parts([1, 2], chunkSize: 1).first);
      dispose.complete();

      await expectLater(assembly, throwsA(isA<BoundedTransferCancelled>()));
      expect(cancelled, isTrue);
    },
  );

  test("validates positive custom limits", () {
    expect(
      () => BoundedTransferAssembler(maximumChunkBytes: 0),
      throwsArgumentError,
    );
    expect(
      () => BoundedTransferPool(maximumActiveTransfers: 0),
      throwsArgumentError,
    );
  });

  test("scopes transfer updates to one safe subject segment", () {
    expect(
      boundedTransferUpdateSubject("realm.catalog", "request_1-a"),
      "realm.catalog.request_1-a",
    );
    for (final invalid in ["", "request.one", "request one", "*", ">"]) {
      expect(
        () => boundedTransferUpdateSubject("realm.catalog", invalid),
        throwsArgumentError,
      );
    }
  });
}

List<BoundedTransferPart> _parts(
  List<int> bytes, {
  required int chunkSize,
  String transferId = "transfer",
}) {
  final digest = sha256.convert(bytes).toString();
  final chunks = <List<int>>[];
  for (var start = 0; start < bytes.length; start += chunkSize) {
    chunks.add(
      bytes.sublist(start, (start + chunkSize).clamp(0, bytes.length)),
    );
  }
  return [
    for (final (index, payload) in chunks.indexed)
      BoundedTransferPart(
        transferId: transferId,
        index: index,
        chunkCount: chunks.length,
        encodedSize: bytes.length,
        sha256: digest,
        payload: payload,
      ),
  ];
}
