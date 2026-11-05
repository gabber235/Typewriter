import "package:typewriter_panel/typewriter_panel.dart";

/// An update policy that applies every new value at once, through the
/// [controller] it created last.
final class ImmediateUpdatePolicy implements ValueUpdatePolicy<int> {
  late ImmediateUpdateController controller;
  @override
  ValueUpdateController<int> create(int initialValue) =>
      controller = ImmediateUpdateController(initialValue);
}

/// An update controller that shows each new value it observes at once and
/// records whether it was disposed.
final class ImmediateUpdateController extends ValueNotifier<int>
    implements ValueUpdateController<int> {
  ImmediateUpdateController(super.value) : latest = value;
  int latest;
  bool disposed = false;
  @override
  void observe(int next) {
    if (next == latest) return;
    latest = next;
    value = next;
  }

  @override
  void dispose() {
    disposed = true;
    super.dispose();
  }
}
