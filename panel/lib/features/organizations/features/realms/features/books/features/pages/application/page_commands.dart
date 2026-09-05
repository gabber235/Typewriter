import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/library/v1/authoring.dart"
    as wire;
import "package:typewriter_panel/typewriter_panel.dart";

extension PageCommands on AuthoringSession {
  Future<wire.ApplyAuthoringBatchResponse> createPage(wire.Page page) =>
      apply([wire.AuthoringOperation.createCreatePage(page: page)]);

  Future<wire.ApplyAuthoringBatchResponse> deletePage(skir.RecordId id) =>
      apply([wire.AuthoringOperation.createDeletePage(id: id)]);

  Future<wire.ApplyAuthoringBatchResponse> patchPage({
    required skir.RecordId id,
    wire.StringChange? name,
    wire.StringChange? chapter,
    wire.Int32Change? priority,
  }) {
    if (name == null && chapter == null && priority == null) {
      throw ApiException.badRequest("At least one page field is required");
    }
    return apply([
      wire.AuthoringOperation.createPatchPage(
        id: id,
        book: null,
        name: name,
        chapter: chapter,
        priority: priority,
      ),
    ]);
  }

  Future<wire.ApplyAuthoringBatchResponse> changePagesChapters(
    Iterable<Page> pages,
    String oldChapter,
    String newChapter,
  ) => apply([
    for (final page in pages)
      wire.AuthoringOperation.createPatchPage(
        id: page.pageId,
        book: null,
        name: null,
        chapter: wire.StringChange(
          expected: page.chapter,
          value: _replaceChapter(page.chapter, oldChapter, newChapter),
        ),
        priority: null,
      ),
  ]);
}

String _replaceChapter(String chapter, String oldChapter, String newChapter) {
  if (chapter != oldChapter && !chapter.startsWith("$oldChapter.")) {
    throw ApiException.badRequest("The page is not in the selected chapter");
  }
  final suffix = chapter.substring(oldChapter.length);
  if (newChapter.isEmpty && suffix.startsWith(".")) return suffix.substring(1);
  return "$newChapter$suffix";
}
