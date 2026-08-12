import "package:freezed_annotation/freezed_annotation.dart";
import "package:typewriter_panel/typewriter_panel.dart";

part "icon_value.freezed.dart";

@freezed
sealed class IconValue with _$IconValue {
  @Assert("value != \"\"", "Iconify value must not be empty.")
  const factory IconValue.iconify(String value) = IconifyIconValue;

  @Assert("source != \"\"", "SVG source must not be empty.")
  const factory IconValue.svg(String source) = SvgIconValue;
}

extension IconValueValidation on IconValue {
  List<TypeDiagnostic> validate({DataPath path = DataPath.root}) =>
      switch (this) {
        IconifyIconValue(:final value) when !value.isValidIconifyValue => [
          TypeDiagnostic(
            code: TypeDiagnosticCode.invalidValue,
            message: "Iconify value must use the prefix:name format",
            path: path,
          ),
        ],
        SvgIconValue(:final source) when !source.isSanitizedSvg => [
          TypeDiagnostic(
            code: TypeDiagnosticCode.invalidValue,
            message: "SVG content is not sanitized",
            path: path,
          ),
        ],
        _ => const [],
      };

  PolymorphicValue get typedValue => switch (this) {
    IconifyIconValue(:final value) => PolymorphicValue(
      concreteType: standardTypeRefs.iconifyIcon,
      value: StringValue(value),
    ),
    SvgIconValue(:final source) => PolymorphicValue(
      concreteType: standardTypeRefs.svgIcon,
      value: StringValue(source),
    ),
  };
}

extension DataValueIcon on DataValue {
  IconValue? get iconValueOrNull => switch (this) {
    PolymorphicValue(concreteType: final type, value: StringValue(:final value))
        when type == standardTypeRefs.iconifyIcon =>
      IconValue.iconify(value),
    PolymorphicValue(concreteType: final type, value: StringValue(:final value))
        when type == standardTypeRefs.svgIcon =>
      IconValue.svg(value),
    _ => null,
  };
}

extension IconTextValidation on String {
  bool get isValidIconifyValue =>
      RegExp(r"^[a-z0-9\-]+:[a-z0-9\-]+$").hasMatch(this);

  bool get isSanitizedSvg {
    final source = trimLeft().toLowerCase();
    final hasSvgRoot = RegExp(r"^(?:<\?xml[^>]*>\s*)?<svg\b").hasMatch(source);
    final linkAttributes = RegExp(
      r'''(?:href|src)\s*=\s*["']([^"']*)["']''',
    ).allMatches(source).toList();
    final unsafeLink =
        RegExp(r"(?:href|src)\s*=").allMatches(source).length !=
            linkAttributes.length ||
        linkAttributes.any(
          (match) => !(match.group(1) ?? "").trimLeft().startsWith("#"),
        );
    final cssUrls = RegExp(
      r'''url\s*\(\s*["']?([^)'"\s]+)''',
    ).allMatches(source);
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
