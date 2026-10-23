import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

/// The panel's regular expression operations over the portable subset,
/// matched by code point with the engine in `portable_regex.dart`. Every
/// matching step charges the meter.
final class PanelRegexKernel implements skir.RegexKernel {
  const PanelRegexKernel();

  @override
  skir.RegexMatch? find(
    String value,
    String pattern,
    skir.PortableMeter meter,
  ) {
    final matcher = _compile(value, pattern);
    final match = matcher.find(value, () => meter.steps(1));
    return match == null ? null : _match(value, match, matcher.groupCount);
  }

  @override
  List<skir.RegexMatch> findAll(
    String value,
    String pattern,
    skir.PortableMeter meter,
  ) {
    final matcher = _compile(value, pattern);
    return [
      for (final match in matcher.findAll(value, () => meter.steps(1)))
        _match(value, match, matcher.groupCount),
    ];
  }

  /// The replacement is parsed before matching, so a malformed one fails
  /// even when nothing matches.
  @override
  String replace(
    String value,
    String pattern,
    String replacement,
    skir.PortableMeter meter,
  ) {
    final matcher = _compile(value, pattern);
    final PortableRegexReplacement template;
    try {
      template = PortableRegexReplacement.parse(
        replacement,
        matcher.groupCount,
      );
    } on PortableRegexCompileFailure catch (failure) {
      throw skir.PortableOperationFailure(
        skir.PortableFailures.invalidRegex,
        failure.message,
      );
    }
    return matcher.replace(value, template, () => meter.steps(1));
  }
}

/// Pattern and input limits, in UTF-16 code units as Kotlin counts them.
const _maximumPatternLength = 512;
const _maximumInputLength = 16384;

PortableRegexMatcher _compile(String value, String pattern) {
  if (pattern.length > _maximumPatternLength ||
      value.length > _maximumInputLength) {
    throw skir.PortableOperationFailure(skir.PortableFailures.regexLimit);
  }
  final normalized = switch (pattern.normalizePortableRegex()) {
    PortableRegexReady(:final pattern) => pattern,
    PortableRegexInvalid(:final reason) ||
    PortableRegexUnsupported(
      :final reason,
    ) => throw skir.PortableOperationFailure(
      skir.PortableFailures.invalidRegex,
      reason,
    ),
  };
  try {
    return PortableRegexMatcher.compile(normalized);
  } on PortableRegexCompileFailure catch (failure) {
    throw skir.PortableOperationFailure(
      skir.PortableFailures.invalidRegex,
      failure.message,
    );
  }
}

skir.RegexMatch _match(String value, PortableRegexMatch match, int groups) =>
    skir.RegexMatch(
      text: match.group(value, 0)!,
      start: match.start,
      end: match.end,
      groups: [
        for (var group = 1; group <= groups; group++) match.group(value, group),
      ],
    );
