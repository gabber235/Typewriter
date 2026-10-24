import { spawnSync } from "node:child_process";
import { globSync, readFileSync, rmSync, writeFileSync } from "node:fs";

import { parseManifest } from "./transport-generator/src/routes/manifest.js";
import { resolveRoutes } from "./transport-generator/src/routes/resolve.js";
import {
  orphanedSubscriptionFiles,
  subscriptionConfigMaps,
  SUBSCRIPTIONS_FILE,
} from "./transport-generator/src/routes/subscriptions.js";
import { compileSkirSources } from "./transport-generator/src/skir_sources.js";

const transportManifest = "services/protocol/transport-routes.yaml";
const skirSources = "skir-src";

const dartOutputs = [
  "panel/lib/infrastructure/protocols/skir/skirout",
  "panel/lib/infrastructure/messaging/generated/skirout",
];

function run(command: string, args: string[], cwd?: string): void {
  const result = spawnSync(command, args, { stdio: "inherit", cwd });
  if (result.error) throw result.error;
  if (result.status !== 0) process.exit(result.status ?? 1);
}

run("bun", ["services/protocol/check-skir-ids.ts", skirSources]);
run("bunx", ["--bun", "--no-install", "skir", "gen"]);
// Skir writes only into each generator's output directory, so the NATS subscription ConfigMaps
// that component deployments load are written here, from the routes `skir gen` just admitted.
const manifest = parseManifest(readFileSync(transportManifest, "utf8"), transportManifest);
const routes = resolveRoutes(manifest, { ...(await compileSkirSources(skirSources)), config: {} });
const configMaps = subscriptionConfigMaps(routes, (path) => readFileSync(path, "utf8"));
const existing = globSync(`backend/**/${SUBSCRIPTIONS_FILE}`, {
  exclude: (path) => path.includes("/target/") || path.includes("/node_modules/"),
});
for (const orphan of orphanedSubscriptionFiles(configMaps, existing)) {
  rmSync(orphan);
}
for (const file of configMaps) {
  writeFileSync(file.path, file.code);
}
run("rustfmt", [
  "--edition", "2024",
  "backend/wasmcloud-utils/src/skirout/base.rs",
  "backend/wasmcloud-utils/src/transport_routes/skirout/mod.rs",
]);
run("dart", ["format", ...dartOutputs]);
