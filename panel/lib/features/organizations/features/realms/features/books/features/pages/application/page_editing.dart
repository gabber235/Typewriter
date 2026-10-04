import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

extension PageEditingRef on WidgetRef {
  Future<void> editPage({
    required skir.ResourceId id,
    String? name,
    String? expectedName,
    String? chapter,
    String? expectedChapter,
    int? priority,
    int? expectedPriority,
  }) async {
    final access = readAuthoringSession();
    final baseline = access.state.draft;
    if (baseline == null) throw StateError("Authoring is not ready");
    final draft = baseline.fork();
    if (name != null) {
      _setString(draft, id, "name", expected: expectedName, proposed: name);
    }
    if (chapter != null) {
      _setString(
        draft,
        id,
        "chapter",
        expected: expectedChapter,
        proposed: chapter,
      );
    }
    if (priority != null) {
      _setInteger(
        draft,
        id,
        "priority",
        expected: expectedPriority,
        proposed: priority,
      );
    }
    await access.notifier.commitDraft(
      draft,
      conflictMessage: "The Page changed before this edit was saved",
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
      _setString(
        draft,
        page.pageId,
        "chapter",
        expected: page.chapter,
        proposed: replacePageChapter(page.chapter, oldChapter, newChapter),
      );
    }
    await access.notifier.commitDraft(
      draft,
      conflictMessage: "A Page changed before this edit was saved",
    );
  }
}

void _setString(
  AuthoredDraft draft,
  skir.ResourceId resource,
  String field, {
  required String? expected,
  required String proposed,
}) {
  final location = _field(resource, field);
  final current = draft.read(location);
  if (current case PortablePathValue(:final value)) {
    if (expected == null || value.authoredString != expected) {
      throw ApiException.conflict("The Page $field changed");
    }
  } else {
    throw StateError("The Page $field is unavailable");
  }
  final result = draft.setPayload(
    location,
    skir.DataValue.wrapStringValue(proposed),
  );
  if (result is PortablePathUnavailable<skir.AuthoringRecord>) {
    throw StateError(result.message);
  }
}

void _setInteger(
  AuthoredDraft draft,
  skir.ResourceId resource,
  String field, {
  required int? expected,
  required int proposed,
}) {
  final location = _field(resource, field);
  final current = draft.read(location);
  if (current case PortablePathValue(:final value)) {
    if (expected == null || value.authoredInteger != BigInt.from(expected)) {
      throw ApiException.conflict("The Page $field changed");
    }
  } else {
    throw StateError("The Page $field is unavailable");
  }
  final result = draft.setPayload(
    location,
    skir.DataValue.wrapInteger(proposed.toString()),
  );
  if (result is PortablePathUnavailable<skir.AuthoringRecord>) {
    throw StateError(result.message);
  }
}

skir.ValueLocation _field(skir.ResourceId resource, String field) =>
    skir.ValueLocation(
      resource: resource,
      path: skir.ValuePath(
        segments: [skir.PathSegment.createField(name: field)],
      ),
    );
