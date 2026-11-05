import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";

/// The system clipboard as a test observes it.
extension RecordClipboard on WidgetTester {
  /// Records the text of every clipboard write until the test ends, in
  /// order.
  List<String> recordClipboard() {
    final writes = <String>[];
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == "Clipboard.setData") {
          writes.add((call.arguments as Map)["text"] as String);
        }
        return null;
      },
    );
    addTearDown(
      () => binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    return writes;
  }

  /// Makes every clipboard write fail until the test ends, as a browser does
  /// when it refuses the page access to the clipboard.
  void refuseClipboard() {
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == "Clipboard.setData") {
          throw PlatformException(code: "copy_fail");
        }
        return null;
      },
    );
    addTearDown(
      () => binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
  }
}
