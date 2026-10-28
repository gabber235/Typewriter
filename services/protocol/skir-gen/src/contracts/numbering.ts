import { tokenizeModule } from "skir/dist/tokenizer.js";
import type { Module, Record, Token } from "skir-internal";

/** Bounded contexts in dependency order. A context's index is the second digit of its numbers. */
export const CONTEXTS = ["kernel", "access", "organization", "service", "editor", "harness"] as const;
export type Context = (typeof CONTEXTS)[number];

/** One number in a Skir source and the value it must hold. */
export interface NumberSlot {
  readonly declaration: string;
  /** Source range of the current number, `?`, or an empty range where a record has none yet. */
  readonly start: number;
  readonly end: number;
  readonly current: number | null;
  readonly expected: number;
  /** `(84060001)` after a record name; `940601` after a method's `=`. */
  readonly replacement: string;
}

export function contextOf(modulePath: string): Context {
  const [context, version] = modulePath.split("/");
  const known = CONTEXTS.find((candidate) => candidate === context);
  if (known === undefined || version !== "v1") {
    throw new Error(`${modulePath} must live in <context>/v1/ with context one of ${CONTEXTS.join(", ")}`);
  }
  return known;
}

/**
 * Derived numbers of every named struct, enum and method of [module], which is file [fileIndex]
 * (1 based, alphabetical) of its context. Declarations are 8 C FF NNNN and methods 9 C FF NN,
 * counted in source order, so a number changes only when its file or position changes.
 */
export function numberSlots(module: Module, fileIndex: number): NumberSlot[] {
  const context = CONTEXTS.indexOf(contextOf(module.path));
  const source = module.sourceCode;
  // Skir's own tokens: comments are single tokens, so a `=` or `(` inside one never matches.
  const tokens = tokenizeModule(source, module.path).result.tokens;
  const records = module.records
    .map((location) => location.record)
    .filter((record) => isNamedDeclaration(source, record))
    .sort((left, right) => left.name.position - right.name.position);
  const recordSlots = records.map((record, index): NumberSlot => {
    const { start, end } = recordNumberRange(tokens, record.name);
    const expected = derived(8, context, fileIndex, index + 1, 4, module.path);
    return {
      declaration: record.name.text,
      start,
      end,
      current: record.recordNumber,
      expected,
      replacement: `(${expected})`,
    };
  });
  const methodSlots = module.methods.map((method, index): NumberSlot => {
    const { start, end } = methodNumberRange(tokens, method.name);
    const expected = derived(9, context, fileIndex, index + 1, 2, module.path);
    return {
      declaration: method.name.text,
      start,
      end,
      current: method.number < 0 ? null : method.number,
      expected,
      replacement: String(expected),
    };
  });
  return [...recordSlots, ...methodSlots];
}

function derived(kind: 8 | 9, context: number, file: number, position: number, width: number, path: string): number {
  if (file > 99) throw new Error(`${path}: a context holds at most 99 files`);
  if (position >= 10 ** width) throw new Error(`${path}: at most ${10 ** width - 1} ${kind === 8 ? "declarations" : "methods"} per file`);
  return Number(`${kind}${context}${String(file).padStart(2, "0")}${String(position).padStart(width, "0")}`);
}

/** Inline request and response records have no `struct Name` in source and carry no number. */
function isNamedDeclaration(source: string, record: Record): boolean {
  return /\b(?:struct|enum)\s+$/u.test(source.slice(Math.max(0, record.name.position - 16), record.name.position));
}

/** `(N)` or `(?)` right after a record name, or the empty range there when the record has no number yet. */
function recordNumberRange(tokens: readonly Token[], name: Token): { start: number; end: number } {
  const at = tokens.findIndex((token) => token.position === name.position);
  const afterName = name.position + name.originalText.length;
  if (tokens[at + 1]?.text !== "(") return { start: afterName, end: afterName };
  const close = tokens[at + 3];
  return { start: afterName, end: close.position + close.text.length };
}

/** The number (or `?`) after a method's top level `=`, skipping inline request and response records. */
function methodNumberRange(tokens: readonly Token[], name: Token): { start: number; end: number } {
  let depth = 0;
  for (let index = tokens.findIndex((token) => token.position === name.position) + 1; index < tokens.length; index++) {
    const { text } = tokens[index];
    if (text === "(" || text === "{" || text === "[" || text === "{|") depth++;
    else if (text === ")" || text === "}" || text === "]" || text === "|}") depth--;
    else if (text === "=" && depth === 0) {
      const number = tokens[index + 1];
      return { start: number.position, end: number.position + number.text.length };
    }
  }
  throw new Error(`method ${name.text} has no number; write \`= ?\``);
}
