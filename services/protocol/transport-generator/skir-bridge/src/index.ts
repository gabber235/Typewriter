import { spawnSync } from "node:child_process";

import type { CodeGenerator } from "skir-internal";
import { exportBindings as dartBindings } from "skir-dart-gen";
import { exportBindings as kotlinBindings } from "skir-kotlin-gen";
import { exportBindings as rustBindings } from "skir-rust-gen";
import { z } from "zod";

import type { LanguageBindings } from "./binding_contract.js";
import { exportCanonicalSymbols } from "./symbols.js";

const Config = z
  .object({
    executable: z.string().min(1),
    manifest: z.string().min(1),
    target: z.enum(["kotlin", "kotlin_loader", "dart", "rust"]),
    dartImportUriPrefix: z.string().min(1).optional(),
  })
  .strict();
type Config = z.infer<typeof Config>;

const Output = z
  .object({
    files: z.array(
      z.object({ path: z.string(), code: z.string() }).strict(),
    ),
  })
  .strict();
const Reference = z.object({ module: z.string(), name: z.string() }).strict();
const Requests = z
  .object({
    methods: z.array(Reference),
    records: z.array(
      z
        .object({ module: z.string(), path: z.array(z.string()) })
        .strict(),
    ),
  })
  .strict();

function run(
  config: Config,
  mode: "symbols" | "generate",
  input?: unknown,
): unknown {
  const result = spawnSync(
    config.executable,
    [mode, "--manifest", config.manifest, "--target", config.target],
    {
      input: input === undefined ? undefined : JSON.stringify(input),
      encoding: "utf8",
      maxBuffer: 64 * 1024 * 1024,
    },
  );
  if (result.error) {
    throw result.error;
  }
  if (result.status !== 0) {
    throw new Error(result.stderr || "Transport generation failed");
  }
  return JSON.parse(result.stdout);
}

function bindings(
  target: Config["target"],
  input: CodeGenerator.Input<Config>,
): LanguageBindings {
  switch (target) {
    case "kotlin":
    case "kotlin_loader":
      return kotlinBindings({ ...input, config: {} });
    case "dart":
      if (!input.config.dartImportUriPrefix) {
        throw new Error("Dart transport generation requires dartImportUriPrefix");
      }
      return dartBindings({
        ...input,
        config: {
          importUriPrefix: input.config.dartImportUriPrefix,
        },
      });
    case "rust":
      return rustBindings(input);
  }
}

export const GENERATOR: CodeGenerator<Config> = {
  id: "typewriter-transport",
  configType: Config,
  generateCode(input) {
    const requested = Requests.parse(run(input.config, "symbols"));
    const symbols = exportCanonicalSymbols(input, requested);
    const binding = bindings(input.config.target, input);
    const output = Output.parse(
      run(input.config, "generate", { symbols, binding }),
    );
    for (const file of output.files) {
      if (
        file.path.startsWith("/") ||
        file.path.split(/[\\/]/).some((part) => part === "..")
      ) {
        throw new Error(
          "Generator output must stay inside its owned target directory",
        );
      }
    }
    return output;
  },
};

export function generatorWithId(id: string): CodeGenerator<Config> {
  return { ...GENERATOR, id };
}
