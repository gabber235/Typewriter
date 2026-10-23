import { readFileSync } from "node:fs";

import type { CodeGenerator } from "skir-internal";
import { z } from "zod";

import { symbolProviders } from "../symbols.js";
import { emitDartOperations } from "./emit/dart.js";
import { emitKotlinOperations } from "./emit/kotlin.js";
import { parseOperations } from "./manifest.js";
import { resolveOperations } from "./resolve.js";
import { unicodeTables } from "./unicode.js";

/** Operations generator options from skir.yml; the target language comes from the module export. */
export const OperationsConfig = z
  .object({
    /** Path of the operations manifest, relative to the Skir project root. */
    manifest: z.string().min(1),
    /** Directory holding one directory of Unicode character data per pinned release. */
    unicodeData: z.string().min(1),
    /** Package URI prefix of the Dart Skir output, required by the Dart target. */
    dartImportUriPrefix: z.string().min(1).optional(),
    /** Package URI of the hand written Dart operation runtime, required by the Dart target. */
    dartRuntimeImport: z.string().min(1).optional(),
  })
  .strict();

export type OperationsConfig = z.infer<typeof OperationsConfig>;

/** A language the operation catalog is generated for. */
export type OperationsTarget = "kotlin" | "dart";

/**
 * One Skir generator per target for the portable operation catalog of operations.yaml. It resolves every signature
 * against the parsed Skir modules and emits the target's declarations, kernel interfaces, dispatch, DSL and the pinned
 * Unicode release's tables in process.
 * Skir owns writing and cleaning the configured output directory.
 */
export function operationsGeneratorFor(target: OperationsTarget): CodeGenerator<OperationsConfig> {
  return {
    id: `typewriter-skir-gen-operations-${target}`,
    configType: OperationsConfig,
    generateCode(input) {
      const { manifest: path } = input.config;
      const catalog = resolveOperations(parseOperations(readFileSync(path, "utf8"), path), input);
      const symbols = symbolProviders(input);
      const tables = unicodeTables(catalog.unicode, input.config.unicodeData);
      const files =
        target === "kotlin"
          ? emitKotlinOperations(catalog, tables, symbols.kotlin, input)
          : emitDartOperations(catalog, tables, symbols.dart, input, requireDartRuntime(input.config));
      return { files };
    },
  };
}

function requireDartRuntime(config: OperationsConfig): string {
  if (!config.dartRuntimeImport) {
    throw new Error("The Dart operations target needs dartRuntimeImport in skir.yml");
  }
  return config.dartRuntimeImport;
}
