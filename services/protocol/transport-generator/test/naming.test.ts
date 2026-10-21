import { describe, expect, test } from "bun:test";

import type { CodeGenerator, RecordLocation } from "skir-internal";
import { GENERATOR as DART } from "skir-dart-gen";
import { GENERATOR as KOTLIN } from "skir-kotlin-gen";
import { GENERATOR as RUST } from "skir-rust-gen";

import type { ResolvedRoute } from "../src/routes/resolve.js";
import { kotlinWrapperClass, symbolProviders } from "../src/symbols.js";
import { committedRoutes, DART_PREFIX } from "./support.js";

/** Concatenates the files of one Skir language generator for the same parsed modules. */
function generated(generator: CodeGenerator<object>, input: CodeGenerator.Input<unknown>): Map<string, string> {
  return new Map(
    generator.generateCode({ ...input, config: {} }).files.map((file) => [file.path, file.code]),
  );
}

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

        if (variant.type !== undefined) {
          const wrapper = last(kotlinWrapperClass(providers.kotlin, location, variant), ".");
          expect(kotlinFile(location.modulePath)).toContain(`class ${wrapper}`);
        }
      }
    }
  });
});
