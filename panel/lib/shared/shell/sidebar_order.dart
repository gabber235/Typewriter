import "package:typewriter_panel/typewriter_panel.dart";

/// Sidebar links in screen order, so a move between sibling pages comes
/// from above or below.
final sidebarOrderProvider = Provider<SidebarOrder>((ref) => SidebarOrder());

/// Where each sidebar link sits: route name to the link's top edge. Page
/// moves read it when a page changes, so it notifies no one, and links may
/// update it while the tree builds or tears down.
final class SidebarOrder {
  final Map<String, double> _tops = {};

  Map<String, double> get tops => Map.unmodifiable(_tops);

  void place(String routeName, double top) => _tops[routeName] = top;

  void remove(String routeName) => _tops.remove(routeName);
}
