import "dart:convert";
import "dart:io";

import "package:integration_test/integration_test_driver_extended.dart";

/// The host side of `flutter drive`. It runs outside the macOS sandbox and
/// outside the browser, so it is what writes the evidence folder: the
/// scenarios' `TestRun` and their screenshots.
///
/// `cargo xtask e2e` sets `EVIDENCE_DIR`.
Future<void> main() {
  final evidence = Directory(
    Platform.environment["EVIDENCE_DIR"] ?? "build/evidence/panel",
  );
  return integrationDriver(
    responseDataCallback: (data) async {
      await evidence.create(recursive: true);
      await File("${evidence.path}/test_run.json")
          .writeAsString(jsonEncode(data?["testRun"]));
      final captures =
          (data?["captures"] as Map?)?.cast<String, String>() ?? {};
      for (final MapEntry(:key, :value) in captures.entries) {
        final file = File("${evidence.path}/$key");
        await file.parent.create(recursive: true);
        await file.writeAsBytes(base64Decode(value));
      }
    },
    // Failed scenarios are results too.
    writeResponseOnFailure: true,
    // Web screenshots taken through the binding arrive here (flutter#118470).
    onScreenshot: (name, bytes, [args]) async {
      final file = File("${evidence.path}/screenshots/$name.png");
      await file.parent.create(recursive: true);
      await file.writeAsBytes(bytes);
      return true;
    },
  );
}
