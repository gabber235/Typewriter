import "package:collection/collection.dart";
import "package:flutter/material.dart";
import "package:freezed_annotation/freezed_annotation.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/library/v1/authoring.dart"
    as wire;
import "package:typewriter_panel/typewriter_panel.dart";

part "book_model.dart";
part "book_queries.dart";
part "book_selection.dart";
part "books.freezed.dart";
part "books.g.dart";

@riverpod
class Books extends _$Books {
  @override
  Future<List<Book>> build() async {
    final organizationId = ref.watch(organizationIdProvider);
    final realmId = ref.watch(realmIdProvider);
    if (organizationId == null || realmId == null) {
      return [];
    }
    final provider = authoringSessionProvider(organizationId, realmId);
    ref.listen(provider, (_, value) {
      if (value.sequence != null) state = AsyncData(_projectBooks(value));
    });
    final lease = ref.watch(
      authoringLibraryScopeProvider(organizationId, realmId),
    );
    await lease.ready;
    return _projectBooks(ref.read(provider));
  }

  Future<Book> createBook({
    required String title,
    String? icon,
    Color? color,
    List<skir.RecordId> tagIds = const [],
  }) async {
    state.ensureReady();
    final book = Book(
      bookId: newResourceId(AuthoringResource.book),
      authoringSequence: ref.readAuthoringSession().state.sequence ?? 0,
      title: title,
      icon: icon ?? "mdi:book",
      color: color ?? Colors.grey,
      tagIds: tagIds,
    );
    state = AsyncData([...state.requireValue, book]);
    try {
      final response = await ref.readAuthoringSession().notifier.createBook(
        book.toWire(),
      );
      response.requireApplied(conflictMessage: "The book already exists");
      return book;
    } on Object {
      _replaceFromSession();
      rethrow;
    }
  }

  Future<TypedMutationResult> updateBook(Book book, {Book? expected}) async {
    state.ensureReady();
    final before =
        expected ??
        state.requireValue.firstWhere((value) => value.bookId == book.bookId);
    state = AsyncData([
      for (final current in state.requireValue)
        if (current.bookId == book.bookId) book else current,
    ]);
    try {
      final response = await ref.readAuthoringSession().notifier.patchBook(
        book,
        expected: before,
      );
      switch (response) {
        case wire.ApplyAuthoringBatchResponse_appliedWrapper(:final value):
          return TypedMutationResult.success(
            revision: value.sequence,
            value: book.inspectorValue,
          );
        case wire.ApplyAuthoringBatchResponse_conflictWrapper():
          return _bookConflict(before);
        case wire.ApplyAuthoringBatchResponse_invalidWrapper() ||
            wire.ApplyAuthoringBatchResponse_internalErrorWrapper() ||
            wire.ApplyAuthoringBatchResponse_unknown():
          _replaceFromSession();
          return response.toMutationFailure(
            unavailableMessage: "The book update could not be completed",
          );
      }
    } on Object {
      _replaceFromSession();
      return unavailableMutation("The book update could not be completed");
    }
  }

  TypedMutationResult _bookConflict(Book expected) {
    final session = ref.readAuthoringSession();
    final canonical = session.state.books[expected.bookId];
    if (canonical == null) {
      return unavailableMutation(
        "The book no longer exists",
        targetDeleted: true,
      );
    }
    final actual = Book.fromWire(canonical, session.state.sequence ?? 0);
    state = AsyncData([
      for (final book in state.requireValue)
        if (book.bookId == actual.bookId) actual else book,
    ]);
    return TypedMutationResult.conflict(
      expectedRevision: expected.authoringSequence,
      actualRevision: actual.authoringSequence,
      actualValue: actual.inspectorValue,
    );
  }

  void _replaceFromSession() {
    state = AsyncData(_projectBooks(ref.readAuthoringSession().state));
  }
}

List<Book> _projectBooks(AuthoringSessionState value) {
  final sequence = value.sequence ?? 0;
  return value.books.values
      .map((book) => Book.fromWire(book, sequence))
      .toList();
}
