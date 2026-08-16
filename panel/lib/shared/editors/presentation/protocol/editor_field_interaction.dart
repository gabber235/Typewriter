import "dart:async";

import "package:flutter_hooks/flutter_hooks.dart";
import "package:typewriter_panel/typewriter_panel.dart";

/// The editing session of a single input field.
///
/// Begins on focus and always ends in a commit: on blur, on dismiss, and on
/// unmount. Only [cancel] discards the typed value, and it must come from an
/// intentional user action such as [CancelIntent].
final class EditorFieldInteraction {
  EditorInteractionSession? _session;
  EditorInteractionSession? Function()? _start;

  bool get active => _session != null;

  void begin() => _session ??= _start?.call();

  void commit() {
    final active = _session;
    _session = null;
    if (active != null) unawaited(active.commit());
  }

  void cancel() {
    final active = _session;
    _session = null;
    active?.cancel();
  }
}

EditorFieldInteraction useEditorFieldInteraction(
  PresentationRenderScope scope,
  BindingReference reference,
) {
  final interaction = useMemoized(EditorFieldInteraction.new)
    .._start = () => scope.beginInteraction(reference);
  useEffect(() => interaction.commit, [reference]);
  return interaction;
}
