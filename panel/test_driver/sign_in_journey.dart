import "package:flutter_driver/driver_extension.dart";
import "package:typewriter_panel/typewriter_panel.dart";

/// The real panel, with its own session store and the identity provider's
/// sign in pages, for the host driven sign in journey
/// (`test_driver/sign_in_journey_test.dart`). Scenarios cannot reach these
/// pages: the web sign in leaves the page a scenario runs in.
Future<void> main() async {
  enableFlutterDriverExtension();
  await bootstrap();
}
