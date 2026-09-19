import "package:typewriter_panel/typewriter_panel.dart";

/// Display state for one stored reference, including retained missing targets.
final class ReferenceResourceSummary {
  const ReferenceResourceSummary({
    required this.id,
    required this.exists,
    this.title,
    this.subtitle,
  });

  final RecordId id;
  final bool exists;
  final String? title;
  final String? subtitle;
}

/// Builds a scoped authoring source for one reference target type.
typedef ReferenceSearchSourceBuilder = SearchSource Function({
  required ResolvedTypeRef target,
  required List<RecordId> origins,
  required TypeRegistry registry,
});

/// Resolves stored identifiers without discarding missing targets.
typedef ReferenceResourceResolver =
    Future<List<ReferenceResourceSummary>> Function({
      required ResolvedTypeRef target,
      required List<RecordId> ids,
      required TypeRegistry registry,
    });

/// Shared payload contract for resource nodes dropped onto reference controls.
abstract interface class ReferenceResourceDragData {
  RecordId get referenceId;
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

extension ReferenceResourceDragCompatibility on ReferenceResourceDragData {
  bool isAcceptedBy(ResolvedTypeRef target, TypeRegistry registry) {
    final family = registry.referenceFamily(target).valueOrNull;
    if (family == null || referenceId.table != family.table) return false;
    if (referenceTypes.isEmpty) return true;
    return referenceTypes.any(
      (type) =>
          NamedType(type)
              .isStructurallyAssignableTo(NamedType(target), registry),
    );
  }
}
