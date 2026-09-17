import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

/// Creates page metadata mutations with the current workspace dependencies.
///
/// Callers use this bridge from widgets so edits enter the same retained local
/// work and transactional save lifecycle as the full page editor.
extension PageEditingRef on WidgetRef {
  /// Applies metadata changes to one page without bypassing local draft state.
  Future<TypedMutationResult> editPage({
    required skir.RecordId id,
    skir.StringChange? name,
    skir.StringChange? chapter,
    skir.Int32Change? priority,
  }) => _pageEditing().edit({
    id: {
      if (name != null) DataPath.root.field("name"): name.value.asValue,
      if (chapter != null)
        DataPath.root.field("chapter"): chapter.value.asValue,
      if (priority != null)
        DataPath.root.field("priority"): priority.value.asValue,
    },
  });

  /// Applies a chapter rename to an already selected page subtree.
  ///
  /// The supplied pages are converted to individual path changes. The caller
  /// receives one typed result after the shared batch owner settles them.
  Future<TypedMutationResult> editPagesChapter(
    List<Page> pages,
    String oldChapter,
    String newChapter,
  ) => _pageEditing().edit({
    for (final page in pages)
      page.pageId: {
        DataPath.root.field("chapter"): replacePageChapter(
          page.chapter,
          oldChapter,
          newChapter,
        ).asValue,
      },
  });
  PageEditing _pageEditing() {
    final session = readAuthoringSession().notifier;
    return PageEditing(
      session,
      read(localWorkControllerProvider),
      read(resourceRepositoriesProvider)
          .authoring(session.organizationId, session.realmId),
    );
  }
}

/// Owns the page metadata editing boundary for non editor page surfaces.
///
/// It leases each page from [session], creates transactional resource owners
/// backed by [repository], submits through [EditorBatch], and releases every
/// lease and owner before returning. Canonical pages remain session state; local
/// drafts remain in [workspace].
final class PageEditing {
  /// Creates an editor operation using explicitly scoped collaborators.
  PageEditing(this.session, this.workspace, this.repository);
  final AuthoringResourceRepository repository;
  final AuthoringSession session;
  final LocalWorkCommands workspace;

  /// Validates and submits metadata changes for one or more pages.
  ///
  /// An absent page returns an unavailable result and marks it as deleted.
  /// Validation or remote rejection leaves the local draft available for
  /// review. Resource ownership is temporary, so this method always releases
  /// leases and editor owners, including when submission throws.
  Future<TypedMutationResult> edit(
    Map<skir.RecordId, Map<DataPath, DataValue>> changes,
  ) async {
    final leases = [for (final id in changes.keys) session.acquirePage(id)];
    final owners = EditorOwnerRegistry(workspace: workspace);
    try {
      await Future.wait(leases.map((lease) => lease.ready));
      final edits = <TransactionalEditorSource, Map<DataPath, DataValue>>{};
      for (final entry in changes.entries) {
        final target = this.target(entry.key);
        if (target == null) {
          return unavailableMutation(
            "The page no longer exists",
            targetDeleted: true,
          );
        }
        final owner = owners.editor(target) as TransactionalEditorSource;
        edits[owner] = entry.value;
      }
      final results = await EditorBatch.submit(changes: edits);
      return results.values
              .where((result) => result is! MutationSuccess)
              .firstOrNull ??
          results.values.firstOrNull ??
          invalidMutation("No page edits were supplied");
    } finally {
      owners.dispose();
      for (final lease in leases) {
        lease.release();
      }
    }
  }

  /// Builds the editor target from the session's current canonical page.
  ///
  /// A missing page means the caller must stop editing it. The snapshot only
  /// exposes editable metadata fields; page elements belong to the dedicated
  /// page editor feature.
  EditorTarget? target(skir.RecordId id) {
    final page = session.snapshot.pages[id];
    if (page == null) return null;
    return ResourceEditorTarget(
      targetId: id,
      label: "Page: ${page.name}",
      resource: PageEditorResource(repository, id),
      snapshot: pageEditorSnapshot(page, session.snapshot.sequence ?? 0),
    );
  }
}

/// Converts a captured metadata commit into a conditional wire patch.
///
/// Only changed paths are emitted. Values read from [commit.baseValue] become
/// expected values, preserving optimistic concurrency at the realm boundary.
skir.AuthoringOperation pagePatchOperation(
  skir.RecordId id,
  EditorCommit commit,
) {
  skir.StringChange? text(String key) {
    final path = DataPath.root.field(key);
    if (!commit.changedPaths.contains(path)) return null;
    return skir.StringChange(
      expected: (path.read(commit.baseValue).valueOrNull! as StringValue).value,
      value: (path.read(commit.rootValue).valueOrNull! as StringValue).value,
    );
  }

  final priority = DataPath.root.field("priority");
  return skir.AuthoringOperation.createPatchPage(
    id: id,
    book: null,
    name: text("name"),
    chapter: text("chapter"),
    priority: commit.changedPaths.contains(priority)
        ? skir.Int32Change(
            expected:
                (priority.read(commit.baseValue).valueOrNull! as IntegerValue)
                    .value
                    .toInt(),
            value:
                (priority.read(commit.rootValue).valueOrNull! as IntegerValue)
                    .value
                    .toInt(),
          )
        : null,
  );
}

/// Creates the metadata editor snapshot used by page list and form surfaces.
///
/// [sequence] identifies the canonical authoring observation, not local draft
/// work. Element content is intentionally outside this snapshot.
EditorSnapshot pageEditorSnapshot(skir.Page page, int sequence) =>
    DocumentEditorSnapshot(
      EditorDocument(
        rootType: RecordType(
          fields: const {
            "name": TypeField(name: "name", type: StringType()),
            "chapter": TypeField(name: "chapter", type: StringType()),
            "priority": TypeField(
              name: "priority",
              type: IntegerType(width: IntegerWidth.signed32),
            ),
          },
        ),
        typeCatalog: const TypeCatalog([]),
        revision: sequence,
        confirmedValue: Page.fromWire(page).editorValue,
      ),
    );

/// Projects page scoped authoring observations into the metadata editor model.
///
/// The resource translates page upserts into a newer canonical document and
/// treats removal as deletion. Unrelated book, tag, and element changes are
/// ignored, leaving this owner responsible only for one page metadata record.
final class PageEditorResource extends AuthoringEditorResource {
  const PageEditorResource(super.repository, super.id);
  @override
  skir.AuthoringSnapshotScope get scope =>
      skir.AuthoringSnapshotScope.createPage(pageId: id);
  @override
  EditorSnapshot? project(skir.AuthoringSnapshot snapshot) {
    for (final slice in snapshot.slices) {
      if (slice case skir.AuthoringSnapshotSlice_pageWrapper(:final value)) {
        if (value.document case final document?) {
          return pageEditorSnapshot(document.page, snapshot.sequence);
        }
      }
    }
    return null;
  }

  @override
  EditorSnapshot? projectApplied(
    skir.AuthoringChanged change,
    EditorSnapshot submitted,
  ) {
    for (final resource in change.changes) {
      switch (resource) {
        case skir.AuthoringResourceChange_upsertPageWrapper(:final value):
          if (value.id == id) return pageEditorSnapshot(value, change.sequence);
        case skir.AuthoringResourceChange_removePageWrapper(:final value):
          if (value == id) return null;
        case skir.AuthoringResourceChange_unknown() ||
            skir.AuthoringResourceChange_upsertBookWrapper() ||
            skir.AuthoringResourceChange_removeBookWrapper() ||
            skir.AuthoringResourceChange_upsertTagWrapper() ||
            skir.AuthoringResourceChange_removeTagWrapper() ||
            skir.AuthoringResourceChange_upsertElementWrapper() ||
            skir.AuthoringResourceChange_removeElementWrapper():
      }
    }
    return null;
  }

  @override
  skir.AuthoringOperation operation(
    EditorSnapshot snapshot,
    EditorCommit commit,
  ) => pagePatchOperation(id, commit);
}
