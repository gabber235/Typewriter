import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

/// Shared payload contract for resource nodes dropped onto reference controls.
abstract interface class ReferenceResourceDragData {
  skir.ResourceId get referenceId;
  List<ResolvedTypeRef> get referenceTypes;
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
