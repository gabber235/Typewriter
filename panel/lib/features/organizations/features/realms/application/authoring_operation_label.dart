part of "authoring_session.dart";

String _authoringLabel(Iterable<skir.AuthoringOperation> operations) {
  final labels = operations
      .map(
        (operation) => switch (operation) {
          skir.AuthoringOperation_createWrapper() => "Create resource",
          skir.AuthoringOperation_commitWrapper() => "Edit resource",
          skir.AuthoringOperation_deleteWrapper() => "Delete resource",
          skir.AuthoringOperation_declareRelationWrapper() => "Attach resource",
          skir.AuthoringOperation_removeRelationWrapper() => "Detach resource",
          skir.AuthoringOperation_unknown() => "Save content",
        },
      )
      .toList();
  final distinct = labels.toSet();
  return distinct.length == 1
      ? "${distinct.single}${labels.length > 1 ? " (${labels.length})" : ""}"
      : "Save content batch (${labels.length})";
}
