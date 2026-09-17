import "package:freezed_annotation/freezed_annotation.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

part "page_commands.freezed.dart";

/// Validated user input required to create one page in a selected book.
@freezed
abstract class PageCreationInput with _$PageCreationInput {
  const factory PageCreationInput({
    required String name,
    required PageKindRef kind,
    required String chapter,
    required int priority,
  }) = _PageCreationInput;
}

/// Builds page mutations at the shared authoring session boundary.
///
/// The session submits operations to the realm and later reconciles the
/// resulting confirmed snapshot. These commands do not maintain a second page
/// store, and patch fields carry expected values so stale metadata is rejected
/// rather than overwritten.
extension PageCommands on AuthoringSession {
  /// Creates a new page from user supplied metadata.
  ///
  /// Identity generation and application validation stay at the authoring
  /// command boundary so dialogs and search actions share one mutation path.
  Future<Page> createPageFromInput(
    skir.RecordId bookId,
    PageCreationInput input,
  ) async {
    final page = skir.Page(
      id: newResourceId(AuthoringResource.page),
      book: bookId,
      name: input.name,
      kind: input.kind.toSkir(),
      chapter: input.chapter,
      priority: input.priority,
    );
    final response = await createPage(page);
    response.requireApplied(conflictMessage: "The page already exists");
    return Page.fromWire(page);
  }

  /// Creates [page] through the session's authoring batch protocol.
  Future<skir.ApplyAuthoringBatchResponse> createPage(skir.Page page) =>
      apply([skir.AuthoringOperation.createCreatePage(page: page)]);

  /// Deletes the page identified by [id] through the authoring boundary.
  Future<skir.ApplyAuthoringBatchResponse> deletePage(skir.RecordId id) =>
      apply([skir.AuthoringOperation.createDeletePage(id: id)]);

  /// Applies the supplied metadata changes if at least one field is present.
  ///
  /// Each non null change contains its expected old value. The returned wire
  /// outcome distinguishes application, rejection, and other boundary states.
  Future<skir.ApplyAuthoringBatchResponse> patchPage({
    required skir.RecordId id,
    skir.StringChange? name,
    skir.StringChange? chapter,
    skir.Int32Change? priority,
  }) {
    if (name == null && chapter == null && priority == null) {
      throw ApiException.badRequest("At least one page field is required");
    }
    return apply([
      skir.AuthoringOperation.createPatchPage(
        id: id,
        book: null,
        name: name,
        chapter: chapter,
        priority: priority,
      ),
    ]);
  }

  /// Renames a chapter path for every supplied page in one authoring batch.
  ///
  /// The page collection must include the complete subtree selected by the
  /// caller. Each operation expects the page's current chapter, making a
  /// concurrent change observable as a conflict.
  Future<skir.ApplyAuthoringBatchResponse> changePagesChapters(
    Iterable<Page> pages,
    String oldChapter,
    String newChapter,
  ) => apply([
    for (final page in pages)
      skir.AuthoringOperation.createPatchPage(
        id: page.pageId,
        book: null,
        name: null,
        chapter: skir.StringChange(
          expected: page.chapter,
          value: replacePageChapter(page.chapter, oldChapter, newChapter),
        ),
        priority: null,
      ),
  ]);
}

/// Rewrites one chapter path while preserving its descendant suffix.
///
/// A chapter belongs to [oldChapter] when it is equal to it or starts with
/// that path followed by a period. Otherwise this reports invalid caller input.
/// Removing the selected root returns the suffix without its leading period.
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
