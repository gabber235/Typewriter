part of "authoring_session.dart";

mixin _AuthoringSessionSnapshots on _$AuthoringSession {
  RealmServiceAddress get _address;

  Future<skir.AuthoringSnapshot> _fetchSnapshot(
    List<_AuthoringScope> scopes,
  ) async {
    final request = skir.GetAuthoringSnapshotRequest(
      scopes: scopes.map((scope) => scope.wireValue),
    );
    final response = await ref.requestSkir(
      _address.request("library.authoring.snapshot.get"),
      skir.GetAuthoringSnapshotRequest.serializer.toBytes(request),
      skir.GetAuthoringSnapshotResponse.serializer,
    );
    return switch (response) {
      skir.GetAuthoringSnapshotResponse_successWrapper(:final value) => value,
      skir.GetAuthoringSnapshotResponse_invalidWrapper(:final value) =>
        throw value.toApiException(),
      skir.GetAuthoringSnapshotResponse_internalErrorWrapper() =>
        throw ApiException.internalServerError(),
      skir.GetAuthoringSnapshotResponse_unknown() =>
        throw ApiException.unknownResponseMessage(),
    };
  }

  void _applySnapshot(skir.AuthoringSnapshot snapshot) {
    var books = Map<skir.RecordId, skir.Book>.of(state.books);
    var tags = Map<skir.RecordId, skir.Tag>.of(state.tags);
    final pages = Map<skir.RecordId, skir.Page>.of(state.pages);
    final documents = Map<skir.RecordId, skir.PageDocument>.of(state.documents);
    for (final slice in snapshot.slices) {
      switch (slice) {
        case skir.AuthoringSnapshotSlice_libraryWrapper(:final value):
          books = {for (final book in value.books) book.id: book};
          tags = {for (final tag in value.tags) tag.id: tag};
        case skir.AuthoringSnapshotSlice_bookWrapper(:final value):
          pages
            ..removeWhere((_, page) => page.book == value.bookId)
            ..addAll({for (final page in value.pages) page.id: page});
          final book = value.book;
          if (book == null) {
            books.remove(value.bookId);
          } else {
            books[book.id] = book;
          }
        case skir.AuthoringSnapshotSlice_pageWrapper(:final value):
          final document = value.document;
          if (document == null) {
            documents.remove(value.pageId);
            pages.remove(value.pageId);
          } else {
            documents[value.pageId] = document;
            pages[document.page.id] = document.page;
          }
        case skir.AuthoringSnapshotSlice_unknown():
          throw ApiException.unknownResponseMessage();
      }
    }
    state = AuthoringSessionState(
      sequence: snapshot.sequence,
      books: Map.unmodifiable(books),
      tags: Map.unmodifiable(tags),
      pages: Map.unmodifiable(pages),
      documents: Map.unmodifiable(documents),
      refreshing: state.refreshing,
    );
  }
}
