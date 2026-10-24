import "package:typewriter_panel/typewriter_panel.dart";

enum GraphDragPhase { ready, dragging, claimed, retired }

/// Owns one offered gesture's hover and acceptance authority.
/// Retired observations remain safe to read and cannot acquire listeners.
final class GraphDragPayload<T extends GraphDragData> extends ChangeNotifier {
  GraphDragPayload({required this.value});

  final T value;
  GraphDragPhase _phase = GraphDragPhase.ready;
  bool _pending = false;
  bool _disposed = false;

  /// The last global pointer position of the drag, reported by its source.
  /// Drop targets read it instead of the avatar position, which follows the
  /// grab point.
  Offset? pointer;

  GraphDragPhase get phase => _phase;
  bool get canHover => _phase == GraphDragPhase.ready || isDragging;
  bool get isDragging => _phase == GraphDragPhase.dragging;

  bool start() {
    if (_phase != GraphDragPhase.ready) return false;
    _phase = GraphDragPhase.dragging;
    _publish();
    return true;
  }

  /// Transfers acceptance once to the target's operation continuation.
  /// Later pointer completion cannot revoke work already accepted here.
  bool claim() {
    if (!isDragging) return false;
    _phase = GraphDragPhase.claimed;
    _publish();
    return true;
  }

  void retire() => dispose();

  void _publish() {
    if (_pending || _disposed) return;
    _pending = true;
    // Coalesce active phase changes. Disposal publishes retirement itself.
    scheduleMicrotask(() {
      _pending = false;
      if (_disposed || _phase == GraphDragPhase.retired) return;
      notifyListeners();
    });
  }

  @override
  void addListener(VoidCallback listener) {
    if (_phase != GraphDragPhase.retired) super.addListener(listener);
  }

  /// Revokes authority immediately, then publishes retirement before cleanup.
  /// Existing avatars may still read this payload or remove their listeners.
  @override
  void dispose() {
    if (_phase == GraphDragPhase.retired) return;
    _phase = GraphDragPhase.retired;
    // The terminal callback owns both notification and notifier disposal.
    // It runs after source tree disposal and any active listener traversal.
    scheduleMicrotask(() {
      notifyListeners();
      _disposed = true;
      super.dispose();
    });
  }
}
