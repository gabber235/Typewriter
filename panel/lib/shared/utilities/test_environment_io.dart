import "package:typewriter_panel/typewriter_panel.dart";

/// Whether the Flutter test runner marked this process as a test process.
bool get isFlutterTest => Platform.environment["FLUTTER_TEST"] == "true";
