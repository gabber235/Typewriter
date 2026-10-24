part of "sidebar.dart";

/// Owns the sidebar width used by desktop layout and keyboard resizing.
///
/// The provider starts at [kSidebarDefaultSize]. Calls to [size] enforce the
/// global minimum; the controller applies the viewport specific maximum before
/// writing a value here.
@riverpod
class SidebarSize extends _$SidebarSize {
  @override
  double build() {
    return kSidebarDefaultSize;
  }

  /// Stores a width after enforcing the minimum sidebar size.
  void size(double size) {
    state = max(size, kSidebarMinSize);
  }
}
