import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

extension PageEditingRef on WidgetRef {
  /// Opens the existing resource inspector without toggling an existing selection.
  void inspectPage(skir.ResourceId id) {
    final organizationId = read(organizationIdProvider);
    final realmId = read(realmIdProvider);
    if (organizationId == null) throw ApiException.noOrganization();
    if (realmId == null) throw ApiException.badRequest("No realm selected");
    read(selectionProvider.notifier).selectAll([
      AuthoringResourceIdentifier(
        organizationId: organizationId,
        realmId: realmId,
        resourceId: id,
      ),
    ]);
  }

  /// Moves a page only if its captured authored chapter is still current.
  Future<void> movePageChapter({
    required skir.ResourceId id,
    required String chapter,
    required skir.DataValue? expectedChapter,
  }) async {
    final access = readAuthoringSession();
    final baseline = access.state.draft;
    if (baseline == null) throw StateError("Authoring is not ready");
    final draft = baseline.fork()
      .._setChapter(id, expected: expectedChapter, proposed: chapter);
    await access.notifier.commitDraft(
      draft,
      conflictMessage: "The Page changed before this move was saved",
    );
  }

  Future<void> editPagesChapter(
    List<Page> pages,
    String oldChapter,
    String newChapter,
  ) async {
    final access = readAuthoringSession();
    final baseline = access.state.draft;
    if (baseline == null) throw StateError("Authoring is not ready");
    final draft = baseline.fork();
    for (final page in pages) {
      draft._setChapter(
        page.pageId,
        expected: page.authoredRecord.authoredField("chapter"),
        proposed: replacePageChapter(page.chapter, oldChapter, newChapter),
      );
    }
    await access.notifier.commitDraft(
      draft,
      conflictMessage: "A Page changed before this edit was saved",
    );
  }
}

extension on AuthoredDraft {
  void _setChapter(
    skir.ResourceId resource, {
    required skir.DataValue? expected,
    required String proposed,
  }) {
    final location = skir.ValueLocation(
      resource: resource,
      path: skir.ValuePath(
        segments: [skir.PathSegment.createField(name: "chapter")],
      ),
    );
    final current = read(location);
    if (current case PortablePathValue(:final value)) {
      if (expected == null || value != expected) {
        throw ApiException.conflict("The Page chapter changed");
      }
    } else {
      throw StateError("The Page chapter is unavailable");
    }
    final result = setPayload(
      location,
      skir.DataValue.wrapStringValue(proposed),
    );
    if (result is PortablePathUnavailable<skir.AuthoringRecord>) {
      throw StateError(result.message);
    }
  }
}
