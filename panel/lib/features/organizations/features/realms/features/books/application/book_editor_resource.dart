part of "books.dart";

/// Confirmed editor state for one book at an authoring session revision.
///
/// The document exposes the inspector representation, not the wire model.
/// Tag edits use set merge semantics because the complete ordered tag list is
/// the value being conditionally replaced.
final class BookEditorSnapshot extends EditorSnapshot {
  const BookEditorSnapshot(this.book, this.revision);
  final Book book;
  final int revision;
  @override
  EditorDocument get document => EditorDocument(
    rootType: NamedType(bookInspectorTypeRef),
    typeCatalog: _bookInspectorCatalog,
    confirmedValue: book.inspectorValue,
    revision: revision,
    mergePolicies: {DataPath.root.field("tags"): EditorMergePolicy.set},
  );
}

/// Adapts one library book to the shared transactional editor lifecycle.
///
/// It reads books from library snapshot slices, accepts only book upserts or
/// removal for its identity from applied changes, and maps editor commits to a
/// conditional [bookPatchOperation]. Unrelated resource changes are ignored.
/// A removal ends the resource by returning no snapshot.
final class BookEditorResource extends AuthoringEditorResource {
  const BookEditorResource(super.repository, super.id);
  @override
  skir.AuthoringSnapshotScope get scope => skir.AuthoringSnapshotScope.library_;

  /// Projects the matching book from a library scoped snapshot.
  @override
  EditorSnapshot? project(skir.AuthoringSnapshot snapshot) {
    for (final slice in snapshot.slices) {
      if (slice case skir.AuthoringSnapshotSlice_libraryWrapper(:final value)) {
        for (final book in value.books) {
          if (book.id == id) {
            return BookEditorSnapshot(Book.fromWire(book), snapshot.sequence);
          }
        }
      }
    }
    return null;
  }

  /// Reconciles an applied batch with this resource's identity and revision.
  @override
  EditorSnapshot? projectApplied(
    skir.AuthoringChanged change,
    EditorSnapshot submitted,
  ) {
    for (final resource in change.changes) {
      switch (resource) {
        case skir.AuthoringResourceChange_upsertBookWrapper(:final value):
          if (value.id == id) {
            return BookEditorSnapshot(Book.fromWire(value), change.sequence);
          }
        case skir.AuthoringResourceChange_removeBookWrapper(:final value):
          if (value == id) return null;
        case skir.AuthoringResourceChange_unknown() ||
            skir.AuthoringResourceChange_upsertTagWrapper() ||
            skir.AuthoringResourceChange_removeTagWrapper() ||
            skir.AuthoringResourceChange_upsertPageWrapper() ||
            skir.AuthoringResourceChange_removePageWrapper() ||
            skir.AuthoringResourceChange_upsertElementWrapper() ||
            skir.AuthoringResourceChange_removeElementWrapper():
      }
    }
    return null;
  }

  /// Converts the editor commit into a conditional book patch.
  @override
  skir.AuthoringOperation operation(
    EditorSnapshot snapshot,
    EditorCommit commit,
  ) {
    final current = snapshot as BookEditorSnapshot;
    final next = current.book.withInspectorValue(commit.rootValue);
    final expected = current.book.withInspectorValue(commit.baseValue);
    if (next == null || expected == null) {
      throw StateError("The Book value is invalid");
    }
    return bookPatchOperation(next, expected: expected);
  }
}
