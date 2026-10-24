import type { Module } from "skir-internal";

import type { ContractProblem } from "./index.js";
import { contextOf } from "./numbering.js";

/**
 * A context imports only its own files and kernel, and kernel imports nothing (skir-src/AGENTS.md,
 * Contract boundary).
 */
export function importProblems(module: Module): ContractProblem[] {
  const context = contextOf(module.path);
  return Object.keys(module.pathToImportedNames).flatMap((imported) => {
    if (context === "kernel") {
      return [{ path: module.path, message: `kernel may not import ${imported}; kernel imports nothing` }];
    }
    const target = contextOf(imported);
    if (target === context || target === "kernel") return [];
    return [{
      path: module.path,
      message: `${context} may not import ${imported}; refer to ${target} entities through a kernel identity`,
    }];
  });
}

/**
 * Skir rejects struct field gaps itself; enum variants must also run 1, 2, 3 (Skir reserves 0 for
 * the unknown variant). `removed` keeps a gap for compatibility, which an unreleased contract never needs.
 */
export function variantProblems(module: Module): ContractProblem[] {
  return module.records.flatMap(({ record }) => {
    const problems: ContractProblem[] = [];
    if (record.removedNumbers.length > 0) {
      problems.push({ path: module.path, message: `${record.name.text} uses removed; renumber instead` });
    }
    if (record.recordType === "enum") {
      const numbers = record.fields.map((field) => field.number);
      if (!numbers.every((number, position) => number === position + 1)) {
        problems.push({ path: module.path, message: `enum ${record.name.text} variants ${numbers.join(", ")} are not 1, 2, 3, ...` });
      }
    }
    return problems;
  });
}
