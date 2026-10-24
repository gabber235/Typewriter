import type { CodeGenerator, RecordLocation } from "skir-internal";

import { BLANK, type Lines } from "../../text.js";

import { skirRecord, type ResolvedOperation, type ResolvedOperations } from "../resolve.js";
import type { Signature } from "../signature.js";

/** Groups operations by the part of their id before the dot, in id order. */
export function operationGroups(
  operations: readonly ResolvedOperation[],
): ReadonlyArray<readonly [string, readonly ResolvedOperation[]]> {
  const groups = new Map<string, ResolvedOperation[]>();
  for (const operation of operations) {
    groups.set(operation.group, [...(groups.get(operation.group) ?? []), operation]);
  }
  return [...groups].sort(([left], [right]) => (left < right ? -1 : left > right ? 1 : 0));
}

/** The framework Skir record `reference` (`module.skir:Name`) that generated code names through a symbol provider. */
export function frameworkRecord(input: Pick<CodeGenerator.Input<unknown>, "modules">, reference: string): RecordLocation {
  return skirRecord(input, reference, () => new Error(`the operations generator needs Skir record ${reference}`));
}

/** What one named signature word declares. */
export type NamedKind =
  | { readonly kind: "enum"; readonly name: string }
  | { readonly kind: "record"; readonly name: string }
  | { readonly kind: "read_model"; readonly name: string; readonly location: RecordLocation };

export function namedKind(catalog: ResolvedOperations, name: string): NamedKind {
  if (catalog.enums.some((value) => value.name === name)) return { kind: "enum", name };
  if (catalog.records.some((value) => value.name === name)) return { kind: "record", name };
  const model = catalog.readModels.find((value) => value.name === name);
  if (model) return { kind: "read_model", name, location: model.location };
  throw new Error(`unresolved signature word ${name}`);
}

/** The bound of a type variable of `operation`. */
export function boundOf(operation: ResolvedOperation, variable: string): string {
  return operation.typeParameters.find((parameter) => parameter.name === variable)?.bound ?? "any";
}

/**
 * Wraps documentation text into lines of at most `width` characters, breaking only between words, so each emitter
 * adds its own comment markers.
 */
export function wrapWords(text: string, width: number): string[] {
  const lines: string[] = [];
  let line = "";
  for (const word of text.replace(/\s+/gu, " ").trim().split(" ")) {
    if (line.length > 0 && line.length + 1 + word.length > width) {
      lines.push(line);
      line = word;
    } else {
      line = line.length === 0 ? word : `${line} ${word}`;
    }
  }
  return [...lines, line];
}

/**
 * Whether kernels see type variable `name` of `operation` as an opaque DataValue: every bound except numeric and
 * integer, which kernels receive as numbers. Without an operation, as for record fields, the bound is any.
 */
export function valueVariable(operation: ResolvedOperation | undefined, name: string): boolean {
  const bound = operation ? boundOf(operation, name) : "any";
  return bound !== "numeric" && bound !== "integer";
}

/** The top level type of a parameter or result below partial, located and maybe. */
export function unwrapped(type: Signature): Signature {
  return type.kind === "partial" || type.kind === "located" || type.kind === "maybe" ? type.value : type;
}

/** SCREAMING_SNAKE_CASE of an operation id, such as TEXT_TRIM_START. */
export function constantName(id: string): string {
  return id.replace(".", "_").toUpperCase();
}

/**
 * Renders lines with a trailing newline, keeping a requested empty line between declarations even after an indented
 * expression body. Empty lines never directly follow an opening bracket or precede a closing one, and repeated
 * requests collapse to one.
 */
export function renderDeclarations(source: Lines): string {
  const output: string[] = [];
  let pending = false;
  for (const line of source) {
    if (line === BLANK || line === "") {
      pending = output.length > 0;
      continue;
    }
    const previous = output.at(-1) ?? "";
    if (pending && !/[{([]$/u.test(previous.trimEnd()) && !/^[})\]]/u.test(line.trimStart())) {
      output.push("");
    }
    pending = false;
    output.push(line);
  }
  return output.map((line) => line + "\n").join("");
}
