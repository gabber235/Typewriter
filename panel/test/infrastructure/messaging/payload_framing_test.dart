import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

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

/// The shared frame vectors the backend framer writes through
/// `cargo xtask generate`; every transport's assembler reads them.
const _frameVectors = "../skir-src/transport/v1/fixtures/frames.json";

void main() {
  group("shared frame vectors", () {
    final vectors = jsonDecode(
      File(_frameVectors).readAsStringSync(),
    ) as Map<String, dynamic>;
    for (final vector
        in (vectors["cases"] as List<dynamic>).cast<Map<String, dynamic>>()) {
      test("frame vector: ${vector["name"]}", () {
        final maxBytes = vector["maxBytes"] as int;
        final assembler = PayloadAssembler(
          TransportLimits(
            chunkBytes: vector["chunkBytes"] as int,
            windowFrames: 2,
            requestMaxBytes: maxBytes,
            replyMaxBytes: maxBytes,
            frameInactivity: const Duration(seconds: 1),
          ),
          maxBytes: maxBytes,
        );
        final frames = [
          for (final frame in vector["frames"] as List<dynamic>)
            (
              headers: switch (frame["headers"] as List<dynamic>) {
                [] => null,
                final headers => NatsHeaders(
                  entries: [
                    for (final [name as String, value as String] in headers)
                      MapEntry(name, value),
                  ],
                ),
              },
              payload: base64Decode(frame["body"] as String),
            ),
        ];
        for (final frame in frames.take(frames.length - 1)) {
          expect(assembler.accept(frame.headers, frame.payload), isNull);
        }

        final last = frames.last;
        Object? accept() => assembler.accept(last.headers, last.payload);
        final expected = vector["expect"] as Map<String, dynamic>;
        switch (expected) {
          case {"bytes": final String bytes}:
            expect(accept(), base64Decode(bytes));
          case {"pending": true}:
            expect(accept(), isNull);
          case {"rejected": true}:
            expect(accept, throwsA(isA<TransferRejected>()));
          case {"failure": PayloadHeaders.tooLarge}:
            expect(accept, throwsA(isA<TransferTooLarge>()));
          case {"failure": PayloadHeaders.interrupted}:
            expect(accept, throwsA(isA<TransferInterrupted>()));
          default:
            fail("unknown expectation $expected");
        }
      });
    }
  });

  group("framing round trip", () {
    // Fixed seeds keep every run on the same corpus; a failing seed becomes
    // an example case below.
    for (var seed = 0; seed < 200; seed++) {
      test("seed $seed: any body, framed at any chunk size and delivered in "
          "any order with duplicates, assembles byte identical", () {
        final generator = Generator(seed);
        final chunkBytes = generator.integer(65, min: 1);
        final limits = TransportLimits(
          chunkBytes: chunkBytes,
          windowFrames: 2,
          requestMaxBytes: 4096,
          replyMaxBytes: 4096,
          frameInactivity: const Duration(seconds: 1),
        );
        final body = Uint8List.fromList(
          generator.list(generator.integer(4097), (it) => it.integer(256)),
        );
        final frames = payloadFrames(body, chunkBytes: chunkBytes)
          ..shuffle(Random(seed));
        final delivered = [
          for (final frame in frames) ...[
            frame,
            if (generator.chance(0.1)) frame,
          ],
        ];

        final assembler = PayloadAssembler(
          limits,
          maxBytes: limits.replyMaxBytes,
        );
        expect(
          delivered
              .map((frame) => assembler.accept(frame.headers, frame.payload))
              .nonNulls
              .firstOrNull,
          body,
        );
      });
    }

    for (var seed = 0; seed < 100; seed++) {
      test("seed $seed: a missing or altered frame never yields other "
          "bytes", () {
        final generator = Generator(seed);
        final body = Uint8List.fromList(
          generator.list(
            generator.integer(64, min: 2),
            (it) => it.integer(256),
          ),
        );
        final frames = payloadFrames(body);
        final index = generator.integer(frames.length);
        final dropped = generator.chance(0.5);
        final damaged = [
          for (final (position, frame) in frames.indexed)
            if (position != index)
              frame
            else if (!dropped)
              (
                headers: frame.headers,
                payload: Uint8List.fromList([
                  for (final byte in frame.payload) byte ^ 0xff,
                ]),
              ),
        ];

        final assembler = PayloadAssembler(
          _limits,
          maxBytes: _limits.replyMaxBytes,
        );
        Uint8List? assembled;
        try {
          assembled = damaged
              .map((frame) => assembler.accept(frame.headers, frame.payload))
              .nonNulls
              .firstOrNull;
        } on TransferFailure {
          return;
        }
        expect(assembled, isNull);
      });
    }
  });

  group("payload assembly", () {
    test("a message without framing headers is a complete payload", () {
      final payload = Generator(0).bytes(3);
      expect(
        PayloadAssembler(
          _limits,
          maxBytes: _limits.replyMaxBytes,
        ).accept(null, payload),
        payload,
      );
      expect(
        PayloadAssembler(
          _limits,
          maxBytes: _limits.replyMaxBytes,
        ).accept(NatsHeaders(), payload),
        payload,
      );
    });

    test("frames out of order and identical duplicates assemble", () {
      final payload = Generator(0).bytes(13);
      final frames = payloadFrames(payload);
      final shuffled = [frames.last, ...frames.reversed];
      final assembler = PayloadAssembler(
        _limits,
        maxBytes: _limits.replyMaxBytes,
      );

      expect(
        shuffled
            .map((frame) => assembler.accept(frame.headers, frame.payload))
            .nonNulls
            .firstOrNull,
        payload,
      );
    });

    test("a changed duplicate is rejected", () {
      final frames = payloadFrames(Generator(0).bytes(8));
      final changed = (
        headers: frames.first.headers,
        payload: Uint8List.fromList([9, 9, 9, 9]),
      );

      final assembler = PayloadAssembler(
        _limits,
        maxBytes: _limits.replyMaxBytes,
      );

      expect(
        () => [frames.first, changed]
            .map((frame) => assembler.accept(frame.headers, frame.payload))
            .nonNulls
            .firstOrNull,
        throwsA(isA<TransferRejected>()),
      );
    });

    test("frames beyond the ceiling or chunk size are rejected", () {
      final frame = payloadFrames(Generator(0).bytes(8)).first;
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
          () => PayloadAssembler(
            _limits,
            maxBytes: _limits.replyMaxBytes,
          ).accept(rejected.headers, rejected.payload),
          throwsA(isA<TransferRejected>()),
        );
      }
    });

    test("size and digest are verified before the payload is returned", () {
      final frames = payloadFrames(Generator(0).bytes(8));
      final corrupted = [
        frames.first,
        (
          headers: frames.last.headers,
          payload: Uint8List.fromList([1, 2, 3, 4]),
        ),
      ];

      final assembler = PayloadAssembler(
        _limits,
        maxBytes: _limits.replyMaxBytes,
      );

      expect(
        () => corrupted
            .map((frame) => assembler.accept(frame.headers, frame.payload))
            .nonNulls
            .firstOrNull,
        throwsA(isA<TransferRejected>()),
      );
    });

    test("a too large failure frame reports the size and limit first", () {
      expect(
        () => PayloadAssembler(_limits, maxBytes: _limits.replyMaxBytes).accept(
          NatsHeaders(
            entries: const [
              MapEntry(PayloadHeaders.payload, "payload"),
              MapEntry(PayloadHeaders.failure, PayloadHeaders.tooLarge),
              MapEntry(PayloadHeaders.size, "40"),
              MapEntry(PayloadHeaders.limit, "16"),
            ],
          ),
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
      final assembler = PayloadAssembler(
        _limits,
        maxBytes: _limits.replyMaxBytes,
      );
      final frames = payloadFrames(Generator(0).bytes(12));
      expect(
        assembler.accept(frames.first.headers, frames.first.payload),
        isNull,
      );

      expect(
        () => assembler.accept(
          NatsHeaders(
            entries: const [
              MapEntry(PayloadHeaders.payload, "payload"),
              MapEntry(PayloadHeaders.failure, PayloadHeaders.interrupted),
            ],
          ),
          Uint8List(0),
        ),
        throwsA(isA<TransferInterrupted>()),
      );
    });

    test("frames of several senders never mix", () {
      final first = Generator(0).bytes(9);
      final second = Generator(7).bytes(9);
      final frames = [...payloadFrames(first), ...payloadFrames(second)];
      final interleaved = [
        for (var index = 0; index < 3; index++) ...[
          frames[index],
          frames[index + 3],
        ],
      ];
      final assembler = PayloadAssembler(
        _limits,
        maxBytes: _limits.replyMaxBytes,
      );

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
        Generator(0).bytes(_limits.requestMaxBytes + 1),
        limits: _limits,
      ),
      throwsA(
        isA<TransferTooLarge>()
            .having((failure) => failure.size, "size", 65)
            .having((failure) => failure.limit, "limit", 64),
      ),
    );
  });
}
