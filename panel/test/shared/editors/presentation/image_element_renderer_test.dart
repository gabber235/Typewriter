import "dart:async";
import "dart:io";

import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";

import "../../../support/test_utils.dart";

void main() {
  testWidgets("shows shimmer until the first image frame loads", (
    tester,
  ) async {
    final response = Completer<HttpClientResponse>();
    debugNetworkImageHttpClientProvider = () =>
        _ControlledHttpClient(response.future);

    await tester.pumpTestApp(
      child: SizedBox(width: 320, child: _renderer()),
      settle: false,
    );
    await tester.pump();

    expect(find.byType(ShimmerBox), findsOneWidget);

    final frame = Completer<void>();
    final image = tester.widget<Image>(find.byType(Image));
    final stream = image.image.resolve(
      createLocalImageConfiguration(tester.element(find.byType(Image))),
    );
    final listener = ImageStreamListener(
      (image, synchronousCall) {
        if (!frame.isCompleted) frame.complete();
      },
      onError: (error, stackTrace) {
        if (!frame.isCompleted) frame.completeError(error, stackTrace);
      },
    );
    stream.addListener(listener);

    response.complete(_ControlledImageResponse(_onePixelPng));
    for (var attempt = 0; attempt < 20 && !frame.isCompleted; attempt++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 10)),
      );
      await tester.pump();
    }

    expect(frame.isCompleted, isTrue);
    expect(find.byType(ShimmerBox), findsNothing);
    expect(find.byType(Image), findsOneWidget);

    stream.removeListener(listener);
    debugNetworkImageHttpClientProvider = null;
  });
}

final _onePixelPng = File("assets/typewriter-icon.png").readAsBytesSync();

final class _ControlledHttpClient implements HttpClient {
  _ControlledHttpClient(this.response);

  final Future<HttpClientResponse> response;

  @override
  Future<HttpClientRequest> getUrl(Uri url) async =>
      _ControlledHttpRequest(response);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _ControlledHttpRequest implements HttpClientRequest {
  _ControlledHttpRequest(this.response);

  final Future<HttpClientResponse> response;

  @override
  Future<HttpClientResponse> close() => response;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _ControlledImageResponse extends Stream<List<int>>
    implements HttpClientResponse {
  _ControlledImageResponse(this.bytes);

  final List<int> bytes;

  @override
  int get contentLength => bytes.length;

  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;

  @override
  int get statusCode => HttpStatus.ok;

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int>)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) => Stream<List<int>>.fromIterable([bytes]).listen(
    onData,
    onError: onError,
    onDone: onDone,
    cancelOnError: cancelOnError,
  );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

EditorProtocolRenderer _renderer() {
  final root = ResolvedTypeRef(
    id: const QualifiedTypeId(namespace: "test", name: "root"),
    revision: 1,
  );
  return EditorProtocolRenderer(
    envelope: TypedValueEnvelope(
      rootType: root,
      rootValue: const StringValue("value"),
    ),
    typeCatalog: TypeCatalog([
      TypeDefinition(
        id: root,
        kind: NominalTypeKind.concrete,
        representation: const StringType(),
      ),
    ]),
    presentation: PresentationNode(
      id: "image",
      element: ImageElement(
        source: "https://example.com/image.png".asStringLiteral,
      ),
    ),
  );
}
