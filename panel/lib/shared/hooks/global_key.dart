import "package:typewriter_panel/typewriter_panel.dart";

/// Creates a stable [GlobalKey] for the lifetime of this hook.
///
/// Use this when a widget state must be addressed across rebuilds. The key is
/// memoized without dependencies, so changing [debugLabel] does not replace
/// it while the hook remains in the same position.
///
/// See also [GlobalKey].
GlobalKey useGlobalKey({String? debugLabel}) {
  return useMemoized(() => GlobalKey(debugLabel: debugLabel), []);
}
