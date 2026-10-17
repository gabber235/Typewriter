/// Timeline editing for frame based page content.
///
/// The feature separates immutable timeline data from derived lane layout and
/// viewport placement. [Timeline] owns the interaction boundary: pointer and
/// keyboard gestures create previews in [TimelineController], then the caller
/// decides how committed frame changes become editor mutations. Scene editing
/// is one caller. Its adapter maps [TimelineCommitPayload] values back to cue
/// mutations, so this feature does not persist or optimistically rewrite the
/// source document.
library;

export "application/application.dart";
export "presentation/presentation.dart";
