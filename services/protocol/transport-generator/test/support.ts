import { readFileSync } from "node:fs";
import { fileURLToPath } from "node:url";

import type { CodeGenerator } from "skir-internal";
import { collectModules } from "skir/dist/module_collector.js";
import { ModuleSet } from "skir/dist/module_set.js";

import type { Config } from "../src/config.js";
import { parseManifest, type Manifest } from "../src/routes/manifest.js";
import { resolveRoutes, type ResolvedRoute, type ResolvedRoutes } from "../src/routes/resolve.js";

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
  resolved: ResolvedRoutes;
  routes: readonly ResolvedRoute[];
}> {
  const input = await loadSkirInput();
  const resolved = resolveRoutes(committedManifest(), input);
  return { input, resolved, routes: resolved.routes };
}

/** The role declarations of the committed manifest, for manifests written inline in tests. */
const ROLES = `roles:
  authenticated_user: { side: panel, personal: user }
  organization_member: { side: panel, tenant: [organization], personal: user }
  registered_service: { side: service, personal: service }
  realm_coordinator: { side: service, tenant: [organization, realm] }
  realm_participant: { side: service, tenant: [organization, realm] }
`;

/**
 * A manifest with the committed role declarations, the given components (each served or called by
 * the given routes) and the given route list items.
 */
export function manifestSource(routes: string, components: readonly string[] = []): string {
  const declared = components.map((component) => `  ${component}: backend/${component}/deploy/base\n`);
  const componentLines = declared.length === 0 ? " {}\n" : `\n${declared.join("")}`;
  return `${ROLES}components:${componentLines}routes:${routes === "" ? " []" : `\n${routes}`}`;
}

/** A Skir input without modules, for admission checks that fail before any Skir lookup. */
export const EMPTY_INPUT: CodeGenerator.Input<unknown> = {
  modules: [],
  recordMap: new Map(),
  config: {},
};
