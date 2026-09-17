/// Shared identity, selection state, operation registry, and selectable UI.
///
/// Selection stores identifiers as canonical state. Resolved selectable objects,
/// operation availability, and focus presentation are derived at their owning
/// boundaries so selection and focus remain distinct.
library;

export "application/application.dart";
export "domain/domain.dart";
export "operations/operations.dart";
export "presentation/presentation.dart";
