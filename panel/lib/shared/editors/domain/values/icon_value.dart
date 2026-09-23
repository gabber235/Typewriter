import "package:freezed_annotation/freezed_annotation.dart";
import "package:typewriter_panel/typewriter_panel.dart";

part "icon_value.freezed.dart";

/// Presentation safe icon input used by editor catalogs and controls.
///
/// Icons are kept separate from [DataValue] while being convertible to the
/// nominal standard icon types. Iconify names and SVG source have different
/// validation rules, and SVG validation rejects active content and external
/// references before rendering.
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

/// Validates icon content at the boundary before it becomes a typed value.
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
      value: RecordValue({"value": StringValue(value)}),
    ),
    SvgIconValue(:final source) => PolymorphicValue(
      concreteType: standardTypeRefs.svgIcon,
      value: RecordValue({"source": StringValue(source)}),
    ),
  };
}

/// Recovers the editor icon model from its nominal [DataValue] form.
///
/// Values with another concrete type or representation are not icons for this
/// boundary and return `null` rather than being coerced.
extension DataValueIcon on DataValue {
  IconValue? get iconValueOrNull => switch (this) {
    PolymorphicValue(
      concreteType: final type,
      value: RecordValue(fields: {"value": StringValue(:final value)}),
    )
        when type == standardTypeRefs.iconifyIcon =>
      IconValue.iconify(value),
    PolymorphicValue(
      concreteType: final type,
      value: RecordValue(fields: {"source": StringValue(:final value)}),
    )
        when type == standardTypeRefs.svgIcon =>
      IconValue.svg(value),
    _ => null,
  };

  /// Resolves a concrete icon representation when its expression carries the
  /// nominal concrete type, as in a search result or selected-value preview.
  IconValue? iconValueFor(TypeExpression type) => switch ((type, this)) {
    (
      NamedType(reference: final reference),
      RecordValue(fields: {"value": StringValue(:final value)}),
    )
        when reference == standardTypeRefs.iconifyIcon &&
            value.isValidIconifyValue =>
      IconValue.iconify(value),
    (
      NamedType(reference: final reference),
      RecordValue(fields: {"source": StringValue(:final value)}),
    )
        when reference == standardTypeRefs.svgIcon && value.isSanitizedSvg =>
      IconValue.svg(value),
    _ => iconValueOrNull,
  };
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
