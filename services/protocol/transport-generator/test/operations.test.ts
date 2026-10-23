import { describe, expect, test } from "bun:test";
import { readFileSync } from "node:fs";

import { parse as parseYaml } from "yaml";

import { symbolProviders } from "../src/symbols.js";
import { emitDartOperations } from "../src/operations/emit/dart.js";
import { emitKotlinOperations } from "../src/operations/emit/kotlin.js";
import { parseOperations } from "../src/operations/manifest.js";
import { resolveOperations, type ResolvedOperations } from "../src/operations/resolve.js";
import { unicodeTables } from "../src/operations/unicode.js";
import { committedOperations, loadSkirInput, OPERATIONS_CONFIG, repository } from "./support.js";

/** The smallest manifest around the given operation entries, for admission checks. */
function manifest(operations: string, extra = ""): string {
  return `unicode: 17.0.0
enums:
  rounding_mode: { type: 467745c1c9534484864d2d63c72c7aae, doc: Modes., cases: [floor, ceiling] }
records:
  regex_match: { type: 02497871dba44c569055b535aa0644c9, doc: A match., fields: [text: text] }
read_models:
  type_selection: editor/v1/type_catalog.skir:TypeSelection
failures:
  sample_failure: A sample failure.
evaluator_failures:
  ill_typed_argument: Wrong kind.
check_failures:
  unknown_operation: Unknown.
${extra}operations:
${operations}`;
}

const SAMPLE_FAILURE_USER = `  text.sample_user:
    doc: Uses the sample failure.
    profile: rule
    parameters: [value: text]
    failures: [sample_failure]
    result: text
`;

async function resolve(operations: string, extra = ""): Promise<ResolvedOperations> {
  const input = await loadSkirInput();
  return resolveOperations(parseOperations(manifest(operations + SAMPLE_FAILURE_USER, extra), "operations.yaml"), input);
}

const operation = (id: string, body: string) => `  ${id}:\n    doc: A sample.\n    profile: rule\n${body}`;

describe("operations manifest admission", () => {
  test("resolves the committed catalog: every manifest operation, sorted, with its profile", async () => {
    const raw = parseYaml(manifestText()) as { operations: Record<string, { profile: string }> };
    const resolved = resolveOperations(committedOperations(), await loadSkirInput());
    expect(resolved.operations.map((value) => value.id)).toEqual(Object.keys(raw.operations).sort());
    for (const value of resolved.operations) {
      expect(value.profile).toBe(raw.operations[value.id]!.profile as "rule" | "panel");
    }
  });

  test("infers type parameters from arguments and lambda results; others are explicit type arguments", async () => {
    const resolved = await resolve(
      operation("value.sample_let", "    type_parameters: { T: any, R: any }\n    parameters:\n      - value: T\n      - body: apply<T, R>\n    result: R\n") +
        operation("value.sample_wrap", "    type_parameters: { X: any }\n    parameters: [payload: representation<X>]\n    result: X\n"),
    );
    const explicit = (id: string) =>
      resolved.operations.find((value) => value.id === id)!.typeParameters.filter((value) => value.explicit).map((value) => value.name);
    expect(explicit("value.sample_let")).toEqual([]);
    expect(explicit("value.sample_wrap")).toEqual(["X"]);
  });

  const rejections: ReadonlyArray<readonly [string, string, RegExp]> = [
    ["unknown words", operation("text.bad", "    parameters: [value: texts]\n    result: text\n"), /operations\.text\.bad\.parameters\[0\]\.value: unknown signature word texts/],
    ["maybe in a parameter", operation("text.bad", "    parameters: [value: maybe<text>]\n    result: text\n"), /maybe is a result's top level word/],
    ["nested lambdas", operation("list.bad", "    type_parameters: { T: any }\n    parameters:\n      - source: list<each<T, T>>\n    result: boolean\n"), /each is a parameter's top level word/],
    ["variadic parameters before the last", operation("number.bad", "    type_parameters: { N: numeric }\n    parameters: [first: N..., second: N]\n    result: N\n"), /only the last parameter can be variadic/],
    ["defaults on non enum parameters", operation("text.bad", "    parameters: [value: text = floor]\n    result: text\n"), /only enum parameters can have a default/],
    ["defaults naming no case", operation("number.bad", "    parameters: [mode: rounding_mode = nearest]\n    result: boolean\n"), /rounding_mode has no case nearest/],
    ["undeclared type parameters", operation("value.bad", "    parameters: [value: T]\n    result: boolean\n"), /undeclared type parameter T/],
    ["undeclared failures", operation("text.bad", "    parameters: [value: text]\n    failures: [missing_failure]\n    result: text\n"), /undeclared failure missing_failure/],
    ["resources outside the panel profile", operation("resource.bad", "    parameters: [value: resource_id]\n    uses: [resources]\n    result: boolean\n"), /resources are only available to profile panel operations/],
    ["list results without item identities", operation("text.bad", "    parameters: [value: text]\n    result: list<text>\n"), /a list result declares item_ids/],
    ["concrete lists named by their source", operation("text.bad", "    parameters: [value: text]\n    result: list<text>\n    item_ids: source\n"), /a list of concrete values has positional item_ids/],
    ["item identities on scalar results", operation("text.bad", "    parameters: [value: text]\n    result: text\n    item_ids: source\n"), /only list, set and map results declare item_ids/],
    ["properties with arguments", operation("text.bad", "    dsl: { property: true }\n    parameters: [value: text, other: text]\n    result: text\n"), /a property takes only its receiver/],
  ];
  for (const [name, source, message] of rejections) {
    test(`rejects ${name} with the YAML path and line`, async () => {
      await expect(resolve(source)).rejects.toThrow(message);
      await expect(resolve(source)).rejects.toThrow(/operations\.yaml:\d+:\d+: /);
    });
  }

  test("rejects failures no operation declares", async () => {
    const input = await loadSkirInput();
    expect(() => resolveOperations(parseOperations(manifest("  {}\n").replace("operations:\n  {}", "operations: {}"), "operations.yaml"), input)).toThrow(
      /failures\.sample_failure: no operation declares failure sample_failure/,
    );
  });

  test("rejects read models that name no Skir record", async () => {
    const source = manifest(SAMPLE_FAILURE_USER).replace("type_catalog.skir:TypeSelection", "type_catalog.skir:Missing");
    await expect(loadSkirInput().then((input) => resolveOperations(parseOperations(source, "operations.yaml"), input))).rejects.toThrow(
      /read_models\.type_selection: unknown Skir record/,
    );
  });

  test("rejects unknown fields with their path", () => {
    expect(() => parseOperations(manifest(SAMPLE_FAILURE_USER).replace("profile: rule", "profile: rule\n    color: red"), "operations.yaml")).toThrow(
      /operations\.text\.sample_user: Unrecognized key/,
    );
  });
});

describe("emitted operation catalog", async () => {
  const input = await loadSkirInput({ dartImportUriPrefix: OPERATIONS_CONFIG.dartImportUriPrefix });
  const catalog = resolveOperations(committedOperations(), input);
  const tables = unicodeTables(catalog.unicode, repository(OPERATIONS_CONFIG.unicodeData));
  const symbols = symbolProviders(input);
  const kotlin = new Map(emitKotlinOperations(catalog, tables, symbols.kotlin, input).map((file) => [file.path, file.code]));
  const dart = new Map(
    emitDartOperations(catalog, tables, symbols.dart, input, OPERATIONS_CONFIG.dartRuntimeImport!).map((file) => [file.path, file.code]),
  );
  const kotlinFile = (name: string) => [...kotlin].find(([path]) => path.endsWith(name))![1];

  test("Realm's kernels and dispatch name exactly the rule profile operations", () => {
    const kernels = kotlinFile("RuleKernels.kt");
    for (const value of catalog.operations) {
      expect(kernels.includes(`"${value.id}" ->`)).toBe(value.profile === "rule");
    }
  });

  test("the panel's dispatch and declarations name every operation", () => {
    const code = dart.get("portable_operations.dart")!;
    for (const value of catalog.operations) {
      expect(code).toContain(`"${value.id}" => const PortableOperationDeclaration(`);
      expect(code.split(`"${value.id}" => `).length - 1).toBe(2);
    }
  });

  test("every declared operation and failure has a Kotlin constant", () => {
    const declarations = kotlinFile("PortableOperationCatalog.kt");
    const failures = kotlinFile("PortableFailures.kt");
    for (const value of catalog.operations) {
      expect(declarations).toContain(`OperationId(value = "${value.id}")`);
    }
    for (const failure of [...catalog.failures, ...catalog.evaluatorFailures, ...catalog.checkFailures]) {
      expect(failures).toContain(`FailureId(value = "${failure.id}")`);
    }
  });

  test("numeric operations reach every Kotlin number type, unsigned ones included", () => {
    const dsl = kotlinFile("PortableOperationDsl.kt");
    for (const suffix of ["", "UByte", "UShort", "UInt", "ULong"]) {
      expect(dsl).toContain(`@JvmName("numberAdd${suffix}")`);
    }
  });

  test("every JVM name in the DSL is unique", () => {
    const names = [...kotlinFile("PortableOperationDsl.kt").matchAll(/@(?:get:)?JvmName\("([^"]+)"\)/g)].map((match) => match[1]);
    expect(new Set(names).size).toBe(names.length);
  });

  test("emits the pinned Unicode release's tables for both hosts", () => {
    expect(kotlinFile("PortableUnicodeTables.kt")).toContain(`Unicode ${catalog.unicode} release`);
    expect(dart.get("portable_unicode_tables.dart")).toContain(`Unicode ${catalog.unicode} release`);
  });
});

function manifestText(): string {
  return readFileSync(repository(OPERATIONS_CONFIG.manifest), "utf8");
}
