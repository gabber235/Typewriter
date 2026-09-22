import "package:typewriter_panel/typewriter_panel.dart";

/// Interprets Page content only for the Page visual search adapter.
extension PageAuthoringSearchResult on AuthoringSearchResultPayload {
  PageKindRef? get pageKind {
    if (definition != CoreResourceDefinitionIds.page) return null;
    final value = subject.content.rootValue;
    if (value is! RecordValue) return null;
    final kind = value.fields["kind"];
    if (kind is! RecordValue) return null;
    final id = kind.fields["id"];
    final revision = kind.fields["revision"];
    return id is StringValue && revision is IntegerValue
        ? PageKindRef(id: id.value, revision: revision.value.toInt())
        : null;
  }
}
