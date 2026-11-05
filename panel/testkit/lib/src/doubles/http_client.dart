import "package:typewriter_panel/typewriter_panel.dart";

/// An HTTP client that answers every request as unavailable (503) and
/// remembers whether its owner closed it.
final class UnavailableHttpClient extends BaseClient {
  /// Whether the client was closed.
  bool closed = false;

  @override
  Future<StreamedResponse> send(BaseRequest request) async => StreamedResponse(
    Stream.value(utf8.encode("Unavailable in this fixture")),
    503,
    request: request,
  );

  @override
  void close() {
    closed = true;
    super.close();
  }
}
