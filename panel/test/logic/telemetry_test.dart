import "dart:typed_data";

import "package:dartastic_opentelemetry/dartastic_opentelemetry.dart";
import "package:flutter_test/flutter_test.dart";
import "package:http/http.dart" as http;
import "package:typewriter_panel/logic/telemetry.dart";

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
        expect(header, isNull);
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
        return http.Response("ok", 200);
      },
    );

    expect(response.statusCode, 200);
  });

  test("OpenTelemetry tracing injects a valid NATS context", () async {
    final traced = OpenTelemetryPanelTelemetry();

    await traced.traceNats(
      subject: "test.subject",
      payloadSize: 3,
      operationName: "request",
      operation: (header) async {
        expect(
          header?.get("traceparent"),
          matches(RegExp(r"^00-[0-9a-f]{32}-[0-9a-f]{16}-01$")),
        );
        expect(header?.get("tracestate"), isNull);
      },
    );
  });

  test("operation errors are rethrown unchanged", () async {
    final error = StateError("network failed");

    expect(
      () => telemetry.traceNats<void>(
        subject: "test.subject",
        payloadSize: 0,
        operationName: "request",
        operation: (_) => Future<void>.error(error),
      ),
      throwsA(same(error)),
    );
  });
}
