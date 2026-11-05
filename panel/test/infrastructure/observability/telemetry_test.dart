import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  const telemetry = NoopPanelTelemetry();

  setUpAll(() async {
    await OTel.initialize(
      endpoint: "http://localhost:4318",
      serviceName: "typewriter-panel-test",
      enableMetrics: false,
      enableLogs: false,
      spanProcessor: SimpleSpanProcessor(ConsoleExporter()),
    );
  });

  test("no-op NATS tracing sends no header", () async {
    final result = await telemetry.traceNats(
      subject: "test.subject",
      payloadSize: 3,
      operationName: "request",
      operation: (header) async {
        expect(header, isEmpty);
        return Uint8List.fromList([1, 2, 3]);
      },
    );

    expect(result, [1, 2, 3]);
  });

  test("no-op HTTP tracing sends no headers", () async {
    final response = await telemetry.traceHttp(
      method: "POST",
      uri: Uri.parse("https://example.com/path"),
      operation: (headers) async {
        expect(headers, isEmpty);
        return Response("ok", 200);
      },
    );

    expect(response.statusCode, 200);
  });

  test("OpenTelemetry tracing injects a valid NATS context", () async {
    final traced = OpenTelemetryPanelTelemetry();
    Map<String, String>? sent;

    await traced.traceNats(
      subject: "test.subject",
      payloadSize: 3,
      operationName: "request",
      operation: (header) async => sent = Map.of(header),
    );

    expect(sent, isNotNull, reason: "the request ran inside the trace");
    expect(
      sent!["traceparent"],
      matches(RegExp(r"^00-[0-9a-f]{32}-[0-9a-f]{16}-01$")),
    );
    expect(sent!["tracestate"], isNull);
  });

  for (final (name, create) in <(String, PanelTelemetry Function())>[
    ("no-op", () => telemetry),
    ("OpenTelemetry", OpenTelemetryPanelTelemetry.new),
  ]) {
    test("$name tracing rethrows operation errors unchanged", () async {
      final traced = create();
      final error = StateError("network failed");

      await expectLater(
        traced.traceNats<void>(
          subject: "test.subject",
          payloadSize: 0,
          operationName: "request",
          operation: (_) => Future<void>.error(error),
        ),
        throwsA(same(error)),
      );
      await expectLater(
        traced.traceHttp(
          method: "POST",
          uri: Uri.parse("https://example.com/path"),
          operation: (_) => Future<Response>.error(error),
        ),
        throwsA(same(error)),
      );
    });
  }

  test("disabled tracing starts the panel without an exporter", () async {
    final world = testWorld(const []);

    expect(
      await world.container.read(panelTelemetryProvider.future),
      isA<NoopPanelTelemetry>(),
    );
  });
}
