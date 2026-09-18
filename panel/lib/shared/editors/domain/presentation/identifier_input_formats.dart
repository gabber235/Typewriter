import "package:typewriter_panel/typewriter_panel.dart";

/// Normalizes user entered identifiers to the format accepted by editor IDs.
///
/// Formatting is applied in order: text is lowercased, whitespace and hyphens
/// become underscores, and every remaining character outside the ASCII
/// identifier alphabet is rejected. The same declaration is consumed by
/// inspector fields and rename dialogs so identifiers have one input contract.
const identifierInputFormats = [
  TextInputFormat.lowercase(),
  TextInputFormat.replace(pattern: r"[\s\-]+", replacement: "_"),
  TextInputFormat.allow("[a-z0-9_]"),
];
