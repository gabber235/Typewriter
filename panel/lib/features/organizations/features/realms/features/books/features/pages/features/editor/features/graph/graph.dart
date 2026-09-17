/// Graph placement view for page entries.
///
/// The page editor supplies a projected page element snapshot, including local
/// drafts layered over canonical authoring data. This feature translates entry
/// placements and outward links into the shared graph contract. The shared
/// graph owns transient selection, viewport, drag, and resize state. Page
/// element commands remain the authority for committing placement changes, so
/// this feature does not persist graph state itself.
library;

export "presentation/presentation.dart";
