part of "route.dart";

class PageDrag {
  const PageDrag({required this.pageId, required this.chapter});

  final skir.RecordId pageId;
  final String chapter;
}

class ChapterDrag {
  const ChapterDrag({required this.chapter});

  final String chapter;
}
