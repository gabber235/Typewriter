import "dart:io";

import "package:integration_test/integration_test_driver_extended.dart";

import "support/evidence.dart";

/// The host side of `flutter drive`. It runs outside the macOS sandbox and
/// outside the browser, so it is what writes the evidence folder: the
/// scenarios' captures, then the `TestRun` that lists them.
///
/// `cargo xtask e2e` sets `EVIDENCE_DIR`.
Future<void> main() {
  final evidence = EvidenceFolder(
    Directory(Platform.environment["EVIDENCE_DIR"] ?? "build/evidence/panel"),
  );
  return integrationDriver(
    responseDataCallback: evidence.writeReported,
    // Failed scenarios are results too.
    writeResponseOnFailure: true,
    // Web screenshots taken through the binding arrive here (flutter#118470),
    // before the run is written.
    onScreenshot: (name, bytes, [args]) async {
      await evidence.write("screenshots/$name.png", bytes);
      return true;
    },
  );
}
