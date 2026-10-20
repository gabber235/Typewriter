import { readFileSync } from "node:fs";
import { fileURLToPath } from "node:url";

import type { CodeGenerator } from "skir-internal";
import { collectModules } from "skir/dist/module_collector.js";
import { ModuleSet } from "skir/dist/module_set.js";

import type { Config } from "../src/config.js";
import { parseManifest, type Manifest } from "../src/routes/manifest.js";
import { resolveRoutes, type ResolvedRoute } from "../src/routes/resolve.js";

const repository = (path: string) => fileURLToPath(new URL(`../../../../${path}`, import.meta.url));

/** The committed transport route manifest. */
export const MANIFEST_PATH = repository("services/protocol/transport-routes.yaml");

/** The Dart import prefix skir.yml configures for the panel. */
export const DART_PREFIX = "package:typewriter_panel/infrastructure/protocols/skir/skirout/";

/** Parses the committed transport route manifest. */
export function committedManifest(): Manifest {
  return parseManifest(readFileSync(MANIFEST_PATH, "utf8"), MANIFEST_PATH);
}

/** Compiles the repository Skir sources into the input skir gen hands to generators. */
export async function loadSkirInput(
  config: Partial<Config> = {},
): Promise<CodeGenerator.Input<Config>> {
  const modules = await collectModules(repository("skir-src"), ModuleSet.empty(), undefined, "strict");
  if (modules.errors.length > 0) {
    throw new Error(`skir-src does not compile: ${modules.errors.length} errors`);
  }
  return {
    modules: [...modules.modules.values()].map((module) => module.result),
    recordMap: modules.recordMap,
    config: { manifest: MANIFEST_PATH, dartImportUriPrefix: DART_PREFIX, ...config },
  };
}

/** Resolves the committed manifest against the repository Skir sources. */
export async function committedRoutes(): Promise<{
  input: CodeGenerator.Input<Config>;
  routes: ResolvedRoute[];
}> {
  const input = await loadSkirInput();
  return { input, routes: resolveRoutes(committedManifest(), input) };
}

/** A Skir input without modules, for admission checks that fail before any Skir lookup. */
export const EMPTY_INPUT: CodeGenerator.Input<unknown> = {
  modules: [],
  recordMap: new Map(),
  config: {},
};
