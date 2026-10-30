import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";

/// The browser links open in.
///
/// Answers the URL launcher plugin the way a browser that opens every URL
/// does, and remembers what was opened. The test binding otherwise has no
/// launcher, so a link would fail to open.
final class FakeBrowser {
  FakeBrowser._();

  static const _channel = MethodChannel("plugins.flutter.io/url_launcher");

  final _opened = <String>[];

  /// The URLs opened so far, in order.
  List<String> get opened => List.unmodifiable(_opened);

  /// Opens links in a fake browser for the rest of the current test.
  static FakeBrowser install(WidgetTester tester) {
    final browser = FakeBrowser._();
    final messenger = tester.binding.defaultBinaryMessenger
      ..setMockMethodCallHandler(_channel, (call) async {
        final url = (call.arguments as Map?)?["url"] as String?;
        if (call.method == "launch" && url != null) browser._opened.add(url);
        return true;
      });
    addTearDown(() => messenger.setMockMethodCallHandler(_channel, null));
    return browser;
  }
}
