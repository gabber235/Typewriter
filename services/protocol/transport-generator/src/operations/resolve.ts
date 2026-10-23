import type { CodeGenerator, RecordLocation } from "skir-internal";

import type { YamlManifest } from "../yaml.js";
import {
  slotEntry,
  type Bound,
  type Capability,
  type ItemIds,
  type Operator,
  type RawOperation,
  type RawOperationsManifest,
} from "./manifest.js";
import { parseParameter, parseSignature, signatureText, type ParsedParameter, type Signature } from "./signature.js";

/** A manifest enum: a catalog enumeration of the core library, generated for both hosts. */
export interface ResolvedEnum {
  readonly name: string;
  readonly typeId: string;
  readonly doc: string;
  readonly cases: readonly string[];
}

/** A manifest record: a catalog record of the core library that operations return. */
export interface ResolvedRecord {
  readonly name: string;
  readonly typeId: string;
  readonly doc: string;
  readonly fields: ReadonlyArray<{ readonly name: string; readonly type: Signature }>;
}

/** A framework read model operations return, a Skir record encoded through canonical read models. */
export interface ResolvedReadModel {
  readonly name: string;
  readonly reference: string;
  readonly location: RecordLocation;
}

/** A declared failure; its id is the manifest key. */
export interface ResolvedFailure {
  readonly id: string;
  readonly message: string;
}

/**
 * How the call rule passes one argument. value arguments must be free of unfilled entries; partial
 * and located ones may contain them; each lambdas are evaluated for every item before the kernel
 * runs; step, comparator and apply lambdas are driven by the kernel.
 */
export type ParameterKind = "value" | "partial" | "located" | "each" | "step" | "comparator" | "apply";

export interface ResolvedParameter extends ParsedParameter {
  readonly kind: ParameterKind;
}

export interface ResolvedTypeParameter {
  readonly name: string;
  readonly bound: Bound;
  /** Not inferable from the arguments, so calls carry it as a type argument, in declaration order. */
  readonly explicit: boolean;
}

export interface ResolvedDsl {
  readonly name: string;
  readonly operator?: Operator;
  readonly infix: boolean;
  readonly property: boolean;
  readonly receiver: boolean;
}

export interface ResolvedOperation {
  readonly id: string;
  /** The part before the dot; one kernel interface per group. */
  readonly group: string;
  /** The part after the dot. */
  readonly name: string;
  readonly doc: string;
  readonly profile: "rule" | "panel";
  readonly dsl: ResolvedDsl | "hand";
  readonly typeParameters: readonly ResolvedTypeParameter[];
  readonly parameters: readonly ResolvedParameter[];
  readonly result: Signature;
  readonly failures: readonly string[];
  readonly uses: readonly Capability[];
  readonly itemIds?: ItemIds;
}

export interface ResolvedOperations {
  readonly unicode: string;
  readonly enums: readonly ResolvedEnum[];
  readonly records: readonly ResolvedRecord[];
  readonly readModels: readonly ResolvedReadModel[];
  readonly failures: readonly ResolvedFailure[];
  readonly evaluatorFailures: readonly ResolvedFailure[];
  readonly checkFailures: readonly ResolvedFailure[];
  /** Sorted by id, so generated output is stable. */
  readonly operations: readonly ResolvedOperation[];
}

const LAMBDA_KINDS = new Set(["each", "step", "comparator", "apply"]);
const PARAMETER_WRAPPERS = new Set(["partial", "located"]);

/**
 * Resolves every signature word of the manifest. Rejects unknown words and names, misplaced
 * wrappers (maybe outside a result, lambdas or partial outside a parameter's top level, variadic
 * parameters before the last), undeclared type parameters, defaults on non enum
 * parameters, undeclared failures, resources outside the panel profile, item identities missing on
 * or given to the wrong results, and read models that name no Skir record. Every error names the
 * YAML path and line.
 */
export function resolveOperations(
  manifest: YamlManifest<RawOperationsManifest>,
  input: Pick<CodeGenerator.Input<unknown>, "modules">,
): ResolvedOperations {
  const { data, error } = manifest;
  const enums = new Map(
    Object.entries(data.enums).map(([name, value]) => [
      name,
      { name, typeId: value.type, doc: value.doc, cases: value.cases },
    ]),
  );
  const readModels = new Map(
    Object.entries(data.read_models).map(([name, reference]) => [
      name,
      { name, reference, location: resolveRecord(input, reference, () => error(["read_models", name], `unknown Skir record ${reference}`)) },
    ]),
  );
  const recordNames = new Set(Object.keys(data.records));
  const namedKinds = (name: string) =>
    enums.has(name) ? "enum" : recordNames.has(name) ? "record" : readModels.has(name) ? "read_model" : undefined;
  for (const name of [...enums.keys(), ...recordNames, ...readModels.keys()]) {
    const owners = [enums.has(name), recordNames.has(name), readModels.has(name)].filter(Boolean);
    if (owners.length > 1) {
      throw error([], `${name} is declared more than once among enums, records and read models`);
    }
  }

  const records = Object.entries(data.records).map(([name, value]) => ({
    name,
    typeId: value.type,
    doc: value.doc,
    fields: value.fields.map((slot, index) => {
      const [field, word] = slotEntry(slot);
      const at = ["records", name, "fields", index];
      const type = parse(() => parseSignature(word), at, error);
      requireRecordField(type, namedKinds, (message) => error(at, message));
      return { name: field, type };
    }),
  }));

  const typeIds = new Map<string, string>();
  for (const [name, typeId] of [...enums.values(), ...records].map((value) => [value.name, value.typeId] as const)) {
    const previous = typeIds.get(typeId);
    if (previous) {
      throw error([], `${name} reuses the type id of ${previous}`);
    }
    typeIds.set(typeId, name);
  }

  const failures = new Set(Object.keys(data.failures));
  const operations = Object.entries(data.operations)
    .map(([id, raw]) => resolveOperation(id, raw, { enums, namedKinds, failures }, (path, message) => error(["operations", id, ...path], message)))
    .sort((left, right) => (left.id < right.id ? -1 : left.id > right.id ? 1 : 0));

  const raised = new Set(operations.flatMap((operation) => operation.failures));
  for (const failure of failures) {
    if (!raised.has(failure)) {
      throw error(["failures", failure], `no operation declares failure ${failure}`);
    }
  }

  const messages = (entries: Record<string, string>) =>
    Object.entries(entries).map(([id, message]) => ({ id, message }));
  return {
    unicode: data.unicode,
    enums: [...enums.values()],
    records,
    readModels: [...readModels.values()],
    failures: messages(data.failures),
    evaluatorFailures: messages(data.evaluator_failures),
    checkFailures: messages(data.check_failures),
    operations,
  };
}

interface Names {
  readonly enums: ReadonlyMap<string, ResolvedEnum>;
  readonly namedKinds: (name: string) => "enum" | "record" | "read_model" | undefined;
  readonly failures: ReadonlySet<string>;
}

type ErrorAt = (path: ReadonlyArray<string | number>, message: string) => Error;

function resolveOperation(id: string, raw: RawOperation, names: Names, error: ErrorAt): ResolvedOperation {
  const [group = "", name = ""] = id.split(".");
  const variables = new Map(Object.entries(raw.type_parameters));
  const used = new Set<string>();
  const inferable = new Set<string>();

  const parameters = raw.parameters.map((slot, index): ResolvedParameter => {
    const [parameterName, word] = slotEntry(slot);
    const at = ["parameters", index, parameterName];
    const parsed = parse(() => parseParameter(parameterName, word), at, error);
    if (parsed.variadic && index !== raw.parameters.length - 1) {
      throw error(at, "only the last parameter can be variadic");
    }
    const kind = parameterKind(parsed.type);
    if (parsed.variadic && kind !== "value") {
      throw error(at, "a variadic parameter takes plain values");
    }
    const inner = kind === "partial" || kind === "located" ? (parsed.type as { value: Signature }).value : parsed.type;
    checkWords(inner, "parameter", variables, names, used, (message) => error(at, message));
    collectInferable(parsed.type, inferable);
    if (parsed.defaultCase !== undefined) {
      const enumeration = parsed.type.kind === "named" ? names.enums.get(parsed.type.name) : undefined;
      if (!enumeration) {
        throw error(at, "only enum parameters can have a default");
      }
      if (!enumeration.cases.includes(parsed.defaultCase)) {
        throw error(at, `${enumeration.name} has no case ${parsed.defaultCase}`);
      }
    }
    return { ...parsed, kind };
  });
  const parameterNames = new Set(parameters.map((parameter) => parameter.name));
  if (parameterNames.size !== parameters.length) {
    throw error(["parameters"], "parameter names must be distinct");
  }
  for (const parameter of parameters) {
    if (parameter.type.kind === "field_type" && !parameterNames.has(parameter.type.field)) {
      throw error(["parameters"], `field_type names no parameter ${parameter.type.field}`);
    }
  }

  const resultAt = ["result"];
  const result = parse(() => parseSignature(raw.result), resultAt, error);
  const resultInner = result.kind === "maybe" ? result.value : result;
  checkWords(resultInner, "result", variables, names, used, (message) => error(resultAt, message));

  for (const failure of raw.failures) {
    if (!names.failures.has(failure)) {
      throw error(["failures"], `undeclared failure ${failure}`);
    }
  }
  if (raw.uses.includes("resources") && raw.profile !== "panel") {
    throw error(["uses"], "resources are only available to profile panel operations");
  }

  const collection = resultInner.kind === "list" || resultInner.kind === "set" || resultInner.kind === "map";
  if (collection && raw.item_ids === undefined) {
    throw error(resultAt, `a ${resultInner.kind} result declares item_ids`);
  }
  if (!collection && raw.item_ids !== undefined) {
    throw error(["item_ids"], "only list, set and map results declare item_ids");
  }
  if (collection && resultInner.kind !== "map" && concrete(resultInner.value) && raw.item_ids !== "positional") {
    throw error(["item_ids"], "a list of concrete values has positional item_ids");
  }

  const dsl = resolveDsl(name, raw, parameters, error);
  return {
    id,
    group,
    name,
    doc: raw.doc,
    profile: raw.profile,
    dsl,
    typeParameters: [...variables].map(([variable, bound]) => ({
      name: variable,
      bound,
      explicit: !inferable.has(variable),
    })),
    parameters,
    result,
    failures: raw.failures,
    uses: raw.uses,
    ...(raw.item_ids === undefined ? {} : { itemIds: raw.item_ids }),
  };
}

function resolveDsl(
  name: string,
  raw: RawOperation,
  parameters: readonly ResolvedParameter[],
  error: ErrorAt,
): ResolvedDsl | "hand" {
  if (raw.dsl === "hand") return "hand";
  const dsl = raw.dsl ?? { infix: false, property: false, receiver: true };
  if (dsl.name !== undefined && dsl.operator !== undefined) {
    throw error(["dsl"], "a DSL entry has a name or an operator, not both");
  }
  const receiverCount = dsl.receiver ? 1 : 0;
  const explicitValues = parameters.length - receiverCount;
  if (dsl.receiver && (parameters.length === 0 || parameters[0]!.kind !== "value" && parameters[0]!.kind !== "partial" && parameters[0]!.kind !== "located")) {
    throw error(["dsl"], "the receiver is the first parameter, a value");
  }
  if (dsl.receiver && parameters[0]!.variadic) {
    throw error(["dsl"], "a variadic parameter cannot be the receiver");
  }
  if (dsl.property && explicitValues !== 0) {
    throw error(["dsl"], "a property takes only its receiver");
  }
  if (dsl.infix && explicitValues !== 1 && !(explicitValues === 2 && parameters.at(-1)!.variadic)) {
    throw error(["dsl"], "an infix function takes its receiver and one argument");
  }
  return {
    name: dsl.name ?? dsl.operator ?? lowerCamelName(name),
    ...(dsl.operator === undefined ? {} : { operator: dsl.operator }),
    infix: dsl.infix,
    property: dsl.property,
    receiver: dsl.receiver,
  };
}

function lowerCamelName(value: string): string {
  return value.replace(/_([a-z0-9])/gu, (_, letter: string) => letter.toUpperCase());
}

function parameterKind(type: Signature): ParameterKind {
  if (LAMBDA_KINDS.has(type.kind)) return type.kind as ParameterKind;
  if (PARAMETER_WRAPPERS.has(type.kind)) return type.kind as ParameterKind;
  return "value";
}

/** Checks words below the top level of a parameter or result, recording the type variables it uses. */
function checkWords(
  type: Signature,
  position: "parameter" | "result",
  variables: ReadonlyMap<string, Bound>,
  names: Names,
  used: Set<string>,
  fail: (message: string) => Error,
  top = true,
): void {
  const nested = (value: Signature) => checkWords(value, position, variables, names, used, fail, false);
  switch (type.kind) {
    case "scalar":
      return;
    case "named":
      if (!names.namedKinds(type.name)) {
        throw fail(`unknown signature word ${type.name}`);
      }
      return;
    case "variable":
      if (!variables.has(type.name)) {
        throw fail(`undeclared type parameter ${type.name}`);
      }
      used.add(type.name);
      return;
    case "nullable":
      if (type.value.kind === "nullable") throw fail("a type is nullable once");
      return nested(type.value);
    case "list":
    case "set":
    case "items":
      return nested(type.value);
    case "link":
      return nested(type.value);
    case "map":
    case "entry":
      nested(type.key);
      return nested(type.value);
    case "each":
    case "apply":
      if (!top || position !== "parameter") throw fail(`${type.kind} is a parameter's top level word`);
      nested(type.input);
      return nested(type.output);
    case "step":
      if (!top || position !== "parameter") throw fail("step is a parameter's top level word");
      nested(type.accumulator);
      return nested(type.item);
    case "comparator":
      if (!top || position !== "parameter") throw fail("comparator is a parameter's top level word");
      return nested(type.value);
    case "field_of":
    case "representation":
      if (type.value.kind !== "variable") throw fail(`${type.kind} names a type parameter`);
      return nested(type.value);
    case "field_type":
      if (type.record.kind !== "variable") throw fail("field_type names a type parameter");
      return nested(type.record);
    case "partial":
    case "located":
      throw fail(`${type.kind} is a parameter's top level word`);
    case "maybe":
      throw fail("maybe is a result's top level word");
  }
}

/**
 * Type variables that a call's arguments determine, lambda results included; representation<X>
 * and field_type do not.
 */
function collectInferable(type: Signature, inferable: Set<string>): void {
  switch (type.kind) {
    case "variable":
      inferable.add(type.name);
      return;
    case "scalar":
    case "named":
    case "representation":
    case "field_type":
      return;
    case "map":
    case "entry":
      collectInferable(type.key, inferable);
      return collectInferable(type.value, inferable);
    case "each":
    case "apply":
      collectInferable(type.input, inferable);
      return collectInferable(type.output, inferable);
    case "step":
      collectInferable(type.accumulator, inferable);
      return collectInferable(type.item, inferable);
    default:
      return collectInferable(type.value, inferable);
  }
}

function requireRecordField(
  type: Signature,
  namedKinds: Names["namedKinds"],
  fail: (message: string) => Error,
): void {
  switch (type.kind) {
    case "scalar":
      return;
    case "named":
      if (namedKinds(type.name) !== "enum") throw fail(`record fields use scalars, enums and lists, not ${type.name}`);
      return;
    case "nullable":
    case "list":
      return requireRecordField(type.value, namedKinds, fail);
    default:
      throw fail(`record fields use scalars, enums and lists, not ${signatureText(type)}`);
  }
}

/** Whether a list item type has a fixed kernel representation rather than an opaque value. */
export function concrete(type: Signature): boolean {
  switch (type.kind) {
    case "scalar":
    case "named":
      return true;
    case "nullable":
      return concrete(type.value);
    default:
      return false;
  }
}

function resolveRecord(
  input: Pick<CodeGenerator.Input<unknown>, "modules">,
  reference: string,
  fail: () => Error,
): RecordLocation {
  const separator = reference.indexOf(":");
  const module = reference.slice(0, separator);
  const path = reference.slice(separator + 1);
  const matches =
    input.modules
      .find((candidate) => candidate.path === module)
      ?.records.filter((location) => location.recordAncestors.map((record) => record.name.text).join(".") === path) ?? [];
  if (matches.length !== 1) {
    throw fail();
  }
  return matches[0]!;
}

function parse<T>(run: () => T, at: ReadonlyArray<string | number>, error: ErrorAt): T {
  try {
    return run();
  } catch (failure) {
    throw error(at, (failure as Error).message);
  }
}
