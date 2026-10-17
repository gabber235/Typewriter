import { spawnSync } from "node:child_process";

function run(command: string, args: string[]): void {
  const result = spawnSync(command, args, { stdio: "inherit" });
  if (result.error) throw result.error;
  if (result.status !== 0) process.exit(result.status ?? 1);
}

run("cargo", [
  "build", "--locked", "--release", "--manifest-path",
  "services/protocol/transport-generator/Cargo.toml",
]);
run("services/protocol/transport-generator/target/release/typewriter-transport-generator", [
  "validate-subscriptions",
  "--manifest", "services/protocol/transport-routes.yaml",
  "--component", "auth-typewriter-permissions",
  "--deployment", "backend/access/auth-typewriter-permissions/deploy/base/workloaddeployment.yaml",
]);
run("bunx", ["--bun", "--no-install", "skir", "gen"]);
run("dart", [
  "services/protocol/transport-generator/normalize_generated_dart.dart",
  "panel/lib/infrastructure/protocols/skir/skirout",
  "panel/lib/infrastructure/messaging/generated/skirout",
]);
run("rustfmt", [
  "--edition", "2024",
  "backend/wasmcloud-utils/src/skirout/base.rs",
  "backend/wasmcloud-utils/src/transport_routes/skirout/mod.rs",
]);
run("dart", [
  "format",
  "panel/lib/infrastructure/protocols/skir/skirout",
  "panel/lib/infrastructure/messaging/generated/skirout",
]);
