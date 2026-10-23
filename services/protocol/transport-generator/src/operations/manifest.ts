import { z } from "zod";

import { parseYamlManifest, type YamlManifest } from "../yaml.js";

const Name = z.string().regex(/^[a-z][a-z0-9_]*$/u, {
  error: (issue) => `invalid name ${JSON.stringify(issue.input)}`,
});

const OperationId = z.string().regex(/^[a-z][a-z0-9_]*\.[a-z][a-z0-9_]*$/u, {
  error: (issue) => `invalid operation id ${JSON.stringify(issue.input)}, expected group.name`,
});

const KotlinIdentifier = z.string().regex(/^[a-z][A-Za-z0-9]*$/u, {
  error: (issue) => `invalid DSL name ${JSON.stringify(issue.input)}`,
});

const TypeId = z.string().regex(/^[0-9a-f]{32}$/u, {
  error: (issue) => `invalid type id ${JSON.stringify(issue.input)}, expected 32 lowercase hex digits`,
});

const SkirReference = z.string().regex(/^[a-z0-9_/]+\.skir:[A-Za-z0-9_.]+$/u, {
  error: (issue) => `invalid Skir reference ${JSON.stringify(issue.input)}, expected module.skir:Declaration`,
});

/** A YAML flow entry such as `value: text` parses as a one entry map, so a slot is a one key record. */
const Slot = z
  .record(Name, z.string().min(1))
  .refine((entry) => Object.keys(entry).length === 1, "one name per entry");

export const Bound = z.enum(["any", "numeric", "integer", "sized", "ordered"]);
export type Bound = z.infer<typeof Bound>;

export const Capability = z.enum(["meter", "types", "resources"]);
export type Capability = z.infer<typeof Capability>;

export const ItemIds = z.enum(["source", "positional", "nested", "grouped", "prefixed"]);
export type ItemIds = z.infer<typeof ItemIds>;

export const Operator = z.enum(["plus", "minus", "times", "div", "rem", "get"]);
export type Operator = z.infer<typeof Operator>;

/** How the Kotlin DSL exposes an operation; `hand` means a hand written DSL function lowers to it. */
const Dsl = z.union([
  z.literal("hand"),
  z.strictObject({
    name: KotlinIdentifier.optional(),
    operator: Operator.optional(),
    infix: z.boolean().default(false),
    property: z.boolean().default(false),
    receiver: z.boolean().default(true),
  }),
]);

const Operation = z.strictObject({
  doc: z.string().min(1),
  profile: z.enum(["rule", "panel"]),
  dsl: Dsl.optional(),
  type_parameters: z.record(z.string().regex(/^[A-Z]$/u), Bound).default({}),
  parameters: z.array(Slot),
  uses: z.array(Capability).default([]),
  failures: z.array(Name).default([]),
  result: z.string().min(1),
  item_ids: ItemIds.optional(),
});

const Messages = z.record(Name, z.string().min(1));

const RawOperationsManifest = z.strictObject({
  unicode: z.string().regex(/^\d+\.\d+\.\d+$/u),
  enums: z.record(
    Name,
    z.strictObject({ type: TypeId, doc: z.string().min(1), cases: z.array(Name).min(1) }),
  ),
  records: z.record(
    Name,
    z.strictObject({ type: TypeId, doc: z.string().min(1), fields: z.array(Slot).min(1) }),
  ),
  read_models: z.record(Name, SkirReference),
  failures: Messages,
  evaluator_failures: Messages,
  check_failures: Messages,
  operations: z.record(OperationId, Operation),
});

export type RawOperationsManifest = z.infer<typeof RawOperationsManifest>;
export type RawOperation = z.infer<typeof Operation>;
export type RawDsl = z.infer<typeof Dsl>;

/**
 * Parses and admits the operations manifest's shape. Words inside signatures are checked later by
 * resolveOperations, which reports through the returned manifest's `error` so every message names
 * the YAML path and line.
 */
export function parseOperations(source: string, file: string): YamlManifest<RawOperationsManifest> {
  return parseYamlManifest(source, file, RawOperationsManifest);
}

/** The single name and value of a one entry slot record. */
export function slotEntry(slot: Record<string, string>): readonly [string, string] {
  const [entry] = Object.entries(slot);
  return entry!;
}
