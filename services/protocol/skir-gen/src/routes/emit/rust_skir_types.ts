import type { CodeGenerator, RecordLocation } from "skir-internal";

import { modulesInPathOrder } from "../../modules.js";

/**
 * Emits `impl crate::SkirType` for one record. The serializer is the generated inherent one. An
 * enum is unknown exactly when no declared variant matches, which leaves the generated unknown
 * variant; a struct is never unknown and keeps the default.
 */
function emitSkirType(location: RecordLocation, symbols: CodeGenerator.SymbolProvider): string[] {
  const { record } = location;
  const serializer = [
    "    fn serializer() -> crate::skir_client::Serializer<Self> {",
    "        Self::serializer()",
    "    }",
  ];
  const known = record.fields.map((field) => symbols.variant(location, field).reference);
  const isUnknown =
    record.recordType !== "enum"
      ? []
      : [
          "    fn is_unknown(&self) -> bool {",
          known.length === 0 ? "        true" : `        !matches!(self, ${known.join(" | ")})`,
          "    }",
        ];
  return [
    `impl crate::SkirType for ${symbols.record(location).reference} {`,
    ...serializer,
    ...isUnknown,
    "}",
  ];
}

/**
 * Emits the `crate::SkirType` implementation of every generated Skir record, nested and inline
 * method records included, in module path order and declaration order within a module. Generic
 * code such as the `SkirDb` storage wrapper and `SkirResponse` serialization reaches any record's
 * serializer and recognizes the unknown variant without per type tables.
 */
export function emitSkirTypes(
  input: CodeGenerator.Input<unknown>,
  symbols: CodeGenerator.SymbolProvider,
): string[] {
  return [
    "//! Generated `SkirType` implementations of every Skir record. Do not edit; regenerate with",
    "//! `bun run generate:protocol`.",
    ...modulesInPathOrder(input).flatMap((module) =>
      module.records.flatMap((location) => emitSkirType(location, symbols)),
    ),
  ];
}
