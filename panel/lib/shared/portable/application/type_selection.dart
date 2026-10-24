import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;

/// The type a selection chooses, whether its arguments are complete or still
/// pending, mirroring `TypeSelection.definition` in the Kotlin contracts.
extension TypeSelectionDefinition on skir.TypeSelection {
  /// Null only for a selection variant this panel does not know.
  skir.TypeDefinitionId? get definition => switch (this) {
    skir.TypeSelection_completeWrapper(:final value) => value.definition,
    skir.TypeSelection_pendingWrapper(:final value) => value.definition,
    _ => null,
  };
}
