import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";

const _seed = "SUAKYRHVIOREXV7EUZTBHUHL7NUMHPMAS7QMDU3GTIUWEI5LDNOXD43IZY";
const _subject = "allowed.chunked";
const _limits = TransportLimits(chunkBytes: 4, maxChunks: 4);

/// One reply frame as a responder publishes it.
typedef _Frame = ({NatsHeaders headers, Uint8List payload});

/// Splits [bytes] into the frames the services and backend transports send.
List<_Frame> _frames(
  Uint8List bytes, {
  required int chunkBytes,
  String replyId = "reply",
}) {
  final count = (bytes.length + chunkBytes - 1) ~/ chunkBytes;
  final digest = sha256.convert(bytes).toString();
  return [
    for (var index = 0; index < count; index++)
      (
        headers: NatsHeaders(
          entries: [
            MapEntry(ReplyHeaders.reply, replyId),
            MapEntry(ReplyHeaders.chunk, "$index/$count"),
            MapEntry(ReplyHeaders.size, "${bytes.length}"),
            MapEntry(ReplyHeaders.sha256, digest),
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
    const MapEntry(ReplyHeaders.reply, "reply"),
    MapEntry(ReplyHeaders.failure, failure),
    if (size != null) MapEntry(ReplyHeaders.size, "$size"),
    if (limit != null) MapEntry(ReplyHeaders.limit, "$limit"),
  ],
);

Uint8List _bytes(int length, {int seed = 0}) => Uint8List.fromList([
  for (var i = 0; i < length; i++) (i * 31 + seed) & 0xff,
]);

/// Feeds [frames] to one assembler and returns the first complete reply.
Uint8List? _assemble(ReplyAssembler assembler, Iterable<_Frame> frames) {
  for (final frame in frames) {
    final complete = assembler.accept(frame.headers, frame.payload);
    if (complete != null) return complete;
  }
  return null;
}

void main() {
  group("reply assembly", () {
    test("a message without framing headers is a complete reply", () {
      final payload = _bytes(3);
      expect(ReplyAssembler(_limits).accept(null, payload), payload);
      expect(ReplyAssembler(_limits).accept(NatsHeaders(), payload), payload);
    });

    test("frames out of order and identical duplicates assemble", () {
      final reply = _bytes(13);
      final frames = _frames(reply, chunkBytes: _limits.chunkBytes);
      final shuffled = [frames.last, ...frames.reversed];

      expect(_assemble(ReplyAssembler(_limits), shuffled), reply);
    });

    test("a changed duplicate is rejected", () {
      final frames = _frames(_bytes(8), chunkBytes: _limits.chunkBytes);
      final changed = (
        headers: frames.first.headers,
        payload: Uint8List.fromList([9, 9, 9, 9]),
      );

      expect(
        () => _assemble(ReplyAssembler(_limits), [frames.first, changed]),
        throwsA(isA<TransferRejected>()),
      );
    });

    test("frames beyond the bounds are rejected before assembly", () {
      final frame = _frames(_bytes(8), chunkBytes: _limits.chunkBytes).first;
      final tooMany = (
        headers: frame.headers.set(
          ReplyHeaders.chunk,
          "0/${_limits.maxChunks + 1}",
        ),
        payload: frame.payload,
      );
      final tooWide = (
        headers: frame.headers,
        payload: Uint8List(_limits.chunkBytes + 1),
      );

      for (final rejected in [tooMany, tooWide]) {
        expect(
          () =>
              ReplyAssembler(_limits)
                  .accept(rejected.headers, rejected.payload),
          throwsA(isA<TransferRejected>()),
        );
      }
    });

    test("size and digest are verified before the reply is returned", () {
      final frames = _frames(_bytes(8), chunkBytes: _limits.chunkBytes);
      final corrupted = [
        frames.first,
        (
          headers: frames.last.headers,
          payload: Uint8List.fromList([1, 2, 3, 4]),
        ),
      ];

      expect(
        () => _assemble(ReplyAssembler(_limits), corrupted),
        throwsA(isA<TransferRejected>()),
      );
    });

    test("a too large failure frame reports the size and limit first", () {
      expect(
        () => ReplyAssembler(_limits).accept(
          _failure(ReplyHeaders.tooLarge, size: 40, limit: 16),
          Uint8List(0),
        ),
        throwsA(
          isA<TransferTooLarge>()
              .having((failure) => failure.size, "size", 40)
              .having((failure) => failure.limit, "limit", 16),
        ),
      );
    });

    test("an interrupted failure frame ends the reply", () {
      final assembler = ReplyAssembler(_limits);
      final frames = _frames(_bytes(12), chunkBytes: _limits.chunkBytes);
      expect(
        assembler.accept(frames.first.headers, frames.first.payload),
        isNull,
      );

      expect(
        () =>
            assembler.accept(_failure(ReplyHeaders.interrupted), Uint8List(0)),
        throwsA(isA<TransferInterrupted>()),
      );
    });

    test("frames of several responders never mix", () {
      final first = _bytes(9);
      final second = _bytes(9, seed: 7);
      final frames = [
        ..._frames(first, chunkBytes: _limits.chunkBytes, replyId: "first"),
        ..._frames(second, chunkBytes: _limits.chunkBytes, replyId: "second"),
      ];
      final interleaved = [
        for (var index = 0; index < 3; index++) ...[
          frames[index],
          frames[index + 3],
        ],
      ];
      final assembler = ReplyAssembler(_limits);

      final completed = interleaved
          .map((frame) => assembler.accept(frame.headers, frame.payload))
          .nonNulls
          .toList();

      expect(completed, [first, second]);
    });
  });

  // Runs against the native NATS fixture that `dagger call panel-nats-integration` starts.
  final serverUrl = Platform.environment["NATS_ADAPTER_URL"];
  final skipReason = serverUrl == null ? "NATS_ADAPTER_URL is not set" : false;

  group("NATS client reply framing", () {
    late NatsConnection responder;
    late NatsCoreClient client;
    late Future<void> Function(CoreNatsMessage request) reply;

    setUp(() async {
      responder = await NatsConnection.connect(
        NatsOptions(
          servers: [NatsServer.parse(serverUrl!)],
          authentication: NatsAuthentication.nkey(_seed),
        ),
      );
      final requests = await responder.subscribe(_subject);
      final listener = requests.messages.listen(
        (request) => unawaited(reply(request)),
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

    Future<void> publishFrames(CoreNatsMessage request, List<_Frame> frames) =>
        Future.wait([
          for (final frame in frames)
            responder.publish(
              request.replySubject!,
              frame.payload,
              headers: frame.headers,
            ),
        ]);

    test(
      "a framed reply arrives as one complete message",
      () async {
        final payload = _bytes(transportLimits.chunkBytes * 2 + 17);
        reply = (request) => publishFrames(
          request,
          _frames(
            payload,
            chunkBytes: transportLimits.chunkBytes,
          ).reversed.toList(),
        );

        final response = await client.request(_subject, Uint8List(0));

        expect(response.payload, payload);
      },
      skip: skipReason,
      timeout: const Timeout(Duration(seconds: 30)),
    );

    test(
      "a too large reply fails with its size and limit",
      () async {
        reply = (request) => responder.publish(
          request.replySubject!,
          Uint8List(0),
          headers: _failure(
            ReplyHeaders.tooLarge,
            size: transportLimits.maxEncodedSize + 1,
            limit: transportLimits.maxEncodedSize,
          ),
        );

        await expectLater(
          client.request(_subject, Uint8List(0)),
          throwsA(
            isA<TransferTooLarge>().having(
              (failure) => failure.limit,
              "limit",
              transportLimits.maxEncodedSize,
            ),
          ),
        );
      },
      skip: skipReason,
      timeout: const Timeout(Duration(seconds: 30)),
    );

    test(
      "a publish failure part way ends the request at once",
      () async {
        final frames = _frames(
          _bytes(transportLimits.chunkBytes * 2 + 1),
          chunkBytes: transportLimits.chunkBytes,
        );
        reply = (request) async {
          await publishFrames(request, [frames.first]);
          await responder.publish(
            request.replySubject!,
            Uint8List(0),
            headers: _failure(ReplyHeaders.interrupted),
          );
        };

        await expectLater(
          client.request(_subject, Uint8List(0)),
          throwsA(isA<TransferInterrupted>()),
        );
      },
      skip: skipReason,
      timeout: const Timeout(Duration(seconds: 30)),
    );

    test(
      "a NATS status reply fails instead of decoding as an empty reply",
      () async {
        reply = (request) => responder.publish(
          request.replySubject!,
          Uint8List(0),
          headers: NatsHeaders(
            statusCode: 408,
            statusDescription: "Request Timeout",
          ),
        );

        await expectLater(
          client.request(_subject, Uint8List(0)),
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
        final frames = _frames(
          _bytes(transportLimits.chunkBytes + 1),
          chunkBytes: transportLimits.chunkBytes,
        );
        final cancelled = Completer<void>();
        reply = (request) async {
          await publishFrames(request, [frames.first]);
          cancelled.complete();
        };

        await expectLater(
          client.request(_subject, Uint8List(0), cancelled: cancelled.future),
          throwsA(isA<TransferCancelled>()),
        );
      },
      skip: skipReason,
      timeout: const Timeout(Duration(seconds: 30)),
    );
  });
}
