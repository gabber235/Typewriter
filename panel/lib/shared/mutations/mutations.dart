/// Shared mutation state and controls for coordinating local drafts and submissions.
///
/// Application owners keep editable values and save lifecycle state here. The
/// presentation layer consumes the resulting read models and invokes commands
/// through the exported control surfaces.
library;

export "application/application.dart";
export "domain/domain.dart";
export "presentation/presentation.dart";
