import "package:flutter/widgets.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/typewriter_panel.dart";

typedef _RenderedBindingKey = ({Object identity, DataPath path});

final renderedBindingFocusControllerProvider =
    Provider<RenderedBindingFocusController>(
      (ref) => RenderedBindingFocusController(),
    );

/// Focuses an exact resource field only while a matching bound control exists.
///
/// Renderers register controls after binding resolution succeeds. Duplicate
/// presentations of the same field form a stack, with the most recently
/// registered visible control receiving focus. Registrations own their removal.
final class RenderedBindingFocusController {
  final Map<_RenderedBindingKey, List<FocusNode>> _nodes = {};
  _RenderedBindingKey? _pending;

  VoidCallback? register({
    required EditOwner owner,
    required BindingReference reference,
    required FocusNode node,
  }) {
    final target = _target(owner, reference.path);
    if (target == null) return null;
    final nodes = _nodes.putIfAbsent(target, () => [])..add(node);
    if (_pending == target) {
      if (_focus(target)) {
        _pending = null;
      } else {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_pending == target && _focus(target)) _pending = null;
        });
      }
    }
    var registered = true;
    return () {
      if (!registered) return;
      registered = false;
      nodes.remove(node);
      if (nodes.isEmpty) _nodes.remove(target);
    };
  }

  bool focus(Object identity, DataPath path) =>
      _focus((identity: identity, path: path));

  void requestFocus(Object identity, DataPath path) {
    final target = (identity: identity, path: path);
    _pending = target;
    if (_focus(target)) _pending = null;
  }

  void cancelPendingFocus() {
    _pending = null;
  }

  bool _focus(_RenderedBindingKey target) {
    final nodes = _nodes[target];
    if (nodes == null) return false;
    for (final node in nodes.reversed) {
      if (!node.canRequestFocus || node.context == null) continue;
      node.requestFocus();
      return true;
    }
    return false;
  }
}

_RenderedBindingKey? _target(EditOwner owner, DataPath path) {
  var currentOwner = owner;
  var currentPath = path;
  while (currentOwner is ProjectedEditOwner) {
    currentPath = currentOwner.path.followedBy(currentPath);
    currentOwner = currentOwner.owner;
  }
  if (currentOwner case TransactionalEditorSource(:final resource?)) {
    return (identity: resource.key.identity, path: currentPath);
  }
  return null;
}
