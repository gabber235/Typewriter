import "package:typewriter_panel/typewriter_panel.dart";

part "dialog_shortcuts.g.dart";

/// Shortcuts that dialogs shown through [showAdvancedDialog] offer beside the
/// current mode's shortcuts.
///
/// Capabilities above the dialog layer, such as clearing the selection,
/// contribute them through appOverrides. Containers built without
/// appOverrides offer none.
@riverpod
List<ActionShortcut> dialogShortcuts(Ref ref) => const [];
