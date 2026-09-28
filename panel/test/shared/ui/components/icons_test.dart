import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:http/http.dart" as http;
import "package:http/testing.dart";
import "package:jovial_svg/jovial_svg.dart";
import "package:typewriter_panel/shared/ui/components/icons.dart";
import "package:typewriter_panel/typewriter_panel.dart";

import "../../../support/test_utils.dart";

void main() {
  test("parses the SVG returned for an Iconify book icon", () {
    const svg =
        '<svg xmlns="http://www.w3.org/2000/svg" width="1em" height="1em" '
        'viewBox="0 0 24 24"><path fill="currentColor" '
        'd="M6 22q-.825 0-1.412-.587T4 20V4q0-.825.588-1.412T6 2h12q.825 0 1.413.588T20 4v16q0 .825-.587 1.413T18 22zm5-11l2.5-1.5L16 11V4h-5z"/></svg>';

    expect(() => ScalableImage.fromSvgString(svg), returnsNormally);
  });

  test(
    "loads an icon from a backup after a response that is not SVG",
    () async {
      final requested = <Uri>[];
      final client = MockClient((request) async {
        requested.add(request.url);
        return request.url.host == "primary.example"
            ? http.Response("<html>unavailable</html>", 200)
            : http.Response(
                '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">
<path d="M0 0h24v24H0z"/></svg>
''',
                200,
                headers: {"content-type": "image/svg+xml"},
              );
      });

      await loadIconifySvg(
        "material-symbols:book",
        client: client,
        hosts: const ["primary.example", "backup.example"],
      );

      expect(requested, [
        Uri.https("primary.example", "material-symbols/book.svg"),
        Uri.https("backup.example", "material-symbols/book.svg"),
      ]);
    },
  );

  testWidgets("uses a safe fallback when an Iconify response is unavailable", (
    tester,
  ) async {
    await tester.pumpTestApp(child: const Icones("mdi:plus"));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.broken_image), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
