import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;

/// Shared payload contract for resource nodes dropped onto reference controls.
abstract interface class ReferenceResourceDragData {
  skir.ResourceId get referenceId;
  List<skir.TypeDefinitionId> get referenceTypes;
}

/// Carries multiple reference resources through one drag interaction.
abstract interface class ReferenceResourceDragGroupData {
  List<ReferenceResourceDragData> get referenceResources;
}

extension ReferenceResourceDragPayload on Object {
  List<ReferenceResourceDragData> get referenceResources => switch (this) {
    ReferenceResourceDragGroupData(:final referenceResources) =>
      referenceResources,
    ReferenceResourceDragData() => [this as ReferenceResourceDragData],
    _ => const [],
  };
}
