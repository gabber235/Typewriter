import "package:typewriter_panel/typewriter_panel.dart";

/// Creates a stable [MenuController] for the current widget instance.
///
/// The controller is memoized without dependencies, so it remains the same
/// across rebuilds and is replaced when this hook leaves the widget tree.
MenuController useMenuController() {
  return useMemoized<MenuController>(MenuController.new);
}
