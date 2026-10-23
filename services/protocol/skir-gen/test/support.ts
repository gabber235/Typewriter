import { readFileSync } from "node:fs";
import { fileURLToPath } from "node:url";

import type { CodeGenerator } from "skir-internal";
import { parse } from "yaml";
import { z } from "zod";

import { Config } from "../src/config.js";
import { OperationsConfig } from "../src/operations/index.js";
import { parseOperations } from "../src/operations/manifest.js";
import { parseManifest, type Manifest } from "../src/routes/manifest.js";
import { resolveRoutes, type ResolvedRoute, type ResolvedRoutes } from "../src/routes/resolve.js";
import { compileSkirSources } from "../src/skir_sources.js";

/** Resolves a path relative to the repository root, where skir.yml lives. */
export const repository = (path: string) => fileURLToPath(new URL(`../../../../${path}`, import.meta.url));

const SkirConfig = z.object({
  generators: z.array(z.object({ mod: z.string(), config: z.record(z.string(), z.unknown()) })),
});

/** The generator entries of the repository skir.yml. */
export const SKIR_GENERATORS = SkirConfig.parse(parse(readFileSync(repository("skir.yml"), "utf8"))).generators;

/** The config skir.yml gives the generator module `mod`. */
export function generatorConfig(mod: string): Record<string, unknown> {
  const entry = SKIR_GENERATORS.find((generator) => generator.mod === mod);
  if (!entry) {
    throw new Error(`skir.yml configures no generator ${mod}`);
  }
  return entry.config;
}

/** The config skir.yml gives the Dart transport target, the only one that takes every option. */
const TRANSPORT_CONFIG = Config.parse(generatorConfig("typewriter-skir-gen/routes/dart"));

/** The committed transport route manifest skir.yml configures. */
export const MANIFEST_PATH = repository(TRANSPORT_CONFIG.manifest);

/** The Dart import prefix skir.yml configures for the panel. */
export const DART_PREFIX = TRANSPORT_CONFIG.dartImportUriPrefix!;

/** Parses the committed transport route manifest. */
export function committedManifest(): Manifest {
  return parseManifest(readFileSync(MANIFEST_PATH, "utf8"), MANIFEST_PATH);
}

/** Compiles the repository Skir sources into the input skir gen hands to generators. */
export async function loadSkirInput(
  config: Partial<Config> = {},
): Promise<CodeGenerator.Input<Config>> {
  return {
    ...(await compileSkirSources(repository("skir-src"))),
    config: { ...TRANSPORT_CONFIG, manifest: MANIFEST_PATH, ...config },
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

/** The committed reply framing limits, appended so inline route lines keep their positions. */
const LIMITS = (() => {
  const { chunkBytes, maxChunks, replyTtlMs } = committedManifest().limits;
  return `limits: { chunk_bytes: ${chunkBytes}, max_chunks: ${maxChunks}, reply_ttl_ms: ${replyTtlMs} }\n`;
})();

/**
 * A manifest with the committed role declarations and limits, the given components (each served or
 * called by the given routes) and the given route list items.
 */
export function manifestSource(routes: string, components: readonly string[] = []): string {
  const declared = components.map((component) => `  ${component}: backend/${component}/deploy/base\n`);
  const componentLines = declared.length === 0 ? " {}\n" : `\n${declared.join("")}`;
  const routeLines = routes === "" ? " []\n" : `\n${routes}`;
  return `${ROLES}components:${componentLines}routes:${routeLines}${LIMITS}`;
}

/** A Skir input without modules, for admission checks that fail before any Skir lookup. */
export const EMPTY_INPUT: CodeGenerator.Input<unknown> = {
  modules: [],
  recordMap: new Map(),
  config: {},
};

/** The config skir.yml gives the Dart operations target, the only one that takes every option. */
export const OPERATIONS_CONFIG = OperationsConfig.parse(generatorConfig("typewriter-skir-gen/operations/dart"));

/** Parses the committed operations manifest skir.yml configures. */
export function committedOperations() {
  const path = repository(OPERATIONS_CONFIG.manifest);
  return parseOperations(readFileSync(path, "utf8"), path);
}
