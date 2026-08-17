import "dart:async";
import "dart:convert";
import "dart:io";

import "package:flutter_test/flutter_test.dart";

void testWidgetsWithNetworkImages(
  String description,
  WidgetTesterCallback callback,
) {
  testWidgets(description, (tester) {
    return HttpOverrides.runZoned(
      () => callback(tester),
      createHttpClient: (_) => _TestImageHttpClient(),
    );
  });
}

final class _TestImageHttpClient implements HttpClient {
  @override
  bool autoUncompress = false;

  @override
  void close({bool force = false}) {}

  @override
  Future<HttpClientRequest> getUrl(Uri url) async => _TestImageRequest(url);

  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) async =>
      _TestImageRequest(url);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _TestImageRequest implements HttpClientRequest {
  _TestImageRequest(this.url);

  final Uri url;

  @override
  int contentLength = 0;

  @override
  bool followRedirects = true;

  @override
  int maxRedirects = 5;

  @override
  bool persistentConnection = true;

  @override
  final HttpHeaders headers = _TestImageHeaders();

  @override
  Future<void> addStream(Stream<List<int>> stream) async {
    await stream.drain<void>();
  }

  @override
  Future<HttpClientResponse> close() async => _TestImageResponse(url);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _TestImageHeaders implements HttpHeaders {
  @override
  void add(String name, Object value, {bool preserveHeaderCase = false}) {}

  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) {}

  @override
  void forEach(void Function(String name, List<String> values) action) {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _TestImageResponse extends Stream<List<int>>
    implements HttpClientResponse {
  _TestImageResponse(Uri url) : bytes = _bytesFor(url);

  static final _pngBytes = File(
    "../assets/typewriter-icon.png",
  ).readAsBytesSync();
  static final _svgBytes = utf8.encode(
    "<svg xmlns=\"http://www.w3.org/2000/svg\" viewBox=\"0 0 1 1\"></svg>",
  );

  final List<int> bytes;

  static List<int> _bytesFor(Uri url) =>
      url.host.contains("dicebear") ? _pngBytes : _svgBytes;

  @override
  int get contentLength => bytes.length;

  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;

  @override
  int get statusCode => HttpStatus.ok;

  @override
  final HttpHeaders headers = _TestImageHeaders();

  @override
  bool get isRedirect => false;

  @override
  bool get persistentConnection => false;

  @override
  String get reasonPhrase => "OK";

  @override
  List<RedirectInfo> get redirects => const [];

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int>)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) => Stream<List<int>>.value(bytes).listen(
    onData,
    onError: onError,
    onDone: onDone,
    cancelOnError: cancelOnError,
  );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
