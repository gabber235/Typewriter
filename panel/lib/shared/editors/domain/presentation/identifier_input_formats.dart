import "package:typewriter_panel/typewriter_panel.dart";

const identifierInputFormats = [
  TextInputFormat.lowercase(),
  TextInputFormat.replace(pattern: r"[\s\-]+", replacement: "_"),
  TextInputFormat.deny("[^a-z0-9_]+"),
];
