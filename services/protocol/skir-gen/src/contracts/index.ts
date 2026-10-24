import { writeFileSync } from "node:fs";
import { join } from "node:path";

import { collectModules } from "skir/dist/module_collector.js";
import { ModuleSet } from "skir/dist/module_set.js";
import type { Module } from "skir-internal";

import { contextOf, numberSlots } from "./numbering.js";
import { importProblems, variantProblems } from "./rules.js";

/** A contract that cannot be fixed automatically; generation stops and prints every one. */
export interface ContractProblem {
  readonly path: string;
  readonly message: string;
}

/**
 * Brings every Skir file below [directory] to the derived numbering, rewriting only files whose
 * numbers differ, and returns the problems no rewrite can fix (forbidden imports, enum gaps).
 *
 * Parses leniently, as `skir format` does, so `= ?`, `(?)`, missing record numbers and duplicate
 * numbers are all accepted as input: those are exactly what this step replaces. Syntax errors stop it.
 */
export async function normalizeContracts(directory: string): Promise<ContractProblem[]> {
  const parsed = await collectModules(directory, ModuleSet.empty(), undefined, "lenient");
  const modules = [...parsed.modules.values()].map((entry) => entry.result);
  // Parser errors carry `expected` instead of `message`; duplicate numbers are what this step fixes.
  const syntax = parsed.errors.filter((error) => !error.message?.startsWith("Same number as"));
  if (syntax.length > 0) {
    return syntax.map((error) => ({
      path: error.token.line.modulePath,
      message: error.message ?? `expected ${error.expected} at line ${error.token.line.lineNumber + 1}`,
    }));
  }
  for (const [module, fileIndex] of fileIndexes(modules)) {
    const slots = numberSlots(module, fileIndex).filter((slot) => slot.current !== slot.expected);
    if (slots.length === 0) continue;
    // Rewrite from the end so earlier offsets stay valid.
    const source = slots
      .sort((left, right) => right.start - left.start)
      .reduce((text, slot) => text.slice(0, slot.start) + slot.replacement + text.slice(slot.end), module.sourceCode);
    writeFileSync(join(directory, module.path), source);
  }
  return modules.flatMap((module) => [...importProblems(module), ...variantProblems(module)]);
}

/**
 * Each module's 1 based position among the files of its context, by code unit order of the path
 * (`catalog.skir` before `catalog_presentation.skir`), never by locale.
 */
function fileIndexes(modules: readonly Module[]): Map<Module, number> {
  const sorted = [...modules].sort((left, right) => (left.path < right.path ? -1 : left.path > right.path ? 1 : 0));
  const next = new Map<string, number>();
  return new Map(sorted.map((module) => {
    const context = contextOf(module.path);
    const index = (next.get(context) ?? 0) + 1;
    next.set(context, index);
    return [module, index];
  }));
}
