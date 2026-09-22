import "package:collection/collection.dart";
import "package:flutter/material.dart";
import "package:freezed_annotation/freezed_annotation.dart";
import "package:riverpod/riverpod.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

part "book_inspector_definition.dart";
part "book_model.dart";
part "book_queries.dart";
part "book_selection.dart";
part "books.freezed.dart";
part "books.g.dart";

/// Owns the confirmed book collection for the selected organization and realm.
///
/// The realm authoring session remains the source of truth. This provider waits
/// for the library scope to become ready, then projects session records into
/// immutable [Book] values and listens for later session sequences. Consumers
/// that render or edit immediately should choose [projectedBooksProvider] or
/// [projectedBookProvider] when local editor values must be visible.
@riverpod
class CanonicalBooks extends _$CanonicalBooks {
  @override
  Future<List<Book>> build() async {
    final organizationId = ref.watch(organizationIdProvider);
    final realmId = ref.watch(realmIdProvider);
    if (organizationId == null || realmId == null) {
      return [];
    }

    ref.watch(
      realmEditorCatalogLeaseProvider(
        RealmEditorCatalogRequest(types: {referenceResourceTypes.book}),
      ),
    );
    final catalogState = await ref.watch(realmEditorCatalogProvider.future);
    final catalog = catalogState.snapshot;
    if (catalog == null) throw StateError("The editor catalog is unavailable");
    final codec = TypedAuthoringCodec(catalog);
    final provider = authoringSessionProvider(organizationId, realmId);
    ref.listen(provider, (_, value) {
      if (value.sequence != null &&
          value.generation?.value == catalog.generation.value) {
        state = AsyncData(_projectBooks(value, codec));
      }
    });
    final lease = ref.watch(
      authoringSelectionLeaseProvider(
        organizationId,
        realmId,
        authoringDefinitionSelection(
          key: "books",
          definitions: const [CoreResourceDefinitionIds.book],
        ),
      ),
    );
    await lease.ready;
    return _projectBooks(ref.read(provider), codec);
  }

  /// Applies the changed inspector fields of [book] against [expected].
  ///
  /// When [expected] is omitted, the current confirmed session value is used.
  /// The editor owner converts the difference into a conditional patch, so a
  /// concurrent change is reported instead of being silently overwritten.
  /// The temporary owner is always disposed after submission.
  Future<TypedMutationResult> updateBook(Book book, {Book? expected}) async {
    state.ensureReady();
    final session = ref.readAuthoringSession();
    final current = session.state.resources[book.bookId];
    if (current == null || session.state.sequence == null) {
      throw ApiException.notFound("Book");
    }
    final catalog = ref.read(realmEditorCatalogProvider).value?.snapshot;
    if (catalog == null) throw StateError("The editor catalog is unavailable");
    final codec = TypedAuthoringCodec(catalog);
    final decoded = codec.decodeResource(current).valueOrNull;
    if (decoded == null) throw StateError("The Book content is invalid");
    final collections = decodeAuthoringCollections(
      session: session.state,
      catalog: catalog,
      presentations: catalog.presentations.values,
    );
    final tags = collections.sources[authoringTagCollectionSourceId];
    if (tags == null) {
      throw StateError("The Realm Tag collection is unavailable");
    }
    final before = expected ?? Book.fromTyped(decoded);
    final commands = session.notifier;
    final owners = EditorOwnerRegistry(
      workspace: ref.read(localWorkControllerProvider),
    );
    try {
      final owner = owners.editor(
        BookSelection(
          resource: TypedAuthoringEditorResource(
            ref
                .read(resourceRepositoriesProvider)
                .authoring(commands.organizationId, commands.realmId),
            book.bookId,
          ),
          onOpen: null,
          id: BookIdentifier(book.bookId),
          book: before,
          snapshot: TypedAuthoringEditorSnapshot(
            resource: current,
            content: decoded.content,
            revision: session.state.sequence!,
            codec: codec,
          ),
          catalogPresentations: catalog.presentations.values.toList(
            growable: false,
          ),
          tagCollection: tags,
          presentationDiagnostics: collections.diagnostics,
        ),
      );
      return await owner.applyChanges(
        editorValueChanges(before.inspectorValue, book.inspectorValue),
      );
    } finally {
      owners.dispose();
    }
  }
}

List<Book> _projectBooks(
  AuthoringSessionState value,
  TypedAuthoringCodec codec,
) {
  return value.resources.values
      .map(codec.decodeResourceOrThrow)
      .where(
        (resource) => codec.isResourceType(
          resource.content,
          CoreResourceDefinitionIds.book,
        ),
      )
      .map(Book.fromTyped)
      .toList();
}

/// Reads one confirmed book together with the session sequence that confirms
/// it. A missing book or uninitialized session produces no editable value.
extension AuthoringBookValue on AuthoringSessionState {
  AuthoringValue<Book>? bookEditorValue(
    skir.ResourceId bookId,
    TypedAuthoringCodec codec,
  ) {
    final value = resources[bookId];
    final revision = sequence;
    if (value == null || revision == null) return null;
    final decoded = codec.decodeResourceOrThrow(value);
    if (!codec.isResourceType(
      decoded.content,
      CoreResourceDefinitionIds.book,
    )) {
      return null;
    }
    return AuthoringValue(value: Book.fromTyped(decoded), revision: revision);
  }
}
