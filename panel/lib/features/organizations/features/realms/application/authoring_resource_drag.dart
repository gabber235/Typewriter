import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

part "authoring_resource_drag.freezed.dart";

/// Captures owned resources and their expected memberships for one gesture.
@freezed
abstract class AuthoringResourceDragGroup
    with _$AuthoringResourceDragGroup
    implements GraphDragData, ReferenceResourceDragGroupData {
  const factory AuthoringResourceDragGroup({
    required AuthoringResourceIdentifier primary,
    required Map<AuthoringResourceIdentifier, skir.LinkOccurrence> memberships,
    bool Function()? sourceCanMutate,
  }) = _AuthoringResourceDragGroup;

  const AuthoringResourceDragGroup._();

  /// Includes the page selection only when the gesture starts on a selected
  /// node. Resources outside this page or authoring scope cannot join it.
  static AuthoringResourceDragGroup forSelection({
    required AuthoringResourceIdentifier primary,
    required List<PortablePageEntryProjection> entries,
    required Iterable<SelectableIdentifier> selection,
    bool Function()? sourceCanMutate,
  }) {
    final selected = selection.toSet();
    final includeSelection = selected.contains(primary);
    return AuthoringResourceDragGroup(
      primary: primary,
      sourceCanMutate: sourceCanMutate,
      memberships: {
        for (final entry in entries)
          if (entry.resource == primary.resourceId ||
              (includeSelection &&
                  selected.contains(
                    AuthoringResourceIdentifier.inScope(
                      primary.scope,
                      entry.resource,
                    ),
                  )))
            AuthoringResourceIdentifier.inScope(primary.scope, entry.resource):
                entry.occurrence,
      },
    );
  }

  @override
  GraphIdentifier get graphId => primary.graphId;

  @override
  List<ReferenceResourceDragData> get referenceResources =>
      memberships.keys.toList(growable: false);
}
