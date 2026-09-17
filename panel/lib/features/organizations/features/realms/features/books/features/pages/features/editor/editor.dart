/// The page editor feature combines authoring state, typed element projections,
/// selection operations, and the widgets that render graph and timeline pages.
///
/// Canonical page documents come from the realm authoring session. The
/// application layer decodes them through the realm editor catalog, overlays
/// local drafts for responsive editing, and submits mutations through the
/// authoring session. Presentation code renders the resulting projection and
/// exposes operations that preserve the page and element ownership rules.
library;

export "application/application.dart";
export "domain/domain.dart";
export "features/features.dart";
export "operations/operations.dart";
export "presentation/presentation.dart";
