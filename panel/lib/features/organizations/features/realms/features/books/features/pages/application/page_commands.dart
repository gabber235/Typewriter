import "package:typewriter_panel/typewriter_panel.dart";

extension ChapterPathOperations on String {
  String replacingChapter({required String from, required String to}) {
    if (this != from && !startsWith("$from.")) {
      throw ApiException.badRequest("The page is not in the selected chapter");
    }
    final suffix = substring(from.length);
    if (to.isEmpty && suffix.startsWith(".")) return suffix.substring(1);
    return "$to$suffix";
  }
}
