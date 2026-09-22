import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

typedef PageFieldEdit = ({DataValue? expected, DataValue value});

/// Detects whether a page command still targets the values shown at origin.
///
/// The authoritative refresh may have a newer value even when the editor has
/// no mounted owner. Returning a conflict here prevents command adapters from
/// replacing a concurrent change that the user never observed.
MutationConflict? pageEditOriginConflict(
  EditorDocument document,
  Map<DataPath, PageFieldEdit> changes,
) {
  for (final change in changes.entries) {
    final actual = change.key.read(document.confirmedValue).valueOrNull;
    if (change.value.expected == null || actual != change.value.expected) {
      return TypedMutationResult.conflict(
        expectedRevision: document.revision,
        actualRevision: document.revision,
        actualValue: document.confirmedValue,
      ) as MutationConflict;
    }
  }
  return null;
}

extension PageEditingRef on WidgetRef {
  Future<TypedMutationResult> editPage({
    required skir.ResourceId id,
    String? name,
    String? expectedName,
    String? chapter,
    String? expectedChapter,
    int? priority,
    int? expectedPriority,
  }) => _pageEditing().edit({
    id: {
      if (name != null)
        DataPath.root.field("name"): (
          expected: expectedName?.asValue,
          value: name.asValue,
        ),
      if (chapter != null)
        DataPath.root.field("chapter"): (
          expected: expectedChapter?.asValue,
          value: chapter.asValue,
        ),
      if (priority != null)
        DataPath.root.field("priority"): (
          expected: expectedPriority?.asValue,
          value: priority.asValue,
        ),
    },
  });

  Future<TypedMutationResult> editPagesChapter(
    List<Page> pages,
    String oldChapter,
    String newChapter,
  ) => _pageEditing().edit({
    for (final page in pages)
      page.pageId: {
        DataPath.root.field("chapter"): (
          expected: page.chapter.asValue,
          value: replacePageChapter(
            page.chapter,
            oldChapter,
            newChapter,
          ).asValue,
        ),
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

final class PageEditing {
  PageEditing(this.session, this.workspace, this.repository);

  final AuthoringResourceRepository repository;
  final AuthoringSession session;
  final LocalWorkCommands workspace;

  Future<TypedMutationResult> edit(
    Map<skir.ResourceId, Map<DataPath, PageFieldEdit>> changes,
  ) async {
    final leases = [
      for (final id in changes.keys) session.acquire(id.pageAuthoringSelection),
    ];
    final owners = EditorOwnerRegistry(workspace: workspace);
    try {
      await Future.wait(leases.map((lease) => lease.ready));
      final edits = <TransactionalEditorSource, Map<DataPath, DataValue>>{};
      for (final entry in changes.entries) {
        final resource = TypedAuthoringEditorResource(repository, entry.key);
        final snapshot = await resource.refresh();
        if (snapshot == null) {
          return unavailableMutation(
            "The page no longer exists",
            targetDeleted: true,
          );
        }
        final originConflict = pageEditOriginConflict(
          snapshot.document,
          entry.value,
        );
        if (originConflict != null) return originConflict;
        final target = ResourceEditorTarget(
          targetId: entry.key,
          label: "Page",
          resource: resource,
          snapshot: snapshot,
        );
        final owner = owners.editor(target) as TransactionalEditorSource;
        edits[owner] = {
          for (final change in entry.value.entries)
            change.key: change.value.value,
        };
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
}
