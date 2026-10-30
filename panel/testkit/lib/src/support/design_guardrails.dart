/// Source scanners that guard the design system, shared by the theme
/// guardrail tests. The tests own their exemption lists; these helpers
/// only find the violations and read the exemptions they are given.
library;

/// An allowed occurrence: a file path, a pattern its snippet must match and
/// the reason it is allowed.
class Exemption {
  Exemption(this.path, this.pattern, this.reason);

  final String path;
  final RegExp pattern;
  final String reason;
}

/// The spacing token name for each spacing literal the scanner reports.
const spacingTokenNames = <int, String>{
  4: "space1",
  8: "space2",
  12: "space3",
  16: "space4",
  20: "space5",
  24: "space6",
  32: "space8",
  40: "space10",
  48: "space12",
};

// Spacing literals (4 to 48) inside EdgeInsets and SizedBox constructions and
// spacing properties, the places the scanner checks.
final _spacingLiteralPattern = RegExp(
  r"(?<![A-Za-z0-9_.])(?:4|8|12|16|20|24|32|40|48)(?:\.0)?(?![A-Za-z0-9_.])",
);
final _edgeInsetsPattern = RegExp(
  r"(?:EdgeInsets|const)\s*\.(?:all|symmetric|only|fromLTRB)\s*\([\s\S]*?\)",
);
final _sizedBoxPattern = RegExp(r"(?:const\s+)?SizedBox\s*\([\s\S]*?\)");
final _sizedBoxDimensionPattern = RegExp(
  r"(?:width|height)\s*:\s*((?:4|8|12|16|20|24|32|40|48)(?:\.0)?)\b",
);
final _spacingPropertyPattern = RegExp(
  r"\b(?:spacing|runSpacing|mainAxisSpacing|crossAxisSpacing)\s*:\s*((?:4|8|12|16|20|24|32|40|48)(?:\.0)?)\b",
);

/// Yields one message per spacing literal in [source] that is not exempted in
/// [layoutSpacingExemptions] and should use a spacing token instead.
Iterable<String> layoutSpacingViolations(
  String path,
  String source,
  List<Exemption> layoutSpacingExemptions,
) sync* {
  final occurrences = <({int offset, String snippet, String literal})>[];

  for (final construct in _edgeInsetsPattern.allMatches(source)) {
    final snippet = construct.group(0)!;
    for (final literal in _spacingLiteralPattern.allMatches(snippet)) {
      occurrences.add((
        offset: construct.start + literal.start,
        snippet: snippet,
        literal: literal.group(0)!,
      ));
    }
  }
  for (final construct in _sizedBoxPattern.allMatches(source)) {
    final snippet = construct.group(0)!;
    final childOffset = snippet.indexOf(RegExp(r"\bchild\s*:"));
    for (final literal in _sizedBoxDimensionPattern.allMatches(snippet)) {
      if (childOffset >= 0 && literal.start > childOffset) continue;
      occurrences.add((
        offset: construct.start + literal.start,
        snippet: snippet,
        literal: literal.group(1)!,
      ));
    }
  }
  for (final literal in _spacingPropertyPattern.allMatches(source)) {
    occurrences.add((
      offset: literal.start,
      snippet: literal.group(0)!,
      literal: literal.group(1)!,
    ));
  }

  for (final occurrence in occurrences) {
    final allowed = layoutSpacingExemptions.any(
      (entry) =>
          entry.path == path && entry.pattern.hasMatch(occurrence.snippet),
    );
    if (allowed) continue;
    final value = double.parse(occurrence.literal).toInt();
    final line =
        "\n".allMatches(source.substring(0, occurrence.offset)).length + 1;
    yield "$path:$line: ${occurrence.snippet.trim()} should use "
        "context.spacing.${spacingTokenNames[value]}";
  }
}
