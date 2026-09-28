part of "route.dart";

/// Drag payload for moving one page between chapter paths.
///
/// The source chapter is retained as the expected value for the later
/// optimistic mutation.
class PageDrag implements ReferenceResourceDragData {
  const PageDrag({required this.pageId, required this.chapter});

  final skir.ResourceId pageId;
  final String chapter;

  @override
  skir.ResourceId get referenceId => pageId;

  @override
  List<ResolvedTypeRef> get referenceTypes => const [];
}

/// Drag payload for moving a chapter subtree.
///
/// The target uses the source path to reject dropping a chapter into itself or
/// one of its descendants.
class ChapterDrag {
  const ChapterDrag({required this.chapter});

  final String chapter;
}
