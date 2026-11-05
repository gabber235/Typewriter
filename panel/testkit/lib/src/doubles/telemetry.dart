import "package:typewriter_panel/typewriter_panel.dart";

/// A trace exporter that hands every NATS and HTTP operation [headers], the
/// trace context an enabled exporter adds to every request.
final class FakeTelemetry implements PanelTelemetry {
  const FakeTelemetry(this.headers);

  /// The trace context every operation receives.
  final Map<String, String> headers;

  @override
  Future<T> traceNats<T>({
    required String subject,
    required int payloadSize,
    required String operationName,
    required Future<T> Function(Map<String, String> headers) operation,
  }) => operation(headers);

  @override
  Future<Response> traceHttp({
    required String method,
    required Uri uri,
    required Future<Response> Function(Map<String, String> headers) operation,
  }) => operation(headers);
}
