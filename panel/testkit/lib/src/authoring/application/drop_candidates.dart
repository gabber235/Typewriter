import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

/// The drop candidates the Realm resolved for dragging [subjects] in
/// [scope]: each operation of [destinations] lands them on its listed
/// resources, and no other operation accepts the drag.
DropCandidateIndex dropCandidateIndex(
  AuthoringScope scope,
  List<skir.ResourceId> subjects, {
  Map<skir.ResourceOperationId, List<skir.ResourceId>> destinations = const {},
}) => DropCandidateIndex(
  drag: ResourceDrag(
    scope: scope,
    primary: AuthoringResourceIdentifier.inScope(scope, subjects.first),
    subjects: subjects,
  ),
  byOperation: {
    for (final MapEntry(key: operation, value: resources)
        in destinations.entries)
      operation: skir.DropCandidates(
        operation: operation,
        destinations: resources,
        complete: true,
      ),
  },
);
