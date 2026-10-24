import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";

const _seed = "SUAKYRHVIOREXV7EUZTBHUHL7NUMHPMAS7QMDU3GTIUWEI5LDNOXD43IZY";
const _subject = "allowed.chunked";

/// Small limits, so a few bytes already span several credit windows.
const _limits = TransportLimits(
  chunkBytes: 4,
  windowFrames: 2,
  requestMaxBytes: 64,
  replyMaxBytes: 64,
  frameInactivity: Duration(seconds: 1),
);

/// One frame as a sender publishes it.
typedef _Frame = ({NatsHeaders headers, Uint8List payload});

/// Splits [bytes] into the frames the services and backend transports send.
List<_Frame> _frames(
  Uint8List bytes, {
  int chunkBytes = 4,
  String payloadId = "payload",
}) {
  final count = (bytes.length + chunkBytes - 1) ~/ chunkBytes;
  final digest = sha256.convert(bytes).toString();
  return [
    for (var index = 0; index < count; index++)
      (
        headers: NatsHeaders(
          entries: [
            MapEntry(PayloadHeaders.payload, payloadId),
            MapEntry(PayloadHeaders.chunk, "$index/$count"),
            MapEntry(PayloadHeaders.size, "${bytes.length}"),
            MapEntry(PayloadHeaders.sha256, digest),
          ],
        ),
        payload: bytes.sublist(
          index * chunkBytes,
          min((index + 1) * chunkBytes, bytes.length),
        ),
      ),
  ];
}

NatsHeaders _failure(String failure, {int? size, int? limit}) => NatsHeaders(
  entries: [
    const MapEntry(PayloadHeaders.payload, "payload"),
    MapEntry(PayloadHeaders.failure, failure),
    if (size != null) MapEntry(PayloadHeaders.size, "$size"),
    if (limit != null) MapEntry(PayloadHeaders.limit, "$limit"),
  ],
);

Uint8List _bytes(int length, {int seed = 0}) => Uint8List.fromList([
  for (var i = 0; i < length; i++) (i * 31 + seed) & 0xff,
]);

PayloadAssembler _assembler() =>
    PayloadAssembler(_limits, maxBytes: _limits.replyMaxBytes);

/// Feeds [frames] to one assembler and returns the first complete payload.
Uint8List? _assemble(PayloadAssembler assembler, Iterable<_Frame> frames) {
  for (final frame in frames) {
    final complete = assembler.accept(frame.headers, frame.payload);
    if (complete != null) return complete;
  }
  return null;
}

void main() {
  group("payload assembly", () {
    test("a message without framing headers is a complete payload", () {
      final payload = _bytes(3);
      expect(_assembler().accept(null, payload), payload);
      expect(_assembler().accept(NatsHeaders(), payload), payload);
    });

    test("frames out of order and identical duplicates assemble", () {
      final payload = _bytes(13);
      final frames = _frames(payload);
      final shuffled = [frames.last, ...frames.reversed];

      expect(_assemble(_assembler(), shuffled), payload);
    });

    test("a changed duplicate is rejected", () {
      final frames = _frames(_bytes(8));
      final changed = (
        headers: frames.first.headers,
        payload: Uint8List.fromList([9, 9, 9, 9]),
      );

      expect(
        () => _assemble(_assembler(), [frames.first, changed]),
        throwsA(isA<TransferRejected>()),
      );
    });

    test("frames beyond the ceiling or chunk size are rejected", () {
      final frame = _frames(_bytes(8)).first;
      final tooMany = (
        headers: frame.headers.set(PayloadHeaders.chunk, "0/17"),
        payload: frame.payload,
      );
      final tooLarge = (
        headers: frame.headers.set(PayloadHeaders.size, "65"),
        payload: frame.payload,
      );
      final tooWide = (headers: frame.headers, payload: Uint8List(5));

      for (final rejected in [tooMany, tooLarge, tooWide]) {
        expect(
          () => _assembler().accept(rejected.headers, rejected.payload),
          throwsA(isA<TransferRejected>()),
        );
      }
    });

    test("size and digest are verified before the payload is returned", () {
      final frames = _frames(_bytes(8));
      final corrupted = [
        frames.first,
        (
          headers: frames.last.headers,
          payload: Uint8List.fromList([1, 2, 3, 4]),
        ),
      ];

      expect(
        () => _assemble(_assembler(), corrupted),
        throwsA(isA<TransferRejected>()),
      );
    });

    test("a too large failure frame reports the size and limit first", () {
      expect(
        () => _assembler().accept(
          _failure(PayloadHeaders.tooLarge, size: 40, limit: 16),
          Uint8List(0),
        ),
        throwsA(
          isA<TransferTooLarge>()
              .having((failure) => failure.size, "size", 40)
              .having((failure) => failure.limit, "limit", 16),
        ),
      );
    });

    test("an interrupted failure frame ends the payload", () {
      final assembler = _assembler();
      final frames = _frames(_bytes(12));
      expect(
        assembler.accept(frames.first.headers, frames.first.payload),
        isNull,
      );

      expect(
        () => assembler.accept(
          _failure(PayloadHeaders.interrupted),
          Uint8List(0),
        ),
        throwsA(isA<TransferInterrupted>()),
      );
    });

    test("frames of several senders never mix", () {
      final first = _bytes(9);
      final second = _bytes(9, seed: 7);
      final frames = [
        ..._frames(first, payloadId: "first"),
        ..._frames(second, payloadId: "second"),
      ];
      final interleaved = [
        for (var index = 0; index < 3; index++) ...[
          frames[index],
          frames[index + 3],
        ],
      ];
      final assembler = _assembler();

      final completed = interleaved
          .map((frame) => assembler.accept(frame.headers, frame.payload))
          .nonNulls
          .toList();

      expect(completed, [first, second]);
    });

    test("failure answers name their transfer failure", () {
      expect(
        TransferFailure.named(PayloadHeaders.busy, NatsHeaders()),
        isA<TransferBusy>(),
      );
      expect(
        TransferFailure.named(PayloadHeaders.rejected, NatsHeaders()),
        isA<TransferRejected>(),
      );
      expect(
        TransferFailure.named(PayloadHeaders.incomplete, NatsHeaders()),
        isA<TransferRejected>(),
      );
    });
  });

  test("a request above its ceiling fails before any frame is sent", () async {
    // The connection never opens, so any attempt to send would hang instead
    // of failing.
    final client = NatsCoreClient.fromConnectionFuture(
      Completer<NatsConnection>().future,
      configuration: const NatsClientConfiguration(
        url: "nats://127.0.0.1:4222",
        seed: _seed,
        requestInboxPrefix: "_INBOX.unit",
        actorId: "unit-user",
        organizationId: "unit-organization",
        connectionSession: "0123456789abcdef0123456789abcdef",
      ),
    );

    await expectLater(
      client.request(
        _subject,
        _bytes(_limits.requestMaxBytes + 1),
        limits: _limits,
      ),
      throwsA(
        isA<TransferTooLarge>()
            .having((failure) => failure.size, "size", 65)
            .having((failure) => failure.limit, "limit", 64),
      ),
    );
  });

  // Runs against a NATS server at NATS_ADAPTER_URL, such as the native
  // fixture of the panel NATS integration tests.
  final serverUrl = Platform.environment["NATS_ADAPTER_URL"];
  final skipReason = serverUrl == null ? "NATS_ADAPTER_URL is not set" : false;

  group("NATS client payload framing", () {
    late NatsConnection responder;
    late NatsCoreClient client;
    late Future<void> Function(CoreNatsMessage request) receive;

    setUp(() async {
      responder = await NatsConnection.connect(
        NatsOptions(
          servers: [NatsServer.parse(serverUrl!)],
          authentication: NatsAuthentication.nkey(_seed),
        ),
      );
      final requests = await responder.subscribe(_subject);
      final listener = requests.messages.listen(
        (request) => unawaited(receive(request)),
      );
      await responder.flush();
      client = NatsCoreClient.connect(
        NatsClientConfiguration(
          url: serverUrl,
          seed: _seed,
          requestInboxPrefix: "_INBOX.integration",
          actorId: "integration-user",
          organizationId: "integration-organization",
          connectionSession: "0123456789abcdef0123456789abcdef",
        ),
      );
      addTearDown(() async {
        await client.close();
        await listener.cancel();
        await requests.unsubscribe();
        await responder.close();
      });
    });

    /// Streams [frames] to [inbox] the way a responder sends a framed reply
    /// to the panel: every frame is published at once, none waits for a
    /// credit. Frames in [dropped] are lost on the way.
    Future<void> streamReply(
      String inbox,
      List<_Frame> frames, {
      Set<int> dropped = const {},
    }) async {
      for (final (index, frame) in frames.indexed) {
        if (dropped.contains(index)) continue;
        await responder.publish(inbox, frame.payload, headers: frame.headers);
      }
    }

    test(
      "a streamed reply of many windows completes without any credit",
      () async {
        final payload = _bytes(_limits.replyMaxBytes);
        final frames = _frames(payload);
        expect(frames.length, greaterThan(_limits.windowFrames * 4));
        receive = (request) => streamReply(request.replySubject!, frames);

        final response = await client.request(
          _subject,
          Uint8List(0),
          limits: _limits,
        );

        expect(response.payload, payload);
      },
      skip: skipReason,
      timeout: const Timeout(Duration(seconds: 30)),
    );

    test(
      "a dropped reply frame fails the request on the inactivity bound",
      () async {
        receive = (request) => streamReply(
          request.replySubject!,
          _frames(_bytes(27)),
          dropped: {0},
        );

        await expectLater(
          client.request(_subject, Uint8List(0), limits: _limits),
          throwsA(
            isA<NatsClientException>().having(
              (failure) => failure.kind,
              "kind",
              NatsFailureKind.timeout,
            ),
          ),
        );
      },
      skip: skipReason,
      timeout: const Timeout(Duration(seconds: 30)),
    );

    test(
      "a framed request arrives whole and the final answer is the response",
      () async {
        final payload = _bytes(21);
        final parts = <int, Uint8List>{};
        final traces = <String?>{};
        receive = (frame) async {
          final headers = frame.headers!;
          final [index, count] = headers
              .first(PayloadHeaders.chunk)!
              .split("/")
              .map(int.parse)
              .toList();
          parts[index] = frame.payload;
          traces.add(headers.first("traceparent"));
          if (frame.replySubject == null) return;
          if (index < count - 1) {
            final credit = min(index + 1 + _limits.windowFrames, count);
            await responder.reply(
              frame,
              const [],
              headers: NatsHeaders(
                entries: [MapEntry(PayloadHeaders.credit, "$credit")],
              ),
            );
            return;
          }
          final received = [for (var i = 0; i < count; i++) ...parts[i]!];
          await responder.reply(
            frame,
            received.length == payload.length ? const [1] : const [0],
          );
        };

        final response = await client.request(
          _subject,
          payload,
          limits: _limits,
          headers: const {"traceparent": "integration-trace"},
        );

        expect(response.payload, [1]);
        expect([for (var i = 0; i < parts.length; i++) ...parts[i]!], payload);
        expect(traces, {"integration-trace"});
      },
      skip: skipReason,
      timeout: const Timeout(Duration(seconds: 30)),
    );

    test(
      "a framed request the receiver refuses tells it the payload stopped",
      () async {
        final interrupted = Completer<String?>();
        receive = (frame) async {
          final headers = frame.headers!;
          if (headers.first(PayloadHeaders.failure) case final failure?) {
            interrupted.complete(failure);
            return;
          }
          if (frame.replySubject == null) return;
          await responder.reply(
            frame,
            const [],
            headers: NatsHeaders(
              entries: [
                MapEntry(
                  PayloadHeaders.payload,
                  headers.first(PayloadHeaders.payload)!,
                ),
                const MapEntry(PayloadHeaders.failure, PayloadHeaders.busy),
              ],
            ),
          );
        };

        await expectLater(
          client.request(_subject, _bytes(21), limits: _limits),
          throwsA(isA<TransferBusy>()),
        );
        expect(await interrupted.future, PayloadHeaders.interrupted);
      },
      skip: skipReason,
      timeout: const Timeout(Duration(seconds: 30)),
    );

    test(
      "a too large reply fails with its size and limit",
      () async {
        receive = (request) => responder.publish(
          request.replySubject!,
          Uint8List(0),
          headers: _failure(
            PayloadHeaders.tooLarge,
            size: _limits.replyMaxBytes + 1,
            limit: _limits.replyMaxBytes,
          ),
        );

        await expectLater(
          client.request(_subject, Uint8List(0), limits: _limits),
          throwsA(
            isA<TransferTooLarge>().having(
              (failure) => failure.limit,
              "limit",
              _limits.replyMaxBytes,
            ),
          ),
        );
      },
      skip: skipReason,
      timeout: const Timeout(Duration(seconds: 30)),
    );

    test(
      "an interrupted frame ends the request at once",
      () async {
        final frames = _frames(_bytes(9));
        receive = (request) async {
          await responder.publish(
            request.replySubject!,
            frames.first.payload,
            headers: frames.first.headers,
          );
          await responder.publish(
            request.replySubject!,
            Uint8List(0),
            headers: _failure(PayloadHeaders.interrupted),
          );
        };

        await expectLater(
          client.request(_subject, Uint8List(0), limits: _limits),
          throwsA(isA<TransferInterrupted>()),
        );
      },
      skip: skipReason,
      timeout: const Timeout(Duration(seconds: 5)),
    );

    test(
      "a NATS status reply fails instead of decoding as an empty reply",
      () async {
        receive = (request) => responder.publish(
          request.replySubject!,
          Uint8List(0),
          headers: NatsHeaders(
            statusCode: 408,
            statusDescription: "Request Timeout",
          ),
        );

        await expectLater(
          client.request(_subject, Uint8List(0), limits: _limits),
          throwsA(
            isA<NatsClientException>()
                .having(
                  (failure) => failure.kind,
                  "kind",
                  NatsFailureKind.protocol,
                )
                .having(
                  (failure) => failure.message,
                  "message",
                  "NATS status 408: Request Timeout",
                ),
          ),
        );
      },
      skip: skipReason,
      timeout: const Timeout(Duration(seconds: 30)),
    );

    test(
      "cancellation stops collection before the reply completes",
      () async {
        final frames = _frames(_bytes(9));
        final cancelled = Completer<void>();
        receive = (request) async {
          await responder.publish(
            request.replySubject!,
            frames.first.payload,
            headers: frames.first.headers,
          );
          cancelled.complete();
        };

        await expectLater(
          client.request(
            _subject,
            Uint8List(0),
            limits: _limits,
            cancelled: cancelled.future,
          ),
          throwsA(isA<TransferCancelled>()),
        );
      },
      skip: skipReason,
      timeout: const Timeout(Duration(seconds: 30)),
    );
  });
}
