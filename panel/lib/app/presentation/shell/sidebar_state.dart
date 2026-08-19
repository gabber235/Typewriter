part of "sidebar.dart";

@riverpod
class SidebarSize extends _$SidebarSize {
  @override
  double build() {
    return kSidebarDefaultSize;
  }

  void size(double size) {
    state = max(size, kSidebarMinSize);
  }
}
