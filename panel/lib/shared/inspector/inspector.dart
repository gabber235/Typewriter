/// Inspection combines the current selectable selection with local editor state.
///
/// Selection is the authoritative set of resources shown here. Focus remains a
/// presentation concern owned by each selectable surface, so focusing an item
/// does not inspect it and inspecting an item does not move focus. The
/// application builds one presentation graph for the selection, retaining
/// resource editor owners across refreshes so drafts survive provider
/// invalidation. The inspector owns only that graph's temporary composite
/// editors and releases them when the graph is replaced or disposed.
library;

export "application/application.dart";
export "presentation/presentation.dart";
