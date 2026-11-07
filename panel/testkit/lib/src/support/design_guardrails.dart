/// Source scanners that guard the design system, shared by the theme
/// guardrail tests. The tests own their exemption lists; these helpers
/// only find the violations and read the exemptions they are given.
library;

import "dart:math";

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

/// The motion API a literal is replaced by.
const motionTokenHint =
    "use a Motion token (MotionToken.<name>, see panel-design Values) "
    "through useMotion, Enter, Leave, Rise, HoldFill or Ring";

final _motionLiteralPattern = RegExp(
  r"(?<![A-Za-z0-9_.])Duration\s*\(\s*(?:milliseconds|microseconds|seconds)\s*:\s*\d"
  r"|(?<![A-Za-z0-9_.])\d+(?:\.\d+)?\.(?:ms|seconds)\b"
  r"|(?<![A-Za-z0-9_])Curves\.[A-Za-z]+"
  r"|(?<![A-Za-z0-9_])ElasticOutCurve\s*\("
  r"|(?<![A-Za-z0-9_])Cubic\s*\(",
);

// A duration given to one of these calls or names keeps time; it does not
// move anything.
const _clockCalls = {
  "Timer",
  "Timer.periodic",
  "useTimer",
  "Future.delayed",
  "Stream.periodic",
  "add",
  "subtract",
  "delayed",
  "debounced",
  "periodic",
};
final _clockName = RegExp(
  "interval|timeout|expiry|threshold|debounce|longpress|refresh",
  caseSensitive: false,
);
// The lookbehind keeps `10.seconds : 3.seconds` in a ternary from reading as
// a named argument.
final _namedTarget = RegExp(
  r"(?<![\w.])(?:this\.)?([A-Za-z_]\w*)\s*[:=]\s*(?:const\s+)?$",
);
final _callee = RegExp(r"([A-Za-z_]\w*(?:\.[A-Za-z_]\w*)?)\s*$");

bool _isClock(String source, int offset) {
  final before = source.substring(max(0, offset - 80), offset);
  final named = _namedTarget.firstMatch(before);
  if (named != null) return _clockName.hasMatch(named.group(1)!);
  var depth = 0;
  for (var index = offset - 1; index >= 0; index--) {
    final char = source[index];
    if (char == ")") depth++;
    if (char != "(") continue;
    if (depth-- > 0) continue;
    final name = _callee
        .firstMatch(source.substring(max(0, index - 60), index))
        ?.group(1);
    if (name == null) return false;
    return _clockCalls.contains(name) ||
        _clockCalls.contains(name.split(".").last);
  }
  return false;
}

/// Yields one message per literal motion value in [source] that is not
/// exempted in [motionExemptions]. A Duration counts only with a numeric
/// literal in milliseconds, microseconds or seconds, and not when it is
/// given to a clock call or a clock name.
Iterable<String> motionLiteralViolations(
  String path,
  String source,
  List<Exemption> motionExemptions,
) sync* {
  for (final match in _motionLiteralPattern.allMatches(source)) {
    final literal = match.group(0)!;
    final isDuration =
        !literal.startsWith("Curves") &&
        !literal.startsWith("ElasticOutCurve") &&
        !literal.startsWith("Cubic");
    if (isDuration && _isClock(source, match.start)) continue;
    if (motionExemptions.any(
      (entry) => entry.path == path && entry.pattern.hasMatch(literal),
    )) {
      continue;
    }
    final line = "\n".allMatches(source.substring(0, match.start)).length + 1;
    yield "$path:$line: $literal is literal motion; $motionTokenHint";
  }
}

/// An API that decides motion or surface behaviour outside the panel's own
/// owners. [allowedIn] maps each file that is the one wrapper for part of it
/// to the uses it may make there.
final class BannedPattern {
  const BannedPattern(this.pattern, this.hint, {this.allowedIn = const {}});

  final RegExp pattern;
  final String hint;
  final Map<String, RegExp> allowedIn;
}

/// Yields one message per use of a [patterns] entry in [source] outside its
/// allowed owners and not exempted in [exemptions].
Iterable<String> bannedApiViolations(
  String path,
  String source,
  List<BannedPattern> patterns,
  List<Exemption> exemptions,
) sync* {
  for (final banned in patterns) {
    for (final match in banned.pattern.allMatches(source)) {
      final hit = match.group(0)!;
      if (banned.allowedIn[path]?.hasMatch(hit) ?? false) continue;
      if (exemptions.any(
        (entry) => entry.path == path && entry.pattern.hasMatch(hit),
      )) {
        continue;
      }
      final line = "\n".allMatches(source.substring(0, match.start)).length + 1;
      yield "$path:$line: $hit is banned; ${banned.hint}";
    }
  }
}

/// Reduced motion read outside resolveMotion.
final bannedDisableAnimations = RegExp(r"\b(?:maybeD|d)isableAnimationsOf\b");

/// A Material card or expansion style that grows on its own clock.
final bannedAnimationStyle = RegExp(r"(?<![\w.])AnimationStyle\s*\(");

/// Material menus.
final bannedMaterialMenus = RegExp(
  r"(?<![\w.])(?:MenuAnchor|PopupMenuButton|DropdownMenu|showMenu)\b",
);

/// Material tooltips.
final bannedTooltip = RegExp(r"(?<![\w.])Tooltip\s*\(");

/// Material dialog and sheet routes.
final bannedMaterialRoutes = RegExp(
  r"(?<![\w.])(?:showDialog|showGeneralDialog|showModalBottomSheet|showBottomSheet|DialogRoute|RawDialogRoute)\b",
);

/// Material list rows.
final bannedListTile = RegExp(r"(?<![\w.])(?:ListTile|ExpansionTile)\s*\(");

/// The flutter_animate package.
final bannedFlutterAnimate = RegExp(r"package:flutter_animate/");

/// Hand written springs.
final bannedSprings = RegExp(
  r"(?<![\w.])SpringDescription(?:\.withDampingRatio)?\s*\(",
);

/// Hand staged motion.
final bannedIntervals = RegExp(r"(?<![\w.])Interval\s*\(");

/// Hand driven animation controllers.
final bannedControllers = RegExp(
  r"(?<![\w.])AnimationController(?:\.unbounded)?\s*\(",
);

/// Every API that decides motion or surface behaviour outside its owner,
/// with the files that own part of it.
final bannedPatterns = <BannedPattern>[
  BannedPattern(
    bannedDisableAnimations,
    "read reduced motion only through resolveMotion",
    allowedIn: {"lib/shared/hooks/motion.dart": bannedDisableAnimations},
  ),
  BannedPattern(
    bannedAnimationStyle,
    "grow the card with GrowingCard and a Motion token",
  ),
  BannedPattern(bannedMaterialMenus, "open the menu with AnchoredPopup"),
  BannedPattern(bannedTooltip, "use PanelTooltip"),
  BannedPattern(
    bannedMaterialRoutes,
    "open dialogs with MotionDialogRoute and sheets with showPanelSheet",
    allowedIn: {
      "lib/shared/ui/components/popups.dart": RegExp(r"^showModalBottomSheet$"),
      "lib/shared/ui/components/motion_dialog_route.dart": RegExp(
        r"^RawDialogRoute$",
      ),
    },
  ),
  BannedPattern(bannedListTile, "build the row with Button"),
  BannedPattern(
    bannedFlutterAnimate,
    "move with a Motion token through useMotion, Enter or Leave",
  ),
  BannedPattern(
    bannedSprings,
    "springs are Motion token values; $motionTokenHint",
  ),
  BannedPattern(
    bannedIntervals,
    "stage motion with a Motion token timeline; $motionTokenHint",
  ),
  BannedPattern(
    bannedControllers,
    "use MotionController with resolveMotion; $motionTokenHint",
  ),
];
