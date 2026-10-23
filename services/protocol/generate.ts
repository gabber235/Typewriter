import { spawnSync } from "node:child_process";

import { writeSubscriptionConfigMaps } from "typewriter-skir-gen/routes/subscriptions";

const transportManifest = "services/protocol/transport-routes.yaml";
const skirSources = "skir-src";

const dartOutputs = [
  "panel/lib/infrastructure/protocols/skir/skirout",
  "panel/lib/infrastructure/messaging/generated/skirout",
  "panel/lib/infrastructure/protocols/operations/skirout",
];

function run(command: string, args: string[], cwd?: string): void {
  const result = spawnSync(command, args, { stdio: "inherit", cwd });
  if (result.error) throw result.error;
  if (result.status !== 0) process.exit(result.status ?? 1);
}

run("bun", ["services/protocol/check-skir-ids.ts", skirSources]);
run("bunx", ["--bun", "--no-install", "skir", "gen"]);
// The NATS subscription ConfigMaps of component deployments come from the routes `skir gen` just admitted.
await writeSubscriptionConfigMaps(transportManifest, skirSources);
run("rustfmt", [
  "--edition", "2024",
  "backend/wasmcloud-utils/src/skirout/base.rs",
  "backend/wasmcloud-utils/src/transport_routes/skirout/mod.rs",
]);
run("dart", ["format", ...dartOutputs]);
