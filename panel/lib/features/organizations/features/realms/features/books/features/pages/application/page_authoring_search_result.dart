import "package:typewriter_panel/typewriter_panel.dart";

/// Interprets Page content only for the Page visual search adapter.
extension PageAuthoringSearchResult on AuthoringSearchResultPayload {
  ResolvedTypeRef? get pageType {
    if (definition != CoreResourceDefinitionIds.page) return null;
    return subject.content.rootType;
  }
}
