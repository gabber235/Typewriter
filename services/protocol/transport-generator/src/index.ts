import { readFileSync } from "node:fs";

import type { CodeGenerator } from "skir-internal";

import { Config } from "./config.js";
import { emitDart } from "./routes/emit/dart.js";
import { emitKotlin } from "./routes/emit/kotlin.js";
import { emitRust } from "./routes/emit/rust.js";
import { parseManifest } from "./routes/manifest.js";
import { resolveRoutes, type ResolvedRoutes } from "./routes/resolve.js";
import { symbolProviders, type SymbolProviders } from "./symbols.js";

export { Config } from "./config.js";

/** A language whose transport route bindings one Skir generator entry writes. */
export type Target = "kotlin" | "dart" | "rust";

type Emitter = (
  routes: ResolvedRoutes,
  symbols: SymbolProviders,
  input: CodeGenerator.Input<Config>,
) => CodeGenerator.OutputFile[];

const EMITTERS: Record<Target, Emitter> = {
  kotlin: (routes, symbols) => emitKotlin(routes, symbols.kotlin),
  dart: (routes, symbols) => emitDart(routes, symbols.dart),
  rust: (routes, symbols, input) => emitRust(routes, symbols.rust, input),
};

function assertRelative(file: CodeGenerator.OutputFile): void {
  if (file.path.startsWith("/") || file.path.split(/[\\/]/u).some((part) => part === "..")) {
    throw new Error(`Generator output ${file.path} must stay inside its owned target directory`);
  }
}

/**
 * One Skir generator per target. It reads the route manifest, resolves every route against the
 * parsed Skir modules and emits the target's bindings in process. Skir owns writing and cleaning
 * the configured output directory, so every output path stays relative to it.
 */
export function generatorFor(target: Target): CodeGenerator<Config> {
  return {
    id: `typewriter-transport-${target}`,
    configType: Config,
    generateCode(input) {
      const { manifest: path } = input.config;
      const manifest = parseManifest(readFileSync(path, "utf8"), path);
      const routes = resolveRoutes(manifest, input);
      const files = EMITTERS[target](routes, symbolProviders(input), input);
      files.forEach(assertRelative);
      return { files };
    },
  };
}
