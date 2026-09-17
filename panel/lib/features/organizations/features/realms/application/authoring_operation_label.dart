part of "authoring_session.dart";

/// Produces the user facing mutation label for one authoring batch.
///
/// Uniform batches retain the specific intent, including their count. Mixed
/// batches use a generic label because no single operation describes the whole
/// transaction. The label is presentation metadata and does not affect routing
/// or protocol identity.
String _authoringLabel(Iterable<skir.AuthoringOperation> operations) {
  final labels = operations
      .map(
        (operation) => switch (operation) {
          skir.AuthoringOperation_createBookWrapper() => "Create book",
          skir.AuthoringOperation_patchBookWrapper() => "Edit book",
          skir.AuthoringOperation_deleteBookWrapper() => "Delete book",
          skir.AuthoringOperation_createTagWrapper() => "Create tag",
          skir.AuthoringOperation_patchTagWrapper() => "Edit tag",
          skir.AuthoringOperation_deleteTagWrapper() => "Delete tag",
          skir.AuthoringOperation_createPageWrapper() => "Create page",
          skir.AuthoringOperation_patchPageWrapper(:final value) =>
            value.name != null
                ? "Rename page"
                : value.chapter != null
                ? "Move page chapter"
                : "Change page priority",
          skir.AuthoringOperation_deletePageWrapper() => "Delete page",
          skir.AuthoringOperation_createElementWrapper() => "Create element",
          skir.AuthoringOperation_patchElementWrapper(:final value) =>
            value.page != null
                ? "Move element to page"
                : value.placement != null
                ? "Change element placement"
                : "Edit element",
          skir.AuthoringOperation_duplicateElementWrapper() =>
            "Duplicate element",
          skir.AuthoringOperation_deleteElementWrapper() => "Delete element",
          skir.AuthoringOperation_unknown() => "Save content",
        },
      )
      .toList();
  final distinct = labels.toSet();
  return distinct.length == 1
      ? "${distinct.single}${labels.length > 1 ? " (${labels.length})" : ""}"
      : "Save content batch (${labels.length})";
}
