import "package:typewriter_panel/typewriter_panel.dart";

part "interaction_suspension.g.dart";

/// Whether mode shortcuts and selection operations are blocked app wide, for
/// example while the realm connection is being checked.
///
/// The app overrides it through appOverrides, which bootstrap, the test kit's
/// worlds and the end to end scenarios install. The unblocked default applies
/// only to containers built without appOverrides.
@riverpod
bool interactionSuspended(Ref ref) => false;
