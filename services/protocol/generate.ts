// Writes the Skir output and the subscription ConfigMaps; `cargo xtask generate` runs it when its
// inputs change. The Skir output is build output that Git ignores, so it is not formatted. The
// ConfigMaps are deployment manifests and stay tracked.
import { spawnSync } from "node:child_process";

import { normalizeContracts } from "typewriter-skir-gen/contracts";
import { writeSubscriptionConfigMaps } from "typewriter-skir-gen/routes/subscriptions";

const transportManifest = "services/protocol/transport-routes.yaml";
const skirSources = "skir-src";

function run(command: string, args: string[], cwd?: string): void {
  const result = spawnSync(command, args, { stdio: "inherit", cwd });
  if (result.error) throw result.error;
  if (result.status !== 0) process.exit(result.status ?? 1);
}

const problems = await normalizeContracts(skirSources);
if (problems.length > 0) {
  console.error(problems.map(({ path, message }) => `${path}: ${message}`).join("\n"));
  process.exit(1);
}
run("bunx", ["--bun", "--no-install", "skir", "gen"]);
// The NATS subscription ConfigMaps of component deployments come from the routes `skir gen` just admitted.
await writeSubscriptionConfigMaps(transportManifest, skirSources);
