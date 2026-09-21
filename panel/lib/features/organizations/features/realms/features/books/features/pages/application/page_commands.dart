import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

RecordValue pageCreationPartial({
  required skir.ResourceId bookId,
  required PageKindRef kind,
  String chapter = "",
}) => RecordValue({
  "book": ReferenceValue(bookId),
  "kind": RecordValue({
    "id": kind.id.asValue,
    "revision": kind.revision.asValue,
  }),
  "chapter": chapter.asValue,
  "priority": 0.asValue,
});

extension PageCommands on AuthoringSession {
  Future<skir.ApplyAuthoringBatchResponse> deletePage(skir.ResourceId id) =>
      apply([skir.AuthoringOperation.createDelete(id: id)]);
}

String replacePageChapter(
  String chapter,
  String oldChapter,
  String newChapter,
) {
  if (chapter != oldChapter && !chapter.startsWith("$oldChapter.")) {
    throw ApiException.badRequest("The page is not in the selected chapter");
  }
  final suffix = chapter.substring(oldChapter.length);
  if (newChapter.isEmpty && suffix.startsWith(".")) return suffix.substring(1);
  return "$newChapter$suffix";
}
