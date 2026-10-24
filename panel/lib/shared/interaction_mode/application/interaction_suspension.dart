import "package:typewriter_panel/typewriter_panel.dart";

part "interaction_suspension.g.dart";

/// Whether mode shortcuts and selection operations are blocked app wide, for
/// example while the realm connection is being checked.
///
/// The app overrides it through appOverrides, which bootstrap, testApp and
/// FakeApp install. The unblocked default applies only to containers built
/// without appOverrides.
@riverpod
bool interactionSuspended(Ref ref) => false;
