import { describe, expect, test } from "bun:test";

import type { CodeGenerator, RecordLocation } from "skir-internal";

import type { ResolvedRoute } from "../src/routes/resolve.js";
import { LANGUAGE_GENERATORS, symbolProviders } from "../src/symbols.js";
import { Config } from "../src/config.js";
import { OperationsConfig } from "../src/operations/index.js";
import { committedRoutes, DART_PREFIX, generatorConfig, SKIR_GENERATORS } from "./support.js";

/**
 * The files of one Skir language generator for the same parsed modules, generated with the config
 * skir.yml gives it, so the providers are checked against the output `skir gen` writes.
 */
function generated<C>(generator: CodeGenerator<C>, input: CodeGenerator.Input<unknown>): Map<string, string> {
  const config = generator.configType.parse(generatorConfig(generator.id));
  return new Map(generator.generateCode({ ...input, config }).files.map((file) => [file.path, file.code]));
}

const { kotlin: KOTLIN, dart: DART, rust: RUST } = LANGUAGE_GENERATORS;

function methods(routes: readonly ResolvedRoute[]) {
  return routes.flatMap(({ flow }) =>
    flow.kind === "event" ? [] : [flow.method],
  );
}

function records(routes: readonly ResolvedRoute[]): RecordLocation[] {
  return routes.flatMap(({ flow }) => {
    switch (flow.kind) {
      case "unary":
      case "scatter":
        return [flow.method.request, flow.method.response];
      case "watch":
        return [flow.method.request, flow.method.response, flow.updates.payload];
      case "event":
        return [flow.payload];
    }
  });
}

const last = (reference: string, separator: string) => reference.slice(reference.lastIndexOf(separator) + separator.length);

describe("skir.yml configures the generators the providers assume", () => {
  test("every transport target reads one manifest with a valid config", () => {
    const targets = SKIR_GENERATORS.filter(
      (generator) => generator.mod.startsWith("typewriter-skir-gen/routes/"),
    );
    expect(targets.map((generator) => generator.mod).sort()).toEqual([
      "typewriter-skir-gen/routes/dart",
      "typewriter-skir-gen/routes/kotlin",
      "typewriter-skir-gen/routes/rust",
    ]);
    const configs = targets.map((generator) => Config.parse(generator.config));
    expect(new Set(configs.map((config) => config.manifest)).size).toBe(1);
  });

  test("every operations target reads one manifest with a valid config", () => {
    const targets = SKIR_GENERATORS.filter((generator) => generator.mod.startsWith("typewriter-skir-gen/operations/"));
    expect(targets.map((generator) => generator.mod).sort()).toEqual([
      "typewriter-skir-gen/operations/dart",
      "typewriter-skir-gen/operations/kotlin",
    ]);
    const configs = targets.map((generator) => OperationsConfig.parse(generator.config));
    expect(new Set(configs.map((config) => config.manifest)).size).toBe(1);
  });

  test("the language generators take the default config the providers are created with", () => {
    for (const generator of [KOTLIN, DART, RUST]) {
      expect(generatorConfig(generator.id)).toEqual({});
    }
  });
});

describe("naming agrees with generated Skir output", async () => {
  const { input, routes } = await committedRoutes();
  const providers = symbolProviders(input);
  const kotlin = generated(KOTLIN, input);
  const dart = generated(DART, input);
  const rust = [...generated(RUST, input).values()].join("\n");
  const kotlinFile = (modulePath: string) => kotlin.get(modulePath.replace(/\.skir$/u, ".kt"))!;
  const dartFile = (symbol: CodeGenerator.Symbol) => {
    const uri = /^import "([^"]+)" as /u.exec(symbol.imports[0]!)![1]!;
    expect(uri.startsWith(DART_PREFIX)).toBe(true);
    return dart.get(uri.slice(DART_PREFIX.length))!;
  };

  test("every route method resolves through the generator providers", () => {
    for (const { module, method } of methods(routes)) {
      const kotlinSymbol = providers.kotlin.method(module, method);
      const kotlinPackage = kotlinSymbol.reference.slice(0, kotlinSymbol.reference.lastIndexOf("."));
      expect(kotlinFile(module.path)).toContain(`package ${kotlinPackage};`);
      expect(kotlinFile(module.path)).toContain(`val ${last(kotlinSymbol.reference, ".")}:`);

      const dartSymbol = providers.dart.method(module, method);
      expect(dartFile(dartSymbol)).toContain(`> ${last(dartSymbol.reference, ".")} =`);

      const rustSymbol = providers.rust.method(module, method);
      expect(rustSymbol.reference.endsWith("()")).toBe(true);
      expect(rust).toContain(`pub fn ${last(rustSymbol.reference, "::").replace("()", "")}()`);
    }
  });

  test("every route record resolves through the generator providers", () => {
    for (const location of records(routes)) {
      const kotlinSymbol = providers.kotlin.record(location);
      expect(kotlinFile(location.modulePath)).toContain(`class ${last(kotlinSymbol.reference, ".")}`);

      const dartSymbol = providers.dart.record(location);
      expect(dartFile(dartSymbol)).toContain(`class ${last(dartSymbol.reference, ".")} `);

      const rustName = last(providers.rust.record(location).reference, "::");
      expect(rust).toMatch(new RegExp(`pub (struct|enum) ${rustName} `, "u"));
    }
  });

  test("every response variant resolves through the generator providers", () => {
    const enums = records(routes).filter((location) => location.record.recordType === "enum");
    expect(enums.length).toBeGreaterThan(0);
    for (const location of enums) {
      for (const variant of location.record.fields) {
        const kotlinConstant = last(providers.kotlin.variant(location, variant).reference, ".");
        expect(kotlinFile(location.modulePath)).toContain(`${kotlinConstant},\n`);

        const dartSymbol = providers.dart.variant(location, variant);
        expect(dartFile(dartSymbol)).toContain(`${last(dartSymbol.reference, ".")}(`);

        const rustPattern = last(providers.rust.variant(location, variant).reference, "::");
        expect(rustPattern.endsWith("(_)")).toBe(variant.type !== undefined);
        expect(rust).toContain(rustPattern.replace("(_)", ""));
      }
    }
  });
});
