import { readFileSync } from "node:fs";
import { join } from "node:path";

import { wrapWords } from "./emit/shared.js";

/**
 * Unicode character data for the portable expression text operations, read from one pinned Unicode
 * release and emitted as compact tables for Kotlin and Dart. Both runtimes implement case mapping,
 * case folding, normalization and white space from these tables alone, so they agree on every code
 * point regardless of the Unicode version their platform ships.
 *
 * Every table is encoded as a stream of unsigned integers spelled in a 91 character ASCII alphabet
 * (`!` to `~` without `"`, `$` and `\`), which both languages accept unescaped in a double quoted
 * literal. A digit below {@link TERMINAL_DIGITS} ends a number; a larger digit continues it. A
 * number is its continuation digits in base {@link CONTINUATION_DIGITS}, most significant first,
 * followed by one terminal digit in base {@link TERMINAL_DIGITS}. Signed deltas are zigzag encoded.
 * Each table documents the shape of its stream in {@link TABLES}.
 */

/** An inclusive range of code points. */
export interface CodePointRange {
  readonly start: number;
  readonly end: number;
}

/** A one level decomposition mapping from UnicodeData.txt. */
export interface Decomposition {
  /** Whether the mapping is tagged, so only compatibility normalization applies it. */
  readonly compatibility: boolean;
  readonly mapping: readonly number[];
}

/**
 * The character data the portable text operations need from one Unicode release, without language
 * tailoring. Full case mappings are the special mappings where present and the simple mappings
 * otherwise; full case folding is the `F` folding where present and the `C` folding otherwise.
 */
export interface UnicodeTables {
  readonly release: string;
  /** The White_Space property plus U+FEFF ZERO WIDTH NO-BREAK SPACE. */
  readonly whiteSpace: readonly CodePointRange[];
  /** The Cased property, for the Final_Sigma condition. */
  readonly cased: readonly CodePointRange[];
  /** The Case_Ignorable property, for the Final_Sigma condition. */
  readonly caseIgnorable: readonly CodePointRange[];
  readonly simpleUpper: ReadonlyMap<number, number>;
  readonly simpleLower: ReadonlyMap<number, number>;
  readonly simpleTitle: ReadonlyMap<number, number>;
  /** Unconditional SpecialCasing.txt uppercase mappings that differ from the simple mapping. */
  readonly specialUpper: ReadonlyMap<number, readonly number[]>;
  /** Unconditional SpecialCasing.txt lowercase mappings that differ from the simple mapping. */
  readonly specialLower: ReadonlyMap<number, readonly number[]>;
  /** Unconditional SpecialCasing.txt titlecase mappings that differ from the simple mapping. */
  readonly specialTitle: ReadonlyMap<number, readonly number[]>;
  /** Lowercase mappings that apply only when the Final_Sigma condition holds. */
  readonly finalSigmaLower: ReadonlyMap<number, readonly number[]>;
  /** CaseFolding.txt entries with status `C`. */
  readonly simpleFold: ReadonlyMap<number, number>;
  /** CaseFolding.txt entries with status `F`. */
  readonly fullFold: ReadonlyMap<number, readonly number[]>;
  /** Nonzero canonical combining classes. */
  readonly combiningClasses: ReadonlyMap<number, number>;
  /** Decomposition mappings, excluding Hangul syllables, which decompose algorithmically. */
  readonly decompositions: ReadonlyMap<number, Decomposition>;
  /** Code points whose two element canonical decomposition recomposes: not fully excluded. */
  readonly primaryComposites: readonly number[];
}

/** Reads the tables of `release` from `root/<release>/`. */
export function unicodeTables(release: string, root: string): UnicodeTables {
  const read = (file: string) => readFileSync(join(root, release, file), "utf8");
  const characters = parseUnicodeData(read("UnicodeData.txt"));
  const properties = parseProperties(read("PropList.txt"));
  const derived = parseProperties(read("DerivedCoreProperties.txt"));
  const special = parseSpecialCasing(read("SpecialCasing.txt"));
  const folding = parseCaseFolding(read("CaseFolding.txt"));
  const exclusions = new Set(parseCodePointList(read("CompositionExclusions.txt")));

  const simpleUpper = new Map<number, number>();
  const simpleLower = new Map<number, number>();
  const simpleTitle = new Map<number, number>();
  const combiningClasses = new Map<number, number>();
  const decompositions = new Map<number, Decomposition>();
  for (const character of characters) {
    const { codePoint } = character;
    if (character.upper !== undefined) simpleUpper.set(codePoint, character.upper);
    if (character.lower !== undefined) simpleLower.set(codePoint, character.lower);
    // UAX #44: an empty titlecase field means the titlecase mapping equals the uppercase mapping.
    const title = character.title ?? character.upper;
    if (title !== undefined) simpleTitle.set(codePoint, title);
    if (character.combiningClass !== 0) combiningClasses.set(codePoint, character.combiningClass);
    if (character.decomposition) decompositions.set(codePoint, character.decomposition);
  }

  const specialUpper = new Map<number, readonly number[]>();
  const specialLower = new Map<number, readonly number[]>();
  const specialTitle = new Map<number, readonly number[]>();
  const finalSigmaLower = new Map<number, readonly number[]>();
  for (const entry of special) {
    if (entry.condition === "Final_Sigma") {
      finalSigmaLower.set(entry.codePoint, entry.lower);
      continue;
    }
    if (entry.condition !== undefined) continue;
    const differs = (simple: ReadonlyMap<number, number>, full: readonly number[]) =>
      full.length !== 1 || full[0] !== (simple.get(entry.codePoint) ?? entry.codePoint);
    if (differs(simpleUpper, entry.upper)) specialUpper.set(entry.codePoint, entry.upper);
    if (differs(simpleLower, entry.lower)) specialLower.set(entry.codePoint, entry.lower);
    if (differs(simpleTitle, entry.title)) specialTitle.set(entry.codePoint, entry.title);
  }

  const simpleFold = new Map<number, number>();
  const fullFold = new Map<number, readonly number[]>();
  for (const entry of folding) {
    if (entry.status === "C") simpleFold.set(entry.codePoint, entry.mapping[0]!);
    if (entry.status === "F") fullFold.set(entry.codePoint, entry.mapping);
  }

  const combiningClass = (codePoint: number) => combiningClasses.get(codePoint) ?? 0;
  const primaryComposites = [...decompositions]
    .filter(
      ([codePoint, { compatibility, mapping }]) =>
        !compatibility &&
        mapping.length === 2 &&
        !exclusions.has(codePoint) &&
        combiningClass(codePoint) === 0 &&
        combiningClass(mapping[0]!) === 0,
    )
    .map(([codePoint]) => codePoint)
    .sort((left, right) => left - right);

  return {
    release,
    whiteSpace: mergeRanges([...(properties.get("White_Space") ?? []), { start: 0xfeff, end: 0xfeff }]),
    cased: mergeRanges(derived.get("Cased") ?? []),
    caseIgnorable: mergeRanges(derived.get("Case_Ignorable") ?? []),
    simpleUpper,
    simpleLower,
    simpleTitle,
    specialUpper,
    specialLower,
    specialTitle,
    finalSigmaLower,
    simpleFold,
    fullFold,
    combiningClasses,
    decompositions,
    primaryComposites,
  };
}

/** Renders the Kotlin `PortableUnicodeTables` object holding the encoded tables. */
export function emitKotlinUnicodeTables(tables: UnicodeTables): string {
  const output = [
    `// Generated from operations.yaml's pinned Unicode ${tables.release} release by`,
    "// services/protocol/transport-generator/src/operations/unicode.ts. Do not edit.",
    "",
    "package com.typewritermc.expression.operations",
    "",
    "/**",
    ` * Compact Unicode ${tables.release} character data for the portable text operations. Each table is a stream of`,
    " * unsigned integers in a 91 character ASCII alphabet that [PortableUnicode] decodes once, at first use. Bulk data",
    " * stays in string literals, split below the class file constant limit, so no initializer grows with the tables.",
    " */",
    "internal object PortableUnicodeTables {",
    `    /** The Unicode release these tables are generated from. */`,
    `    const val RELEASE: String = "${tables.release}"`,
    "",
    "    /** The digits of every table, in ascending order of value. */",
    `    const val ALPHABET: String = "${ALPHABET}"`,
    "",
    "    /** Digits below this value end a number; the others continue it. */",
    `    const val TERMINAL_DIGITS: Int = ${TERMINAL_DIGITS}`,
  ];
  for (const table of TABLES) {
    output.push("", `    /** ${table.doc} */`, `    fun ${table.name}(): String =`, "        listOf(");
    for (const chunk of chunks(encodeTable(table, tables))) output.push(`            "${chunk}",`);
    output.push(`        ).joinToString("")`);
  }
  output.push("}");
  return output.join("\n") + "\n";
}

/** Renders the Dart `PortableUnicodeTables` class holding the encoded tables, formatted as `dart format` would. */
export function emitDartUnicodeTables(tables: UnicodeTables): string {
  const output = [
    `// Generated from operations.yaml's pinned Unicode ${tables.release} release by`,
    "// services/protocol/transport-generator/src/operations/unicode.ts. Do not edit.",
    "",
    "/// Compact Unicode character data for the portable text operations.",
    "///",
    "/// Each table is a stream of unsigned integers in a 91 character ASCII",
    "/// alphabet that the portable Unicode kernel decodes once, at first use.",
    "abstract final class PortableUnicodeTables {",
    "  /// The Unicode release these tables are generated from.",
    `  static const release = "${tables.release}";`,
    "",
    "  /// The digits of every table, in ascending order of value.",
    "  static const alphabet =",
    `      "${ALPHABET}";`,
    "",
    "  /// Digits below this value end a number; the others continue it.",
    `  static const terminalDigits = ${TERMINAL_DIGITS};`,
  ];
  for (const table of TABLES) {
    output.push("", ...dartDoc(table.doc));
    const parts = chunks(encodeTable(table, tables));
    const single = `  static const ${table.name} = "${parts[0] ?? ""}";`;
    if (parts.length <= 1 && single.length <= 80) {
      output.push(single);
      continue;
    }
    output.push(`  static const ${table.name} =`);
    parts.forEach((part, index) => output.push(`      "${part}"${index === parts.length - 1 ? ";" : ""}`));
  }
  output.push("}");
  return output.join("\n") + "\n";
}

/** Characters per string literal line: a Dart literal line at its indentation stays within 80 columns. */
const CHUNK = 72;

function chunks(data: string): string[] {
  const parts: string[] = [];
  for (let index = 0; index < data.length; index += CHUNK) parts.push(data.slice(index, index + CHUNK));
  return parts;
}

/** A member dartdoc comment that stays within 80 columns. */
function dartDoc(text: string): string[] {
  return wrapWords(text, 80 - "  /// ".length).map((line) => `  /// ${line}`);
}

/** The digit alphabet: printable ASCII without the characters Kotlin or Dart literals would escape. */
export const ALPHABET = Array.from({ length: 0x7e - 0x21 + 1 }, (_, index) => String.fromCharCode(0x21 + index))
  .filter((character) => !`"$\\`.includes(character))
  .join("");

/** Digits that end a number. */
export const TERMINAL_DIGITS = 46;

/** Digits that continue a number. */
export const CONTINUATION_DIGITS = ALPHABET.length - TERMINAL_DIGITS;

/** Spells one unsigned integer. */
function encodeNumber(value: number): string {
  if (!Number.isSafeInteger(value) || value < 0) throw new Error(`cannot encode ${value}`);
  let rest = Math.floor(value / TERMINAL_DIGITS);
  let output = ALPHABET[value % TERMINAL_DIGITS]!;
  while (rest > 0) {
    output = ALPHABET[TERMINAL_DIGITS + (rest % CONTINUATION_DIGITS)]! + output;
    rest = Math.floor(rest / CONTINUATION_DIGITS);
  }
  return output;
}

function zigzag(value: number): number {
  return value < 0 ? -2 * value - 1 : 2 * value;
}

/** One encoded table: its accessor name, documentation, and integer stream. */
interface TableEncoding {
  readonly name: string;
  readonly doc: string;
  readonly numbers: (tables: UnicodeTables) => readonly number[];
}

function encodeTable(table: TableEncoding, tables: UnicodeTables): string {
  return table.numbers(tables).map(encodeNumber).join("");
}

const RANGE_SET = "Range set: (gap from the previous range end, length) pairs, ascending.";
const CASE_RUNS =
  "Case runs: (gap from the previous run end, (length - 1) * 2 + stride - 1, zigzag delta) triples; each code point a whole number of strides past the run start maps to itself plus the delta.";
const MULTI_MAP = "Multi map: (gap from the previous code point, count, count mapped code points) entries.";

/** The emitted tables, in emission order. */
const TABLES: readonly TableEncoding[] = [
  { name: "whiteSpace", doc: `White_Space plus U+FEFF. ${RANGE_SET}`, numbers: (t) => rangeSet(t.whiteSpace) },
  { name: "cased", doc: `Cased. ${RANGE_SET}`, numbers: (t) => rangeSet(t.cased) },
  { name: "caseIgnorable", doc: `Case_Ignorable. ${RANGE_SET}`, numbers: (t) => rangeSet(t.caseIgnorable) },
  { name: "simpleUpper", doc: `Simple uppercase mappings. ${CASE_RUNS}`, numbers: (t) => caseRuns(t.simpleUpper) },
  { name: "simpleLower", doc: `Simple lowercase mappings. ${CASE_RUNS}`, numbers: (t) => caseRuns(t.simpleLower) },
  { name: "simpleTitle", doc: `Simple titlecase mappings. ${CASE_RUNS}`, numbers: (t) => caseRuns(t.simpleTitle) },
  {
    name: "specialUpper",
    doc: `Unconditional full uppercase mappings that replace the simple mapping. ${MULTI_MAP}`,
    numbers: (t) => multiMap(t.specialUpper),
  },
  {
    name: "specialLower",
    doc: `Unconditional full lowercase mappings that replace the simple mapping. ${MULTI_MAP}`,
    numbers: (t) => multiMap(t.specialLower),
  },
  {
    name: "specialTitle",
    doc: `Unconditional full titlecase mappings that replace the simple mapping. ${MULTI_MAP}`,
    numbers: (t) => multiMap(t.specialTitle),
  },
  {
    name: "finalSigmaLower",
    doc: `Lowercase mappings under the Final_Sigma condition. ${MULTI_MAP}`,
    numbers: (t) => multiMap(t.finalSigmaLower),
  },
  { name: "simpleFold", doc: `Common (C) case foldings. ${CASE_RUNS}`, numbers: (t) => caseRuns(t.simpleFold) },
  {
    name: "fullFold",
    doc: `Full (F) case foldings that replace the common folding. ${MULTI_MAP}`,
    numbers: (t) => multiMap(t.fullFold),
  },
  {
    name: "combiningClasses",
    doc: "Nonzero canonical combining classes: (gap from the previous run end, length, class) triples.",
    numbers: (t) => combiningClassRuns(t.combiningClasses),
  },
  {
    name: "decompositions",
    doc: "Decomposition mappings without Hangul syllables: (gap from the previous code point, count * 2 + 1 when compatibility only, count mapped code points) entries. Each mapped code point is the zigzag delta from the previous entry's mapped code point at the same position, or its last one when that entry is shorter, or zero in the first entry.",
    numbers: (t) => decompositionEntries(t.decompositions),
  },
  {
    name: "primaryComposites",
    doc: "Primary composites, which compose from their two element canonical decomposition: gaps from the previous code point.",
    numbers: (t) => gaps(t.primaryComposites),
  },
];

function rangeSet(ranges: readonly CodePointRange[]): number[] {
  let end = 0;
  return ranges.flatMap((range) => {
    const encoded = [range.start - end, range.end - range.start + 1];
    end = range.end + 1;
    return encoded;
  });
}

interface CaseRun {
  readonly start: number;
  length: number;
  stride: number;
  readonly delta: number;
}

/** Groups mappings into runs of equal delta whose code points advance by a stride of one or two. */
function caseRuns(mappings: ReadonlyMap<number, number>): number[] {
  const runs: CaseRun[] = [];
  for (const [codePoint, target] of sorted(mappings)) {
    const delta = target - codePoint;
    const run = runs.at(-1);
    if (run && run.delta === delta) {
      const step = codePoint - run.start;
      if (run.length === 1 && (step === 1 || step === 2)) {
        run.stride = step;
        run.length = 2;
        continue;
      }
      if (run.length > 1 && step === run.length * run.stride) {
        run.length += 1;
        continue;
      }
    }
    runs.push({ start: codePoint, length: 1, stride: 1, delta });
  }
  let end = 0;
  return runs.flatMap((run) => {
    const encoded = [run.start - end, (run.length - 1) * 2 + run.stride - 1, zigzag(run.delta)];
    end = run.start + (run.length - 1) * run.stride + 1;
    return encoded;
  });
}

function multiMap(mappings: ReadonlyMap<number, readonly number[]>): number[] {
  let previous = 0;
  return sorted(mappings).flatMap(([codePoint, mapping]) => {
    const encoded = [codePoint - previous, mapping.length, ...mapping];
    previous = codePoint;
    return encoded;
  });
}

function combiningClassRuns(classes: ReadonlyMap<number, number>): number[] {
  const runs: { start: number; length: number; value: number }[] = [];
  for (const [codePoint, value] of sorted(classes)) {
    const run = runs.at(-1);
    if (run && run.value === value && run.start + run.length === codePoint) run.length += 1;
    else runs.push({ start: codePoint, length: 1, value });
  }
  let end = 0;
  return runs.flatMap((run) => {
    const encoded = [run.start - end, run.length, run.value];
    end = run.start + run.length;
    return encoded;
  });
}

function decompositionEntries(decompositions: ReadonlyMap<number, Decomposition>): number[] {
  let previous = 0;
  let previousMapping: readonly number[] = [0];
  return sorted(decompositions).flatMap(([codePoint, { compatibility, mapping }]) => {
    const deltas = mapping.map((mapped, index) => zigzag(mapped - (previousMapping[index] ?? previousMapping.at(-1)!)));
    const encoded = [codePoint - previous, mapping.length * 2 + (compatibility ? 1 : 0), ...deltas];
    previous = codePoint;
    previousMapping = mapping;
    return encoded;
  });
}

function gaps(codePoints: readonly number[]): number[] {
  let previous = 0;
  return codePoints.map((codePoint) => {
    const gap = codePoint - previous;
    previous = codePoint;
    return gap;
  });
}

function sorted<V>(map: ReadonlyMap<number, V>): [number, V][] {
  return [...map].sort(([left], [right]) => left - right);
}

function mergeRanges(ranges: readonly CodePointRange[]): CodePointRange[] {
  const merged: CodePointRange[] = [];
  for (const range of [...ranges].sort((left, right) => left.start - right.start)) {
    const last = merged.at(-1);
    if (last && range.start <= last.end + 1) merged[merged.length - 1] = { start: last.start, end: Math.max(last.end, range.end) };
    else merged.push(range);
  }
  return merged;
}

interface CharacterData {
  readonly codePoint: number;
  readonly combiningClass: number;
  readonly decomposition?: Decomposition;
  readonly upper?: number;
  readonly lower?: number;
  readonly title?: number;
}

/** Data lines of a UCD file: comments and blank lines removed, fields split and trimmed. */
function records(text: string): string[][] {
  return text
    .split("\n")
    .map((line) => line.replace(/#.*/, "").trim())
    .filter((line) => line.length > 0)
    .map((line) => line.split(";").map((field) => field.trim()));
}

function hex(value: string): number {
  if (!/^[0-9A-F]{4,6}$/.test(value)) throw new Error(`malformed code point ${value}`);
  return Number.parseInt(value, 16);
}

function hexes(value: string): number[] {
  return value.length === 0 ? [] : value.split(/\s+/).map(hex);
}

function optionalHex(value: string | undefined): number | undefined {
  return value ? hex(value) : undefined;
}

/**
 * The explicitly listed characters of UnicodeData.txt. Range entries (`<..., First>`) are skipped:
 * their characters have no case mappings, no combining class, and no tabled decomposition.
 */
function parseUnicodeData(text: string): CharacterData[] {
  return records(text)
    .filter((fields) => !fields[1]!.endsWith(", First>") && !fields[1]!.endsWith(", Last>"))
    .map((fields) => {
      const decomposition = fields[5]!;
      const compatibility = decomposition.startsWith("<");
      const mapping = hexes(compatibility ? decomposition.replace(/^<[^>]+>\s*/, "") : decomposition);
      return {
        codePoint: hex(fields[0]!),
        combiningClass: Number.parseInt(fields[3]!, 10),
        decomposition: mapping.length > 0 ? { compatibility, mapping } : undefined,
        upper: optionalHex(fields[12]),
        lower: optionalHex(fields[13]),
        title: optionalHex(fields[14]),
      };
    });
}

/** The ranges of every binary property listed in a `code..code ; Property` file. */
function parseProperties(text: string): Map<string, CodePointRange[]> {
  const properties = new Map<string, CodePointRange[]>();
  for (const [codes, property] of records(text)) {
    const [start, end = start] = codes!.split("..");
    const ranges = properties.get(property!) ?? [];
    ranges.push({ start: hex(start!), end: hex(end!) });
    properties.set(property!, ranges);
  }
  return properties;
}

function parseCodePointList(text: string): number[] {
  return records(text).flatMap(([codes]) => {
    const [start, end = start] = codes!.split("..");
    return Array.from({ length: hex(end!) - hex(start!) + 1 }, (_, index) => hex(start!) + index);
  });
}

interface SpecialCasing {
  readonly codePoint: number;
  readonly lower: number[];
  readonly title: number[];
  readonly upper: number[];
  readonly condition?: string;
}

function parseSpecialCasing(text: string): SpecialCasing[] {
  return records(text).map(([code, lower, title, upper, condition]) => ({
    codePoint: hex(code!),
    lower: hexes(lower!),
    title: hexes(title!),
    upper: hexes(upper!),
    condition: condition || undefined,
  }));
}

function parseCaseFolding(text: string): { codePoint: number; status: string; mapping: number[] }[] {
  return records(text).map(([code, status, mapping]) => ({
    codePoint: hex(code!),
    status: status!,
    mapping: hexes(mapping!),
  }));
}
