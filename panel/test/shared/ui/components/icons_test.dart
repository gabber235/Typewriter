import "package:flutter_test/flutter_test.dart";
import "package:http/testing.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  test(
    "loads an icon from a backup after a response that is not SVG",
    () async {
      final requested = <Uri>[];
      final client = MockClient((request) async {
        requested.add(request.url);
        return request.url.host == "primary.example"
            ? Response("<html>unavailable</html>", 200)
            : Response(
                '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 16">
<path d="M0 0h32v16H0z"/></svg>
''',
                200,
                headers: {"content-type": "image/svg+xml"},
              );
      });

      final icon = await loadIconifySvg(
        "material-symbols:book",
        client: client,
        hosts: const ["primary.example", "backup.example"],
      );

      expect(requested, [
        Uri.https("primary.example", "material-symbols/book.svg"),
        Uri.https("backup.example", "material-symbols/book.svg"),
      ]);
      expect(icon.viewport, const Rect.fromLTWH(0, 0, 32, 16));
    },
  );

  testWidgets("uses a safe fallback when an Iconify response is unavailable", (
    tester,
  ) async {
    // The panel's image hosts answer every icon; this one is unreachable.
    await HttpOverrides.runZoned(
      () => tester.pumpPanel(
        const [],
        at: const PanelLocation.component(Icones("mdi:plus")),
      ),
      createHttpClient: (_) => throw const SocketException("unreachable"),
    );

    expect(find.byIcon(Icons.broken_image), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
