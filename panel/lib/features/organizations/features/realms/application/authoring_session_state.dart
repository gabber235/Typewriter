part of "authoring_session.dart";

/// A presentation value paired with the canonical authoring sequence used to
/// produce it.
///
/// Use the revision when creating an editor snapshot or comparing a local
/// draft with canonical state. It is not a local draft version.
@freezed
abstract class AuthoringValue<T> with _$AuthoringValue<T> {
  const factory AuthoringValue({required T value, required int revision}) =
      _AuthoringValue<T>;
}

/// Immutable canonical read model maintained by [AuthoringSession].
///
/// [sequence] is the server revision shared by every collection in this
/// model. Null means no authoritative snapshot has completed. Collections can
/// be partial because the session retains only the scopes currently leased.
/// [documents] includes the page metadata needed to keep a page and its
/// document consistent when an event changes either one. Local drafts live in
/// the separate local work state and are projected by editors.
@freezed
abstract class AuthoringSessionState with _$AuthoringSessionState {
  const factory AuthoringSessionState({
    /// The server sequence represented by all canonical collections.
    int? sequence,

    /// Canonical books retained by active scopes.
    @Default({}) Map<skir.RecordId, skir.Book> books,

    /// Canonical tags retained by the library scope.
    @Default({}) Map<skir.RecordId, skir.Tag> tags,

    /// Canonical page metadata retained by active book or page scopes.
    @Default({}) Map<skir.RecordId, skir.Page> pages,

    /// Canonical page documents retained by active page scopes.
    @Default({}) Map<skir.RecordId, skir.PageDocument> documents,

    /// Whether an authoritative refresh is currently reconciling the model.
    @Default(false) bool refreshing,
  }) = _AuthoringSessionState;
}

@freezed
sealed class _AuthoringScope with _$AuthoringScope {
  const _AuthoringScope._();

  const factory _AuthoringScope.library() = _LibraryScope;
  const factory _AuthoringScope.book(skir.RecordId bookId) = _BookScope;
  const factory _AuthoringScope.page(skir.RecordId pageId) = _PageScope;

  skir.AuthoringSnapshotScope get wireValue => switch (this) {
    _LibraryScope() => skir.AuthoringSnapshotScope.library_,
    _BookScope(:final bookId) => skir.AuthoringSnapshotScope.createBook(
      bookId: bookId,
    ),
    _PageScope(:final pageId) => skir.AuthoringSnapshotScope.createPage(
      pageId: pageId,
    ),
  };
}

/// Retains one authoring snapshot scope for the lifetime of a consumer.
///
/// A lease is reference counted by the owning [AuthoringSession]. It controls
/// both data retention and the provider lifetime, so every acquired lease must
/// be released when its consumer is disposed.
abstract interface class AuthoringScopeLease {
  /// Completes after subscriptions are active and the scope has its snapshot.
  Future<void> get ready;

  /// Releases this lease. Repeated release calls have no effect.
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
