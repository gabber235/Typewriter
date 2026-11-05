// Verifies the Skir sources and the generator that turns them into code. Mirrors generate.ts, so
// protocol generation and protocol checks are both Bun programs next to the code they cover.
import { spawnSync } from "node:child_process";

function run(command: string, args: string[]): void {
  const result = spawnSync(command, args, { stdio: "inherit" });
  if (result.error) throw result.error;
  if (result.status !== 0) process.exit(result.status ?? 1);
}

// Scripts stay off: no dependency needs an install script.
run("bun", ["install", "--frozen-lockfile", "--ignore-scripts"]);
run("bunx", ["--bun", "--no-install", "skir", "format", "--ci"]);
run("bun", ["run", "--cwd", "services/protocol/skir-gen", "check"]);
run("bun", ["run", "test:skir-gen"]);
