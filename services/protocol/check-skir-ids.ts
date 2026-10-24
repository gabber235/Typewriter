// Verifies that Skir declaration IDs and enum variant numbers stay contiguous and ascending.
// Each file numbers its declarations from its own unique prefix: the first declaration in
// `editor/v1/action.skir` is 810700001, the next 810700002, and so on. Skir already rejects
// missing struct field numbers itself.

import { readdirSync, readFileSync } from "node:fs";
import { join, relative } from "node:path";

const root = process.argv[2] ?? "skir-src";

function skirFiles(directory: string): string[] {
  return readdirSync(directory, { withFileTypes: true }).flatMap((entry) => {
    const path = join(directory, entry.name);
    if (entry.isDirectory()) return skirFiles(path);
    return entry.name.endsWith(".skir") ? [path] : [];
  });
}

const prefixOwners = new Map<number, string>();

function checkDeclarations(file: string, source: string): string[] {
  const ids = [...source.matchAll(/\b(?:struct|enum)\s+(\w+)\s*\(\s*(\d+)\s*\)/g)]
    .map((match) => ({ name: match[1], id: Number(match[2]) }));
  if (ids.length === 0) return [];
  const prefix = ids[0].id - (ids[0].id % 1000);
  const owner = prefixOwners.get(prefix);
  if (owner !== undefined) return [`${file}: declaration prefix ${prefix} is already used by ${owner}`];
  prefixOwners.set(prefix, file);
  return ids.flatMap(({ name, id }, index) => {
    const expected = prefix + index + 1;
    return id === expected ? [] : [`${file}: ${name} has ID ${id}, expected ${expected}`];
  });
}

function checkVariants(file: string, source: string): string[] {
  const errors: string[] = [];
  const blocks: { name: string; isEnum: boolean; numbers: number[] }[] = [];
  for (let index = 0; index < source.length; index++) {
    const character = source[index];
    if (character === "{") {
      const header = source.slice(Math.max(0, index - 200), index)
        .match(/\b(struct|enum)\s*(\w+)?\s*(?:\(\s*\d+\s*\))?\s*$/);
      blocks.push({ name: header?.[2] ?? "<anonymous>", isEnum: header?.[1] === "enum", numbers: [] });
    } else if (character === "}") {
      const block = blocks.pop();
      if (!block?.isEnum || block.numbers.length === 0) continue;
      const first = block.numbers[0];
      const contiguous = (first === 0 || first === 1) &&
        block.numbers.every((number, position) => number === first + position);
      if (!contiguous) errors.push(`${file}: enum ${block.name} variants ${block.numbers.join(", ")} are not contiguous`);
    } else if (character === "=" && blocks.length > 0) {
      const number = source.slice(index).match(/^=\s*(\d+)\s*;/);
      if (number) blocks[blocks.length - 1].numbers.push(Number(number[1]));
    }
  }
  return errors;
}

const errors = skirFiles(root).sort().flatMap((path) => {
  const file = relative(root, path);
  const source = readFileSync(path, "utf8").replace(/\/\/[^\n]*/g, "");
  return [...checkDeclarations(file, source), ...checkVariants(file, source)];
});

if (errors.length > 0) {
  console.error(errors.join("\n"));
  process.exit(1);
}
