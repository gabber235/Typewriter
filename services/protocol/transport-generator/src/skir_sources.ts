import type { CodeGenerator } from "skir-internal";
import { collectModules } from "skir/dist/module_collector.js";
import { ModuleSet } from "skir/dist/module_set.js";

/** The parsed Skir model that `skir gen` hands to every generator, without a generator config. */
export type SkirSources = Pick<CodeGenerator.Input<unknown>, "modules" | "recordMap">;

/**
 * Compiles the Skir sources below `directory` in strict mode, the way `skir gen` does, for code
 * that resolves the transport routes outside a generator run. Throws when they do not compile.
 */
export async function compileSkirSources(directory: string): Promise<SkirSources> {
  const modules = await collectModules(directory, ModuleSet.empty(), undefined, "strict");
  if (modules.errors.length > 0) {
    throw new Error(`${directory} does not compile: ${modules.errors.length} errors`);
  }
  return {
    modules: [...modules.modules.values()].map((module) => module.result),
    recordMap: modules.recordMap,
  };
}
