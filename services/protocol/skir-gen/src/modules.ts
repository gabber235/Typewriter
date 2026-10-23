import type { CodeGenerator, Module } from "skir-internal";

/**
 * The modules of the Skir input in module path order. Skir hands modules over in collection order,
 * which varies between runs; emitters that walk every module use this order to keep their output
 * stable.
 */
export function modulesInPathOrder(input: CodeGenerator.Input<unknown>): Module[] {
  return [...input.modules].sort((left, right) =>
    left.path < right.path ? -1 : left.path > right.path ? 1 : 0,
  );
}
