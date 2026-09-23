/// Application services for page metadata, projections, editing, and creation.
///
/// This layer keeps the authoring session as the canonical source, then adapts
/// it for callers that need local editor drafts, conditional mutations, or the
/// catalog types allowed by a concrete page.
library;

export "page_authoring_search_result.dart";
export "page_authoring_selections.dart";
export "page_commands.dart";
export "page_editing.dart";
export "page_relation_fields.dart";
export "pages.dart";
