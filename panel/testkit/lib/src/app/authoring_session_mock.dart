import "dart:async";

// ignore: implementation_imports
import "package:riverpod/src/framework.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

class AuthoringSessionMock extends AuthoringSession {
  AuthoringSessionMock({
    this.initial = const AuthoringSessionState(sequence: 1),
    this.onApply,
  });
  final AuthoringSessionState initial;
  final FutureOr<void> Function(List<skir.AuthoringOperation> operations)?
  onApply;

  @override
  AuthoringSessionState build(
    skir.RecordId organizationId,
    skir.RecordId realmId,
  ) => initial;

  @override
  Future<skir.ApplyAuthoringBatchResponse> apply(
    Iterable<skir.AuthoringOperation> operations, {
    String? batchId,
  }) async {
    await onApply?.call(List.unmodifiable(operations));
    state = state.copyWith(sequence: (state.sequence ?? 0) + 1);
    return skir.ApplyAuthoringBatchResponse.createApplied(
      sequence: state.sequence!,
      batchId: batchId ?? "fixture",
      changes: const [],
      indirectlyAffectedResources: const [],
    );
  }
}

List<Override> authoringSessionMockOverrides({
  AuthoringSessionState? initial,
  Iterable<Book> books = const [],
  Iterable<Tag> tags = const [],
  FutureOr<void> Function(List<skir.AuthoringOperation> operations)? onApply,
}) {
  assert(
    initial == null || (books.isEmpty && tags.isEmpty),
    "Use either an initial state or domain fixtures",
  );
  final state =
      initial ??
      AuthoringSessionState(
        sequence: 1,
        books: {for (final book in books) book.bookId: book.toWire()},
        tags: {for (final tag in tags) tag.tagId: tag.toWire()},
      );
  return [
    authoringSessionProvider.overrideWith2(
      (_) => AuthoringSessionMock(initial: state, onApply: onApply),
    ),
  ];
}
