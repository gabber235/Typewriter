import "package:dart_nats/dart_nats.dart";
import "package:dartastic_opentelemetry/dartastic_opentelemetry.dart";
import "package:http/http.dart" as http;
import "package:riverpod_annotation/riverpod_annotation.dart";
import "package:typewriter_panel/typewriter_panel.dart" hide Header;

part "telemetry.g.dart";

abstract interface class PanelTelemetry {
  Future<T> traceNats<T>({
    required String subject,
    required int payloadSize,
    required String operationName,
    required Future<T> Function(Header? header) operation,
  });

  Future<http.Response> traceHttp({
    required String method,
    required Uri uri,
    required Future<http.Response> Function(Map<String, String> headers)
    operation,
  });
}

final class NoopPanelTelemetry implements PanelTelemetry {
  const NoopPanelTelemetry();

  @override
  Future<T> traceNats<T>({
    required String subject,
    required int payloadSize,
    required String operationName,
    required Future<T> Function(Header? header) operation,
  }) => operation(null);

  @override
  Future<http.Response> traceHttp({
    required String method,
    required Uri uri,
    required Future<http.Response> Function(Map<String, String> headers)
    operation,
  }) => operation(const {});
}

final class OpenTelemetryPanelTelemetry implements PanelTelemetry {
  OpenTelemetryPanelTelemetry()
    : _tracer = OTel.tracer(),
      _propagator = W3CTraceContextPropagator();

  final Tracer _tracer;
  final W3CTraceContextPropagator _propagator;

  Map<String, String> _headers() {
    final headers = <String, String>{};
    _propagator.inject(Context.current, headers, _MapTextMapSetter(headers));
    if (headers["tracestate"]?.isEmpty ?? false) {
      headers.remove("tracestate");
    }
    return headers;
  }

  @override
  Future<T> traceNats<T>({
    required String subject,
    required int payloadSize,
    required String operationName,
    required Future<T> Function(Header? header) operation,
  }) => _tracer.startActiveSpanAsync(
    name: "nats $operationName",
    kind: SpanKind.producer,
    attributes: Attributes.of({
      "messaging.system": "nats",
      "messaging.operation.name": operationName,
      "messaging.operation.type": "send",
      "messaging.destination.name": subject,
      "messaging.message.body.size": payloadSize,
    }),
    fn: (_) => operation(Header(headers: _headers())),
  );

  @override
  Future<http.Response> traceHttp({
    required String method,
    required Uri uri,
    required Future<http.Response> Function(Map<String, String> headers)
    operation,
  }) => _tracer.startActiveSpanAsync(
    name: "$method ${uri.path}",
    kind: SpanKind.client,
    attributes: Attributes.of({
      "http.request.method": method,
      "server.address": uri.host,
      "url.path": uri.path,
    }),
    fn: (span) async {
      final response = await operation(_headers());
      span.setIntAttribute("http.response.status_code", response.statusCode);
      if (response.statusCode >= 400) {
        span.setStatus(SpanStatusCode.Error);
      }
      return response;
    },
  );
}

final class _MapTextMapSetter implements TextMapSetter<String> {
  const _MapTextMapSetter(this._carrier);

  final Map<String, String> _carrier;

  @override
  void set(String key, String value) => _carrier[key] = value;
}

@Riverpod(keepAlive: true)
Future<PanelTelemetry> panelTelemetry(Ref ref) async {
  final config = AppConfig.telemetry;
  if (!config.enabled) return const NoopPanelTelemetry();

  final endpoint = Uri.tryParse(config.tracesEndpoint);
  if (endpoint == null || !endpoint.hasScheme || endpoint.host.isEmpty) {
    throw StateError("A valid OTLP traces endpoint is required");
  }

  // TODO: Reassess Dartastic maturity, web support, and dependency pinning.
  // TODO: Define production sampling, authenticated ingestion, and limits.
  // TODO: Review concrete NATS subjects for cardinality and identifier privacy.
  // TODO: Add app lifecycle flush and shutdown if this pilot is retained.
  await OTel.initialize(
    endpoint: config.tracesEndpoint,
    serviceName: "typewriter-panel",
    enableMetrics: false,
    enableLogs: false,
    sampler: const AlwaysOnSampler(),
  );
  return OpenTelemetryPanelTelemetry();
}
