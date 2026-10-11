import "package:typewriter_panel/typewriter_panel.dart";

/// Enables direct scrolling with the pointer devices supported by the panel.
///
/// This extends Material's platform defaults so desktop web users can drag
/// scrollable content with a mouse while touch and stylus input remain valid.
class GlobalCustomScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.stylus,
  };
}
