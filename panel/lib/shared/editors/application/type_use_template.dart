import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

/// The type template that declares a binding of exactly this type use.
extension PortableTypeUseTemplate on skir.TypeUse {
  skir.TypeTemplate get portableTemplate => switch (this) {
    skir.TypeUse_scalarWrapper(:final value) => skir.TypeTemplate.wrapScalar(
      value,
    ),
    skir.TypeUse_nullableWrapper(:final value) =>
      skir.TypeTemplate.createNullable(value: value.value.portableTemplate),
    skir.TypeUse_namedWrapper(:final value) => skir.TypeTemplate.createNamed(
      definition: value.definition,
      arguments: value.arguments.map((argument) => argument.portableTemplate),
    ),
    skir.TypeUse_unknown() => skir.TypeTemplate.unknown,
  };
}
