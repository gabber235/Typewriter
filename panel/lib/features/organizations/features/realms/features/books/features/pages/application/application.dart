/// Application services for page metadata, projections, editing, and element type policy.
///
/// This layer keeps the authoring session as the canonical source, then adapts
/// it for callers that need local editor drafts, conditional mutations, or the
/// catalog types allowed by a page kind.
library;

export "page_commands.dart";
export "page_editing.dart";
export "page_element_type_policy.dart";
export "pages.dart";
