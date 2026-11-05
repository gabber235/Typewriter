import "dart:js_interop";

import "package:flutter_driver/driver_extension.dart";
import "package:typewriter_panel/typewriter_panel.dart";

/// Set once the panel drew its first frame, for `Journey.panelReady`. The driver
/// extension exists from the start of [main], but most of its commands fail
/// until the app's root widget is attached.
@JS("panelRunning")
external set _panelRunning(bool running);

/// The real panel, with its own session store and the identity provider's
/// sign in pages, for the host driven sign in journey
/// (`test_driver/sign_in_journey_test.dart`). Scenarios cannot reach these
/// pages: the web sign in leaves the page a scenario runs in.
Future<void> main() async {
  enableFlutterDriverExtension();
  await bootstrap();
  await WidgetsBinding.instance.endOfFrame;
  _panelRunning = true;
}
