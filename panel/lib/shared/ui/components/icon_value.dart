import "package:typewriter_panel/typewriter_panel.dart";

part "icon_value.freezed.dart";

/// Presentation safe icon input used by controls.
///
/// Iconify names and SVG source have different validation rules. SVG
/// validation rejects active content and external references before rendering.
@freezed
sealed class IconValue with _$IconValue {
  @Assert("value != \"\"", "Iconify value must not be empty.")
  const factory IconValue.iconify(String value) = IconifyIconValue;

  @Assert("source != \"\"", "SVG source must not be empty.")
  const factory IconValue.svg(String source) = SvgIconValue;

  factory IconValue.from(String value) {
    if (value.isValidIconifyValue) return IconifyIconValue(value);
    return SvgIconValue(value);
  }
}

/// Syntax and safety checks shared by icon constructors and validation.
extension IconTextValidation on String {
  bool get isValidIconifyValue =>
      RegExp(r"^[a-z0-9\-]+:[a-z0-9\-]+$").hasMatch(this);

  bool get isSanitizedSvg {
    final source = trimLeft().toLowerCase();
    final hasSvgRoot = RegExp(r"^(?:<\?xml[^>]*>\s*)?<svg\b").hasMatch(source);
    final linkAttributes = RegExp(r'''(?:href|src)\s*=\s*["']([^"']*)["']''')
        .allMatches(source)
        .toList();
    final unsafeLink =
        RegExp(r"(?:href|src)\s*=").allMatches(source).length !=
            linkAttributes.length ||
        linkAttributes.any(
          (match) => !(match.group(1) ?? "").trimLeft().startsWith("#"),
        );
    final cssUrls = RegExp(r'''url\s*\(\s*["']?([^)'"\s]+)''')
        .allMatches(source);
    return hasSvgRoot &&
        !source.contains("<script") &&
        !source.contains("<iframe") &&
        !source.contains("<object") &&
        !source.contains("<embed") &&
        !source.contains("<foreignobject") &&
        !RegExp(r"\son[a-z]+\s*=").hasMatch(source) &&
        !source.contains("javascript:") &&
        !source.contains("@import") &&
        !unsafeLink &&
        !cssUrls.any(
          (match) => !(match.group(1) ?? "").trimLeft().startsWith("#"),
        );
  }
}
