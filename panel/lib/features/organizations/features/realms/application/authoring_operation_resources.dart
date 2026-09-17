part of "authoring_session.dart";

/// Returns every resource reservation required by an authoring operation.
///
/// The mutation coordinator uses these identities to prevent overlapping local
/// submissions. Related parent resources are included when the protocol
/// operation changes their projection, such as creating or moving a child.
/// Unknown protocol variants fail instead of creating an incomplete reservation.
Set<skir.RecordId> _operationResources(skir.AuthoringOperation operation) =>
    switch (operation) {
      skir.AuthoringOperation_createBookWrapper(:final value) => {
        value.book.id,
      },
      skir.AuthoringOperation_patchBookWrapper(:final value) => {value.id},
      skir.AuthoringOperation_deleteBookWrapper(:final value) => {value.id},
      skir.AuthoringOperation_createTagWrapper(:final value) => {value.tag.id},
      skir.AuthoringOperation_patchTagWrapper(:final value) => {value.id},
      skir.AuthoringOperation_deleteTagWrapper(:final value) => {value.id},
      skir.AuthoringOperation_createPageWrapper(:final value) => {
        value.page.id,
        value.page.book,
      },
      skir.AuthoringOperation_patchPageWrapper(:final value) => {value.id},
      skir.AuthoringOperation_deletePageWrapper(:final value) => {value.id},
      skir.AuthoringOperation_createElementWrapper(:final value) => {
        value.element.id,
        value.element.page,
      },
      skir.AuthoringOperation_patchElementWrapper(:final value) => {
        value.id,
        if (value.page != null) value.page!.value,
      },
      skir.AuthoringOperation_duplicateElementWrapper(:final value) => {
        value.sourceId,
        value.newId,
        value.page,
      },
      skir.AuthoringOperation_deleteElementWrapper(:final value) => {value.id},
      skir.AuthoringOperation_unknown() => throw ArgumentError(
        "Unknown authoring operation",
      ),
    };
