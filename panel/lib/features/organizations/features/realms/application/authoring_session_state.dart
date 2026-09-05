part of "authoring_session.dart";

@freezed
abstract class AuthoringSessionState with _$AuthoringSessionState {
  const factory AuthoringSessionState({
    int? sequence,
    @Default({}) Map<skir.RecordId, wire.Book> books,
    @Default({}) Map<skir.RecordId, wire.Tag> tags,
    @Default({}) Map<skir.RecordId, wire.Page> pages,
    @Default({}) Map<skir.RecordId, wire.PageDocument> documents,
    @Default(false) bool refreshing,
  }) = _AuthoringSessionState;
}

@freezed
sealed class _AuthoringScope with _$AuthoringScope {
  const _AuthoringScope._();

  const factory _AuthoringScope.library() = _LibraryScope;
  const factory _AuthoringScope.book(skir.RecordId bookId) = _BookScope;
  const factory _AuthoringScope.page(skir.RecordId pageId) = _PageScope;

  wire.AuthoringSnapshotScope get wireValue => switch (this) {
    _LibraryScope() => wire.AuthoringSnapshotScope.library_,
    _BookScope(:final bookId) => wire.AuthoringSnapshotScope.createBook(
      bookId: bookId,
    ),
    _PageScope(:final pageId) => wire.AuthoringSnapshotScope.createPage(
      pageId: pageId,
    ),
  };
}

abstract interface class AuthoringScopeLease {
  Future<void> get ready;

  void release();
}

final class _AuthoringScopeLease implements AuthoringScopeLease {
  _AuthoringScopeLease(this.ready, this._release);

  @override
  final Future<void> ready;

  final void Function() _release;
  var _released = false;

  @override
  void release() {
    if (_released) return;
    _released = true;
    _release();
  }
}
