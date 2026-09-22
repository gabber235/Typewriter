/// Application services for page metadata, projections, editing, and creation.
///
/// This layer keeps the authoring session as the canonical source, then adapts
/// it for callers that need local editor drafts, conditional mutations, or the
/// catalog types allowed by a page kind.
library;

export "page_commands.dart";
export "page_creation_slots.dart";
export "page_editing.dart";
export "pages.dart";
